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
  bool _hasExistingBank = false; // Flag status rekening/PIN existing

  @override
  void initState() {
    super.initState();
    _checkExistingBankAccounts(); // Cek ketersediaan rekening saat layar dibuka
  }

  // --- CEK APAKAH MITRA SUDAH PUNYA REKENING / PIN TERDAFTAR ---
  Future<void> _checkExistingBankAccounts() async {
    final result = await _apiService.getBankAccounts();
    if (mounted && result['success'] == true) {
      final List data = result['data'] is List ? result['data'] : [];
      setState(() {
        _hasExistingBank = data.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _noRekController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  // --- VALIDASI AWAL SEBELUM POPUP PIN ---
  void _onSavePressed() {
    String noRek = _noRekController.text.trim();
    String nama = _namaController.text.trim();

    if (_selectedBank == null || noRek.isEmpty || nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan lengkapi semua data rekening!')),
      );
      return;
    }

    _showRegisterPinDialog();
  }

  // --- POPUP MODAL DAFTAR PIN TRANSAKSI (DINAMIS) ---
  void _showRegisterPinDialog() {
    final TextEditingController pinController = TextEditingController();
    bool isPinVisible = false;

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
                      Text(
                        _hasExistingBank ? 'Masukkan PIN Transaksi' : 'Buat PIN Transaksi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasExistingBank
                        ? 'Masukkan 6 digit PIN Transaksi Anda untuk mengonfirmasi penambahan rekening baru ini.'
                        : 'Daftarkan 6 digit PIN Transaksi Anda. PIN ini akan digunakan untuk mengonfirmasi setiap penarikan saldo ke rekening ini.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: !isPinVisible,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: const TextStyle(letterSpacing: 8, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      suffixIcon: IconButton(
                        icon: Icon(isPinVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setModalState(() => isPinVisible = !isPinVisible),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        String pin = pinController.text.trim();
                        if (pin.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN harus terdiri dari 6 digit angka!')),
                          );
                          return;
                        }

                        Navigator.pop(ctx); // Tutup modal PIN
                        _submitTambahRekening(pin); // Jalankan submit dengan PIN
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _hasExistingBank ? 'Konfirmasi & Simpan' : 'Simpan PIN & Rekening',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- FUNGSI SUBMIT DENGAN PARAMETER PIN ---
  Future<void> _submitTambahRekening(String pin) async {
    String noRek = _noRekController.text.trim();
    String nama = _namaController.text.trim();

    setState(() => _isLoading = true);

    debugPrint('=== [SUBMIT BANK ACCOUNT] ===');
    debugPrint('Bank: $_selectedBank, No.Rek: $noRek, AccountHolder: $nama, PIN: $pin');

    try {
      final result = await _apiService.addBankAccount(
        bankName: _selectedBank!,
        accountNumber: noRek,
        accountHolderName: nama,
        pin: pin, // Mengirimkan PIN ke backend
      );

      debugPrint('=== [RESULT API] ===');
      debugPrint('Success: ${result['success']}');
      debugPrint('Message: ${result['message']}');

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Rekening & PIN berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menambahkan rekening.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('=== [ERROR SUBMIT] ===: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        title: const Text(
          'Tambah Rekening',
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryCyan.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryCyan,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pastikan nama pemilik rekening sesuai dengan profil Anda untuk kelancaran proses penarikan dana.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Nama Bank',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedBank,
                  hint: const Text(
                    'Pilih Bank',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  items: <String>[
                    'Bank BCA',
                    'Bank Mandiri',
                    'Bank BNI',
                    'Bank BRI',
                    'BSI',
                    'DANA',
                    'Gopay',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (String? newValue) {
                          setState(() {
                            _selectedBank = newValue;
                          });
                        },
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Nomor Rekening / E-Wallet',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noRekController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 1234567890',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Nama Pemilik Rekening',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _namaController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Masukkan Nama Sesuai Buku Tabungan',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Simpan Rekening',
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