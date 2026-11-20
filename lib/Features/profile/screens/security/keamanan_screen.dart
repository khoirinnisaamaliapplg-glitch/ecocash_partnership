import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import 'package:ecocash_partnership/core/widgets/app_loading.dart';

class KeamananScreen extends StatefulWidget {
  const KeamananScreen({super.key});

  @override
  State<KeamananScreen> createState() => _KeamananScreenState();
}

class _KeamananScreenState extends State<KeamananScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  static const Color _navy = Color(0xFF142D4E);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _background = Color(0xFFF4F6F9);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFEDF0F4);
  static const Color _green = Color(0xFF27945D);
  static const Color _red = Color(0xFFE05252);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }
  // ============================================================
  // UBAH PIN TRANSAKSI
  // ============================================================

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    bool isOldPinVisible = false;
    bool isNewPinVisible = false;
    bool isConfirmPinVisible = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModalHandle(),
                    _buildModalHeader(
                      title: 'Ubah PIN Transaksi',
                      subtitle:
                          'Perbarui PIN untuk menjaga keamanan penarikan saldo Anda.',
                      icon: Icons.password_rounded,
                      onClose: isSubmitting ? null : () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 26),

                    _buildFieldLabel('PIN Saat Ini'),
                    const SizedBox(height: 8),
                    _buildPinField(
                      controller: oldPinController,
                      visible: isOldPinVisible,
                      enabled: !isSubmitting,
                      onToggle: () => setModalState(
                        () => isOldPinVisible = !isOldPinVisible,
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildFieldLabel('PIN Baru'),
                    const SizedBox(height: 8),
                    _buildPinField(
                      controller: newPinController,
                      visible: isNewPinVisible,
                      enabled: !isSubmitting,
                      onToggle: () => setModalState(
                        () => isNewPinVisible = !isNewPinVisible,
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildFieldLabel('Konfirmasi PIN Baru'),
                    const SizedBox(height: 8),
                    _buildPinField(
                      controller: confirmPinController,
                      visible: isConfirmPinVisible,
                      enabled: !isSubmitting,
                      onToggle: () => setModalState(
                        () => isConfirmPinVisible = !isConfirmPinVisible,
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildPrimaryButton(
                      label: 'Simpan PIN Baru',
                      loading: isSubmitting,
                      onPressed: () async {
                        final oldPin = oldPinController.text.trim();
                        final newPin = newPinController.text.trim();
                        final confirmPin = confirmPinController.text.trim();

                        if (oldPin.length != 6 ||
                            newPin.length != 6 ||
                            confirmPin.length != 6 ||
                            !RegExp(r'^\d{6}$').hasMatch(oldPin) ||
                            !RegExp(r'^\d{6}$').hasMatch(newPin) ||
                            !RegExp(r'^\d{6}$').hasMatch(confirmPin)) {
                          _showMessage(
                            'Semua PIN harus terdiri dari 6 digit angka.',
                            isError: true,
                          );
                          return;
                        }

                        if (newPin != confirmPin) {
                          _showMessage(
                            'PIN baru dan konfirmasi PIN tidak cocok.',
                            isError: true,
                          );
                          return;
                        }

                        if (oldPin == newPin) {
                          _showMessage(
                            'PIN baru harus berbeda dari PIN saat ini.',
                            isError: true,
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);

                        try {
                          final result = await _apiService.changePin(
                            oldPin: oldPin,
                            newPin: newPin,
                          );

                          if (!mounted || !ctx.mounted) return;

                          if (result['success'] == true) {
                            Navigator.pop(ctx);
                            _showMessage(
                              result['message'] ??
                                  'PIN transaksi berhasil diperbarui.',
                            );
                          } else {
                            setModalState(() => isSubmitting = false);
                            _showMessage(
                              result['message'] ?? 'Gagal memperbarui PIN.',
                              isError: true,
                            );
                          }
                        } catch (e) {
                          if (!mounted || !ctx.mounted) return;

                          setModalState(() => isSubmitting = false);
                          _showMessage(
                            'Terjadi kesalahan. Silakan coba kembali.',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      oldPinController.dispose();
      newPinController.dispose();
      confirmPinController.dispose();
    });
  }

  // ============================================================
  // UBAH KATA SANDI
  // ============================================================

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    bool isOldPassVisible = false;
    bool isNewPassVisible = false;
    bool isConfirmPassVisible = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModalHandle(),
                    _buildModalHeader(
                      title: 'Ubah Kata Sandi',
                      subtitle:
                          'Gunakan kata sandi yang kuat untuk melindungi akun Anda.',
                      icon: Icons.lock_reset_rounded,
                      onClose: isSubmitting ? null : () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 26),

                    _buildFieldLabel('Kata Sandi Saat Ini'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: oldPassController,
                      visible: isOldPassVisible,
                      enabled: !isSubmitting,
                      hint: 'Masukkan kata sandi saat ini',
                      onToggle: () => setModalState(
                        () => isOldPassVisible = !isOldPassVisible,
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildFieldLabel('Kata Sandi Baru'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: newPassController,
                      visible: isNewPassVisible,
                      enabled: !isSubmitting,
                      hint: 'Minimal 6 karakter',
                      onToggle: () => setModalState(
                        () => isNewPassVisible = !isNewPassVisible,
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildFieldLabel('Konfirmasi Kata Sandi Baru'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: confirmPassController,
                      visible: isConfirmPassVisible,
                      enabled: !isSubmitting,
                      hint: 'Ulangi kata sandi baru',
                      onToggle: () => setModalState(
                        () => isConfirmPassVisible = !isConfirmPassVisible,
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildPrimaryButton(
                      label: 'Simpan Kata Sandi',
                      loading: isSubmitting,
                      onPressed: () async {
                        final oldPass = oldPassController.text.trim();
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();

                        if (oldPass.isEmpty ||
                            newPass.isEmpty ||
                            confirmPass.isEmpty) {
                          _showMessage(
                            'Semua kolom kata sandi harus diisi.',
                            isError: true,
                          );
                          return;
                        }

                        if (newPass.length < 6) {
                          _showMessage(
                            'Kata sandi baru minimal 6 karakter.',
                            isError: true,
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          _showMessage(
                            'Konfirmasi kata sandi tidak cocok.',
                            isError: true,
                          );
                          return;
                        }

                        if (oldPass == newPass) {
                          _showMessage(
                            'Kata sandi baru harus berbeda dari kata sandi lama.',
                            isError: true,
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);

                        try {
                          final result = await _apiService.changePassword(
                            oldPassword: oldPass,
                            newPassword: newPass,
                          );

                          if (!mounted || !ctx.mounted) return;

                          if (result['success'] == true) {
                            Navigator.pop(ctx);
                            _showMessage(
                              result['message'] ??
                                  'Kata sandi berhasil diperbarui.',
                            );
                          } else {
                            setModalState(() => isSubmitting = false);
                            _showMessage(
                              result['message'] ??
                                  'Gagal memperbarui kata sandi.',
                              isError: true,
                            );
                          }
                        } catch (e) {
                          if (!mounted || !ctx.mounted) return;

                          setModalState(() => isSubmitting = false);
                          _showMessage(
                            'Terjadi kesalahan. Silakan coba kembali.',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      oldPassController.dispose();
      newPassController.dispose();
      confirmPassController.dispose();
    });
  }

  // ============================================================
  // KOMPONEN MODAL
  // ============================================================

  Widget _buildModalHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFE1E5EB),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildModalHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onClose,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5D8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: _navy, size: 24),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _secondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: _secondary),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required bool visible,
    required bool enabled,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      obscureText: !visible,
      enabled: enabled,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 19,
        letterSpacing: 9,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
      decoration: _fieldDecoration(
        hint: '••••••',
        suffix: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _secondary,
            size: 20,
          ),
        ),
      ).copyWith(counterText: ''),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool visible,
    required bool enabled,
    required String hint,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 14,
        color: _navy,
        fontWeight: FontWeight.w500,
      ),
      decoration: _fieldDecoration(
        hint: hint,
        prefix: const Icon(
          Icons.lock_outline_rounded,
          color: _secondary,
          size: 20,
        ),
        suffix: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _secondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFFAAB3C0),
        letterSpacing: 0,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          disabledBackgroundColor: _navy.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: _yellow,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // KOMPONEN HALAMAN
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? _red : _green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: _secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildSecurityItem(
            icon: Icons.password_rounded,
            title: 'Ubah PIN Transaksi',
            subtitle: 'Perbarui PIN 6 digit akun bank Anda',
            onTap: _showChangePinDialog,
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.lock_reset_rounded,
            title: 'Ubah Kata Sandi',
            subtitle: 'Gunakan kata sandi yang kuat dan unik',
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5D8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _navy, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: _secondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondary,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      endIndent: 16,
      color: _border,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: AppLoading(message: 'Menyiapkan keamanan akun kamu...', size: 76),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigasi halaman
              Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const SizedBox(
                        width: 43,
                        height: 43,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _navy,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Keamanan Akun',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: _navy,
                      size: 21,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Banner Perlindungan Akun
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.13),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // 1. Dekorasi lingkaran di pojok kanan atas
                      Positioned(
                        right: -22,
                        top: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.045),
                          ),
                        ),
                      ),

                      // 2. Gambar ilustrasi menempel rapat di pojok kanan bawah
                      Positioned(
                        right: -100,
                        bottom: -10,
                        child: Opacity(
                          opacity:
                              0.5, // Ubah ke 0.30 jika ingin menyatu gelap seperti watermark
                          child: Image.asset(
                            'assets/images/keamanan.png',
                            width: 400,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomRight,
                            errorBuilder: (context, error, stackTrace) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Icon(
                                  Icons.security_rounded,
                                  color: _yellow,
                                  size: 65,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 3. Konten teks di sisi kiri
                      Padding(
                        padding: const EdgeInsets.fromLTRB(19, 19, 145, 19),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _yellow,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: _navy,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                const Expanded(
                                  child: Text(
                                    'Perlindungan Akun',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            const Text(
                              'Keamanan dimulai dari Anda.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Jaga kerahasiaan PIN dan kata sandi. Jangan bagikan informasi login kepada siapa pun.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 10,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _yellow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 27),

              _buildSectionTitle(
                'Kredensial & Autentikasi',
                'Kelola informasi untuk mengakses akun Anda',
              ),

              _buildSecurityCard(),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'EcoCash Partner • Keamanan Akun',
                  style: TextStyle(
                    color: _secondary.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
