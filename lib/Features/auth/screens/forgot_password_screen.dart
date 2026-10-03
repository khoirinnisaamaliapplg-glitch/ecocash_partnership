import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final PartnerApiService _apiService = PartnerApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Fungsi pembantu untuk konversi otomatis 08... menjadi 62...
  String _normalizeTo62(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), ''); // Hapus spasi/karakter non-digit
    if (clean.startsWith('0')) {
      return '62${clean.substring(1)}';
    }
    return clean;
  }

  Future<void> _requestOtpBackend() async {
    String rawPhone = _phoneController.text.trim();

    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor WhatsApp Anda!')),
      );
      return;
    }

    // Otomatis ubah awalan 08 menjadi 62 sebelum dikirim ke API
    String formattedPhone = _normalizeTo62(rawPhone);

    setState(() => _isLoading = true);

    final result = await _apiService.sendOtp(
      phoneNumber: formattedPhone,
      channel: 'WHATSAPP',
      purpose: 'FORGOT_PASSWORD',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Kode OTP berhasil dikirim via WhatsApp.'),
          backgroundColor: Colors.green,
        ),
      );

      context.push('/forgot-otp', extra: {
        'target': formattedPhone,
        'phoneNumber': formattedPhone,
        'channel': 'WHATSAPP',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim kode OTP.'),
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _isLoading ? null : () => context.pop(),
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
                  
                  const Text('Nomor WhatsApp Terdaftar', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 085716818225',
                      helperText: 'Bisa diawali 08... atau 62...',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryButtonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestOtpBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Kirim OTP WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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