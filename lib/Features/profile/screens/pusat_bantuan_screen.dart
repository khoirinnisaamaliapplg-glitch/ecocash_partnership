import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

// Model data FAQ agar mudah di-mapping dari API Backend nantinya
class FaqItem {
  final String id;
  final String question;
  final String answer;

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class PusatBantuanScreen extends StatefulWidget {
  const PusatBantuanScreen({super.key});

  @override
  State<PusatBantuanScreen> createState() => _PusatBantuanScreenState();
}

class _PusatBantuanScreenState extends State<PusatBantuanScreen> {
  // List FAQ default (Siap diganti/diisi via API backend)
  final List<FaqItem> _faqList = [
    FaqItem(
      id: '1',
      question: 'Bagaimana cara mencairkan saldo ke rekening bank?',
      answer:
          'Buka menu Wallet > pilih Tarik Saldo > masukkan nominal dan pilih rekening bank tujuan Anda yang sudah terverifikasi.',
    ),
    FaqItem(
      id: '2',
      question: 'Mengapa tugas yang saya ambil dibatalkan otomatis?',
      answer:
          'Tugas dapat dibatalkan otomatis oleh sistem jika Anda tidak melakukan check-in di lokasi penjemputan dalam batas waktu yang ditentukan.',
    ),
    FaqItem(
      id: '3',
      question: 'Cara mengubah nomor telepon yang terdaftar?',
      answer:
          'Anda dapat mengubah nomor telepon pada menu Pengaturan > Edit Profil. Pastikan nomor baru aktif untuk menerima kode verifikasi OTP.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER & SEARCH BAR ---
            const Text(
              'Ada yang bisa kami bantu?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2B48),
              ),
            ),
            const SizedBox(height: 24),

            // --- BANTUAN CEPAT ---
            const Text(
              'Bantuan Cepat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            // Card Chat Customer Service (Utama)
            _buildChatCsCard(
              onTap: () => context.push('/chat-cs'),
            ),
            const SizedBox(height: 12),

            // Card Laporkan Masalah & Riwayat Laporan
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFDE8E8),
                    title: 'Laporkan Masalah',
                    onTap: () => context.push('/laporkan-masalah'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickHelpCard(
                    icon: Icons.history_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    title: 'Riwayat Laporan',
                    onTap: () => context.push('/riwayat-laporan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- PERTANYAAN POPULER (INTERAKTIF) ---
            const Text(
              'Pertanyaan Populer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            // Mapping item FAQ ke Widget Dropdown/Accordion
            ..._faqList.map((faq) => FaqExpandableTile(item: faq)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCsCard({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2B48),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chat Customer Service',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2B48),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Balasan instan',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2B48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DROPDOWN/ACCORDION FAQ INTERAKTIF ---
class FaqExpandableTile extends StatefulWidget {
  final FaqItem item;

  const FaqExpandableTile({super.key, required this.item});

  @override
  State<FaqExpandableTile> createState() => _FaqExpandableTileState();
}

class _FaqExpandableTileState extends State<FaqExpandableTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          title: Text(
            widget.item.question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F2B48),
              height: 1.3,
            ),
          ),
          trailing: Icon(
            _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: const Color(0xFF64748B),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.answer,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}