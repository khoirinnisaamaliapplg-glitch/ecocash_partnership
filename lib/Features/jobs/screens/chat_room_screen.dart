import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/app_storage.dart';
import '../../../services/api_service.dart';

class ChatMessageItem {
  final String id;
  final String text;
  final String time;
  final bool isMe;

  ChatMessageItem({
    required this.id,
    required this.text,
    required this.time,
    required this.isMe,
  });
}

class ChatRoomScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? extraData;

  const ChatRoomScreen({
    super.key,
    required this.jobId,
    this.extraData,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  io.Socket? _chatSocket;
  bool _isSocketConnected = false;

  String? _roomId;
  int? _partnerId;
  String _customerName = 'Warga EcoCash';
  String? _avatarUrl;
  bool _isLoading = true;
  Timer? _pollingTimer;

  List<ChatMessageItem> _messages = [];

  final List<String> _quickReplies = [
    'Sesuai titik penjemputan ya bu/pak',
    'Saya sedang dalam perjalanan',
    'Sudah sampai di depan lokasi',
    'Mohon bantuannya untuk timbang sampah',
  ];

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (_chatSocket != null) {
      if (_roomId != null) {
        _chatSocket!.emit('leaveRoom', _roomId);
      }
      _chatSocket!.disconnect();
      _chatSocket!.dispose();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChatRoom() async {
    final profile = await AppStorage.getProfile();
    if (profile != null) {
      _partnerId = profile['id'] ?? profile['partnerId'];
    }

    if (widget.extraData != null) {
      _customerName = widget.extraData!['customerName'] ??
          widget.extraData!['user']?['name'] ??
          widget.extraData!['title'] ??
          'Warga EcoCash';
      _avatarUrl = widget.extraData!['avatarUrl'] ?? widget.extraData!['user']?['avatarUrl'];
    }

    try {
      final res = await _apiService.getJobRoom(widget.jobId);
      if (res['success'] == true && res['data'] != null) {
        final room = res['data'];
        _roomId = room['id']?.toString();

        if (room['partnerId'] != null) {
          _partnerId ??= room['partnerId'];
        }

        if (room['customer'] != null) {
          _customerName = room['customer']['name'] ?? _customerName;
          _avatarUrl = room['customer']['avatarUrl'] ?? _avatarUrl;
        }

        if (room['messages'] is List) {
          _parseMessages(room['messages']);
        }
      }
    } catch (e) {
      debugPrint('Error init chat room: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }

    if (_roomId != null) {
      await _connectChatSocket(_roomId!);
    }
    _startMessagePolling();
  }

  Future<void> _connectChatSocket(String roomId) async {
    final token = await AppStorage.getToken();
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');

    final socket = io.io(
      '$base/chat',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token ?? ''})
          .enableReconnection()
          .build(),
    );

    socket.onConnect((_) {
      if (!mounted) return;
      setState(() => _isSocketConnected = true);
      socket.emit('joinRoom', roomId);
    });

    socket.onDisconnect((_) {
      if (!mounted) return;
      setState(() => _isSocketConnected = false);
    });

    socket.on('newMessage', (data) {
      if (!mounted || data is! Map) return;
      final String senderType = (data['senderType'] ?? '').toString().toUpperCase();
      // Abaikan pantulan pesan sendiri yang sudah ditambahkan lewat optimistic UI
      if (senderType == 'PARTNER') return;

      final String incomingId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      if (_messages.any((m) => m.id == incomingId)) return;

      final DateTime dt = DateTime.tryParse(data['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      setState(() {
        _messages.add(
          ChatMessageItem(
            id: incomingId,
            text: (data['message'] ?? '').toString(),
            time: timeStr,
            isMe: false,
          ),
        );
      });
      _scrollToBottom();
    });

    _chatSocket = socket;
  }

  void _startMessagePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (!mounted || _roomId == null) return;
      try {
        final res = await _apiService.getChatHistory(_roomId!);
        if (res['success'] == true && res['data'] is List) {
          final List rawList = res['data'];
          if (rawList.length > _messages.length && mounted) {
            setState(() {
              _parseMessages(rawList);
            });
            _scrollToBottom();
          }
        }
      } catch (_) {}
    });
  }

  void _parseMessages(List rawList) {
    _messages = rawList.map((msg) {
      final String senderType = (msg['senderType'] ?? '').toString().toUpperCase();
      final bool isMe = (senderType == 'PARTNER');

      final DateTime dt = DateTime.tryParse(msg['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      return ChatMessageItem(
        id: msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: msg['message'] ?? '',
        time: timeStr,
        isMe: isMe,
      );
    }).toList();
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(
        ChatMessageItem(
          id: now.millisecondsSinceEpoch.toString(),
          text: text,
          time: timeStr,
          isMe: true,
        ),
      );
    });
    _scrollToBottom();

    if (_roomId != null) {
      try {
        await _apiService.sendChatMessage(
          roomId: _roomId!,
          senderId: _partnerId ?? 1,
          message: text,
          senderType: 'PARTNER',
        );
      } catch (e) {
        debugPrint('Gagal mengirim pesan chat: $e');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.darkNavy,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? Text(
                          _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'W',
                          style: const TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.ecoGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryYellow, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customerName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Order #${widget.jobId} • Nasabah',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slateNavy,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isSocketConnected ? const Color(0xFF22C55E) : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSocketConnected ? 'LIVE' : 'SYNC',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Memuat percakapan...', size: 68)
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryYellow.withValues(alpha: 0.28),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 36,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Mulai obrolan dengan $_customerName',
                                style: const TextStyle(
                                  color: AppColors.darkNavy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Gunakan balasan cepat di bawah untuk konfirmasi lokasi.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildChatBubble(_messages[index]);
                          },
                        ),
            ),

            // Quick Reply Chips
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chipText = _quickReplies[index];
                  return OutlinedButton(
                    onPressed: () => _sendMessage(chipText),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkNavy, width: 1.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      chipText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan ke nasabah...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.darkNavy,
                      child: Icon(Icons.send_rounded, color: AppColors.primaryYellow, size: 19),
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

  Widget _buildChatBubble(ChatMessageItem msg) {
    if (msg.isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.darkNavy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.35),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  msg.time,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 14, color: AppColors.ecoGreen),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 60),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.4),
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Text(
                      _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'W',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkNavy,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.time,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
