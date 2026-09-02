import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SkorPartnerScreen extends StatelessWidget {
  const SkorPartnerScreen({super.key});

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
        title: const Text('Skor Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
      body: SingleChildScrollView(
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
                  const Text('Level Silver', style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('876', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 4),
                        child: Text('/1000', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Pertahankan performa luar biasa Anda!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.876,
                      backgroundColor: Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Silver', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('Gold (1000)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. BENEFIT LEVEL ---
            const Text('Benefit Level Silver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.payments_outlined, Colors.green, 'Bonus Pendapatan 5%', 'Tambahan 5% untuk setiap penyelesaian tugas harian.', AppColors.primaryCyan),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.star_outline, const Color(0xFF1565C0), 'Prioritas Tugas', 'Akses lebih awal ke tugas-tugas bervolume tinggi.', const Color(0xFF1565C0)),
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
                  _buildPerformanceRow(Icons.recycling, 'Kualitas Material', 'Akurasi pemilahan sampah', '280', '300', Colors.green),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildPerformanceRow(Icons.local_shipping_outlined, 'Kecepatan Penjemputan', 'Ketepatan waktu tiba di lokasi', '245', '250', Colors.green),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildPerformanceRow(Icons.thumb_up_outlined, 'Rating Pelanggan', 'Kepuasan pengguna aplikasi', '185', '200', Colors.orange),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildPerformanceRow(Icons.event_available_outlined, 'Kehadiran', 'Konsistensi aktif mingguan', '166', '250', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 4. TIPS LEVEL GOLD DENGAN TOMBOL ---
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
                          children: const [
                            Text('Tips ke Level Gold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryCyan)),
                            SizedBox(height: 4),
                            Text('Tingkatkan skor kehadiran Anda. Aktif 5 hari berturut-turut minggu ini akan memberikan bonus +50 poin!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
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
                      onPressed: () {
                        // Aksi tombol lihat jadwal tugas
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2B48), // Warna gelap ala mockup
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lihat Jadwal Tugas',
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
    );
  }

  // Widget benefit dengan border aksen di sisi kiri
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
            border: Border(
              left: BorderSide(color: borderColor, width: 5), // Garis aksen kiri
            ),
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