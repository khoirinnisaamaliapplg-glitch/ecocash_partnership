import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'Transfer Bank (VA)';

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
        title: const Text('Top Up Saldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nominal top up untuk menambah saldo EcoCash Partner Anda. Minimal top up Rp10.000.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['50.000', '100.000', '250.000', '500.000'].map((nominal) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _amountController.text = nominal;
                          });
                        },
                        child: Text(
                          nominal,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- METODE PEMBAYARAN ---
            const Text('Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildPaymentOption('Transfer Bank (VA)', 'BCA, Mandiri, BNI, BRI', Icons.account_balance),
            const SizedBox(height: 10),
            _buildPaymentOption('Minimarket', 'Alfamart, Indomaret', Icons.store),
            const SizedBox(height: 10),
            _buildPaymentOption('QRIS', 'Gopay, OVO, Dana, LinkAja', Icons.qr_code_2),
            const SizedBox(height: 30),

            // --- TOMBOL LANJUTKAN PEMBAYARAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Aksi lanjutkan pembayaran
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B), // Warna disesuaikan seperti tombol Konfirmasi Penarikan
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Lanjutkan Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(14),
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
            Radio<String>(
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
                color: AppColors.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryCyan, size: 22),
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