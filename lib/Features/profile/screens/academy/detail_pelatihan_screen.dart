import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class DetailPelatihanScreen extends StatelessWidget {
  const DetailPelatihanScreen({super.key});

  static const Color _navyColor = Color(0xFF0F2C59);

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
          'EcoCash Academy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOMBOL KEMBALI KE DAFTAR PELATIHAN ---
            InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, size: 14, color: _navyColor),
                  SizedBox(width: 4),
                  Text(
                    'Kembali ke Daftar Pelatihan',
                    style: TextStyle(
                      color: _navyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- JUDUL & DESKRIPSI PELATIHAN ---
            const Text(
              'Pengenalan Material & Sortasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pelajari dasar-dasar identifikasi material daur ulang untuk meningkatkan efisiensi dan nilai tukar.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // --- BANNER VIDEO PEMBELAJARAN ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                    ),
                  ),
                  // Overlay Lingkaran Tombol Play Video
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- TOMBOL TONTON DI YOUTUBE ---
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                label: const Text(
                  'Tonton di YouTube',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KARTU TENTANG PELATIHAN INI ---
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tentang Pelatihan Ini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _navyColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dalam pelatihan ini, Anda akan mempelajari cara mengidentifikasi berbagai jenis plastik (PET, HDPE, PVC, dll) dengan cepat dan akurat. Kami juga akan membahas teknik sortasi yang efisien untuk meminimalkan kontaminasi dan memaksimalkan pendapatan Anda dari setiap penjemputan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.access_time, size: 14, color: AppColors.primaryCyan),
                          SizedBox(width: 4),
                          Text(
                            '15 Menit Total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _navyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: const [
                          Icon(Icons.verified, size: 14, color: AppColors.primaryCyan),
                          SizedBox(width: 4),
                          Text(
                            'Sertifikat Tersedia',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _navyColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- BAGIAN PROGRESS ANDA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Progress Anda',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _navyColor,
                  ),
                ),
                Text(
                  '33% Selesai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _navyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 0.33,
                backgroundColor: Color(0xFFE8ECEF),
                valueColor: AlwaysStoppedAnimation(AppColors.primaryCyan),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 24),

            // --- BAGIAN MODUL PELATIHAN ---
            const Text(
              'Modul Pelatihan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 12),

            // Modul 1: Selesai
            _buildModuleItem(
              iconBgColor: const Color(0xFFCEF5F5),
              icon: Icons.check,
              iconColor: AppColors.primaryCyan,
              title: 'Modul 1: Mengenal Jenis Plastik',
              subtitle: 'Video • 5 min',
              isCompleted: true,
            ),
            const SizedBox(height: 10),

            // Modul 2: Aktif / Sedang Dipelajari
            _buildModuleItem(
              iconBgColor: _navyColor,
              icon: Icons.play_arrow,
              iconColor: Colors.white,
              title: 'Modul 2: Teknik Sortasi Efektif',
              subtitle: 'Video • 8 min',
              isActive: true,
              showMoreIcon: true,
            ),
            const SizedBox(height: 10),

            // Modul 3: Terkunci
            _buildModuleItem(
              iconBgColor: const Color(0xFFEFEFEF),
              icon: Icons.lock_outline,
              iconColor: Colors.grey,
              title: 'Modul 3: Standar Kebersihan Material',
              subtitle: 'Document • 2 pages',
              isLocked: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Item Modul Pelatihan
  Widget _buildModuleItem({
    required Color iconBgColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isActive = false,
    bool isLocked = false,
    bool showMoreIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.primaryCyan.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isLocked ? Icons.description_outlined : Icons.play_circle_outline,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showMoreIcon)
            const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}