import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class SuccessWithdrawScreen extends StatelessWidget {
  final Map<String, dynamic>? withdrawalData;

  static const Color _primaryYellow = Color(0xFFFFE600);
  static const Color _primaryDark = Color(0xFF1C1C1E);
  static const Color _navyColor = Color(0xFF0F2C59);

  const SuccessWithdrawScreen({super.key, this.withdrawalData});

  String _formatRupiah(dynamic rawAmount) {
    if (rawAmount == null) return 'Rp 0';
    double amount = double.tryParse(rawAmount.toString()) ?? 0;
    String formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final data = withdrawalData ?? {};
    final String amountText = _formatRupiah(data['amount'] ?? 0);
    final String trxId = data['id'] != null ? 'TRX-${data['id']}' : 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    
    final bankObj = data['bankAccount'] as Map<String, dynamic>?;
    final String bankName = bankObj?['bankName'] ?? 'Bank';
    final String accNum = bankObj?['accountNumber'] ?? '-';
    final String bankInfo = '$bankName - $accNum';

    final String timeText = data['createdAt'] != null 
        ? data['createdAt'].toString().replaceFirst('T', ' ').substring(0, 16)
        : 'Hari ini';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _primaryYellow,
        elevation: 0,
        title: const Text('Status Transaksi', style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navyColor),
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
                    color: _navyColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: _navyColor, size: 40),
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
                
                // Nominal Dinamis
                Text(
                  amountText,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),

                // --- KARTU DETAIL TRANSAKSI ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Waktu Transaksi', timeText),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),
                      _buildDetailRow('Bank Tujuan', bankInfo),
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
                              Text(trxId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: trxId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ID Transaksi disalin!'), duration: Duration(seconds: 1)),
                                  );
                                },
                                child: const Icon(Icons.copy, size: 14, color: _navyColor),
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
                    icon: const Icon(Icons.share, color: _primaryYellow, size: 16),
                    label: const Text('Bagikan Resi', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryYellow)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryDark,
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
                      side: const BorderSide(color: _primaryDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryDark)),
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