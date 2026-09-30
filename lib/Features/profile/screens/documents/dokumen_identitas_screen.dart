import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'unggah_ktp_screen.dart';
import 'unggah_stnk_screen.dart';

class DokumenIdentitasScreen extends StatefulWidget {
  const DokumenIdentitasScreen({super.key});

  @override
  State createState() => _DokumenIdentitasScreenState();
}

class _DokumenIdentitasScreenState extends State {
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
          'Dokumen Identitas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-header Deskripsi
            const Text(
              'Pastikan dokumen Anda valid dan terbaru untuk kelancaran verifikasi sebagai mitra EcoCash.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // --- 1. KARTU KTP ---
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIconCircle(Icons.badge_outlined, const Color(0xFFDDE9FA), _navyColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('KTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            Text('Kartu Tanda Penduduk', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      // Badge Terverifikasi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0F4F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, size: 12, color: AppColors.primaryCyan),
                            SizedBox(width: 4),
                            Text(
                              'Terverifikasi',
                              style: TextStyle(fontSize: 11, color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Visual Pratinjau e-KTP Realistis (Klik untuk membuka Unggah KTP)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UnggahKtpScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: _buildKtpPreview(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- 2. KARTU STNK ---
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIconCircle(Icons.directions_car_outlined, const Color(0xFFEFEFEF), Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('STNK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            Text('Surat Tanda Nomor\nKendaraan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      // Badge Belum Diunggah
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7D6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_circle, size: 12, color: Color(0xFFB78103)),
                            SizedBox(width: 4),
                            Text(
                              'Belum\nDiunggah',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: Color(0xFFB78103), fontWeight: FontWeight.bold, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Box Unggah Foto STNK
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UnggahStnkScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC5CEE0), width: 1, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.description_outlined, color: _navyColor, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Unggah Foto STNK',
                            style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- 3. KARTU SIM ---
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIconCircle(Icons.subtitles_outlined, const Color(0xFFEFEFEF), Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('SIM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('OPSIONAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ),
                              ],
                            ),
                            const Text('Surat Izin Mengemudi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tombol Tambah Dokumen
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.textSecondary),
                      label: const Text('Tambah Dokumen', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- TOMBOL SIMPAN PERUBAHAN ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perubahan dokumen berhasil disimpan')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Visual Pratinjau KTP Khas e-KTP Indonesia
  Widget _buildKtpPreview() {
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBBE2EC), Color(0xFFE0F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF88AB8E).withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Frame Pas Foto KTP (Merah khas e-KTP)
          Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person, size: 48, color: Colors.white),
                SizedBox(height: 2),
                Text(
                  'FOTO KTP',
                  style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Rincian Identitas KTP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PROVINSI JAWA BARAT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _navyColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('e-KTP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _navyColor)),
                    ),
                  ],
                ),
                const Text(
                  'KOTA BANDUNG',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const Divider(height: 6, thickness: 0.8, color: Colors.black26),
                const Text('NIK : 3273012809950001', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text('Nama : BUDI SANTOSO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text('Tempat/Tgl Lahir : BANDUNG, 28-09-1995', style: TextStyle(fontSize: 7.5, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text('Alamat : JL. SUDIRMAN NO. 45', style: TextStyle(fontSize: 7.5, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text('Berlaku Hingga : SEUMUR HIDUP', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconCircle(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}