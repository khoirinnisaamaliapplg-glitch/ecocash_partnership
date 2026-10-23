import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color _cyanHeader = Color(0xFF00C7C9);
  static const Color _tealBubble = Color(0xFF178CA4);
  static const Color _navyColor = Color(0xFF0B3C5D);

  String get _customerName =>
      widget.extraData?['customerName'] ?? widget.extraData?['title'] ?? 'Ibu Ratna';

  String? get _avatarUrl => widget.extraData?['avatarUrl'];

  // Percakapan awal sesuai tampilan desain
  final List<ChatMessageItem> _messages = [
    ChatMessageItem(
      id: '1',
      text: 'Sesuai titik Penjemputan ya mas',
      time: '09:42',
      isMe: false,
    ),
    ChatMessageItem(
      id: '2',
      text: 'Baik Bu saya sedang dalam Perjalanan Mohon di tunggu ya',
      time: '09:44',
      isMe: true,
    ),
  ];

  final List<String> _quickReplies = [
    'Masalah Scan',
    'Masalah Pembayaran',
    'Masalah Pekerjaan',
    'Sudah Sampai Lokasi',
  ];

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(
        ChatMessageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          time: timeStr,
          isMe: true,
        ),
      );
      if (customText == null) {
        _messageController.clear();
      }
    });

    _scrollToBottom();
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
                          _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'U',
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
                  const Text(
                    '• Respon rata-rata < 5 menit',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // List Pesan Chat
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Pill Pembatas Tanggal
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Hari ini, 09:41',
                        style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  // Items Pesan
                  ..._messages.map((msg) => _buildChatBubble(msg)),
                ],
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

            // Input Bar Bawah
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.black54, size: 22),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54, size: 22),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: const CircleAvatar(
                      radius: 20,
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
                      _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'U',
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