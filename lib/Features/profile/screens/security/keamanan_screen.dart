import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecocash_partnership/core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import 'package:ecocash_partnership/data/app_storage.dart';

class KeamananScreen extends StatefulWidget {
  const KeamananScreen({super.key});

  @override
  State<KeamananScreen> createState() => _KeamananScreenState();
}

class _KeamananScreenState extends State<KeamananScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  bool _isBiometricEnabled = true;

  // --- MODAL DIALOG UBAH PIN TRANSAKSI BANK ---
  void _showChangePinDialog() {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    bool isOldPinVisible = false;
    bool isNewPinVisible = false;
    bool isConfirmPinVisible = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Text Header + Link Lupa PIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PIN Saat Ini',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx); // Tutup modal Ubah PIN
                            _showResetPinViaOtpDialog(); // Buka modal Lupa PIN via OTP
                          },
                          child: const Text(
                            'Lupa PIN?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PIN ini digunakan untuk verifikasi penarikan saldo ke rekening bank Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input PIN Lama
                    const Text(
                      'PIN Saat Ini',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: oldPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: !isOldPinVisible,
                      enabled: !isSubmitting,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isOldPinVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => isOldPinVisible = !isOldPinVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Input PIN Baru
                    const Text(
                      'PIN Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: !isNewPinVisible,
                      enabled: !isSubmitting,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isNewPinVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => isNewPinVisible = !isNewPinVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Konfirmasi PIN Baru
                    const Text(
                      'Konfirmasi PIN Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: !isConfirmPinVisible,
                      enabled: !isSubmitting,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPinVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => isConfirmPinVisible = !isConfirmPinVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                String oldPin = oldPinController.text.trim();
                                String newPin = newPinController.text.trim();
                                String confirmPin = confirmPinController.text
                                    .trim();

                                if (oldPin.length < 6 ||
                                    newPin.length < 6 ||
                                    confirmPin.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Semua PIN harus terdiri dari 6 digit angka!',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPin != confirmPin) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'PIN Baru dan Konfirmasi PIN tidak cocok!',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final result = await _apiService.changePin(
                                  oldPin: oldPin,
                                  newPin: newPin,
                                );

                                if (!context.mounted) return;
                                setModalState(() => isSubmitting = false);

                                if (result['success'] == true) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ??
                                            'PIN transaksi berhasil diperbarui!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ??
                                            'Gagal memperbarui PIN.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Simpan PIN Baru',
                                style: TextStyle(
                                  fontSize: 14,
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
          },
        );
      },
    );
  }

  void _showResetPinViaOtpDialog() async {
    final userData = await AppStorage.getUserData();
    final String phoneNumber = userData?['phoneNumber'] ?? userData?['user']?['phoneNumber'] ?? '';

    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    bool isSubmitting = false;
    bool isOtpSent = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reset PIN via OTP',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kode OTP akan dikirim via WhatsApp ke nomor $phoneNumber.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  if (!isOtpSent) ...[
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final res = await _apiService.sendOtp(
                                phoneNumber: phoneNumber,
                                channel: 'WHATSAPP',
                                purpose: 'FORGOT_PASSWORD',
                              );
                              setModalState(() {
                                isSubmitting = false;
                                if (res['success'] == true) isOtpSent = true;
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'OTP dikirim!'),
                                    backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Kirim Kode OTP WhatsApp', style: TextStyle(color: Colors.white)),
                    ),
                  ] else ...[
                    const Text('Kode OTP (WhatsApp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('PIN Transaksi Baru (6 Digit)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              String code = otpController.text.trim();
                              String newPin = newPinController.text.trim();

                              if (code.length < 4 || newPin.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Lengkapi kode OTP dan 6 digit PIN baru!')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              final res = await _apiService.resetPinOtp(
                                phoneNumber: phoneNumber,
                                code: code,
                                newPin: newPin,
                              );
                              setModalState(() => isSubmitting = false);

                              if (!context.mounted) return;
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'PIN berhasil diperbarui!'), backgroundColor: Colors.green),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Gagal mereset PIN.'), backgroundColor: Colors.red),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan PIN Baru', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL DIALOG UBAH KATA SANDI LOGIN ---
  void _showChangePasswordDialog() {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();

    bool isOldPassVisible = false;
    bool isNewPassVisible = false;
    bool isConfirmPassVisible = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ubah Kata Sandi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan kata sandi saat ini dan kata sandi baru Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Kata Sandi Lama
                    const Text(
                      'Kata Sandi Saat Ini',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: oldPassController,
                      obscureText: !isOldPassVisible,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata sandi saat ini',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isOldPassVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => isOldPassVisible = !isOldPassVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Input Kata Sandi Baru
                    const Text(
                      'Kata Sandi Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: newPassController,
                      obscureText: !isNewPassVisible,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Minimal 6 karakter',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isNewPassVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => isNewPassVisible = !isNewPassVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Konfirmasi Kata Sandi Baru
                    const Text(
                      'Konfirmasi Kata Sandi Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPassController,
                      obscureText: !isConfirmPassVisible,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Ulangi kata sandi baru',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPassVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => isConfirmPassVisible = !isConfirmPassVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                String oldPass = oldPassController.text.trim();
                                String newPass = newPassController.text.trim();
                                String confirmPass = confirmPassController.text
                                    .trim();

                                if (oldPass.isEmpty ||
                                    newPass.isEmpty ||
                                    confirmPass.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Semua kolom kata sandi harus diisi!',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPass.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kata sandi baru minimal 6 karakter!',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPass != confirmPass) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kata sandi baru dan konfirmasi tidak cocok!',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final result = await _apiService.changePassword(
                                  oldPassword: oldPass,
                                  newPassword: newPass,
                                );

                                if (!context.mounted) return;
                                setModalState(() => isSubmitting = false);

                                if (result['success'] == true) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ??
                                            'Kata sandi berhasil diperbarui!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ??
                                            'Gagal memperbarui kata sandi.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Simpan Kata Sandi',
                                style: TextStyle(
                                  fontSize: 14,
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KATEGORI: KREDENSIAL & AUTENTIKASI ---
            const Text(
              'Kredensial & Autentikasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSecurityItem(
                    icon: Icons.pin_outlined,
                    title: 'Ubah PIN Transaksi',
                    subtitle: 'Perbarui PIN 6 digit akun bank Anda',
                    onTap: _showChangePinDialog,
                  ),
                  _buildDivider(),
                  _buildSecurityItem(
                    icon: Icons.lock_outline,
                    title: 'Ubah Kata Sandi',
                    subtitle: 'Gunakan kata sandi yang kuat dan unik',
                    onTap: _showChangePasswordDialog,
                  ),
                  _buildDivider(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- KATEGORI: PERANGKAT YANG TERHUBUNG ---
            const Text(
              'Perangkat yang Terhubung',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDeviceItem(
                    icon: Icons.phone_android,
                    deviceName: 'Samsung Galaxy S23',
                    deviceLocation: 'Jakarta, Indonesia • Sedang aktif',
                    deviceIp: 'IP: 192.168.1.15',
                    isCurrentDevice: true,
                    onLogout: () {},
                  ),
                  _buildDivider(),
                  _buildDeviceItem(
                    icon: Icons.laptop_windows,
                    deviceName: 'Windows 11 • Chrome',
                    deviceLocation:
                        'Bandung, Indonesia • Terakhir aktif: 2 jam lalu',
                    deviceIp: '',
                    isCurrentDevice: false,
                    onLogout: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Berhasil keluar dari perangkat Windows 11',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TOMBOL KELUAR DARI SEMUA PERANGKAT ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar dari Semua Perangkat'),
                      content: const Text(
                        'Anda akan keluar dari semua sesi aktif di perangkat lain.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/login');
                          },
                          child: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'Keluar dari Semua Perangkat',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDeviceItem({
    required IconData icon,
    required String deviceName,
    required String deviceLocation,
    required String deviceIp,
    required bool isCurrentDevice,
    required VoidCallback onLogout,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentDevice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Perangkat Ini',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deviceLocation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (deviceIp.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    deviceIp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isCurrentDevice)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              onPressed: onLogout,
              tooltip: 'Keluar',
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 56, endIndent: 16);
  }
}