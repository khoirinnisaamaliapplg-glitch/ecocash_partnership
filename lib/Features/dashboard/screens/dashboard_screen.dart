import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, this.userData = const {}});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;

  // State Data Dashboard
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _availableJobs = [];
  num _todayMaterialWeight = 0; // State untuk berat material hari ini

  // Palet Warna Resmi EcoCash Brand Palette
  static const Color _primaryYellow = Color(0xFFFFE600);
  static const Color _primaryDark = Color(0xFF1C1C1E);
  static const Color _ecoGreen = Color(0xFF00AA13);
  static const Color _darkNavy = Color(0xFF0F2C59);
  static const Color _appBackground = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// Mengambil data dashboard dan statistik material dari API
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Panggil API Dashboard dan API Statistik Material secara sejajar
      final results = await Future.wait([
        _apiService.getDashboard(),
        _apiService.getMaterialStatistics(),
      ]);

      if (!mounted) return;

      final dashboardRes = results[0];
      final statsRes = results[1];

      if (dashboardRes['success'] == true) {
        num weightToday = 0;

        // Ambil data totalWeight hari ini dari response getMaterialStatistics
        if (statsRes['success'] == true && statsRes['data']?['today'] != null) {
          weightToday = statsRes['data']['today']['totalWeight'] ?? 0;
        }

        setState(() {
          _dashboardData = dashboardRes['data'];
          _availableJobs = dashboardRes['data']?['availableJobsPreview'] ?? [];
          _todayMaterialWeight = weightToday;
          _isLoading = false;
        });

        debugPrint('=== RESPONSE DASHBOARD ===');
        debugPrint('$_dashboardData');
      } else {
        setState(() {
          _errorMessage = dashboardRes['message'] ?? 'Gagal mengambil data dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi ke server';
        _isLoading = false;
      });
    }
  }

  /// Memproses pengambilan pekerjaan via API
  Future<void> _acceptJob(int jobId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _darkNavy),
      ),
    );

    final res = await _apiService.acceptJob(jobId);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan berhasil diambil!'),
          backgroundColor: _ecoGreen,
        ),
      );
      _fetchDashboardData();
      context.push('/riwayat-pekerjaan');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengambil pekerjaan'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _appBackground,
        body: Center(
          child: CircularProgressIndicator(color: _darkNavy),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _appBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkNavy,
                  ),
                  onPressed: _fetchDashboardData,
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _dashboardData?['partnerProfile'] ??
        _dashboardData?['partner'] ??
        _dashboardData?['profile'] ?? {};
    final wallet = _dashboardData?['walletSummary'] ?? {};
    final stats = _dashboardData?['performanceStats'] ?? {};

    final String namaUser =
        profile['name'] ??
        widget.userData['name'] ??
        widget.userData['nama'] ??
        'Mitra';
    final num monthlyEarnings = wallet['monthlyEarnings'] ?? 0;
    final int jobsCompleted = stats['monthlyJobsCompleted'] ?? 0;
    final String level = profile['level'] ?? 'Bronze';
    final int score = profile['score'] ?? 0;
    final int maxScore = profile['maxScore'] ?? 300;
    final double progressValue = maxScore > 0
        ? (score / maxScore).clamp(0.0, 1.0)
        : 0.0;

    // Kalkulasi target level berikutnya dan sisa poin secara dinamis
    String nextLevel = 'Silver';
    if (level.toUpperCase() == 'SILVER') {
      nextLevel = 'Gold';
    } else if (level.toUpperCase() == 'GOLD') {
      nextLevel = 'Maksimal';
    }
    final int remainingPoints = (maxScore - score).clamp(0, maxScore);

    return Scaffold(
      backgroundColor: _appBackground,
      body: RefreshIndicator(
        color: _darkNavy,
        onRefresh: _fetchDashboardData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double topSafePadding = MediaQuery.paddingOf(context).top;

            // Ukuran banner proporsional mengikuti lebar layar (rasio gambar ~2.05 : 1)
            final double bannerWidth = (screenWidth * 0.74).clamp(245.0, 450.0);
            final double bannerHeight = bannerWidth / 2.05;
            final double headerHeight = topSafePadding + bannerHeight + 54;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Kuning Solid Responsif + Ilustrasi Banner dengan Tepi Memudar Halus
                  Container(
                    width: double.infinity,
                    height: headerHeight,
                    decoration: const BoxDecoration(
                      color: _primaryYellow,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        // Ilustrasi Banner di Sisi Kanan dengan Efek Feathering di Semua Tepi
                        Positioned(
                          top: topSafePadding + 8,
                          right: 0,
                          width: bannerWidth,
                          height: bannerHeight,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.26, 0.95, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.16, 0.84, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image.asset(
                                'assets/images/banner_partner.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // Teks Sapaan Kiri Atas
                        Positioned(
                          top: topSafePadding + 26,
                          left: 20,
                          right: bannerWidth * 0.68,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Hi, $namaUser!',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready to recycle?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _primaryDark.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kartu Total Penghasilan (Bayangan Kuning Tipis)
                  Transform.translate(
                    offset: const Offset(0, -44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: InkWell(
                        onTap: () => context.push('/detail-penghasilan'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _primaryDark,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryYellow.withOpacity(0.22),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Penghasilan Bulan Ini',
                                style: TextStyle(
                                  color: _primaryYellow,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatCurrency(monthlyEarnings),
                                style: const TextStyle(
                                  color: _primaryYellow,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.trending_up,
                                    color: _ecoGreen,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tercatat Real-time',
                                    style: TextStyle(
                                      color: _ecoGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Konten Statistik & Pekerjaan
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Material',
                                  '${_todayMaterialWeight.toString().replaceAll('.', ',')} kg',
                                  'Hari ini',
                                  Icons.recycling,
                                  _darkNavy,
                                  onTap: () => context.push('/statistik-material'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Pekerjaan',
                                  '$jobsCompleted Selesai',
                                  'Bulan ini',
                                  Icons.local_shipping_outlined,
                                  _ecoGreen,
                                  onTap: () => context.push('/riwayat-pekerjaan'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () => context.push('/skor-partner'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryYellow.withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Level $level',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        nextLevel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _ecoGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Skor Partner: $score/$maxScore',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    child: LinearProgressIndicator(
                                      value: progressValue,
                                      backgroundColor: const Color(0xFFE0E0E0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        _ecoGreen,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      remainingPoints > 0
                                          ? '$remainingPoints poin lagi ke Level $nextLevel'
                                          : 'Selamat! Level Anda sudah maksimal',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pekerjaan Tersedia',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/daftar-pekerjaan',
                                  extra: {'fromDashboard': true},
                                ),
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    color: _darkNavy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_availableJobs.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryYellow.withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Belum ada pekerjaan tersedia saat ini',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 160,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _availableJobs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final job = _availableJobs[index];
                                  final machine = job['machine'] ?? {};
                                  final int jobId = job['id'];
                                  final String rawCode = job['code'] ?? 'JOB-#$jobId';
                                  final String code = rawCode.length > 10
                                      ? '#${rawCode.substring(0, 8).toUpperCase()}'
                                      : rawCode;
                                  final String title =
                                      job['title'] ?? 'Penjemputan Sampah';
                                  final String address =
                                      machine['placeName'] ??
                                      machine['address'] ??
                                      'Lokasi Penjemputan';
                                  final String priority = job['priority'] ?? 'MEDIUM';

                                  final String jobPrice = job['price'] ??
                                      (job['machineId'] == null
                                          ? 'Rp20.000+'
                                          : 'Rp35.000+');

                                  return _buildJobCard(
                                    jobId: jobId,
                                    code: code,
                                    title: title,
                                    distance: address,
                                    price: jobPrice,
                                    priority: priority,
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryYellow.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard({
    required int jobId,
    required String code,
    required String title,
    required String distance,
    required String price,
    required String priority,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryYellow.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priority == 'HIGH' || priority == 'URGENT'
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: priority == 'HIGH' || priority == 'URGENT'
                        ? Colors.red
                        : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimasi',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _darkNavy,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _acceptJob(jobId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ambil',
                  style: TextStyle(fontSize: 12, color: _primaryYellow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}