import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class StatistikMaterialScreen extends StatefulWidget {
  const StatistikMaterialScreen({super.key});

  @override
  State<StatistikMaterialScreen> createState() => _StatistikMaterialScreenState();
}

class _StatistikMaterialScreenState extends State<StatistikMaterialScreen> {
  // Inisialisasi service partner API
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;

  // State data agregasi
  Map<String, dynamic> _today = {
    'totalWeight': 0.0,
    'percentageVsYesterday': 0.0,
    'trendText': '0% dari kemarin',
    'trend': 'EQUAL',
  };
  List<dynamic> _breakdown = [];
  List<dynamic> _recentSessions = [];

  // Penyesuaian tema warna
  static const Color _navyColor = Color(0xFF0F2C59);
  static const Color _badgeBgColor = Color(0xFFCEF5F5);
  static const Color _historyIconBgColor = Color(0xFFDDE9FA);
  static const Color _progressBgColor = Color(0xFFE8ECEF);

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  /// Mengambil data dari endpoint backend
  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _apiService.getMaterialStatistics();

    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'];
      setState(() {
        _today = data['today'] ?? _today;
        _breakdown = data['breakdown'] ?? [];
        _recentSessions = data['recentSessions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['message'];
        _isLoading = false;
      });
    }
  }

  /// Menentukan ikon berdasarkan tipe material daur ulang
  IconData _getMaterialIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'PET':
        return Icons.local_drink;
      case 'HDPE':
        return Icons.recycling;
      case 'PAPER':
      case 'KARDUS':
        return Icons.inventory_2_outlined;
      case 'ALUMINIUM':
        return Icons.view_in_ar_outlined;
      case 'GLASS':
        return Icons.wine_bar;
      default:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTrendDown = _today['trend'] == 'DOWN';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Statistik Material',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCyan,
                          ),
                          onPressed: _fetchStatistics,
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryCyan,
                  onRefresh: _fetchStatistics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. KARTU TOTAL TERKUMPUL HARI INI ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.scale_outlined,
                                size: 38,
                                color: _navyColor,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Total Terkumpul Hari Ini',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${_today['totalWeight']?.toString().replaceAll('.', ',') ?? '0'} ',
                                    style: const TextStyle(
                                      color: _navyColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'kg',
                                    style: TextStyle(
                                      color: _navyColor,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isTrendDown ? const Color(0xFFFFEBEE) : _badgeBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isTrendDown ? Icons.trending_down : Icons.trending_up,
                                      color: isTrendDown ? Colors.redAccent : AppColors.primaryCyan,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _today['trendText'] ?? '0% dari kemarin',
                                      style: TextStyle(
                                        color: isTrendDown ? Colors.redAccent : AppColors.primaryCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- 2. RINCIAN MATERIAL ---
                        const Text(
                          'Rincian Material',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_breakdown.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada material yang ditimbang hari ini',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._breakdown.map((item) {
                            final weight = item['totalWeight']?.toString().replaceAll('.', ',') ?? '0';
                            final double pct = (item['percentage'] as num?)?.toDouble() ?? 0.0;
                            return _buildMaterialCard(
                              icon: _getMaterialIcon(item['materialType']),
                              title: item['name'] ?? item['materialType'] ?? '-',
                              weight: '$weight kg',
                              percent: pct,
                            );
                          }),

                        const SizedBox(height: 16),

                        // --- 3. RIWAYAT TIMBANGAN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Riwayat Timbangan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/riwayat-pekerjaan');
                                }
                              },
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  color: _navyColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _recentSessions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Belum ada sesi timbangan hari ini',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recentSessions.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 24, color: Color(0xFFEEEEEE)),
                                  itemBuilder: (context, index) {
                                    final session = _recentSessions[index];
                                    return _buildRiwayatItem(
                                      session['sessionName'] ?? 'Sesi Penjemputan',
                                      session['subtitle'] ?? '-',
                                      session['weight'] ?? '0 kg',
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Helper Kartu Rincian Material Per Item
  Widget _buildMaterialCard({
    required IconData icon,
    required String title,
    required String weight,
    required double percent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: _navyColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                weight,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _navyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: _progressBgColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryCyan),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk Item Riwayat Timbangan
  Widget _buildRiwayatItem(String title, String subtitle, String weight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _historyIconBgColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.scale, color: _navyColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          weight,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _navyColor,
          ),
        ),
      ],
    );
  }
}