import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'sertifikat_pelatihan_screen.dart';

class DetailPelatihanKeselamatanScreen extends StatelessWidget {
  const DetailPelatihanKeselamatanScreen({super.key});

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
            // --- BANNER VIDEO PEMBELAJARAN ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&auto=format&fit=crop&q=60',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- BADGE STATUS SELESAI ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCEF5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: AppColors.primaryCyan),
                      SizedBox(width: 4),
                      Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '100% Modul Diselesaikan',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- JUDUL & DESKRIPSI ---
            const Text(
              'Keselamatan Kerja Lapangan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pelatihan komprehensif mengenai standar operasi keselamatan, penggunaan Alat Pelindung Diri (APD) yang benar, dan strategi mitigasi risiko saat melakukan pengangkutan material di lapangan.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // --- TOMBOL LIHAT SERTIFIKAT ---
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SertifikatPelatihanScreen()),
                  );
                },
                icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'Lihat Sertifikat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- BAGIAN KURIKULUM PELATIHAN ---
            const Text(
              'Kurikulum Pelatihan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 12),

            _buildCurriculumItem(
              title: '1. Penggunaan Standar Keselamatan',
              subtitle: '05:30',
            ),
            const SizedBox(height: 10),
            _buildCurriculumItem(
              title: '2. Penggunaan APD (Alat Pelindung Diri)',
              subtitle: '08:45',
            ),
            const SizedBox(height: 10),
            _buildCurriculumItem(
              title: '3. Penanganan Material Berbahaya',
              subtitle: '12:20',
            ),
            const SizedBox(height: 10),
            _buildCurriculumItem(
              title: '4. Evaluasi & Ujian Akhir',
              subtitle: 'Nilai: 95/100',
              isExam: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumItem({
    required String title,
    required String subtitle,
    bool isExam = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFCEF5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: AppColors.primaryCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isExam ? Icons.assignment_outlined : Icons.access_time,
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
        ],
      ),
    );
  }
}