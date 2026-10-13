import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/app_storage.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class ChatCsScreen extends StatefulWidget {
  const ChatCsScreen({super.key});

  @override
  State<ChatCsScreen> createState() => _ChatCsScreenState();
}

class _ChatCsScreenState extends State<ChatCsScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  IO.Socket? _socket;
  String? _roomId;
  int? _userId;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  XFile? _selectedAttachment;

  @override
  void initState() {
    super.initState();
    _initChatSession();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChatSession() async {
    final userData = await AppStorage.getUserData();
    
    final dynamic partnerIdRaw = userData?['partner']?['id'] ?? 
                                 userData?['partnerId'] ?? 
                                 userData?['id'] ?? 
                                 userData?['user']?['id'];

    final int? partnerId = partnerIdRaw != null ? int.tryParse(partnerIdRaw.toString()) : null;

    if (partnerId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat profil mitra.')),
        );
      }
      return;
    }

    _userId = partnerId;

    final roomResult = await _apiService.getChatRoom(partnerId);
    if (roomResult['success'] == true && roomResult['data'] != null) {
      _roomId = roomResult['data']['id']?.toString();

      if (_roomId != null) {
        final historyResult = await _apiService.getChatHistory(_roomId!);
        if (historyResult['success'] == true) {
          _messages = historyResult['data'] is List ? historyResult['data'] : [];
        }

        _connectSocket();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(roomResult['message'] ?? 'Gagal terhubung ke room chat.')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _connectSocket() {
    final String cleanBaseUrl = ApiConstants.baseUrl.replaceAll('/api', '').replaceAll(RegExp(r'/$'), '');
    final String socketUrl = '$cleanBaseUrl/chat';

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Mendukung fallback polling untuk Web
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print('>>> [Socket Connected] Joined Room: $_roomId');
      _socket?.emit('joinRoom', _roomId);
    });

    // Listener Pesan Baru dari Server (Balasan CS / Admin)
    _socket?.on('newMessage', (data) {
      if (mounted) {
        final int incomingSenderId = int.tryParse(data['senderId']?.toString() ?? '') ?? 0;
        final String senderType = data['senderType'] ?? '';

        // Hanya tambahkan jika pesan datang dari ADMIN/CS (agar tidak duplikat dengan Optimistic Update)
        if (senderType == 'ADMIN' || incomingSenderId != _userId) {
          setState(() {
            _messages.add(data);
          });
          _scrollToBottom();
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedAttachment = image;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    if (_roomId == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi chat belum siap, silakan tunggu sebentar...')),
      );
      return;
    }

    String? uploadedUrl;

    if (_selectedAttachment != null) {
      final uploadRes = await _apiService.uploadSingleFile(
        _selectedAttachment!.path,
        xFile: _selectedAttachment,
        category: 'chat',
      );
      if (uploadRes['success'] == true) {
        uploadedUrl = uploadRes['url'];
      }
    }

    // 1. Optimistic Update: Tambahkan pesan langsung ke UI lokal
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'roomId': _roomId,
      'senderId': _userId,
      'message': text,
      'senderType': 'PARTNER',
      'attachmentUrl': uploadedUrl,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    _messageController.clear();
    setState(() {
      _selectedAttachment = null;
    });

    // 2. Kirim pesan ke Backend via REST API (sekaligus mentrigger broadcast Socket)
    final res = await _apiService.sendChatMessage(
      roomId: _roomId!,
      senderId: _userId!,
      message: text,
      attachmentUrl: uploadedUrl,
    );

    // 3. Fallback via Socket jika REST API gagal
    if (res['success'] != true) {
      _socket?.emit('sendMessage', {
        'roomId': _roomId,
        'senderId': _userId,
        'message': text,
        'senderType': 'PARTNER',
        'attachmentUrl': uploadedUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, color: AppColors.primaryCyan, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Customer Support', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('CS Online • Respons rata-rata < 5 menit', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final chat = _messages[index];
                      final String msg = chat['message'] ?? '';
                      final String senderType = chat['senderType'] ?? 'PARTNER';
                      final bool isMe = senderType == 'PARTNER';
                      final String? attachmentUrl = chat['attachmentUrl'];
                      final String time = chat['createdAt'] != null
                          ? chat['createdAt'].toString().substring(11, 16)
                          : '';

                      return _buildChatBubble(
                        message: msg,
                        time: time,
                        isMe: isMe,
                        attachmentUrl: attachmentUrl,
                      );
                    },
                  ),
                ),

                if (_selectedAttachment != null)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.image, color: AppColors.primaryCyan, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAttachment!.name,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () => setState(() => _selectedAttachment = null),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
                        onPressed: _pickAttachment,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryCyan,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 16),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChatBubble({
    required String message,
    required String time,
    required bool isMe,
    String? attachmentUrl,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryCyan : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    attachmentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: isMe ? Colors.white : AppColors.textPrimary),
                ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}