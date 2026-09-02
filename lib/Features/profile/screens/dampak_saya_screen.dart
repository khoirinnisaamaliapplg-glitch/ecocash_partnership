import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DampakSayaScreen extends StatelessWidget {
  const DampakSayaScreen({super.key});

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
        title: const Text(
          'Dampak Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER INFO ---
            const Text(
              'Dampak Saya',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kontribusi Anda untuk ekonomi sirkular.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // --- KARTU UTAMA DENGAN LATAR GRADASI/CYAN LEMBUT ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.22),
                    AppColors.primaryCyan.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  // --- BADGE SEJAK BERGABUNG ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.military_tech, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Sejak Bergabung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Pahlawan Lingkungan Level 3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- 4 KARTU PUTIH STATISTIK ---
                  _buildInnerImpactCard(
                    icon: Icons.recycling,
                    title: 'MATERIAL TERKUMPUL',
                    value: '8.420',
                    unit: 'kg',
                  ),
                  const SizedBox(height: 12),
                  _buildInnerImpactCard(
                    icon: Icons.delete_outline,
                    title: 'SAMPAH DIALIHKAN',
                    value: '8,4',
                    unit: 'Ton',
                  ),
                  const SizedBox(height: 12),
                  _buildInnerImpactCard(
                    icon: Icons.cloud_outlined,
                    title: 'CO2E EMISI DIKURANGI',
                    value: '24,6',
                    unit: 'Ton',
                  ),
                  const SizedBox(height: 12),
                  _buildInnerImpactCard(
                    icon: Icons.school_outlined,
                    title: 'PELATIHAN SELESAI',
                    value: '17',
                    unit: '',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION RIWAYAT DAMPAK ---
            const Text(
              'Riwayat Dampak',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lihat rincian detail kontribusi harian Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryCyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lihat Detail', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION BAGIKAN PENCAPAIAN ---
            const Text(
              'Bagikan Pencapaian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Inspirasi komunitas dengan dampak positif Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Bagikan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Kartu Putih dengan Aksen Garis Vertikal di Sisi Kiri
  Widget _buildInnerImpactCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Garis aksen vertikal di sisi kiri
              Container(
                width: 6,
                color: AppColors.primaryCyan,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          if (unit.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                unit,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}