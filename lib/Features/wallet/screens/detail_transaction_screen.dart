import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DetailTransactionScreen extends StatelessWidget {
  final bool isWithdrawal; // Parameter untuk membedakan jenis transaksi (masuk / penarikan)

  const DetailTransactionScreen({super.key, this.isWithdrawal = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Detail Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.green, size: 30),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryCyan)),
              ),
              const SizedBox(height: 12),
              Text(
                isWithdrawal ? '-Rp100.000' : '+Rp82.000',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isWithdrawal ? Colors.red : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text('10 Agustus 2026 • 10:24', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              
              if (isWithdrawal) ...[
                _buildDetailRow('Jenis', 'Penarikan Saldo'),
                const SizedBox(height: 10),
                _buildDetailRow('Bank Tujuan', 'Bank BCA - **** 1234'),
                const SizedBox(height: 10),
                _buildDetailRow('Jumlah Penarikan', 'Rp100.000'),
                const SizedBox(height: 10),
                _buildDetailRow('Biaya Admin', 'Rp2.500'),
                const SizedBox(height: 10),
                _buildDetailRow('Metode', 'Transfer Bank'),
                const SizedBox(height: 10),
                _buildDetailRow('ID Transaksi', 'TRX-20260810-901928'),
              ] else ...[
                _buildDetailRow('Jenis', 'Pembayaran Pekerjaan'),
                const SizedBox(height: 10),
                _buildDetailRow('Pekerjaan', 'EcoCash Valen #BGD-021'),
                const SizedBox(height: 10),
                _buildDetailRow('Material', 'PET (Botol)'),
                const SizedBox(height: 10),
                _buildDetailRow('Berat', '44,60 kg'),
                const SizedBox(height: 10),
                _buildDetailRow('Metode', 'EcoCash Wallet'),
                const SizedBox(height: 10),
                _buildDetailRow('ID Transaksi', 'ECX-20260810-001928'),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, color: Colors.white, size: 16),
                  label: const Text('Unduh Bukti', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28859B), // Memaksa warna toska gelap secara langsung
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}