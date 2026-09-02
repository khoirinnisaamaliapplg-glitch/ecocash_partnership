import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AkunBankScreen extends StatefulWidget {
  const AkunBankScreen({super.key});

  @override
  State<AkunBankScreen> createState() => _AkunBankScreenState();
}

class _AkunBankScreenState extends State<AkunBankScreen> {
  // Daftar data rekening bank yang dinamis
  final List<Map<String, dynamic>> _bankList = [
    {
      'bankName': 'Bank BCA',
      'accountNumber': '* * * *     4567',
      'rawNumber': '1234567890',
      'accountName': 'Budi Santoso',
      'isPrimary': true,
      'cabang': 'KCP Braga',
      'tipe': 'Tabungan',
    },
    {
      'bankName': 'Bank Mandiri',
      'accountNumber': '* * * *     8901',
      'rawNumber': '8765432109',
      'accountName': 'Budi Santoso',
      'isPrimary': false,
      'cabang': 'KCP Utama',
      'tipe': 'Tabungan',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          'Akun Bank',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DESKRIPSI INFO ---
            const Text(
              'Kelola rekening bank Anda untuk menerima pembayaran hasil penjualan material. Pastikan nama pemilik rekening sesuai dengan nama profil Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // --- REKENING TERSIMPAN ---
            const Text(
              'Rekening Tersimpan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Render seluruh kartu rekening secara dinamis
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bankList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _bankList[index];
                return _buildBankCard(
                  item: item,
                  index: index,
                );
              },
            ),
            const SizedBox(height: 24),

            // --- TOMBOL TAMBAH REKENING BARU ---
            GestureDetector(
              onTap: () async {
                // Menunggu data kembalian dari TambahRekeningScreen
                final newBankData = await context.push<Map<String, dynamic>>('/tambah-rekening');
                if (newBankData != null) {
                  setState(() {
                    _bankList.add(newBankData);
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryCyan,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle_outline, color: AppColors.primaryCyan, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tambah Rekening Baru',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Kartu Rekening Bank Interaktif
  Widget _buildBankCard({
    required Map<String, dynamic> item,
    required int index,
  }) {
    final bool isPrimary = item['isPrimary'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          if (isPrimary)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Utama',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Icon(Icons.account_balance, color: AppColors.textSecondary, size: 22),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['bankName']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(item['accountName']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['accountNumber']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary, letterSpacing: 1.2),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.cyan.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline, size: 12, color: AppColors.primaryCyan),
                              SizedBox(width: 4),
                              Text('Terverifikasi', style: TextStyle(fontSize: 10, color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // PopUp Menu Titik Tiga
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'detail') {
                      context.push('/detail-rekening', extra: {
                        'bankName': item['bankName'],
                        'accountNumber': item['rawNumber'] ?? item['accountNumber'],
                        'accountName': item['accountName'],
                        'cabang': item['cabang'] ?? 'KCP Utama',
                        'tipe': item['tipe'] ?? 'Tabungan',
                      });
                    } else if (value == 'hapus') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Rekening'),
                          content: Text('Apakah Anda yakin ingin menghapus ${item['bankName']}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _bankList.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${item['bankName']} berhasil dihapus')),
                                );
                              },
                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 10),
                          Text('Detail Rekening', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'hapus',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Hapus Rekening', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}