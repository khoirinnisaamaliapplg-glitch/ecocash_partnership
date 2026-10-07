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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// Mengambil data dashboard dari endpoint GET /partners/me/dashboard
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.getDashboard();

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _dashboardData = res['data'];
          _availableJobs = res['data']?['availableJobsPreview'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Gagal mengambil data dashboard';
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
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
      ),
    );

    final res = await _apiService.acceptJob(jobId);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Tutup loading dialog

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan berhasil diambil!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh data dashboard & pindah ke riwayat pekerjaan
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
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6F8),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                  onPressed: _fetchDashboardData,
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mapping Data dari Response API
    final profile = _dashboardData?['partnerProfile'] ?? {};
    final wallet = _dashboardData?['walletSummary'] ?? {};
    final stats = _dashboardData?['performanceStats'] ?? {};

    final String namaUser = profile['name'] ?? widget.userData['name'] ?? widget.userData['nama'] ?? 'Mitra';
    final num monthlyEarnings = wallet['monthlyEarnings'] ?? 0;
    final num totalWeight = stats['totalWeightCollectedKg'] ?? 0;
    final int jobsCompleted = stats['monthlyJobsCompleted'] ?? 0;
    final String level = profile['level'] ?? 'Silver';
    final int score = profile['score'] ?? 0;
    final int maxScore = profile['maxScore'] ?? 1000;
    final double progressValue = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        color: AppColors.primaryCyan,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER DENGAN GRADIENT & SAPAAN ---
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: HeaderWaveClipper(),
                    child: Container(
                      width: double.infinity,
                      height: 240,
                      decoration: const BoxDecoration(color: AppColors.primaryCyan),
                    ),
                  ),
                  ClipPath(
                    clipper: CurvedColorWaveClipper(),
                    child: Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $namaUser!',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ready to recycle?',
                          style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // KARTU TOTAL PENGHASILAN
                  Positioned(
                    top: 150,
                    left: 20,
                    right: 20,
                    child: InkWell(
                      onTap: () => context.push('/detail-penghasilan'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Penghasilan Bulan Ini', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(_formatCurrency(monthlyEarnings), style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(Icons.trending_up, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('Tercatat Real-time', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),

              // --- STATISTIK RINGKASAN ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Material',
                            '${totalWeight.toString().replaceAll('.', ',')} kg',
                            'Terkumpul',
                            Icons.recycling,
                            const Color(0xFF1565C0),
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
                            Colors.green,
                            onTap: () => context.push('/riwayat-pekerjaan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // KARTU LEVEL PARTNER
                    InkWell(
                      onTap: () => context.push('/skor-partner'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Level $level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                const Text('Gold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Skor Partner: $score/$maxScore', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: const Color(0xFFE0E0E0),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('${maxScore - score} poin lagi ke Level Gold', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- PEKERJAAN TERSEDIA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pekerjaan Tersedia',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton(
                          onPressed: () => context.push('/riwayat-pekerjaan'),
                          child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_availableJobs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(
                          child: Text('Belum ada pekerjaan tersedia saat ini', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                      )
                    else
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableJobs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final job = _availableJobs[index];
                            final machine = job['machine'] ?? {};
                            final int jobId = job['id'];
                            final String code = job['code'] ?? 'JOB-#$jobId';
                            final String title = job['title'] ?? 'Penjemputan Sampah';
                            final String address = machine['placeName'] ?? machine['address'] ?? 'Lokasi Mesin';
                            final String priority = job['priority'] ?? 'MEDIUM';

                            return _buildJobCard(
                              jobId: jobId,
                              code: code,
                              title: title,
                              distance: address,
                              price: 'Rp15.000+',
                              priority: priority,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color iconColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
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
                  child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priority == 'HIGH' || priority == 'URGENT' ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: priority == 'HIGH' || priority == 'URGENT' ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(distance, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryCyan)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _acceptJob(jobId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ambil', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 35);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 25);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 50);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CurvedColorWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, size.height * 0.12);

    var controlPoint = Offset(size.width * 0.6, size.height * 0.45);
    var endPoint = Offset(size.width, size.height * 0.22);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}