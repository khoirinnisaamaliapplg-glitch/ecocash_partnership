import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class UnggahKtpScreen extends StatefulWidget {
  const UnggahKtpScreen({super.key});

  @override
  State createState() => _UnggahKtpScreenState();
}

class _UnggahKtpScreenState extends State {
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
          'Unggah Dokumen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- JUDUL & DESKRIPSI ---
            const Text(
              'KTP (Kartu Tanda Penduduk)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navyColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pastikan foto KTP terlihat jelas untuk mempercepat proses verifikasi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // --- AREA AMBIL FOTO KTP ---
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC5CEE0), width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: _navyColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ambil Foto KTP',
                      style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KARTU PANDUAN FOTO ---
            Container(
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
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.primaryCyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Panduan Foto',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _navyColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildCheckItem('Foto harus jelas dan tidak buram.'),
                  _buildCheckItem('Semua sudut KTP harus terlihat.'),
                  _buildCheckItem('Tidak ada pantulan cahaya atau bayangan.'),
                  _buildCheckItem('KTP harus asli dan masih berlaku.'),

                  const SizedBox(height: 16),

                  // Contoh Foto Benar & Salah
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildMiniKtp(isBlur: false),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Benar',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildMiniKtp(isBlur: true),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Salah\n(Buram/Terpotong)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- TOMBOL SIMPAN DOKUMEN ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Simpan Dokumen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKtp({required bool isBlur}) {
    return Container(
      height: 85,
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isBlur ? const Color(0xFFCFD8DC) : const Color(0xFFBBE2EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isBlur
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.blur_on, color: Colors.grey, size: 28),
                SizedBox(height: 2),
                Text('KTP Buram', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.person, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 55, height: 5, color: _navyColor),
                      const SizedBox(height: 4),
                      Container(width: 35, height: 4, color: Colors.black45),
                      const SizedBox(height: 3),
                      Container(width: 45, height: 4, color: Colors.black45),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}