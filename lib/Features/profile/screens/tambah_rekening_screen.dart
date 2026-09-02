import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class TambahRekeningScreen extends StatefulWidget {
  const TambahRekeningScreen({super.key});

  @override
  State<TambahRekeningScreen> createState() => _TambahRekeningScreenState();
}

class _TambahRekeningScreenState extends State<TambahRekeningScreen> {
  final TextEditingController _noRekController = TextEditingController();
  final TextEditingController _namaController = TextEditingController(text: 'BUDI SANTOSO');
  String? _selectedBank;

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
          'Tambah Rekening',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INFO PERINGATAN ---
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: AppColors.primaryCyan, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pastikan nama pemilik rekening sesuai dengan profil Anda untuk kelancaran proses penarikan dana.',
                      style: TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- FORM INPUT ---
            const Text('Nama Bank', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
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
                  hint: const Text('Pilih Bank', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  items: <String>['Bank BCA', 'Bank Mandiri', 'Bank BNI', 'Bank BRI'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBank = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Nomor Rekening', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noRekController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 1234567890',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Nama Pemilik Rekening', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _namaController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedBank == null || _noRekController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Silakan pilih bank dan isi nomor rekening!')),
                    );
                    return;
                  }

                  final String rawNum = _noRekController.text.trim();
                  // Format sensor 4 digit terakhir (misal: * * * *     8901)
                  final String last4 = rawNum.length >= 4 ? rawNum.substring(rawNum.length - 4) : rawNum;
                  final String maskedNumber = '* * * *     $last4';

                  final Map<String, dynamic> newBank = {
                    'bankName': _selectedBank!,
                    'accountNumber': maskedNumber,
                    'rawNumber': rawNum,
                    'accountName': _namaController.text,
                    'isPrimary': false,
                    'cabang': 'KCP Utama',
                    'tipe': 'Tabungan',
                  };

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rekening berhasil ditambahkan!')),
                  );

                  // Kembalikan data newBank ke halaman AkunBankScreen
                  context.pop(newBank);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Rekening',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}