import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'success_withdraw_screen.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController = TextEditingController(text: '100000');
  final PartnerApiService _apiService = PartnerApiService();

  List<dynamic> _bankAccounts = [];
  String? _selectedBankAccountId;
  bool _isLoadingBank = true;
  bool _isSubmitting = false;

  static const Color _navyColor = Color(0xFF0F2C59);

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

  Future<void> _fetchBankAccounts() async {
    final result = await _apiService.getBankAccounts();
    if (mounted) {
      setState(() {
        _isLoadingBank = false;
        if (result['success'] == true) {
          _bankAccounts = result['data'] is List ? result['data'] : [];
          if (_bankAccounts.isNotEmpty) {
            _selectedBankAccountId = _bankAccounts[0]['id'].toString();
          }
        }
      });
    }
  }

  Future<void> _submitWithdrawal() async {
    String rawAmount = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    double? amount = double.tryParse(rawAmount);

    if (amount == null || amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal penarikan adalah Rp50.000!')),
      );
      return;
    }

    if (_selectedBankAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rekening bank tujuan penarikan!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _apiService.requestWithdrawal(
      amount: amount,
      bankAccountId: _selectedBankAccountId!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

   if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessWithdrawScreen(
            withdrawalData: result['data'], // Send data dari backend
          ),
        ),
      );
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengajukan penarikan.'),
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
        centerTitle: true,
        title: const Text(
          'Tarik Saldo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nominal Penarikan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: TextField(
                      controller: _amountController,
                      enabled: !_isSubmitting,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryCyan)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Minimal penarikan Rp50.000', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  const Text(
                    'Pilih Rekening Tujuan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                  const SizedBox(height: 12),

                  _isLoadingBank
                      ? const Center(child: CircularProgressIndicator())
                      : _bankAccounts.isEmpty
                          ? const Text('Belum ada rekening tersimpan. Silakan tambah rekening terlebih dahulu.', style: TextStyle(color: Colors.red, fontSize: 12))
                          : Column(
                              children: _bankAccounts.map((item) {
                                String id = item['id'].toString();
                                String bankName = item['bankName'] ?? 'Bank';
                                String num = item['accountNumber'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedBankAccountId = id),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _selectedBankAccountId == id ? _navyColor : Colors.grey.shade200, width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.account_balance, color: _navyColor),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text('$bankName - $num', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Radio<String>(
                                            value: id,
                                            groupValue: _selectedBankAccountId,
                                            onChanged: (val) => setState(() => _selectedBankAccountId = val),
                                            activeColor: _navyColor,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88A8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          'Konfirmasi Penarikan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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