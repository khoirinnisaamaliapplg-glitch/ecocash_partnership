import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';

// ======================================================
// FAQ MODEL
// ======================================================

class FaqItem {
  final String id;
  final String question;
  final String answer;

  FaqItem({required this.id, required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

// ======================================================
// PUSAT BANTUAN SCREEN
// ======================================================

class PusatBantuanScreen extends StatefulWidget {
  const PusatBantuanScreen({super.key});

  @override
  State<PusatBantuanScreen> createState() => _PusatBantuanScreenState();
}

class _PusatBantuanScreenState extends State<PusatBantuanScreen> {
  static const Color _navy = Color(0xFF142D4E);
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFE9EDF2);
  static const Color _yellow = Color(0xFFFFC928);

  bool _isLoading = true;

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
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: AppLoading(message: 'Menyiapkan pusat bantuan kamu...', size: 76),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroduction(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      'Bantuan Cepat',
                      'Pilih layanan yang Anda butuhkan',
                    ),
                    const SizedBox(height: 13),
                    _buildChatCsCard(onTap: () => context.push('/chat-cs')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickHelpCard(
                            icon: Icons.report_problem_outlined,
                            iconColor: const Color(0xFFE05252),
                            bgColor: const Color(0xFFFFEEEE),
                            title: 'Laporkan Masalah',
                            subtitle: 'Sampaikan kendala',
                            onTap: () => context.push('/laporkan-masalah'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickHelpCard(
                            icon: Icons.history_rounded,
                            iconColor: const Color(0xFF269B72),
                            bgColor: const Color(0xFFE8F7F0),
                            title: 'Riwayat Laporan',
                            subtitle: 'Lihat laporan Anda',
                            onTap: () => context.push('/riwayat-laporan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      'Pertanyaan Populer',
                      'Temukan jawaban dari pertanyaan berikut',
                    ),
                    const SizedBox(height: 13),
                    ..._faqList.map((faq) => FaqExpandableTile(item: faq)),
                    const SizedBox(height: 12),
                    _buildBottomInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }
  // ======================================================
  // HEADER
  // ======================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pusat Bantuan',
              style: TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryCyan,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // INTRODUCTION
  // ======================================================

  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      height: 145,
      padding: const EdgeInsets.only(left: 18, right: 18, top: 17, bottom: 0),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Halo, Mitra!',
                        style: TextStyle(
                          color: _yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Ada yang bisa kami bantu?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kami siap membantu kendala dan pertanyaan Anda.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 75),
            ],
          ),

          Positioned(
            right: -5,
            bottom: 0,
            child: Image.asset(
              'assets/images/bantuan.png',
              width: 250,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }
  // ======================================================
  // SECTION TITLE
  // ======================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _secondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ======================================================
  // CHAT CUSTOMER SERVICE
  // ======================================================

  Widget _buildChatCsCard({required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: _yellow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Customer Service',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Hubungi tim bantuan kami secara langsung',
                      style: TextStyle(
                        color: _secondary,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _secondary,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // QUICK HELP CARDS
  // ======================================================

  Widget _buildQuickHelpCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 125),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: _secondary, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // BOTTOM INFORMATION
  // ======================================================

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _secondary, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum menemukan jawaban? Silakan hubungi Customer Service kami.',
              style: TextStyle(color: _secondary, fontSize: 10, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// FAQ EXPANDABLE TILE
// ======================================================

class FaqExpandableTile extends StatefulWidget {
  final FaqItem item;

  const FaqExpandableTile({super.key, required this.item});

  @override
  State<FaqExpandableTile> createState() => _FaqExpandableTileState();
}

class _FaqExpandableTileState extends State<FaqExpandableTile> {
  bool _isExpanded = false;

  static const Color _navy = Color(0xFF142D4E);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: PageStorageKey(widget.item.id),
          initiallyExpanded: _isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          title: Text(
            widget.item.question,
            style: const TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _secondary,
              size: 22,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: Text(
                  widget.item.answer,
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
