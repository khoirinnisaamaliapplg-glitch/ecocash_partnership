import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/auth_local_service.dart'; // <-- IMPORT INI YANG KURANG

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: Image.asset('assets/images/logo.png', height: 60)),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'EcoCash Partner',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Lupa kata sandi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input No Ponsel
                  const Text('Nomor Ponsel yang Terdaftar', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 08123456789',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Email
                  const Text('E-mail yang terdaftar', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Contoh: baba@gmail.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Lanjut ke OTP
                  ElevatedButton(
                    onPressed: () async {
                      if (phoneController.text.isEmpty && emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Masukkan nomor ponsel atau e-mail Anda!')),
                        );
                        return;
                      }

                      // Ambil data yang diisi (Prioritaskan nomor telepon atau email)
                      String identifier = phoneController.text.isNotEmpty ? phoneController.text : emailController.text;

                      // Cek apakah akun terdaftar di database lokal
                      String? existingPassword = await AuthLocalService.resetPassword(identifier);

                      if (!context.mounted) return;

                      if (existingPassword != null) {
                        // Jika ada, lanjut ke halaman OTP
                        context.push('/forgot-otp');
                      } else {
                        // Jika tidak ditemukan
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nomor atau E-mail tidak ditemukan di sistem!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('lanjut', style: TextStyle(fontSize: 16, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
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