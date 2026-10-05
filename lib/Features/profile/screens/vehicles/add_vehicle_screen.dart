import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart'; // 1. Import API Service

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State {
  // 2. Inisialisasi API Service & Loading State
  final PartnerApiService _apiService = PartnerApiService();
  bool _isSubmitting = false;

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

  Future _pilihBerkasSTNK() async {
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
            const SnackBar(content: Text('Dokumen STNK berhasil dipilih!'), backgroundColor: Colors.green),
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

  // 3. Helper untuk mapping jenis ke Enum Backend
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

  @override
  Widget build(BuildContext context) {
    // 4. Bungkus dengan Stack untuk menampilkan loading overlay
    return Stack(
      children: [
        Scaffold(
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
                // ... (Kode UI input field sama seperti sebelumnya, tidak ada perubahan) ...
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
                    const SizedBox(width: 8),
                    Expanded(child: _buildJenisOption('Roda 3', Icons.electric_rickshaw)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildJenisOption('Mobil', Icons.local_shipping)),
                    const SizedBox(width: 8),
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
                          hintText: _selectedJenis == 'Gerobak' 
                              ? 'Contoh: Gerobak Standar' 
                              : (_selectedJenis == 'Roda 3' ? 'Contoh: Viar Karya 200' : 'Contoh: Honda Beat / Suzuki Carry'),
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_selectedJenis == 'Gerobak' ? 'ID / Label Gerobak' : 'Nomor Plat / ID', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _platController,
                        decoration: InputDecoration(
                          hintText: _selectedJenis == 'Gerobak' ? 'Contoh: GBK-001' : 'Contoh: B 1234 XYZ',
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
                          hintText: _selectedJenis == 'Gerobak' ? 'Contoh: 300' : (_selectedJenis == 'Roda 3' ? 'Contoh: 500' : 'Contoh: 150'),
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

                // --- 3. UPLOAD DOKUMEN KENDARAAN (STNK) - HANYA TAMPIL JIKA BUKAN GEROBAK ---
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
                                onPressed: _pilihBerkasSTNK,
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
                  const SizedBox(height: 20),
                ],

                // --- 4. TOMBOL SIMPAN (LOGIKA DIUBAH KE API) ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitKendaraan, // Panggil fungsi submit
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

  // 5. Fungsi Fungsi Integrasi API
  Future _submitKendaraan() async {
    // Validasi Dasar
    if (_modelController.text.isEmpty || _platController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data kendaraan!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validasi STNK untuk non-gerobak
    if (_selectedJenis != 'Gerobak' && _fileBytes == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon unggah foto STNK!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // MOCK UPLOAD FOTO (TAHAP 3.1)
    // Karena belum ada endpoint upload, kita kirim string dummy/nama file dulu.
    // Backend mengharapkan URL, jadi ini akan menyebabkan status 'PENDING' di backend.
    String? stnkUrl;
    if (_selectedJenis != 'Gerobak' && _fileName != null) {
        // Dalam implementasi nyata, unggah _fileBytes dulu, dapatkan URL, lalu masukkan sini.
        stnkUrl = "MOCK_URL_FROM_FRONTEND/$_fileName"; 
    }

    // Panggil API
    final result = await _apiService.registerOrUpdateVehicle(
      type: _mapJenisToBackend(_selectedJenis),
      plateNumber: _platController.text,
      stnkPhotoUrl: stnkUrl,
      // vehiclePhotoUrl: null // Opsional untuk gerobak, abaikan dulu
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        // Jika sukses, kembali ke layar list dan kirim sinyal 'true' agar list reload
        Navigator.pop(context, true); 
      } else {
        // Jika gagal, tampilkan pesan error dari backend
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