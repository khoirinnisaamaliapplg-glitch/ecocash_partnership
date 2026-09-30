import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class UnggahStnkScreen extends StatefulWidget {
  const UnggahStnkScreen({super.key});

  @override
  State createState() => _UnggahStnkScreenState();
}

class _UnggahStnkScreenState extends State {
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
          'Unggah STNK',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AREA AMBIL FOTO STNK ---
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
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
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ambil Foto STNK',
                      style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tekan di sini untuk membuka kamera atau memilih dari galeri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KARTU INFORMASI PENTING ---
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
                      Icon(Icons.info, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Penting',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _navyColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem('Pastikan STNK sesuai dengan kendaraan yang didaftarkan.'),
                  _buildCheckItem('Pajak kendaraan harus masih berlaku.'),
                  _buildCheckItem('Foto harus mencakup seluruh bagian lembar STNK (depan dan belakang jika perlu).'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- TIPS FOTO YANG BAIK ---
            const Text(
              'Tips Foto yang Baik',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navyColor),
            ),
            const SizedBox(height: 10),

            _buildTipCard(Icons.wb_sunny_outlined, 'Pencahayaan terang & jelas'),
            _buildTipCard(Icons.crop_landscape, 'Letakkan di permukaan datar'),
            _buildTipCard(Icons.crop, 'Jangan ada bagian terpotong'),

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

  Widget _buildTipCard(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFCEF5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryCyan),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}