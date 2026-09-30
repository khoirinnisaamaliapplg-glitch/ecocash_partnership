import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class SertifikatPelatihanScreen extends StatelessWidget {
  const SertifikatPelatihanScreen({super.key});

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
            // --- HEADER TEKS ---
            const Text(
              'PENCAPAIAN ANDA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Sertifikat Pelatihan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selamat! Anda telah berhasil menyelesaikan pelatihan dengan baik. Sertifikat digital Anda tersedia di bawah ini.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // --- KARTU SERTIFIKAT ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Watermark samar di latar belakang
                  Positioned.fill(
                    child: Center(
                      child: Opacity(
                        opacity: 0.03,
                        child: Text(
                          'ECOCASH',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900, // Perbaikan di sini (menggunakan w900 pengganti .black)
                            color: _navyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      // Header Logo EcoCash Academy Partner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.eco, size: 20, color: _navyColor),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'EcoCash',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _navyColor,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'ACADEMY PARTNER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                  color: Colors.green,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Diberikan Kepada',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Budi Santoso',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _navyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(width: 140, height: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 14),

                      const Text(
                        'Atas keberhasilannya menyelesaikan program pelatihan wajib bagi Mitra EcoCash:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 12),

                      // Nama Kursus di Sertifikat
                      const Text(
                        'Keselamatan Kerja Lapangan\n& Penanganan Limbah Medis B3',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _navyColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tanggal & Tanda Tangan
                      const Text(
                        'Tanggal Penyelesaian',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                      const Text(
                        '15 November 2023',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanda Tangan Digital Nama Direktur
                      Column(
                        children: [
                          const Text(
                            'Dr. Hendra W.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _navyColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const Text(
                            'Direktur Operasional',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ID Sertifikat
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ID Sertifikat: ECA-2023-88492X',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TOMBOL UNDUH PDF & BAGIKAN ---
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh Sertifikat PDF...')),
                  );
                },
                icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                label: const Text(
                  'Unduh PDF',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, color: _navyColor, size: 18),
                label: const Text(
                  'Bagikan',
                  style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC5CEE0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}