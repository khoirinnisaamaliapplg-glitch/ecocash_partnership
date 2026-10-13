import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart'; // 1. Import API Service

class EditVehicleScreen extends StatefulWidget {
  final Map vehicleData;

  const EditVehicleScreen({super.key, required this.vehicleData});

  @override
  State createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State {
  // 2. Inisialisasi API Service & Loading State
  final PartnerApiService _apiService = PartnerApiService();
  bool _isSubmitting = false;

  late String _selectedJenis;
  late final TextEditingController _modelController;
  late final TextEditingController _platController;
  late final TextEditingController _kapasitasController;

  final ImagePicker _picker = ImagePicker();
  String? _fileName;
  Uint8List? _fileBytes;

  // Casting eksplisit untuk mencegah error type resolution pada Dart Dev Compiler
  Map get _vehicleData => (widget as EditVehicleScreen).vehicleData;

  @override
  void initState() {
    super.initState();
    final String type = _vehicleData['backendType'] ?? ''; // Gunakan backendType untuk presisi
    if (type == 'MOTORCYCLE') {
      // Cek apakah Viar (Roda 3) berdasarkan plat atau title dari data API sebelumnya
      if (_vehicleData['type'].contains('Roda 3')) {
         _selectedJenis = 'Roda 3';
      } else {
         _selectedJenis = 'Motor';
      }
    } else if (type == 'CART') {
      _selectedJenis = 'Gerobak';
    } else if (type == 'CAR') {
      _selectedJenis = 'Mobil';
    } else {
       _selectedJenis = 'Motor'; // Default
    }

    _modelController = TextEditingController(text: _vehicleData['title'] ?? '');
    _platController = TextEditingController(text: _vehicleData['plat'] ?? '');
    _kapasitasController = TextEditingController(
      text: (_vehicleData['capacity'] ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
    );

    // Logika STNK (Jika STNK berupa URL dari API, kita abaikan bytes-nya dulu untuk pratinjau lama)
    _fileName = _vehicleData['stnk'];
  }

  @override
  void dispose() {
    _modelController.dispose();
    _platController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  // Helper untuk mapping jenis ke Enum Backend
  String _mapJenisToBackend(String jenis) {
    switch (jenis) {
      case 'Motor':
      case 'Roda 3':
        return 'MOTORCYCLE';
      case 'Mobil':
        return 'CAR';
      case 'Gerobak':
        return 'CART';
      default:
        return 'MOTORCYCLE';
    }
  }

  Future _ubahFotoSTNK() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _fileName = image.name;
          _fileBytes = bytes;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto STNK berhasil diperbarui!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih berkas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                // ... (UI sama seperti sebelumnya) ...
                // --- 1. PILIH JENIS KENDARAAN ---
                const Text('Jenis Kendaraan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildJenisOption('Motor', Icons.two_wheeler)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildJenisOption('Roda 3', Icons.electric_rickshaw)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildJenisOption('Mobil', Icons.local_shipping)),
                    const SizedBox(width: 8),
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
                      Text(_selectedJenis == 'Gerobak' ? 'ID / Label Gerobak' : 'Nomor Plat', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

                // --- 3. DOKUMEN KENDARAAN (STNK) - HANYA TAMPIL JIKA BUKAN GEROBAK ---
                if (_selectedJenis != 'Gerobak') ...[
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
                                              Text('STNK Terunggah', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                  const SizedBox(height: 20),
                ],

                // --- 4. TOMBOL SIMPAN PERUBAHAN (LOGIKA DIUBAH KE API) ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _updateKendaraan, // Panggil fungsi update
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
        ),
        // Loading Overlay
        if (_isSubmitting)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  // 3. Fungsi Integrasi API untuk Update
  Future _updateKendaraan() async {
    if (_modelController.text.isEmpty || _platController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data kendaraan!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // MOCK UPLOAD FOTO (Sama seperti Add, gunakan URL lama atau mock URL baru)
    String? stnkUrl = _vehicleData['stnk']; // Gunakan URL lama secara default
    if (_selectedJenis != 'Gerobak' && _fileBytes != null && _fileName != null) {
        // Jika user memilih foto baru, dalam realita unggah dulu, di sini kita mock.
        stnkUrl = "MOCK_URL_UPDATED/$_fileName"; 
    } else if (_selectedJenis == 'Gerobak') {
        stnkUrl = null;
    }

    // Panggil API (Backend menggunakan upsert, jadi method-nya sama)
    final result = await _apiService.registerOrUpdateVehicle(
      type: _mapJenisToBackend(_selectedJenis),
      plateNumber: _platController.text,
      stnkPhotoUrl: stnkUrl,
      // vehiclePhotoUrl: _vehicleData['vehiclePhotoUrl'] // Pertahankan URL foto fisik lama
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        // Kembali ke layar detail dengan sinyal sukses agar detail melakukan reload
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
            Icon(icon, color: isSelected ? const Color(0xFF28859B) : AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              jenis,
              style: TextStyle(
                fontSize: 11,
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