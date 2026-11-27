import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/constants/api_constants.dart';
import '../../../data/app_storage.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import '../../../core/widgets/app_loading.dart';

class ChatCsScreen extends StatefulWidget {
  const ChatCsScreen({super.key});

  @override
  State<ChatCsScreen> createState() => _ChatCsScreenState();
}

class _ChatCsScreenState extends State<ChatCsScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color _navy = Color(0xFF142D4E);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _background = Color(0xFFF4F6F9);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFE9EDF2);
  static const Color _green = Color(0xFF27945D);

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

    final dynamic partnerIdRaw =
        userData?['partner']?['id'] ??
        userData?['partnerId'] ??
        userData?['id'] ??
        userData?['user']?['id'];

    final int? partnerId = partnerIdRaw != null
        ? int.tryParse(partnerIdRaw.toString())
        : null;

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
          _messages = historyResult['data'] is List
              ? historyResult['data']
              : [];
        }

        _connectSocket();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              roomResult['message'] ?? 'Gagal terhubung ke room chat.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _connectSocket() {
    final String cleanBaseUrl = ApiConstants.baseUrl
        .replaceAll('/api', '')
        .replaceAll(RegExp(r'/$'), '');

    final String socketUrl = '$cleanBaseUrl/chat';

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print('>>> [Socket Connected] Joined Room: $_roomId');
      _socket?.emit('joinRoom', _roomId);
    });

    // Listener pesan baru dari server (balasan CS / Admin).
    _socket?.on('newMessage', (data) {
      if (mounted) {
        final int incomingSenderId =
            int.tryParse(data['senderId']?.toString() ?? '') ?? 0;

        final String senderType = data['senderType'] ?? '';

        // Mencegah pesan milik sendiri tampil dua kali.
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

    if (image != null && mounted) {
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
        const SnackBar(
          content: Text('Koneksi chat belum siap, silakan tunggu sebentar...'),
        ),
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

    // 1. Optimistic Update: tampilkan pesan langsung di UI lokal.
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'roomId': _roomId,
      'senderId': _userId,
      'message': text,
      'senderType': 'PARTNER',
      'attachmentUrl': uploadedUrl,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (!mounted) return;

    setState(() {
      _messages.add(tempMessage);
    });

    _scrollToBottom();

    _messageController.clear();

    setState(() {
      _selectedAttachment = null;
    });

    // 2. Kirim pesan melalui REST API.
    final res = await _apiService.sendChatMessage(
      roomId: _roomId!,
      senderId: _userId!,
      message: text,
      attachmentUrl: uploadedUrl,
    );

    // 3. Fallback melalui Socket jika REST API gagal.
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

  String _formatTime(dynamic value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _isLoading
                  ? AppLoading(
                      message: 'Menghubungkan ke Customer Service...',
                      size: 76,
                    )
                  : _buildMessageList(),
            ),

            if (_selectedAttachment != null) _buildAttachmentPreview(),

            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          // Tombol kembali
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _navy,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Avatar customer support
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: _yellow,
              size: 23,
            ),
          ),

          const SizedBox(width: 11),

          // Informasi CS
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Customer Support',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bantuan mitra EcoCash',
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Label support
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headset_mic_rounded, color: _green, size: 13),
                SizedBox(width: 5),
                Text(
                  'Support',
                  style: TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE LIST
  // ============================================================

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyChat();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
      itemCount: _messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 13),
      itemBuilder: (context, index) {
        final chat = _messages[index];

        final String msg = chat['message']?.toString() ?? '';
        final String senderType = chat['senderType']?.toString() ?? 'PARTNER';

        final bool isMe = senderType == 'PARTNER';

        final String? attachmentUrl = chat['attachmentUrl']?.toString();

        final String time = _formatTime(chat['createdAt']);

        return _buildChatBubble(
          message: msg,
          time: time,
          isMe: isMe,
          attachmentUrl: attachmentUrl,
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.forum_outlined, size: 39, color: _navy),
            ),

            const SizedBox(height: 20),

            const Text(
              'Mulai Percakapan',
              style: TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Belum ada pesan di sini. Kirim pertanyaan atau ceritakan kendala yang sedang kamu alami.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondary, fontSize: 12, height: 1.6),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, color: _green, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Percakapan bantuan mitra',
                    style: TextStyle(
                      color: _secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHAT BUBBLE
  // ============================================================

  Widget _buildChatBubble({
    required String message,
    required String time,
    required bool isMe,
    String? attachmentUrl,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isMe ? _navy : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 5),
              bottomRight: Radius.circular(isMe ? 5 : 18),
            ),
            border: isMe ? null : Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    attachmentUrl,
                    width: 230,
                    height: 165,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return Container(
                        width: 230,
                        height: 145,
                        color: isMe
                            ? Colors.white.withOpacity(0.10)
                            : _background,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _navy,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 230,
                        height: 90,
                        color: isMe
                            ? Colors.white.withOpacity(0.10)
                            : _background,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: _secondary,
                              size: 25,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Gambar tidak dapat dimuat',
                              style: TextStyle(color: _secondary, fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                if (message.isNotEmpty) const SizedBox(height: 9),
              ],

              if (message.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isMe ? Colors.white : const Color(0xFF263449),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 7),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 9,
                      color: isMe ? Colors.white60 : _secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: _yellow,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ATTACHMENT PREVIEW
  // ============================================================

  Widget _buildAttachmentPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6D9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.image_rounded, color: _navy, size: 21),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lampiran gambar',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedAttachment!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondary, fontSize: 10),
                ),
              ],
            ),
          ),

          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _selectedAttachment = null;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFE05252),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE INPUT
  // ============================================================

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border.withOpacity(0.9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: _background,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _pickAttachment,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.add_rounded, color: _navy, size: 25),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(fontSize: 12, color: _secondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                ),
                style: const TextStyle(color: _navy, fontSize: 13, height: 1.4),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Material(
            color: _navy,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _sendMessage,
              child: const SizedBox(
                width: 47,
                height: 47,
                child: Icon(Icons.send_rounded, color: _yellow, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
