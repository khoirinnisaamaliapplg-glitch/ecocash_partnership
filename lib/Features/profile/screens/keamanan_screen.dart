import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class KeamananScreen extends StatefulWidget {
  const KeamananScreen({super.key});

  @override
  State<KeamananScreen> createState() => _KeamananScreenState();
}

class _KeamananScreenState extends State<KeamananScreen> {
  bool _isBiometricEnabled = true; // Status toggle biometrik

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
          'Keamanan Akun',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KATEGORI: KREDENSIAL & AUTENTIKASI ---
            const Text(
              'Kredensial & Autentikasi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _buildSecurityItem(
                    icon: Icons.pin_outlined,
                    title: 'Ubah PIN',
                    subtitle: 'Perbarui PIN 6 digit Anda secara berkala',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSecurityItem(
                    icon: Icons.lock_outline,
                    title: 'Ubah Kata Sandi',
                    subtitle: 'Gunakan kata sandi yang kuat dan unik',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  // Biometrik dengan Toggle Switch
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: AppColors.textSecondary, size: 24),
                    title: const Text('Login Biometrik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    subtitle: const Text('Gunakan FaceID atau Sidik Jari untuk login', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: _isBiometricEnabled,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (bool value) {
                      setState(() {
                        _isBiometricEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- KATEGORI: PERANGKAT YANG TERHUBUNG ---
            const Text(
              'Perangkat yang Terhubung',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // Perangkat 1 (Aktif saat ini)
                  _buildDeviceItem(
                    icon: Icons.phone_android,
                    deviceName: 'Samsung Galaxy S23',
                    deviceLocation: 'Jakarta, Indonesia • Sedang aktif',
                    deviceIp: 'IP: 192.168.1.15',
                    isCurrentDevice: true,
                    onLogout: () {},
                  ),
                  _buildDivider(),
                  // Perangkat 2
                  _buildDeviceItem(
                    icon: Icons.laptop_windows,
                    deviceName: 'Windows 11 • Chrome',
                    deviceLocation: 'Bandung, Indonesia • Terakhir aktif: 2 jam lalu',
                    deviceIp: '',
                    isCurrentDevice: false,
                    onLogout: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Berhasil keluar dari perangkat Windows 11')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TOMBOL KELUAR DARI SEMUA PERANGKAT ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar dari Semua Perangkat'),
                      content: const Text('Anda akan keluar dari semua sesi aktif di perangkat lain.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/login');
                          },
                          child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'Keluar dari Semua Perangkat',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Item Pengaturan Kredensial
  Widget _buildSecurityItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  // Widget Item Perangkat Terhubung
  Widget _buildDeviceItem({
    required IconData icon,
    required String deviceName,
    required String deviceLocation,
    required String deviceIp,
    required bool isCurrentDevice,
    required VoidCallback onLogout,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(deviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    if (isCurrentDevice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Perangkat Ini', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(deviceLocation, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (deviceIp.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(deviceIp, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          if (!isCurrentDevice)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              onPressed: onLogout,
              tooltip: 'Keluar',
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 56, endIndent: 16);
  }
}