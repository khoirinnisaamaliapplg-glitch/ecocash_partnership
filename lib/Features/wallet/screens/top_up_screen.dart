import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'Transfer Bank (VA)';
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
        title: const Text(
          'Top Up Saldo',
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
                    'Masukkan nominal top up untuk menambah saldo EcoCash Partner Anda. Minimal top up Rp 10.000.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // --- KARTU INPUT NOMINAL & PILIHAN CEPAT ---
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
                        const Text('Nominal Top Up', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          onChanged: (val) {
                            setState(() {}); // Update tampilan saat input manual
                          },
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
                        const SizedBox(height: 16),

                        // --- KOTAK PILIHAN NOMINAL CEPAT ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['50.000', '100.000', '250.000', '500.000'].map((nominal) {
                            bool isSelected = _amountController.text == nominal;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _amountController.text = nominal;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryCyan.withOpacity(0.1) : const Color(0xFFF4F6F8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryCyan : Colors.grey.shade300,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  nominal,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- METODE PEMBAYARAN ---
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption('Transfer Bank (VA)', 'BCA, Mandiri, BNI, BRI', Icons.account_balance),
                  const SizedBox(height: 10),
                  _buildPaymentOption('Minimarket', 'Alfamart, Indomaret', Icons.store),
                  const SizedBox(height: 10),
                  _buildPaymentOption('QRIS', 'Gopay, OVO, Dana, LinkAja', Icons.qr_code_2),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- TOMBOL LANJUTKAN PEMBAYARAN (FIXED BOTTOM) ---
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88A8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lanjutkan Pembayaran',
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

  Widget _buildPaymentOption(String title, String subtitle, IconData icon) {
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
          border: isSelected ? Border.all(color: AppColors.primaryCyan, width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Radio(
              value: title,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
              activeColor: AppColors.primaryCyan,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(10),
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
          ],
        ),
      ),
    );
  }
}