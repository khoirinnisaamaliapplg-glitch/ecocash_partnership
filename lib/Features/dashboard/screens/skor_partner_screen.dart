import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/widgets/app_loading.dart';

class SkorPartnerScreen extends StatefulWidget {
  const SkorPartnerScreen({super.key});

  @override
  State<SkorPartnerScreen> createState() => _SkorPartnerScreenState();
}

class _SkorPartnerScreenState extends State<SkorPartnerScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchScoreData();
  }

  // =========================================================
  // PENGAMBILAN DATA API - TETAP DIPERTAHANKAN
  // =========================================================

  Future<void> _fetchScoreData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _apiService.getDashboard();

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _dashboardData = res['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Gagal memuat data skor partner';
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // TAMPILAN UTAMA
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoading(message: 'Menyiapkan skor partner kamu...', size: 76),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final profile =
        _dashboardData?['partnerProfile'] ??
        _dashboardData?['partner'] ??
        _dashboardData?['profile'] ??
        {};

    final String level = profile['level'] ?? 'Bronze';
    final int score = profile['score'] ?? 0;
    final int maxScore = profile['maxScore'] ?? 300;

    final double progressValue = maxScore > 0
        ? (score / maxScore).clamp(0.0, 1.0)
        : 0.0;

    final int remainingPoints = (maxScore - score).clamp(0, maxScore);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchScoreData,
                color: AppColors.ecoGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScoreCard(level, score, maxScore, progressValue),
                      const SizedBox(height: 26),

                      _buildSectionHeader(
                        'Keuntungan Level',
                        'Benefit yang kamu dapatkan',
                      ),
                      const SizedBox(height: 13),
                      _buildBenefitCard(),
                      const SizedBox(height: 26),

                      _buildSectionHeader(
                        'Rincian Performa',
                        'Komponen penilaian partner',
                      ),
                      const SizedBox(height: 13),
                      _buildPerformanceCard(score),
                      const SizedBox(height: 26),

                      _buildTipsCard(remainingPoints, maxScore),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECOCASH PARTNER',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Skor Partner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.darkNavy,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Pantau pencapaian dan perkembangan performamu',
                  style: TextStyle(
                    color: Color(0xFFD5E1E8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(Icons.eco_rounded, color: Color(0xFF55C878), size: 19),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KARTU SKOR UTAMA
  // =========================================================

  Widget _buildScoreCard(
    String level,
    int score,
    int maxScore,
    double progressValue,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2C59), Color(0xFF075B48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.17),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.045),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -65,
              child: Icon(
                Icons.eco_rounded,
                size: 190,
                color: AppColors.ecoGreen.withOpacity(0.17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryYellow.withOpacity(0.28),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.primaryYellow,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'PARTNER LEVEL',
                              style: TextStyle(
                                color: AppColors.primaryYellow,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF7DE2A5),
                        size: 21,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryYellow.withOpacity(0.2),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.darkNavy,
                          size: 37,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Level Partner Saat Ini',
                              style: TextStyle(
                                color: Color(0xFFD0DCE8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              level,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -1.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 5),
                        child: Text(
                          '/ $maxScore poin',
                          style: const TextStyle(
                            color: Color(0xFFD0DCE8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.17),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progres pencapaian',
                        style: TextStyle(
                          color: Color(0xFFD0DCE8),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(progressValue * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.primaryYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 19),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.primaryYellow,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            score >= maxScore
                                ? 'Kamu telah mencapai skor maksimal!'
                                : 'Terus tingkatkan performamu untuk mencapai target.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

  // =========================================================
  // JUDUL BAGIAN
  // =========================================================

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  // =========================================================
  // BENEFIT LEVEL
  // =========================================================

  Widget _buildBenefitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5C2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.darkNavy,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prioritas Tugas',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Akses lebih awal ke tugas-tugas penjemputan bervolume tinggi.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textMuted,
            size: 14,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RINCIAN PERFORMA
  // =========================================================

  Widget _buildPerformanceCard(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPerformanceRow(
            Icons.recycling_rounded,
            'Kualitas Material',
            'Akurasi pemilahan sampah',
            '${(score * 0.35).round()}',
            '300',
            AppColors.ecoGreen,
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildPerformanceRow(
            Icons.local_shipping_outlined,
            'Kecepatan Penjemputan',
            'Ketepatan waktu tiba di lokasi',
            '${(score * 0.25).round()}',
            '250',
            AppColors.ecoGreen,
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildPerformanceRow(
            Icons.thumb_up_alt_outlined,
            'Rating Pelanggan',
            'Kepuasan pengguna aplikasi',
            '${(score * 0.20).round()}',
            '200',
            AppColors.warning,
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildPerformanceRow(
            Icons.event_available_rounded,
            'Kehadiran',
            'Konsistensi aktif mingguan',
            '${(score * 0.20).round()}',
            '250',
            AppColors.ecoGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(
    IconData icon,
    String title,
    String subtitle,
    String score,
    String maxScore,
    Color scoreColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6F2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.ecoGreen, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '/ $maxScore',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIPS MENINGKATKAN SKOR
  // =========================================================

  Widget _buildTipsCard(int remainingPoints, int maxScore) {
    final bool isMaxScore = remainingPoints <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9DC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isMaxScore
                      ? Icons.emoji_events_rounded
                      : Icons.lightbulb_rounded,
                  color: AppColors.darkNavy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips Meningkatkan Skor',
                      style: TextStyle(
                        color: AppColors.darkNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Jaga konsistensi dan tingkatkan kualitas pekerjaanmu.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isMaxScore
                ? 'Selamat! Kamu telah mencapai skor maksimal.'
                : 'Kumpulkan $remainingPoints poin lagi untuk mencapai target $maxScore poin. Selesaikan tugas penjemputan dan berikan pelayanan terbaik.',
            style: const TextStyle(
              color: AppColors.slateNavy,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              onPressed: () => context.push(
                '/daftar-pekerjaan',
                extra: {'fromDashboard': true},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                foregroundColor: AppColors.primaryYellow,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline_rounded, size: 18),
                  SizedBox(width: 9),
                  Text(
                    'Lihat Tugas Tersedia',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 7),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 42,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Data Belum Bisa Dimuat',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Terjadi kesalahan',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: _fetchScoreData,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkNavy,
                          foregroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
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
