import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() => _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState extends State<PengaturanNotifikasiScreen> {
  // Status toggle sesuai dengan rancangan dokumen[cite: 1]
  bool _notifTugasBaru = true;   // Tugas Baru (Aktif)[cite: 1]
  bool _notifPembayaran = true;  // Pembayaran (Aktif)[cite: 1]
  bool _notifPromo = false;      // Promo & Berita (Non-aktif)[cite: 1]

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
          'Pengaturan Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DESKRIPSI HEADER ---[cite: 1]
            const Text(
              'Kelola preferensi notifikasi Anda agar selalu mendapatkan informasi terbaru mengenai aktivitas di EcoCash Partner.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // --- KARTU OPSI 1: TUGAS BARU ---[cite: 1]
            _buildNotificationCard(
              icon: Icons.assignment_outlined,
              title: 'Tugas Baru',
              description: 'Terima pemberitahuan saat ada permintaan penjemputan baru di area Anda.',
              value: _notifTugasBaru,
              onChanged: (val) {
                setState(() {
                  _notifTugasBaru = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // --- KARTU OPSI 2: PEMBAYARAN ---[cite: 1]
            _buildNotificationCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Pembayaran',
              description: 'Dapatkan notifikasi seketika saat pencairan dana berhasil atau saldo masuk.',
              value: _notifPembayaran,
              onChanged: (val) {
                setState(() {
                  _notifPembayaran = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // --- KARTU OPSI 3: PROMO & BERITA ---[cite: 1]
            _buildNotificationCard(
              icon: Icons.campaign_outlined,
              title: 'Promo & Berita',
              description: 'Informasi terbaru mengenai program insentif, update aplikasi, dan berita komunitas EcoCash.',
              value: _notifPromo,
              onChanged: (val) {
                setState(() {
                  _notifPromo = val;
                });
              },
            ),
            const SizedBox(height: 28),

            // --- TOMBOL SIMPAN PENGATURAN (POSISI DI KANAN) ---[cite: 1]
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 180, // Lebar tombol proporsional di sebelah kanan
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pengaturan notifikasi berhasil disimpan!')),
                    );
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Pengaturan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Kartu Opsi Notifikasi sesuai Gambar Referensi
  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Kotak di Kiri
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 14),

          // Teks Judul dan Deskripsi di Tengah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Switch di Kanan
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryCyan,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}