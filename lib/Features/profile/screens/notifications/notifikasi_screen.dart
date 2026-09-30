import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State {
  static const Color _navyColor = Color(0xFF0F2C59);
  bool _hasUnread = true; // Status indikator notifikasi belum dibaca

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
          'Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hasUnread = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
              );
            },
            child: const Text(
              'Tandai Semua Sudah Dibaca',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
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
            // --- SECTION: HARI INI ---
            const Text(
              'Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 12),

            // Item 1: Pekerjaan Baru Tersedia (Unread Dot)
            _buildNotificationCard(
              icon: Icons.work_outline,
              title: 'Pekerjaan baru tersedia',
              subtitle: 'EcoCash Valen #BGD-021 (2,3 km)',
              time: '10 mnt yang lalu',
              isUnread: _hasUnread,
            ),
            const SizedBox(height: 10),

            // Item 2: Pembayaran Berhasil (Unread Dot)
            _buildNotificationCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Pembayaran berhasil',
              subtitle: 'Rp82.000 masuk ke Wallet',
              time: '1 jam yang lalu',
              isUnread: _hasUnread,
            ),
            const SizedBox(height: 10),

            // Item 3: Verifikasi Berhasil
            _buildNotificationCard(
              icon: Icons.verified_outlined,
              title: 'Verifikasi berhasil',
              subtitle: 'Material PET terverifikasi.',
              time: '3 jam yang lalu',
              isUnread: false,
            ),
            const SizedBox(height: 10),

            // Item 4: Pelatihan hampir selesai (Dengan Progres Bar)
            _buildNotificationCard(
              icon: Icons.school_outlined,
              title: 'Pelatihan hampir selesai',
              subtitle: 'Modul Digital Literacy sudah 75%.',
              time: '5 jam yang lalu',
              isUnread: false,
              progressValue: 0.75,
            ),
            const SizedBox(height: 24),

            // --- SECTION: SEBELUMNYA ---
            const Text(
              'Sebelumnya',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _navyColor,
              ),
            ),
            const SizedBox(height: 12),

            // Item 5: Tugas Selesai
            _buildNotificationCard(
              icon: Icons.local_shipping_outlined,
              title: 'Tugas selesai',
              subtitle: 'Pengambilan di Kios Pak Budi berhasil diselesaikan.',
              time: 'Kemarin, 14:30',
              isUnread: false,
            ),
            const SizedBox(height: 10),

            // Item 6: Info Sistem
            _buildNotificationCard(
              icon: Icons.campaign_outlined,
              title: 'Info Sistem',
              subtitle: 'Pembaruan aplikasi versi 3.1 tersedia. Silakan update.',
              time: '2 Hari yang lalu',
              isUnread: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Widget Kartu Notifikasi
  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
    double? progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lingkaran Ikon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF).withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 14),

          // Detail Konten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _navyColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (progressValue != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: const Color(0xFFE8ECEF),
                      valueColor: const AlwaysStoppedAnimation(_navyColor),
                      minHeight: 6,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}