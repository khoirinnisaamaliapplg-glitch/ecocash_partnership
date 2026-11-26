import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() =>
      _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState
    extends State<PengaturanNotifikasiScreen> {
  bool _notifTugasBaru = true;
  bool _notifPembayaran = true;
  bool _notifPromo = false;

  static const Color _navy = Color(0xFF0F2C59);
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _border = Color(0xFFE9EDF2);

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pengaturan notifikasi berhasil disimpan!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF21845B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 58,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _navy,
            size: 19,
          ),
        ),
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 23),

              Row(
                children: [
                  const Text(
                    'Preferensi Notifikasi',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '3 PENGATURAN',
                      style: TextStyle(
                        color: Color(0xFF3766A5),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildNotificationCard(
                icon: Icons.assignment_outlined,
                title: 'Tugas Baru',
                description:
                    'Terima pemberitahuan saat ada permintaan penjemputan baru di area Anda.',
                value: _notifTugasBaru,
                onChanged: (value) {
                  setState(() => _notifTugasBaru = value);
                },
              ),

              const SizedBox(height: 12),

              _buildNotificationCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Pembayaran',
                description:
                    'Dapatkan notifikasi saat pencairan dana berhasil atau saldo masuk.',
                value: _notifPembayaran,
                onChanged: (value) {
                  setState(() => _notifPembayaran = value);
                },
              ),

              const SizedBox(height: 12),

              _buildNotificationCard(
                icon: Icons.campaign_outlined,
                title: 'Promo & Berita',
                description:
                    'Informasi program insentif, pembaruan aplikasi, dan berita komunitas EcoCash.',
                value: _notifPromo,
                onChanged: (value) {
                  setState(() => _notifPromo = value);
                },
              ),

              const SizedBox(height: 18),

              _buildInformationNote(),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 9),
                      Text(
                        'Simpan Pengaturan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153C70), Color(0xFF0F2C59)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -14,
            child: Icon(
              Icons.notifications_active_rounded,
              size: 105,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PREFERENSI APLIKASI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Atur Notifikasi Anda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Pilih informasi yang ingin Anda terima\nselama menggunakan layanan EcoCash Partner.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _navy, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF78818D),
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: value
                            ? const Color(0xFF21845B)
                            : const Color(0xFF9AA3AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      value ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        color: value
                            ? const Color(0xFF21845B)
                            : const Color(0xFF8993A0),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          Switch.adaptive(
            value: value,
            activeTrackColor: _navy,
            activeColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE1E5EA),
            inactiveThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInformationNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD9E8F8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF3766A5), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pengaturan ini mengatur preferensi notifikasi Anda. Pastikan izin notifikasi aplikasi juga telah diaktifkan pada perangkat.',
              style: TextStyle(
                color: Color(0xFF385675),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
