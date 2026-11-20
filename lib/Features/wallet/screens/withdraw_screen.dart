
import 'package:flutter/material.dart';
import 'package:ecocash_partnership/core/theme/app_colors.dart';
import 'package:ecocash_partnership/core/widgets/app_loading.dart';
import 'package:ecocash_partnership/services/api_service.dart';

import 'success_withdraw_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '100000');

  final PartnerApiService _apiService = PartnerApiService();

  List<dynamic> _bankAccounts = [];

  String? _selectedBankAccountId;
  String? _bankLoadError;

  bool _isLoadingBank = true;
  bool _isSubmitting = false;

  static const Color _navy = AppColors.darkNavy;
  static const Color _yellow = AppColors.primaryYellow;
  static const Color _background = AppColors.background;
  static const Color _secondary = AppColors.textSecondary;
  static const Color _border = AppColors.cardBorder;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // AMBIL REKENING BANK DARI BACKEND
  // ============================================================

  Future<void> _fetchBankAccounts() async {
    if (mounted) {
      setState(() {
        _isLoadingBank = true;
        _bankLoadError = null;
      });
    }

    try {
      final result = await _apiService.getBankAccounts();

      if (!mounted) return;

      setState(() {
        if (result['success'] == true) {
          _bankAccounts =
              result['data'] is List ? result['data'] : [];

          if (_bankAccounts.isNotEmpty) {
            final selectedStillExists = _bankAccounts.any(
              (item) =>
                  item['id'].toString() == _selectedBankAccountId,
            );

            if (!selectedStillExists) {
              _selectedBankAccountId =
                  _bankAccounts[0]['id'].toString();
            }
          } else {
            _selectedBankAccountId = null;
          }
        } else {
          _bankAccounts = [];
          _bankLoadError =
              result['message'] ?? 'Gagal mengambil rekening bank.';
        }

        _isLoadingBank = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingBank = false;
        _bankAccounts = [];
        _bankLoadError =
            'Terjadi kesalahan saat mengambil rekening.';
      });
    }
  }

  // ============================================================
  // FORMAT NOMINAL
  // ============================================================

  String _formatRupiah(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return '';

    final number = int.tryParse(digits);
    if (number == null) return '';

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return formatted;
  }

  // ============================================================
  // VALIDASI PENARIKAN
  // ============================================================

  void _onConfirmWithdrawal() {
    final rawAmount = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final amount = double.tryParse(rawAmount);

    if (amount == null || amount < 50000) {
      _showMessage(
        'Minimal penarikan adalah Rp50.000.',
        isError: true,
      );
      return;
    }

    if (_selectedBankAccountId == null) {
      _showMessage(
        'Pilih rekening bank tujuan penarikan.',
        isError: true,
      );
      return;
    }

    _showPinDialog(amount);
  }

  // ============================================================
  // DIALOG PIN TRANSAKSI
  // ============================================================

 
Future<void> _showPinDialog(double amount) async {
  final pinController = TextEditingController();

  bool isPinVisible = false;

  String? pin;

  try {
    pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E7ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _yellow.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.password_rounded,
                            color: _navy,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verifikasi Transaksi',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Masukkan PIN transaksi Anda',
                                style: TextStyle(
                                  color: _secondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _secondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: _navy,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Nominal penarikan',
                              style: TextStyle(
                                color: _secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            'Rp ${_formatRupiah(amount.toInt().toString())}',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'PIN Transaksi',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                        fontSize: 22,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: const TextStyle(
                          letterSpacing: 8,
                          color: Color(0xFFB7C0CC),
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
                            color: _secondary,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _navy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Jangan berikan PIN transaksi kepada siapa pun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _secondary,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final enteredPin =
                              pinController.text.trim();

                          if (!RegExp(r'^\d{6}$')
                              .hasMatch(enteredPin)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'PIN harus terdiri dari 6 digit angka.',
                                ),
                              ),
                            );
                            return;
                          }

                          // Kembalikan PIN dan tutup bottom sheet.
                          Navigator.pop(sheetContext, enteredPin);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Konfirmasi & Tarik Saldo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 9),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _yellow,
                              size: 19,
                            ),
                          ],
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
  } finally {
    // Controller baru dibuang setelah bottom sheet selesai ditutup.
    pinController.dispose();
  }

  // Request baru dijalankan setelah dialog benar-benar tertutup.
  if (!mounted || pin == null) return;

  await _submitWithdrawal(amount, pin);
}


  // ============================================================
  // KIRIM PERMINTAAN PENARIKAN KE BACKEND
  // ============================================================

  Future<void> _submitWithdrawal(
    double amount,
    String pin,
  ) async {
    if (_selectedBankAccountId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _apiService.requestWithdrawal(
        amount: amount,
        bankAccountId: _selectedBankAccountId!,
        pin: pin,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessWithdrawScreen(
              withdrawalData: result['data'],
            ),
          ),
        );
      } else {
        _showMessage(
          result['message'] ?? 'Gagal mengajukan penarikan.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Terjadi kesalahan. Silakan coba kembali.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFE05252)
              : AppColors.ecoGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ============================================================
  // KARTU REKENING BANK
  // ============================================================

  Widget _buildBankAccounts() {
    if (_isLoadingBank) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: _navy,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_bankLoadError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: _secondary,
              size: 35,
            ),
            const SizedBox(height: 10),
            Text(
              _bankLoadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 13),
            TextButton.icon(
              onPressed: _fetchBankAccounts,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: TextButton.styleFrom(
                foregroundColor: _navy,
              ),
            ),
          ],
        ),
      );
    }

    if (_bankAccounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.account_balance_outlined,
              color: _secondary,
              size: 36,
            ),
            SizedBox(height: 10),
            Text(
              'Belum Ada Rekening',
              style: TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Silakan tambahkan rekening bank terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondary,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _bankAccounts.map((item) {
        final String id = item['id'].toString();
        final String bankName = item['bankName'] ?? 'Bank';
        final String accountNumber = item['accountNumber'] ?? '';
        final bool isSelected = _selectedBankAccountId == id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedBankAccountId = id;
                      });
                    },
              borderRadius: BorderRadius.circular(17),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: isSelected ? _navy : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: _yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: _navy,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bankName,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            accountNumber,
                            style: const TextStyle(
                              color: _secondary,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? _navy : _secondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // RINGKASAN PENARIKAN
  // ============================================================

  Widget _buildWithdrawalInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _yellow.withOpacity(0.13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _yellow.withOpacity(0.35),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _navy,
            size: 20,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Pastikan nominal dan rekening tujuan sudah benar sebelum melakukan penarikan. Minimal penarikan adalah Rp50.000.',
              style: TextStyle(
                color: _navy,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tarik Saldo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: _isLoadingBank
          ? const AppLoading(
              message: 'Menyiapkan penarikan saldo kamu...',
              size: 76,
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        const Text(
                          'Penarikan Saldo',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tarik saldo EcoCash ke rekening bank kamu.',
                          style: TextStyle(
                            color: _secondary,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 23),

                        // NOMINAL
                        const Text(
                          'Nominal Penarikan',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 11),

                        Container(
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withOpacity(0.035),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Masukkan jumlah saldo',
                                style: TextStyle(
                                  color: _secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Rp',
                                    style: TextStyle(
                                      color: _navy,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      enabled: !_isSubmitting,
                                      keyboardType:
                                          TextInputType.number,
                                      style: const TextStyle(
                                        color: _navy,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '0',
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        final formatted =
                                            _formatRupiah(value);

                                        if (formatted != value) {
                                          _amountController.value =
                                              TextEditingValue(
                                            text: formatted,
                                            selection:
                                                TextSelection.collapsed(
                                              offset: formatted.length,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                color: _border,
                                height: 24,
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: _secondary,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Minimal penarikan Rp50.000',
                                    style: TextStyle(
                                      color: _secondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // REKENING TUJUAN
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Rekening Tujuan',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${_bankAccounts.length} rekening',
                              style: const TextStyle(
                                color: _secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 11),

                        _buildBankAccounts(),

                        const SizedBox(height: 10),

                        _buildWithdrawalInfo(),
                      ],
                    ),
                  ),
                ),

                // TOMBOL KONFIRMASI
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: _border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.045),
                        blurRadius: 15,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ||
                                _bankAccounts.isEmpty ||
                                _selectedBankAccountId == null
                            ? null
                            : _onConfirmWithdrawal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          disabledBackgroundColor:
                              _navy.withOpacity(0.35),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 23,
                                width: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Konfirmasi Penarikan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 9),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _yellow,
                                    size: 19,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
