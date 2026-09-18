import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const EditVehicleScreen({super.key, required this.vehicleData});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  late String _selectedJenis;
  late final TextEditingController _modelController;
  late final TextEditingController _platController;
  late final TextEditingController _kapasitasController;

  final ImagePicker _picker = ImagePicker();
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void initState() {
    super.initState();
    _selectedJenis = widget.vehicleData['type']?.contains('Motor') == true 
        ? 'Motor' 
        : (widget.vehicleData['type']?.contains('Gerobak') == true ? 'Gerobak' : 'Mobil');
    
    _modelController = TextEditingController(text: widget.vehicleData['title'] ?? '');
    _platController = TextEditingController(text: widget.vehicleData['plat'] ?? '');
    _kapasitasController = TextEditingController(
      text: (widget.vehicleData['capacity'] ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
    );

    // Ambil data stnk bytes jika ada sebelumnya
    final String? base64Stnk = widget.vehicleData['stnkBytes'];
    if (base64Stnk != null && base64Stnk.isNotEmpty) {
      _fileBytes = base64Decode(base64Stnk);
    }
    _fileName = widget.vehicleData['stnk'];
  }

  @override
  void dispose() {
    _modelController.dispose();
    _platController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengubah foto STNK
  Future<void> _ubahFotoSTNK() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _fileName = image.name;
          _fileBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto STNK berhasil diperbarui!'), backgroundColor: Colors.green),
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
        title: const Text('Edit Kendaraan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

            // --- 2. FORM INPUT DETAIL KENDARAAN ---
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
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nomor Plat', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _platController,
                    decoration: InputDecoration(
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

            // --- 3. DOKUMEN KENDARAAN (STNK) DENGAN PRATINJAU & TOMBOL UBAH ---
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: SizedBox(
                            height: 130,
                            width: double.infinity,
                            child: _fileBytes != null
                                ? Image.memory(_fileBytes!, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.description_outlined, size: 36, color: AppColors.textSecondary),
                                        SizedBox(height: 4),
                                        Text('Belum ada foto STNK', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Text(
                                _fileName ?? 'STNK_Dokumen.jpg',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              const Text('Terakhir diupdate: Hari ini', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _ubahFotoSTNK,
                                icon: const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF28859B)),
                                label: const Text('Ubah Foto STNK', style: TextStyle(fontSize: 12, color: Color(0xFF28859B), fontWeight: FontWeight.bold)),
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
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 4. TOMBOL SIMPAN PERUBAHAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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

                  // Memetakan data yang telah diperbarui
                  final updatedVehicleData = {
                    'title': _modelController.text,
                    'subtitle': '$_selectedJenis • ${_platController.text}',
                    'type': _selectedJenis == 'Motor' ? 'Sepeda Motor' : (_selectedJenis == 'Mobil' ? 'Mobil Pick-up' : 'Gerobak'),
                    'plat': _platController.text,
                    'capacity': '${_kapasitasController.text.isEmpty ? '100' : _kapasitasController.text} kg',
                    'tahun': widget.vehicleData['tahun'] ?? '2026',
                    'iconCode': selectedIcon.codePoint,
                    'stnk': _fileName ?? 'STNK_Dokumen.jpg',
                    'stnkBytes': _fileBytes != null ? base64Encode(_fileBytes!) : widget.vehicleData['stnkBytes'],
                  };

                  // Mengirim data yang diperbarui kembali ke halaman list & detail
                  Navigator.pop(context, updatedVehicleData);
                },
                icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                label: const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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