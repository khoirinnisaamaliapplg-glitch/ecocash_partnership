import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ChatCsScreen extends StatelessWidget {
  const ChatCsScreen({super.key});

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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Text('Hari ini, 09:41', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ),
                const SizedBox(height: 16),
                // Pesan dari CS
                _buildChatBubble(
                  message: 'Halo Budi, ada yang bisa kami bantu?',
                  time: '09:42',
                  isMe: false,
                ),
                const SizedBox(height: 12),
                // Pesan dari User
                _buildChatBubble(
                  message: 'Saya mengalami masalah saat scan QR Smart Container.',
                  time: '09:44',
                  isMe: true,
                ),
                const SizedBox(height: 12),
                // Pesan balasan CS
                _buildChatBubble(
                  message: 'Baik, kami bantu cek. Silakan kirimkan foto QR atau kode Smart Container.',
                  time: '09:45',
                  isMe: false,
                ),
              ],
            ),
          ),
          // Input Pesan Bawah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.attach_file, color: AppColors.textSecondary), onPressed: () {}),
                IconButton(icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary), onPressed: () {}),
                Expanded(
                  child: TextField(
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
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({required String message, required String time, required bool isMe}) {
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