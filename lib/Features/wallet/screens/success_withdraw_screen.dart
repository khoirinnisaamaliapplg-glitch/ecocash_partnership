import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class SuccessWithdrawScreen extends StatelessWidget {
  const SuccessWithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Status Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- ICON SUKSES ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28859B).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF28859B), size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Penarikan Berhasil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dana telah ditransfer ke rekening bank Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rp 250.000',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),

                // --- KARTU DETAIL TRANSAKSI ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Waktu Transaksi', '24 Okt 2025, 14:30'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),
                      _buildDetailRow('Bank Tujuan', 'BCA - 1234567890'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ID Transaksi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Row(
                            children: [
                              const Text('TRX-987654321', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(const ClipboardData(text: 'TRX-987654321'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ID Transaksi disalin!'), duration: Duration(seconds: 1)),
                                  );
                                },
                                child: const Icon(Icons.copy, size: 14, color: Color(0xFF28859B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- TOMBOL BAGIKAN RESI ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, color: Colors.white, size: 16),
                    label: const Text('Bagikan Resi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28859B), // Warna disesuaikan
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- TOMBOL SELESAI ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                ),
              ],
            ),
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