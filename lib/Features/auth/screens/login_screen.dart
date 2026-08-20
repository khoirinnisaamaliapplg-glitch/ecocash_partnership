import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/auth_local_service.dart'; // Import service dummy data lokal

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk inputan login
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- ALUR GOOGLE LOGIN: 1. Pilih Akun ---
  void _showGoogleAccountPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.g_mobiledata, size: 50, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Pilih akun',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
              child: Text(
                'untuk melanjutkan ke EcoCash Partner',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            // Akun Pilihan 1: Budi Santoso
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Text('BS', style: TextStyle(color: Colors.white)),
              ),
              title: const Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('budi.s@gmail.com'),
              onTap: () {
                Navigator.pop(context);
                _showGoogleConsent('Budi Santoso', 'budi.s@gmail.com');
              },
            ),
            const Divider(),

            // Akun Pilihan 2: Siti Rahmawati
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary2,
                child: Text('SR', style: TextStyle(color: Colors.white)),
              ),
              title: const Text('Siti Rahmawati', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('sitirahma.eco@gmail.com'),
              onTap: () {
                Navigator.pop(context);
                _showGoogleConsent('Siti Rahmawati', 'sitirahma.eco@gmail.com');
              },
            ),
            const Divider(),

            // Opsi: Gunakan akun lain
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person_add_outlined, color: Colors.white),
              ),
              title: const Text('Gunakan akun lain', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showGoogleConsent('Mitra Baru', 'mitra.baru@gmail.com');
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda dengan EcoCash Partner.',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- ALUR GOOGLE LOGIN: 2. Konfirmasi Izin ---
  void _showGoogleConsent(String name, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Google',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'EcoCash Partner ingin mengakses Akun Google Anda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            // Info Akun yang Dipilih
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary2,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hal ini akan memungkinkan EcoCash Partner untuk:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Melihat nama dan foto profil Anda', style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Melihat alamat email Anda', style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),

            // Tombol Izinkan
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8), // Warna biru ala Google Button
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () async {
                // Simpan atau verifikasi akun ke storage lokal
                await AuthLocalService.googleSignIn(email: email, name: name);
                
                if (!context.mounted) return;
                Navigator.pop(context); // Tutup bottom sheet

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Berhasil masuk sebagai $name!')),
                );

                // Masuk ke Dashboard Utama
                context.go('/main');
              },
              child: const Text('Izinkan', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 8),

            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF1A73E8))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Background abu-abu terang
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              // Kotak kartu putih dengan sudut melengkung dan bayangan
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo & Judul Dua Warna
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'EcoCash ',
                            style: TextStyle(color: AppColors.primary2),
                          ),
                          TextSpan(
                            text: 'Partner',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Collect. Verify. Earn. Grow.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Masuk ke Akun Anda
                  const Text(
                    'Masuk ke Akun Anda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nomor Ponsel / E-mail / Username
                  const Text('Nomor Ponsel / E-mail', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      hintText: 'No. Ponsel / Email / Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kata Sandi
                  const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lupa Kata Sandi (Dialihkan ke Halaman Multi-Step Lupa Password)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Mengarahkan ke rute halaman Lupa Password
                        context.push('/forgot-password');
                      },
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(color: AppColors.textLink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Masuk (Terhubung ke AuthLocalService)
                  ElevatedButton(
                    onPressed: () async {
                      if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kolom identitas dan kata sandi harus diisi!')),
                        );
                        return;
                      }

                      bool isValid = await AuthLocalService.login(
                        identifier: _identifierController.text,
                        password: _passwordController.text,
                      );

                      if (!context.mounted) return;

                      if (isValid) {
                        context.go('/main');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nomor/Email atau Kata Sandi salah!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Masuk', style: TextStyle(fontSize: 16, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Atau masuk dengan',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tombol Sosial Media
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Memanggil Bottom Sheet Pilihan Akun Google
                            _showGoogleAccountPicker();
                          },
                          icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                          label: const Text('Google', style: TextStyle(color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.apple, color: Colors.black, size: 24),
                          label: const Text('Apple', style: TextStyle(color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Belum punya akun? Daftar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.go('/register');
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: AppColors.textLink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}