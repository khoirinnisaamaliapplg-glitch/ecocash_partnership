import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

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
          'Pengaturan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KATEGORI: AKUN ---
            const Text(
              'Akun',
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
                  _buildMenuItem(Icons.person_outline, 'Edit Profil', () {
                    context.push('/edit-profile');
                  }),
                  _buildDivider(),
                 _buildMenuItem(Icons.security_outlined, 'Keamanan', () {
  context.push('/keamanan');
}),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- KATEGORI: PREFERENSI ---
            const Text(
              'Preferensi',
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
                  _buildMenuItemWithTrailingText(Icons.language, 'Bahasa', 'Indonesia', () {}),
                  _buildDivider(),
                  _buildMenuItem(Icons.notifications_outlined, 'Pengaturan Notifikasi', () {
  context.push('/pengaturan-notifikasi');
}),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- KATEGORI: UMUM ---
            const Text(
              'Umum',
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
                  _buildMenuItem(Icons.help_outline, 'Pusat Bantuan', () {
                    context.push('/pusat-bantuan');
                  }),
                  _buildDivider(),
                  _buildMenuItemWithTrailingText(Icons.info_outline, 'Tentang EcoCash Indonesia', 'v3.0.0', () {}),
                  _buildDivider(),
                  _buildMenuItem(Icons.description_outlined, 'Syarat & Ketentuan / Privasi', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TOMBOL HAPUS AKUN ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Hapus Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                onTap: () {
                  // Dialog konfirmasi hapus akun
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildMenuItemWithTrailingText(IconData icon, String title, String trailingText, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailingText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 56, endIndent: 16);
  }
}