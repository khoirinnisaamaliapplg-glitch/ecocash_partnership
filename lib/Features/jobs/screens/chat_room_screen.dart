import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/app_storage.dart';
import 'package:ecocash_partnership/services/api_service.dart';

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

  static const Color _cyanHeader = Color(0xFF00C7C9);
  static const Color _tealBubble = Color(0xFF178CA4);
  static const Color _navyColor = Color(0xFF0B3C5D);

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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChatRoom() async {
    // 1. Ambil ID Partner kurir dari storage lokal
    final profile = await AppStorage.getProfile();
    if (profile != null) {
      _partnerId = profile['id'] ?? profile['partnerId'];
    }

    // 2. Ambil fallback nama & avatar dari parameter navigasi
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
        _roomId = room['id'];

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

    // 3. Polling update pesan setiap 3.5 detik
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
      if (!mounted || _roomId == null) return;
      try {
        final res = await _apiService.getChatHistory(_roomId!);
        if (res['success'] == true && res['data'] is List) {
          final List rawList = res['data'];
          if (rawList.length != _messages.length) {
            if (mounted) {
              setState(() {
                _parseMessages(rawList);
              });
              _scrollToBottom();
            }
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

    // Optimistic UI update
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _cyanHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? Text(
                          _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'W',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87),
                      shape: BoxShape.circle,
                      border: Border.all(color: _cyanHeader, width: 1.5),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Order #${widget.jobId} • Nasabah',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
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
                  ? const Center(child: CircularProgressIndicator(color: _cyanHeader))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'Mulai obrolan dengan $_customerName',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chipText = _quickReplies[index];
                  return OutlinedButton(
                    onPressed: () => _sendMessage(chipText),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _navyColor, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      chipText,
                      style: const TextStyle(fontSize: 11, color: _navyColor, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan ke nasabah...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: const CircleAvatar(
                      radius: 21,
                      backgroundColor: _tealBubble,
                      child: Icon(Icons.send, color: Colors.white, size: 18),
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
                color: _tealBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.3),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  msg.time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 14, color: _tealBubble),
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
              radius: 14,
              backgroundColor: Colors.teal.shade100,
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Text(
                      _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'W',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEDED),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.time,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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