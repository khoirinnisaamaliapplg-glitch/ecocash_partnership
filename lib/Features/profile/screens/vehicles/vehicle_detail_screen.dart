import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'edit_vehicle_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleDetailScreen({super.key, required this.vehicleData});

  @override
  Widget build(BuildContext context) {
    // Memeriksa apakah ada bytes gambar dokumen yang diunggah
    Uint8List? stnkBytes;
    final String? base64Stnk = vehicleData['stnkBytes'];
    if (base64Stnk != null && base64Stnk.isNotEmpty) {
      stnkBytes = base64Decode(base64Stnk);
    }

    // Menentukan ikon utama
    IconData iconData = Icons.directions_car;
    if (vehicleData['iconCode'] != null) {
      iconData = IconData(vehicleData['iconCode'], fontFamily: 'MaterialIcons');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Detail Kendaraan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            // --- 1. KARTU INFORMASI UTAMA ---
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 36, color: AppColors.primaryCyan),
                  ),
                  const SizedBox(height: 12),
                  Text(vehicleData['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(vehicleData['plat'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Terverifikasi', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. INFORMASI KENDARAAN ---
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
                  const Text('Informasi Kendaraan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Type', vehicleData['type'] ?? '-'),
                  const Divider(height: 24),
                  _buildDetailRow('Kapasitas Maksimal', vehicleData['capacity'] ?? '-'),
                  const Divider(height: 24),
                  _buildDetailRow('Tanggal Verifikasi', '12 Agustus 2026'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Text('Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. DOKUMEN KENDARAAN (PRATINJAU FOTO STNK) ---
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
                  const Text('Dokumen Kendaraan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Foto STNK/Dokumen Pendukung', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: stnkBytes != null
                          ? Image.memory(stnkBytes, fit: BoxFit.cover)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.description_outlined, size: 36, color: AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  Text(vehicleData['stnk'] ?? 'STNK_Dokumen.jpg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 4. TOMBOL AKSI (EDIT & HAPUS) ---
            // --- 4. TOMBOL AKSI (EDIT & HAPUS) ---
SizedBox(
  width: double.infinity, // <--- Tambahkan SizedBox ini agar tombol penuh ke samping
  child: OutlinedButton(
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditVehicleScreen(vehicleData: vehicleData),
        ),
      );
      if (result == true || result != null) {
        Navigator.pop(context, result);
      }
    },
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF28859B)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
    ),
    child: const Text('Edit Data Kendaraan', style: TextStyle(color: Color(0xFF28859B), fontWeight: FontWeight.bold)),
  ),
),
const SizedBox(height: 12),
// ... Lanjut ke tombol Hapus Kendaraan ...
            // --- 4. TOMBOL AKSI (EDIT & HAPUS) ---
// ... (Kode tombol Edit Data Kendaraan tetap sama)

const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    onPressed: () {
      // Tampilkan dialog konfirmasi sebelum menghapus
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Apakah Anda yakin ingin menghapus kendaraan ini dari daftar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext), // Tutup dialog
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Tutup dialog
                  Navigator.pop(context, 'delete'); // Kembali ke list dan kirim sinyal 'delete'
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: Colors.red.shade300),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
    ),
    child: const Text('Hapus Kendaraan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
  ),
),
const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}