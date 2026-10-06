import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();

  String _selectedJenis = 'Motor'; // Motor, Mobil, Roda Tiga, Gerobak
  final TextEditingController _brandModelController = TextEditingController();
  final TextEditingController _platController = TextEditingController();

  XFile? _pickedXFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _brandModelController.dispose();
    _platController.dispose();
    super.dispose();
  }

  Future<void> _pilihBerkas() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _pickedXFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih berkas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

Future<void> _simpanKendaraan() async {
    // 1. Mapping jenis ke enum backend
    String backendType = 'MOTORCYCLE';
    if (_selectedJenis == 'Mobil') {
      backendType = 'CAR';
    } else if (_selectedJenis == 'Roda Tiga') {
      backendType = 'MOTORCYCLE';
    } else if (_selectedJenis == 'Gerobak') {
      backendType = 'CART';
    }

    // 2. Validasi input
    if (backendType != 'CART') {
      if (_platController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor plat wajib diisi!'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_pickedXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto STNK wajib diunggah!'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      if (_pickedXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto fisik gerobak wajib diunggah!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // 3. Upload berkas
    String? uploadedUrl;
    if (_pickedXFile != null) {
      final uploadRes = await _apiService.uploadSingleFile(
        _pickedXFile!.path,
        xFile: _pickedXFile,
        category: 'document',
      );

      if (uploadRes['success'] == true && uploadRes['url'] != null) {
        uploadedUrl = uploadRes['url'];
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadRes['message'] ?? 'Gagal mengunggah foto.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // 4. Kirim ke API PUT /partners/me/vehicle (PERBAIKAN DI SINI: plateNumber murni plat saja)
    final result = await _apiService.registerOrUpdateVehicle(
      type: backendType,
      plateNumber: backendType != 'CART' ? _platController.text.trim() : null,
      stnkPhotoUrl: backendType != 'CART' ? uploadedUrl : null,
      vehiclePhotoUrl: backendType == 'CART' ? uploadedUrl : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Data kendaraan berhasil disimpan!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan kendaraan.'), backgroundColor: Colors.red),
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
              'Pilih jenis dan lengkapi spesifikasi kendaraan operasional pengangkutan Anda.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // --- 1. PILIH JENIS KENDARAAN ---
            const Text('Jenis Kendaraan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildJenisOption('Motor', Icons.two_wheeler),
                _buildJenisOption('Mobil', Icons.local_shipping),
                _buildJenisOption('Roda Tiga', Icons.electric_rickshaw),
                _buildJenisOption('Gerobak', Icons.shopping_cart),
              ],
            ),
            const SizedBox(height: 20),

            // --- 2. DETAIL KENDARAAN ---
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
                  const Text('Nama / Merk / Model Kendaraan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _brandModelController,
                    decoration: InputDecoration(
                      hintText: _selectedJenis == 'Roda Tiga' 
                          ? 'Contoh: ViAR Karya 200 / Tossa' 
                          : (_selectedJenis == 'Motor' ? 'Contoh: Honda Beat 2022' : 'Contoh: Suzuki Carry / Gerobak Kayu'),
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (_selectedJenis != 'Gerobak') ...[
                    const SizedBox(height: 16),
                    const Text('Nomor Plat Kendaraan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _platController,
                      textCapitalization: TextCapitalization.characters,
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. UPLOAD DOKUMEN / FOTO ---
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
                  Text(
                    _selectedJenis == 'Gerobak' ? 'Foto Fisik Gerobak' : 'Foto Dokumen STNK',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedJenis == 'Gerobak'
                        ? 'Unggah foto fisik gerobak yang jelas untuk verifikasi.'
                        : 'Unggah foto STNK asli kendaraan Roda Tiga/Motor/Mobil Anda.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
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
                          _pickedXFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                          size: 40,
                          color: _pickedXFile != null ? Colors.green : const Color(0xFF28859B),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pickedXFile != null ? _pickedXFile!.name : 'Belum ada foto dipilih',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pilihBerkas,
                          icon: const Icon(Icons.folder_open, size: 14, color: Color(0xFF28859B)),
                          label: Text(
                            _pickedXFile != null ? 'Ganti Foto' : 'Pilih Foto',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF28859B), fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF28859B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.white,
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
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanKendaraan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Simpan Kendaraan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
          _pickedXFile = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF28859B) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF28859B) : AppColors.textSecondary, size: 20),
            const SizedBox(width: 6),
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