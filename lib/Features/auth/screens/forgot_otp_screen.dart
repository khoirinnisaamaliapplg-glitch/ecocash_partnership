import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';// <-- 1. IMPORT SERVICE DI SINI (sesuaikan path jika beda)

class ForgotOtpScreen extends StatefulWidget {
  final Map extraData;

  const ForgotOtpScreen({super.key, this.extraData = const {}});

  @override
  State<ForgotOtpScreen> createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State<ForgotOtpScreen> {
  // <-- 2. DEKLARASI API SERVICE DI SINI
  final PartnerApiService _apiService = PartnerApiService();

  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  Map get _data => widget.extraData;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (var c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  String _formatPhoneDisplay(String phone) {
    if (phone.isEmpty) return 'nomor WhatsApp Anda';
    if (phone.startsWith('62')) {
      return '+62 ${phone.substring(2)}';
    }
    return phone;
  }

  Future<void> _resendOtp() async {
    String target = _data['target'] ?? _data['phoneNumber'] ?? '';
    if (target.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _apiService.sendOtp(
      phoneNumber: target,
      channel: 'WHATSAPP',
      purpose: 'FORGOT_PASSWORD',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Kode OTP WhatsApp telah dikirim ulang.'),
          backgroundColor: Colors.green,
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim ulang OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    String otpCode = _controllers.map((c) => c.text).join();
    String target = _data['target'] ?? _data['phoneNumber'] ?? '';

    if (otpCode.length < 4 || target.isEmpty) return;

    _showSuccessDialog(context, otpCode, target);
  }

  @override
  Widget build(BuildContext context) {
    String target = _data['target'] ?? _data['phoneNumber'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DD3FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        title: const Text('Verifikasi OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 35,
                      child: const Icon(Icons.lock_outline, color: Color(0xFF003F5C), size: 35),
                    ),
                    const SizedBox(height: 24),
                    const Text('Masukkan OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003F5C))),
                    const SizedBox(height: 8),
                    Text(
                      'Kami telah mengirimkan 4 digit kode WhatsApp ke nomor:\n${_formatPhoneDisplay(target)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (i) => SizedBox(
                          width: 55,
                          height: 55,
                          child: TextFormField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            enabled: !_isLoading,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003F5C)),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 3) {
                                FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                              } else if (val.isEmpty && i > 0) {
                                FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                              }
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF217D9B), width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Opacity(
                      opacity: _isOtpComplete && !_isLoading ? 1.0 : 0.4,
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
                          onPressed: (_isOtpComplete && !_isLoading) ? _verifyOtp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Verifikasi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("Belum menerima kode?", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _canResend && !_isLoading ? _resendOtp : null,
                child: Text(
                  _canResend ? 'Kirim Ulang Kode Sekarang' : 'Kirim Ulang Kode (0:${_secondsRemaining.toString().padLeft(2, '0')})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _canResend ? const Color(0xFF13B49E) : const Color(0xFF003F5C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String code, String targetPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(backgroundColor: Colors.green, radius: 30, child: Icon(Icons.check, color: Colors.white, size: 40)),
            const SizedBox(height: 16),
            const Text('Verifikasi Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Kode OTP valid. Silakan buat kata sandi baru Anda.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF217D9B), Color(0xFF13B49E)]),
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
                  context.push('/new-password', extra: {
                    'target': targetPhone,
                    'phoneNumber': targetPhone,
                    'channel': 'WHATSAPP',
                    'code': code,
                  });
                },
                child: const Text('Buat Kata Sandi Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}