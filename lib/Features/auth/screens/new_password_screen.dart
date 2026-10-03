import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart'; // <-- 1. IMPORT SERVICE DI SINI (sesuaikan path jika beda)

class NewPasswordScreen extends StatefulWidget {
  final Map extraData;

  const NewPasswordScreen({super.key, this.extraData = const {}});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  // <-- 2. DEKLARASI API SERVICE DI SINI
  final PartnerApiService _apiService = PartnerApiService();

  bool _obscurePass1 = true;
  bool _obscurePass2 = true;
  bool _isLoading = false;

  final TextEditingController _passController1 = TextEditingController();
  final TextEditingController _passController2 = TextEditingController();

  Map get _data => widget.extraData;

  @override
  void dispose() {
    _passController1.dispose();
    _passController2.dispose();
    super.dispose();
  }

  Future<void> _resetPasswordBackend() async {
    String pass1 = _passController1.text;
    String pass2 = _passController2.text;
    String target = _data['target'] ?? _data['phoneNumber'] ?? '';
    String code = _data['code'] ?? '';

    if (pass1.isEmpty || pass2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom kata sandi harus diisi!')),
      );
      return;
    }

    if (pass1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi minimal 6 karakter!')),
      );
      return;
    }

    if (pass1 != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok!')),
      );
      return;
    }

    if (target.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi pemulihan tidak valid, silakan ulangi proses.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.resetPasswordOtp(
      phoneNumber: target,
      code: code,
      newPassword: pass1,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Kata sandi berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memperbarui kata sandi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

                  const Text('Masukan Kata Sandi Baru', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passController1,
                    obscureText: _obscurePass1,
                    enabled: !_isLoading,
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

                  const Text('Konfirmasi Sandi', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passController2,
                    obscureText: _obscurePass2,
                    enabled: !_isLoading,
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
                      onPressed: _isLoading ? null : _resetPasswordBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Simpan & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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