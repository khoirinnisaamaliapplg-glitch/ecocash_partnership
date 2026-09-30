import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class DetailPelatihanRuteScreen extends StatelessWidget {
  const DetailPelatihanRuteScreen({super.key});

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BANNER HEADER PETA ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=600&auto=format&fit=crop&q=60',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.map, size: 40, color: Colors.grey)),
                          ),
                        ),
                        // Dark Overlay Gradient
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        // Banner Text & Badge
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Logistik',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Optimasi Rute Pengangkutan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- KARTU PROGRES BELAJAR ---
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Progres Belajar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _navyColor,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '0 dari 4 Modul Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              '0%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            value: 0.0,
                            backgroundColor: Color(0xFFE8ECEF),
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryCyan),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- KARTU TENTANG PELATIHAN INI ---
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
                    'Pelajari strategi terbaik dalam merencanakan rute harian Anda. Modul ini dirancang khusus untuk mitra logistik EcoCash, mengajarkan cara membaca peta kepadatan, menghindari kemacetan, dan memaksimalkan volume pengangkutan dalam waktu yang lebih singkat.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Informasi Badge Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.access_time, '1 Jam 30 Menit'),
                      _buildInfoChip(Icons.menu_book, '4 Modul'),
                      _buildInfoChip(Icons.emoji_events_outlined, '+50 Poin Reputasi'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- BAGIAN KURIKULUM ---
                  const Text(
                    'Kurikulum',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _navyColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Item 1: Dasar Pemetaan EcoCash (Aktif)
                  _buildCurriculumItem(
                    icon: Icons.play_arrow,
                    iconBg: const Color(0xFFEFEFEF),
                    iconColor: AppColors.textPrimary,
                    title: 'Dasar Pemetaan EcoCash',
                    subtitle: 'Pengenalan antarmuka peta dan fitur dasar.',
                    duration: '15 Menit',
                    isActive: true,
                  ),

                  // Item 2: Analisis Kepadatan Lalu Lintas (Locked)
                  _buildCurriculumItem(
                    icon: Icons.lock_outline,
                    iconBg: const Color(0xFFEFEFEF),
                    iconColor: Colors.grey,
                    title: 'Analisis Kepadatan Lalu Lintas',
                    subtitle: 'Cara membaca heatmap kemacetan.',
                    duration: '25 Menit',
                  ),

                  // Item 3: Strategi Pemilihan Jalur Alternatif (Locked)
                  _buildCurriculumItem(
                    icon: Icons.lock_outline,
                    iconBg: const Color(0xFFEFEFEF),
                    iconColor: Colors.grey,
                    title: 'Strategi Pemilihan Jalur Alternatif',
                    subtitle: 'Memilih jalan kecil untuk efisiensi waktu.',
                    duration: '20 Menit',
                  ),

                  // Item 4: Kuis Penilaian (Locked)
                  _buildCurriculumItem(
                    icon: Icons.lock_outline,
                    iconBg: const Color(0xFFEFEFEF),
                    iconColor: Colors.grey,
                    title: 'Kuis Penilaian',
                    subtitle: 'Uji pemahaman Anda tentang optimasi rute.',
                    duration: '10 Menit',
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // --- TOMBOL MULAI BELAJAR (BOTTOM FIXED) ---
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memulai Modul 1: Dasar Pemetaan EcoCash')),
                    );
                  },
                  icon: const Icon(Icons.play_circle, color: Colors.white, size: 20),
                  label: const Text(
                    'Mulai Belajar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88A8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String duration,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          if (isActive)
            Container(
              width: 4,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryCyan,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
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
                            color: isActive ? AppColors.textPrimary : AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}