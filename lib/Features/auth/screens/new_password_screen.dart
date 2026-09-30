import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/auth_local_service.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State {
  bool _obscurePass1 = true;
  bool _obscurePass2 = true;

  final TextEditingController _passController1 = TextEditingController();
  final TextEditingController _passController2 = TextEditingController();

  @override
  void dispose() {
    _passController1.dispose();
    _passController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Konfirmasi Sandi Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Masukan Kata Sandi Baru
                  const Text('Masukan Kata Sandi Baru', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passController1,
                    obscureText: _obscurePass1,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass1 ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePass1 = !_obscurePass1),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Konfirmasi Sandi
                  const Text('Konfirmasi Sandi', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passController2,
                    obscureText: _obscurePass2,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass2 ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePass2 = !_obscurePass2),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Lanjut (Dengan Gradient Teal Cyan Sesuai Gambar)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF217D9B), Color(0xFF13B49E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF13B49E).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_passController1.text.isEmpty || _passController2.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Semua kolom kata sandi harus diisi!')),
                          );
                          return;
                        }

                        if (_passController1.text != _passController2.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok!')),
                          );
                          return;
                        }

                        bool success = await AuthLocalService.updatePassword(_passController1.text);

                        if (!context.mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kata sandi berhasil diperbarui!')),
                          );
                          context.go('/login');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terjadi kesalahan, sesi pemulihan tidak valid.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lanjut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
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