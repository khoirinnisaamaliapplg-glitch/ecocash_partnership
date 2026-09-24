import 'dart:io';
import 'dart:convert'; // Tambahkan import ini untuk base64Encode
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  String _selectedJenis = 'Motor';
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _platController = TextEditingController();
  final TextEditingController _kapasitasController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void dispose() {
    _modelController.dispose();
    _platController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih berkas dari perangkat
  Future<void> _pilihBerkasSTNK() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _fileName = image.name;
          _fileBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokumen STNK berhasil dipilih!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih berkas: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Tambah Kendaraan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              'Tambahkan kendaraan yang akan digunakan untuk operasional pengangkutan material daur ulang.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // --- 1. PILIH JENIS KENDARAAN ---
            const Text('Jenis Kendaraan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildJenisOption('Motor', Icons.two_wheeler)),
                const SizedBox(width: 10),
                Expanded(child: _buildJenisOption('Mobil', Icons.local_shipping)),
                const SizedBox(width: 10),
                Expanded(child: _buildJenisOption('Gerobak', Icons.shopping_cart)),
              ],
            ),
            const SizedBox(height: 20),

            // --- 2. FORM KARTU INPUT DETAIL KENDARAAN ---
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
                  const Text('Nama/Model Kendaraan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Honda Beat / Suzuki Carry',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nomor Plat / ID', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _platController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: B 1234 XYZ',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kapasitas Maksimum (kg)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _kapasitasController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 150',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      suffixText: 'kg',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. UPLOAD DOKUMEN KENDARAAN (STNK) ---
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
                  const Text('Dokumen Kendaraan (STNK)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Unggah foto STNK atau dokumen pendukung untuk verifikasi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _fileName != null ? Icons.description : Icons.cloud_upload_outlined,
                          size: 40,
                          color: const Color(0xFF28859B),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fileName ?? 'Belum ada dokumen dipilih',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        const Text('Format: JPG, PNG, atau PDF (Maks. 5MB)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pilihBerkasSTNK, // Memanggil fungsi picker
                          icon: const Icon(Icons.folder_open, size: 14, color: Color(0xFF28859B)),
                          label: Text(_fileName != null ? 'Ganti Berkas' : 'Pilih Berkas', style: const TextStyle(fontSize: 12, color: Color(0xFF28859B), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF28859B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 4. TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_modelController.text.isEmpty || _platController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mohon lengkapi data kendaraan!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  IconData selectedIcon = Icons.two_wheeler;
                  if (_selectedJenis == 'Mobil') {
                    selectedIcon = Icons.local_shipping;
                  } else if (_selectedJenis == 'Gerobak') {
                    selectedIcon = Icons.shopping_cart;
                  }

                  final newVehicleData = {
                    'title': _modelController.text,
                    'subtitle': '$_selectedJenis • ${_platController.text}',
                    'type': _selectedJenis == 'Motor' ? 'Sepeda Motor' : (_selectedJenis == 'Mobil' ? 'Mobil Pick-up' : 'Gerobak'),
                    'plat': _platController.text,
                    'capacity': '${_kapasitasController.text.isEmpty ? '100' : _kapasitasController.text} kg',
                    'tahun': '2026',
                    'iconCode': selectedIcon.codePoint,
                    'stnk': _fileName ?? 'STNK_${_modelController.text.replaceAll(' ', '_')}.jpg',
                    // BARIS INI YANG DITAMBAHKAN AGAR GAMBAR TERSIMPAN:
                    'stnkBytes': _fileBytes != null ? base64Encode(_fileBytes!) : null,
                  };

                  Navigator.pop(context, newVehicleData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Simpan Kendaraan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildJenisOption(String jenis, IconData icon) {
    bool isSelected = _selectedJenis == jenis;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedJenis = jenis;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF28859B) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF28859B) : AppColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(
              jenis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF28859B) : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}