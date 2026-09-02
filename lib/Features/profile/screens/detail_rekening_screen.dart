import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DetailRekeningScreen extends StatelessWidget {
  final Map<String, String>? bankData; // Menerima data kiriman

  const DetailRekeningScreen({super.key, this.bankData});

  @override
  Widget build(BuildContext context) {
    // Data default jika dibuka bukan dari form tambah rekening
    final data = bankData ?? {
      'bankName': 'Bank BCA',
      'accountNumber': '1234567890',
      'accountName': 'BUDI SANTOSO',
      'cabang': 'KCP Braga',
      'tipe': 'Tabungan',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Rekening',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- KARTU UTAMA DETAIL REKENING ---
            Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance, color: AppColors.primaryCyan, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, size: 12, color: AppColors.primaryCyan),
                            SizedBox(width: 4),
                            Text('Terverifikasi', style: TextStyle(fontSize: 11, color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nomor Rekening Dinamis
                  const Text('Nomor Rekening', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['accountNumber']!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: AppColors.primaryCyan),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nomor rekening disalin!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),

                  // Nama Pemilik Dinamis
                  const Text('Nama Pemilik', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    data['accountName']!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),

                  // Informasi Rekening Dinamis
                  const Text('Informasi Rekening', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Bank', data['bankName']!),
                  const SizedBox(height: 8),
                  _buildInfoRow('Cabang', data['cabang']!),
                  const SizedBox(height: 8),
                  _buildInfoRow('Tipe Akun', data['tipe']!),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TOMBOL HAPUS REKENING ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Rekening'),
                      content: const Text('Apakah Anda yakin ingin menghapus rekening ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.pop();
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Rekening berhasil dihapus')),
                            );
                          },
                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Hapus Rekening',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Menghapus rekening ini dapat mempengaruhi proses penarikan dana Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}