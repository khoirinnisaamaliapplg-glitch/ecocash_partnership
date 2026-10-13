import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const EditVehicleScreen({super.key, required this.vehicleData});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();

  late String _selectedJenis;
  late final TextEditingController _platController;

  XFile? _pickedXFile;
  String? _existingPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final String type = (widget.vehicleData['type'] ?? 'MOTORCYCLE').toString();
    if (type == 'CAR') {
      _selectedJenis = 'Mobil';
    } else if (type == 'CART') {
      _selectedJenis = 'Gerobak';
    } else {
      _selectedJenis = 'Motor';
    }

    _platController = TextEditingController(text: widget.vehicleData['plateNumber'] ?? '');
    _existingPhotoUrl = type == 'CART'
        ? widget.vehicleData['vehiclePhotoUrl']
        : widget.vehicleData['stnkPhotoUrl'];
  }

  @override
  void dispose() {
    _platController.dispose();
    super.dispose();
  }

  Future<void> _pilihFotoBaru() async {
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
          SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _simpanPerubahan() async {
    String backendType = 'MOTORCYCLE';
    if (_selectedJenis == 'Mobil') {
      backendType = 'CAR';
    } else if (_selectedJenis == 'Gerobak') {
      backendType = 'CART';
    }

    if (backendType != 'CART' && _platController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor plat wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Upload berkas baru jika pengguna memilih foto baru
    String? finalPhotoUrl = _existingPhotoUrl;
    if (_pickedXFile != null) {
      final uploadRes = await _apiService.uploadSingleFile(
        _pickedXFile!.path,
        xFile: _pickedXFile,
        category: 'document',
      );

      if (uploadRes['success'] == true && uploadRes['url'] != null) {
        finalPhotoUrl = uploadRes['url'];
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadRes['message'] ?? 'Gagal mengunggah foto baru.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Kirim pembaruan ke API PUT /partners/me/vehicle
    final result = await _apiService.registerOrUpdateVehicle(
      type: backendType,
      plateNumber: backendType != 'CART' ? _platController.text.trim() : null,
      stnkPhotoUrl: backendType != 'CART' ? finalPhotoUrl : null,
      vehiclePhotoUrl: backendType == 'CART' ? finalPhotoUrl : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Perubahan kendaraan berhasil disimpan!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal memperbarui kendaraan.'), backgroundColor: Colors.red),
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

            // --- 2. FORM DETAIL KENDARAAN ---
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
                  if (_selectedJenis != 'Gerobak') ...[
                    const Text('Nomor Plat', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _platController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ] else
                    const Text(
                      'Pendaftaran gerobak tidak memerlukan nomor plat.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. DOKUMEN / FOTO FISIK ---
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
                            height: 140,
                            width: double.infinity,
                            child: _pickedXFile != null
                                ? const Center(child: Icon(Icons.check_circle, size: 40, color: Colors.green))
                                : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                    ? Image.network(_existingPhotoUrl!, fit: BoxFit.cover)
                                    : const Center(child: Icon(Icons.description_outlined, size: 36, color: AppColors.textSecondary))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _pilihFotoBaru,
                            icon: const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF28859B)),
                            label: Text(
                              _pickedXFile != null ? 'Ganti Foto' : 'Ubah Foto',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF28859B), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF28859B)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.white,
                            ),
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
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _simpanPerubahan,
                icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                label: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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