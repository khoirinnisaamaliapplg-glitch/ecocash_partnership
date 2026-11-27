import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/widgets/app_loading.dart';

class DetailPenghasilanScreen extends StatefulWidget {
  const DetailPenghasilanScreen({super.key});

  @override
  State<DetailPenghasilanScreen> createState() =>
      _DetailPenghasilanScreenState();
}

class _DetailPenghasilanScreenState extends State<DetailPenghasilanScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;

  num _monthlyEarnings = 0;
  num _balance = 0;

  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  // =========================================================
  // PENGAMBILAN DATA API
  // =========================================================

  Future<void> _fetchEarningsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getDashboard(),
        _apiService.getMyJobs(status: 'COMPLETED'),
      ]);

      if (!mounted) return;

      final dashboardRes = results[0];
      final jobsRes = results[1];

      if (dashboardRes['success'] == true) {
        final walletSummary = dashboardRes['data']?['walletSummary'] ?? {};

        _monthlyEarnings = walletSummary['monthlyEarnings'] ?? 0;

        _balance = walletSummary['balance'] ?? 0;
      }

      if (jobsRes['success'] == true && jobsRes['data'] is List) {
        final List rawJobs = jobsRes['data'];

        _recentTransactions = rawJobs.map((item) {
          final job = item['job'] ?? {};

          final String title = job['title'] ?? 'Penjemputan Sampah';

          final String code = job['code'] != null
              ? '#${job['code'].toString().substring(0, 8).toUpperCase()}'
              : 'JOB-#${job['id']}';

          double totalKg = 0.0;

          final weights = (job['weights'] as List?) ?? [];

          for (var w in weights) {
            totalKg +=
                double.tryParse(
                  (w['handoverWeight'] ?? w['pickupWeight'] ?? 0).toString(),
                ) ??
                0.0;
          }

          final int earning =
              int.tryParse(
                (item['actualReward'] ?? item['job']?['actualReward'])
                        ?.toString() ??
                    '',
              ) ??
              (20000 + (totalKg * 1000)).toInt();

          String dateStr = (item['completedAt'] ?? item['assignedAt'] ?? '')
              .toString();

          if (dateStr.isNotEmpty) {
            try {
              final dt = DateTime.parse(dateStr).toLocal();
              dateStr = DateFormat('HH:mm').format(dt);
            } catch (_) {
              dateStr = 'Hari ini';
            }
          }

          return {
            'title': '$title $code',
            'subtitle': '${totalKg.toStringAsFixed(1)} kg • $dateStr',
            'amount': '+Rp${_formatNumber(earning)}',
          };
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal memuat data detail penghasilan';
        _isLoading = false;
      });
    }
  }

  String _formatNumber(num number) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(number);
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return formatter.format(amount);
  }

  // =========================================================
  // TAMPILAN UTAMA
  // =========================================================

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Memuat informasi penghasilan...')
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _fetchEarningsData,
                      color: AppColors.ecoGreen,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEarningsCard(),
                            const SizedBox(height: 25),
                            _buildChartCard(),
                            const SizedBox(height: 25),
                            _buildTransactionHeader(),
                            const SizedBox(height: 13),
                            _buildTransactionCard(),
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
  // HEADER ECO NATURE
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
                      'Penghasilan Saya',
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
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.darkNavy,
                  size: 22,
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
                  'Pantau hasil kerja dan perkembangan pendapatanmu',
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
  // KARTU PENGHASILAN
  // =========================================================

  // =========================================================
  // KARTU PENGHASILAN
  // =========================================================

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // --- GAMBAR DAUN (DISESUAIKAN AGAR PAS DI FRAME & TIDAK NGAMBANG) ---
            Positioned(
              right: 0,
              bottom: 80,
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/images/daun-eco.png',
                  width: 150,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox(
                      width: 300,
                      child: CustomPaint(painter: _PlantSilhouettePainter()),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 135,
                height: 135,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.035),
                ),
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
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryYellow.withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              color: AppColors.primaryYellow,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'PENGHASILAN',
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
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Total penghasilan bulan ini',
                    style: TextStyle(
                      color: Color(0xFFD0DCE8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.only(right: 55),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(_monthlyEarnings),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 23),
                  Container(height: 1, color: Colors.white.withOpacity(0.17)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.darkNavy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Dompet',
                            style: TextStyle(
                              color: Color(0xFFD0DCE8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatCurrency(_balance),
                            style: const TextStyle(
                              color: AppColors.primaryYellow,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
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
  // STATISTIK
  // =========================================================

  Widget _buildStatisticsCards() {
    final completedCount = _recentTransactions.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatisticItem(
            icon: Icons.task_alt_rounded,
            title: 'Pekerjaan selesai',
            value: '$completedCount',
            unit: 'pekerjaan',
            iconColor: AppColors.ecoGreen,
            backgroundColor: const Color(0xFFE5F5EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticItem(
            icon: Icons.payments_rounded,
            title: 'Penghasilan',
            value: _formatCurrency(_monthlyEarnings),
            unit: 'bulan ini',
            iconColor: AppColors.darkNavy,
            backgroundColor: const Color(0xFFFFF6C7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unit,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // GRAFIK PENDAPATAN
  // =========================================================

  Widget _buildChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.darkNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Pendapatan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ilustrasi aktivitas per jam',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hari ini',
                  style: TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(40, '08:00', false),
                _buildBar(60, '10:00', false),
                _buildBar(50, '12:00', false),
                _buildBar(100, '14:00', true),
                _buildBar(70, '16:00', false),
                _buildBar(30, '18:00', false),
                _buildBar(10, '20:00', false),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.ecoGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Aktivitas tertinggi',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Puncak',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightPercentage, String label, bool isHighlighted) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 19,
            height: (heightPercentage / 100) * 90,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.primaryYellow
                  : AppColors.ecoGreen.withOpacity(0.17),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RIWAYAT TRANSAKSI
  // =========================================================

  Widget _buildTransactionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Penghasilan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pekerjaan yang telah diselesaikan',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_recentTransactions.length} transaksi',
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: _recentTransactions.isEmpty
          ? _buildEmptyTransactions()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final tx = _recentTransactions[index];

                return _buildTransactionItem(
                  tx['title'],
                  tx['subtitle'],
                  tx['amount'],
                );
              },
            ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: const BoxDecoration(
              color: Color(0xFFE5F5EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 32,
              color: AppColors.ecoGreen,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pekerjaan yang selesai akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F5EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: AppColors.ecoGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
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
                amount,
                style: const TextStyle(
                  color: AppColors.ecoGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 10,
                      color: AppColors.ecoGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Selesai',
                      style: TextStyle(
                        color: AppColors.ecoGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Center(
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
              onPressed: _fetchEarningsData,
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
    );
  }
}

// =============================================================
// FALLBACK SILUET TANAMAN JIKA GAMBAR BELUM DITEMUKAN
// =============================================================

class _PlantSilhouettePainter extends CustomPainter {
  const _PlantSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF00AA13).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final leaf1 = Paint()..color = const Color(0xFF00AA13).withOpacity(0.85);

    final leaf2 = Paint()..color = const Color(0xFF38C95A).withOpacity(0.75);

    final stem = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.65,
        size.width * 0.65,
        size.height * 0.35,
        size.width * 0.95,
        0,
      );

    canvas.drawPath(stem, stemPaint);

    _drawLeaf(
      canvas,
      size,
      const Offset(0.68, 0.35),
      const Offset(0.98, 0.02),
      leaf1,
    );

    _drawLeaf(
      canvas,
      size,
      const Offset(0.68, 0.35),
      const Offset(0.45, 0.18),
      leaf2,
    );

    _drawLeaf(
      canvas,
      size,
      const Offset(0.56, 0.62),
      const Offset(0.95, 0.38),
      leaf2,
    );

    _drawLeaf(
      canvas,
      size,
      const Offset(0.56, 0.62),
      const Offset(0.12, 0.43),
      leaf1,
    );

    _drawLeaf(
      canvas,
      size,
      const Offset(0.48, 0.82),
      const Offset(0.86, 0.66),
      leaf1,
    );

    _drawLeaf(
      canvas,
      size,
      const Offset(0.48, 0.82),
      const Offset(0.20, 0.68),
      leaf2,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Size size,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final p1 = Offset(start.dx * size.width, start.dy * size.height);

    final p2 = Offset(end.dx * size.width, end.dy * size.height);

    final middle = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(middle.dx - 8, middle.dy - 28, p2.dx, p2.dy)
      ..quadraticBezierTo(middle.dx + 12, middle.dy + 20, p1.dx, p1.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlantSilhouettePainter oldDelegate) {
    return false;
  }
}
