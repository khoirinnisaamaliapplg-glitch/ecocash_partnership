import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'success_withdraw_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State {
  final TextEditingController _amountController = TextEditingController(text: '100.000');
  String _selectedNominal = '100.000';
  String _selectedMethod = 'Bank BCA';

  static const Color _navyColor = Color(0xFF0F2C59);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU SALDO TERSEDIA ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: const [
                        Text('Saldo Tersedia', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(height: 6),
                        Text(
                          'Rp1.245.000',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _navyColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- NOMINAL PENARIKAN ---
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _amountController,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          onChanged: (val) {
                            setState(() {
                              _selectedNominal = val;
                            });
                          },
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
                        const SizedBox(height: 14),

                        // --- KOTAK PILIHAN NOMINAL PENARIKAN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['50.000', '100.000', '200.000', 'Semua'].map((nominal) {
                            bool isSelected = _selectedNominal == nominal;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedNominal = nominal;
                                  _amountController.text = nominal == 'Semua' ? '1.245.000' : nominal;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? _navyColor : Colors.grey.shade300,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  nominal,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? _navyColor : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Minimal penarikan Rp50.000', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  // --- METODE PENARIKAN ---
                  const Text(
                    'Metode Penarikan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                  const SizedBox(height: 12),
                  _buildBankOption('Bank BCA', '**** 1234 a.n. Partner EcoCash', Icons.account_balance),
                  const SizedBox(height: 10),
                  _buildBankOption('Bank Mandiri', '**** 5678 a.n. Partner EcoCash', Icons.account_balance),
                  const SizedBox(height: 10),
                  _buildBankOption('DANA', '0812****9012', Icons.account_balance_wallet),
                  const SizedBox(height: 12),

                  // Tombol Tambah Rekening/E-Wallet Baru
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: _navyColor, size: 18),
                      label: const Text(
                        'Tambah Rekening/E-Wallet Baru',
                        style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _navyColor),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- RINCIAN PENARIKAN ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rincian Penarikan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _navyColor),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jumlah Penarikan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('Rp${_amountController.text}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Biaya Admin', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('Rp2.500', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- TOMBOL KONFIRMASI PENARIKAN (FIXED BOTTOM) ---
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
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SuccessWithdrawScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88A8), // Warna tombol samakan dengan gambar
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Konfirmasi Penarikan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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

  Widget _buildBankOption(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: _navyColor, width: 1.5) : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE), // Background biru muda lembut seperti di gambar
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _navyColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Radio(
              value: title,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
              activeColor: _navyColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}