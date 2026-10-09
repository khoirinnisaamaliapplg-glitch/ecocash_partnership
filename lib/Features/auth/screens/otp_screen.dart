import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class OtpScreen extends StatefulWidget {
  final Map userData;

  const OtpScreen({super.key, this.userData = const {}});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  
  String _selectedMethod = 'phone'; // Default tab terpilih No. Ponsel (sebelah kiri)
  bool _isComplete = false;
  bool _isLoading = false;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  Map get _data => widget.userData;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
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
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _checkOtpCompletion() {
    String otp = _controllers.map((c) => c.text).join();
    setState(() {
      _isComplete = otp.length == 4;
    });
  }

  // --- MASKING EMAIL & PHONE NUMBER ---
  String _maskEmail(String? email) {
    if (email == null || email.trim().isEmpty || !email.contains('@')) {
      return 'mitra@gmail.com';
    }
    List parts = email.trim().split('@');
    String name = parts[0];
    String domain = parts[1];

    if (name.length <= 3) {
      return name[0] + '***@' + domain;
    }

    String visibleName = name.substring(0, 3);
    return visibleName + '***@' + domain;
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty || phone.length < 8) {
      return '+62 812 **** 7890';
    }
    String cleanPhone = phone.trim();
    String start = cleanPhone.substring(0, 4);
    String end = cleanPhone.substring(cleanPhone.length - 4);
    return start + ' **** ' + end;
  }

  // --- RESEND OTP (Dinamis WhatsApp / Email) ---
  Future<void> _resendCode() async {
    String emailTarget = _data['email'] ?? '';
    String phoneTarget = _data['phone'] ?? _data['phoneNumber'] ?? '';

    bool isEmail = _selectedMethod == 'email';
    String target = isEmail ? emailTarget : phoneTarget;

    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEmail ? 'Alamat Email tidak terdeteksi!' : 'Nomor WhatsApp tidak terdeteksi!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.sendOtp(
      email: isEmail ? emailTarget : null,
      phoneNumber: !isEmail ? phoneTarget : null,
      channel: isEmail ? 'EMAIL' : 'WHATSAPP',
      purpose: 'REGISTRATION',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Kode OTP berhasil dikirim ulang.'),
          backgroundColor: Colors.green,
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim ulang OTP.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- VERIFY OTP (Dinamis WhatsApp / Email) ---
  Future<void> _verifyOtp() async {
    String otpCode = _controllers.map((c) => c.text).join();
    String emailTarget = _data['email'] ?? '';
    String phoneTarget = _data['phone'] ?? _data['phoneNumber'] ?? '';

    bool isEmail = _selectedMethod == 'email';
    String target = isEmail ? emailTarget : phoneTarget;

    if (otpCode.length < 4 || target.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _apiService.verifyOtp(
      email: isEmail ? emailTarget : null,
      phoneNumber: !isEmail ? phoneTarget : null,
      code: otpCode,
      purpose: 'REGISTRATION',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccessDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Verifikasi OTP gagal.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String emailTarget = _data['email'] ?? '';
    String phoneTarget = _data['phone'] ?? _data['phoneNumber'] ?? '';

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
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: _isLoading ? null : () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verifikasi Kode OTP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        // KIRI: No. Ponsel
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : () => setState(() => _selectedMethod = 'phone'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedMethod == 'phone' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedMethod == 'phone'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: _selectedMethod == 'phone' ? AppColors.primaryGreen : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'No. Ponsel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedMethod == 'phone' ? AppColors.primaryGreen : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // KANAN: E-mail
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : () => setState(() => _selectedMethod = 'email'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedMethod == 'email' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedMethod == 'email'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: _selectedMethod == 'email' ? AppColors.primaryGreen : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'E-mail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedMethod == 'email' ? AppColors.primaryGreen : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedMethod == 'phone'
                        ? 'Masukkan 4 digit kode OTP yang dikirim ke nomor\n' + _maskPhone(phoneTarget)
                        : 'Masukkan kode verifikasi yang dikirim ke email\n' + _maskEmail(emailTarget),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) => SizedBox(
                      width: 55,
                      height: 55,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        enabled: !_isLoading,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 3) {
                            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                          }
                          _checkOtpCompletion();
                        },
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Belum menerima kode?',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _canResend && !_isLoading ? _resendCode : null,
                          child: Text(
                            _canResend
                                ? 'Kirim Ulang Kode Sekarang'
                                : 'Kirim ulang dalam 00:' + _secondsRemaining.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _canResend ? AppColors.textLink : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF1A73E8)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jangan bagikan kode OTP kepada siapa pun, termasuk pihak EcoCash Partner.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1A73E8), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: _isComplete && !_isLoading ? 1.0 : 0.5,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _isComplete ? AppColors.primaryButtonGradient : null,
                        color: _isComplete ? null : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isComplete
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: (_isComplete && !_isLoading) ? _verifyOtp : null,
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
                                  Text(
                                    'Verifikasi',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '→',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verifikasi Berhasil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Akun EcoCash Partner Anda berhasil diverifikasi. Silakan masuk menggunakan akun Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButtonGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Lanjut ke Halaman Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}