import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ForgotOtpScreen extends StatelessWidget {
  const ForgotOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Background abu-abu terang
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DD3FC), // Warna header biru muda
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            children: [
              // Kartu Putih Utama
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Kunci dalam Lingkaran Biru Muda
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 35,
                      child: const Icon(Icons.lock_outline, color: Color(0xFF003F5C), size: 35),
                    ),
                    const SizedBox(height: 24),
                    
                    // Judul
                    const Text(
                      'Enter OTP',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003F5C)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "We've sent a 4-digit code to\n+62 812-3456-7890",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // 4 Kotak Input OTP (Dengan border merah dan nilai contoh)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOtpBox('4'),
                        _buildOtpBox('2'),
                        _buildOtpBox('8'),
                        _buildOtpBox('9'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Incorrect OTP. Please try again.',
                      style: TextStyle(color: Color(0xFFC62828), fontSize: 12),
                    ),
                    const SizedBox(height: 32),

                    // Tombol Verify (Hijau Pastel / Pill)
                    ElevatedButton(
                      onPressed: () {
                        // Pop-up Dialog Sukses
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  radius: 30,
                                  child: Icon(Icons.check, color: Colors.white, size: 40),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Verifikasi Berhasil!',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Kode OTP telah berhasil dan\nKata sandi Sudah di rubah',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    minimumSize: const Size(double.infinity, 45),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.go('/new-password'); // Pindah ke buat sandi baru
                                  },
                                  child: const Text('Lanjut Untuk Login', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784), // Hijau pastel
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Bagian Bawah: Teks Belum Terima Kode & Hitung Mundur Waktu
              const Text(
                "Didn't receive the code?",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resend Code (0:45)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003F5C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk kotak OTP
  Widget _buildOtpBox(String initialVal) {
    return SizedBox(
      width: 55,
      height: 55,
      child: TextFormField(
        initialValue: initialVal,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003F5C)),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5), // Border merah
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC62828), width: 2),
          ),
        ),
      ),
    );
  }
}