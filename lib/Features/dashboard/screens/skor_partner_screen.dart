import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6F8),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                onPressed: _fetchScoreData,
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _dashboardData?['partnerProfile'] ?? 
                _dashboardData?['partner'] ?? 
                _dashboardData?['profile'] ?? {};
    final String level = profile['level'] ?? 'Bronze';
    final int score = profile['score'] ?? 0;
    final int maxScore = profile['maxScore'] ?? 300;
    final double progressValue = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    final int remainingPoints = (maxScore - score).clamp(0, maxScore);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Skor Partner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Online', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchScoreData,
        color: AppColors.primaryCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. KARTU LEVEL UTAMA ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primaryCyan.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.military_tech, size: 48, color: AppColors.primaryCyan),
                    ),
                    const SizedBox(height: 16),
                    Text('Level $level', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$score', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text('/$maxScore', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Pertahankan performa luar biasa Anda!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: const Color(0xFFE0E0E0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(level, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('Target ($maxScore)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. BENEFIT LEVEL (Bonus Pendapatan 5% Dihapus) ---
              Text('Benefit Level $level', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.star_outline,
                const Color(0xFF1565C0),
                'Prioritas Tugas',
                'Akses lebih awal ke tugas-tugas penjemputan bervolume tinggi.',
                const Color(0xFF1565C0),
              ),
              const SizedBox(height: 24),

              // --- 3. RINCIAN PERFORMA ---
              const Text('Rincian Performa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(
                  children: [
                    _buildPerformanceRow(Icons.recycling, 'Kualitas Material', 'Akurasi pemilahan sampah', '${(score * 0.35).round()}', '300', Colors.green),
                    const Divider(height: 24, color: Color(0xFFEEEEEE)),
                    _buildPerformanceRow(Icons.local_shipping_outlined, 'Kecepatan Penjemputan', 'Ketepatan waktu tiba di lokasi', '${(score * 0.25).round()}', '250', Colors.green),
                    const Divider(height: 24, color: Color(0xFFEEEEEE)),
                    _buildPerformanceRow(Icons.thumb_up_outlined, 'Rating Pelanggan', 'Kepuasan pengguna aplikasi', '${(score * 0.20).round()}', '200', Colors.orange),
                    const Divider(height: 24, color: Color(0xFFEEEEEE)),
                    _buildPerformanceRow(Icons.event_available_outlined, 'Kehadiran', 'Konsistensi aktif mingguan', '${(score * 0.20).round()}', '250', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 4. TIPS LEVEL DENGAN TOMBOL ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.primaryCyan),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tips Meningkatkan Skor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryCyan)),
                              const SizedBox(height: 4),
                              Text(
                                remainingPoints > 0
                                    ? 'Kumpulkan $remainingPoints poin lagi untuk naik ke level berikutnya! Selesaikan tugas penjemputan harian Anda.'
                                    : 'Selamat! Anda telah mencapai skor maksimal.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () => context.push('/daftar-pekerjaan', extra: {'fromDashboard': true}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B2B48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lihat Tugas Tersedia',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, Color iconColor, String title, String subtitle, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(IconData icon, String title, String subtitle, String score, String maxScore, Color scoreColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(score, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scoreColor)),
            Text('/$maxScore', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}