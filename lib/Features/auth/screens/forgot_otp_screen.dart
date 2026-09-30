import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ForgotOtpScreen extends StatefulWidget {
  const ForgotOtpScreen({super.key});

  @override
  State createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State {
  // Controller untuk 4 digit OTP (Diinisialisasi kosong tanpa teks awal)
  final TextEditingController _otp1 = TextEditingController();
  final TextEditingController _otp2 = TextEditingController();
  final TextEditingController _otp3 = TextEditingController();
  final TextEditingController _otp4 = TextEditingController();

  final FocusNode _focus1 = FocusNode();
  final FocusNode _focus2 = FocusNode();
  final FocusNode _focus3 = FocusNode();
  final FocusNode _focus4 = FocusNode();

  // Mengecek apakah seluruh 4 digit OTP sudah terisi
  bool get _isOtpComplete =>
      _otp1.text.isNotEmpty &&
      _otp2.text.isNotEmpty &&
      _otp3.text.isNotEmpty &&
      _otp4.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _otp1.addListener(_onOtpChanged);
    _otp2.addListener(_onOtpChanged);
    _otp3.addListener(_onOtpChanged);
    _otp4.addListener(_onOtpChanged);
  }

  void _onOtpChanged() {
    setState(() {}); // Rebuild UI untuk memperbarui status pudar/jelas tombol
  }

  @override
  void dispose() {
    _otp1.dispose();
    _otp2.dispose();
    _otp3.dispose();
    _otp4.dispose();
    _focus1.dispose();
    _focus2.dispose();
    _focus3.dispose();
    _focus4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DD3FC),
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
                    // Icon Kunci
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

                    // 4 Kotak Input OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOtpBox(_otp1, _focus1, null, _focus2),
                        _buildOtpBox(_otp2, _focus2, _focus1, _focus3),
                        _buildOtpBox(_otp3, _focus3, _focus2, _focus4),
                        _buildOtpBox(_otp4, _focus4, _focus3, null),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // TOMBOL VERIFY (Pudar saat belum terisi, Jelas + Gradient Teal saat 4 digit terisi)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isOtpComplete ? 1.0 : 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF217D9B), Color(0xFF13B49E)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: _isOtpComplete
                              ? () {
                                  _showSuccessDialog(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text(
                            'Verify',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Bagian Bawah: Resend Code
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

  // Dialog Sukses
  void _showSuccessDialog(BuildContext context) {
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
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF217D9B), Color(0xFF13B49E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/new-password');
                },
                child: const Text('Lanjut Untuk Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Kotak Input OTP Interaktif dengan Navigasi Focus
  Widget _buildOtpBox(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? prevFocus,
    FocusNode? nextFocus,
  ) {
    return SizedBox(
      width: 55,
      height: 55,
      child: TextFormField(
        controller: controller,
        focusNode: currentFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003F5C)),
        onChanged: (val) {
          if (val.isNotEmpty && nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else if (val.isEmpty && prevFocus != null) {
            FocusScope.of(context).requestFocus(prevFocus);
          }
        },
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
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