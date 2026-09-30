import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class StatistikMaterialScreen extends StatelessWidget {
  const StatistikMaterialScreen({super.key});

  // Penyesuaian warna persis sesuai gambar
  static const Color _navyColor = Color(0xFF0F2C59);
  static const Color _badgeBgColor = Color(0xFFCEF5F5);
  static const Color _historyIconBgColor = Color(0xFFDDE9FA);
  static const Color _progressBgColor = Color(0xFFE8ECEF);

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
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
                    children: const [
                      Text(
                        '48,6 ',
                        style: TextStyle(
                          color: _navyColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
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
                      color: _badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.trending_up,
                          color: AppColors.primaryCyan,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+12% dari kemarin',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
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

            // --- 2. RINCIAN MATERIAL (6 KARTU ITEM) ---
            const Text(
              'Rincian Material',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildMaterialCard(
              icon: Icons.local_drink,
              title: 'PET (Botol)',
              weight: '20,5 kg',
              percent: 0.45,
            ),
            _buildMaterialCard(
              icon: Icons.local_drink,
              title: 'PET (Botol)',
              weight: '20,5 kg',
              percent: 0.45,
            ),
            _buildMaterialCard(
              icon: Icons.local_drink,
              title: 'PET (Botol)',
              weight: '20,5 kg',
              percent: 0.45,
            ),
            _buildMaterialCard(
              icon: Icons.recycling,
              title: 'HDPE',
              weight: '15,2 kg',
              percent: 0.32,
            ),
            _buildMaterialCard(
              icon: Icons.inventory_2_outlined,
              title: 'Kardus',
              weight: '8,4 kg',
              percent: 0.18,
            ),
            _buildMaterialCard(
              icon: Icons.view_in_ar_outlined,
              title: 'Aluminium',
              weight: '4,5 kg',
              percent: 0.10,
            ),

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
              child: Column(
                children: [
                  _buildRiwayatItem('Sesi Pagi', '09:45 AM • Area Sudirman', '24,1 kg'),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildRiwayatItem('Sesi Siang', '13:20 PM • Area Thamrin', '18,5 kg'),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildRiwayatItem('Sesi Sore', '16:10 PM • Area Blok M', '6,0 kg'),
                ],
              ),
            ),
          ],
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
              value: percent,
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