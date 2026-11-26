import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class TambahRekeningScreen extends StatefulWidget {
  const TambahRekeningScreen({super.key});

  @override
  State<TambahRekeningScreen> createState() => _TambahRekeningScreenState();
}

class _TambahRekeningScreenState extends State<TambahRekeningScreen> {
  final TextEditingController _noRekController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final PartnerApiService _apiService = PartnerApiService();

  String? _selectedBank;
  bool _isLoading = false;
  bool _isCheckingBank = true;
  bool _hasExistingBank = false;

  static const Color _navy = Color(0xFF0F2C59);
  static const Color _cyan = AppColors.primaryCyan;
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _border = Color(0xFFE9EDF2);

  static const List<String> _banks = [
    'Bank BCA',
    'Bank Mandiri',
    'Bank BNI',
    'Bank BRI',
    'BSI',
    'DANA',
    'Gopay',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingBankAccounts();
  }

  Future<void> _checkExistingBankAccounts() async {
    try {
      final result = await _apiService.getBankAccounts();

      if (!mounted) return;

      setState(() {
        if (result['success'] == true) {
          final List data = result['data'] is List ? result['data'] : [];
          _hasExistingBank = data.isNotEmpty;
        }
        _isCheckingBank = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingBank = false);
    }
  }

  @override
  void dispose() {
    _noRekController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final noRek = _noRekController.text.trim();
    final nama = _namaController.text.trim();

    if (_selectedBank == null || noRek.isEmpty || nama.isEmpty) {
      _showSnackBar('Silakan lengkapi semua data rekening.', isError: true);
      return;
    }

    if (noRek.length < 5) {
      _showSnackBar(
        'Nomor rekening atau e-wallet terlalu pendek.',
        isError: true,
      );
      return;
    }

    _showRegisterPinDialog();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFD94B4B)
            : const Color(0xFF21845B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showRegisterPinDialog() async {
    final pinController = TextEditingController();
    bool isPinVisible = false;

    try {
      final String? pin = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (modalContext, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCE1E8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 23),

                          Row(
                            children: [
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FC),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: _navy,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _hasExistingBank
                                      ? 'Konfirmasi PIN'
                                      : 'Buat PIN Transaksi',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF87909C),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _hasExistingBank
                                ? 'Masukkan PIN transaksi 6 digit untuk mengonfirmasi penambahan rekening baru.'
                                : 'Buat PIN transaksi 6 digit. PIN ini akan digunakan untuk mengonfirmasi penarikan saldo.',
                            style: const TextStyle(
                              color: Color(0xFF78818D),
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 23),

                          const Text(
                            'PIN TRANSAKSI',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),

                          const SizedBox(height: 9),

                          TextField(
                            controller: pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: !isPinVisible,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              letterSpacing: 12,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              hintStyle: const TextStyle(
                                color: Color(0xFFBCC3CD),
                                letterSpacing: 10,
                              ),
                              filled: true,
                              fillColor: _background,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    isPinVisible = !isPinVisible;
                                  });
                                },
                                icon: Icon(
                                  isPinVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: const Color(0xFF8993A0),
                                  size: 19,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: _cyan,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 21),

                          SizedBox(
                            width: double.infinity,
                            height: 49,
                            child: ElevatedButton(
                              onPressed: () {
                                final enteredPin = pinController.text.trim();

                                if (!RegExp(
                                  r'^[0-9]{6}$',
                                ).hasMatch(enteredPin)) {
                                  _showSnackBar(
                                    'PIN harus terdiri dari 6 digit angka.',
                                    isError: true,
                                  );
                                  return;
                                }

                                // Kirim PIN sebagai hasil modal.
                                // Proses API dilakukan setelah modal tertutup.
                                Navigator.pop(sheetContext, enteredPin);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _navy,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: Text(
                                _hasExistingBank
                                    ? 'Konfirmasi & Simpan'
                                    : 'Simpan PIN & Rekening',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      // Modal sudah selesai ditutup sebelum API dipanggil.
      if (!mounted || pin == null) return;

      await _submitTambahRekening(pin);
    } finally {
      pinController.dispose();
    }
  }

  Future<void> _submitTambahRekening(String pin) async {
    final noRek = _noRekController.text.trim();
    final nama = _namaController.text.trim();

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.addBankAccount(
        bankName: _selectedBank!,
        accountNumber: noRek,
        accountHolderName: nama,
        pin: pin,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSnackBar(
          result['message'] ?? 'Rekening dan PIN berhasil ditambahkan.',
        );
        context.pop(true);
      } else {
        _showSnackBar(
          result['message'] ?? 'Gagal menambahkan rekening.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSnackBar(
        'Terjadi kesalahan saat menyimpan rekening.',
        isError: true,
      );
      debugPrint('Tambah rekening error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          onPressed: _isLoading ? null : () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _navy,
            size: 19,
          ),
        ),
        title: const Text(
          'Tambah Rekening',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 21),

              _buildInformationCard(),
              const SizedBox(height: 23),

              Row(
                children: [
                  const Text(
                    'Informasi rekening',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_isCheckingBank)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: _cyan,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Bank / E-Wallet'),
                    const SizedBox(height: 8),
                    _buildBankDropdown(),

                    const SizedBox(height: 19),

                    _buildFieldLabel('Nomor Rekening / E-Wallet'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _noRekController,
                      hint: 'Masukkan nomor rekening',
                      icon: Icons.account_balance_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 19),

                    _buildFieldLabel('Nama Pemilik Rekening'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _namaController,
                      hint: 'Sesuai nama pada buku tabungan',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 17),

              _buildSecurityNote(),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSavePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: _navy.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Simpan Rekening',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153C70), Color(0xFF0F2C59)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -18,
            child: Icon(
              Icons.account_balance_rounded,
              size: 112,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PENGATURAN PEMBAYARAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Tambah Rekening',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hubungkan rekening atau e-wallet untuk\nmemudahkan pencairan saldo mitra.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD9E8F8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF3766A5), size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan nama pemilik rekening sesuai dengan profil Anda agar proses penarikan dana berjalan lancar.',
              style: TextStyle(
                color: Color(0xFF385675),
                fontSize: 10,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _navy,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBankDropdown() {
    return Container(
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBank,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF78818D),
          ),
          hint: const Text(
            'Pilih bank atau e-wallet',
            style: TextStyle(color: Color(0xFF9AA3AE), fontSize: 11),
          ),
          items: _banks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank,
              child: Row(
                children: [
                  Icon(
                    bank == 'DANA' || bank == 'Gopay'
                        ? Icons.account_balance_wallet_outlined
                        : Icons.account_balance_outlined,
                    size: 17,
                    color: _navy,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    bank,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() => _selectedBank = value);
                },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _navy,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9AA3AE),
          fontSize: 11,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF8794A5), size: 18),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _cyan, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: Color(0xFF21845B), size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Informasi rekening dan PIN transaksi digunakan untuk kebutuhan pembayaran mitra. Jangan bagikan PIN kepada siapa pun.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
