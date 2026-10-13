import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class UnggahStnkScreen extends StatefulWidget {
  const UnggahStnkScreen({super.key});

  @override
  State<UnggahStnkScreen> createState() => _UnggahStnkScreenState();
}

class _UnggahStnkScreenState extends State<UnggahStnkScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _plateController = TextEditingController();

  XFile? _pickedXFile;
  File? _selectedImage;
  // Enum Tipe Kendaraan Sesuai Backend: MOTORCYCLE, CAR, CART
  String _selectedVehicleType = 'MOTORCYCLE';
  bool _isLoading = false;

  static const Color _navyColor = Color(0xFF0F2C59);

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedXFile = pickedFile;
          if (!kIsWeb) {
            _selectedImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _showPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _navyColor),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _navyColor),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitVehicleAndStnk() async {
    final bool isCart = _selectedVehicleType == 'CART';
    final String plateNumber = _plateController.text.trim();

    if (_pickedXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCart
              ? 'Silakan pilih foto fisik gerobak terlebih dahulu!'
              : 'Silakan pilih foto STNK terlebih dahulu!'),
        ),
      );
      return;
    }

    if (!isCart && plateNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nomor plat kendaraan!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Upload berkas fisik ke server
    final uploadResult = await _apiService.uploadSingleFile(
      _pickedXFile!.path,
      xFile: _pickedXFile,
      category: 'document',
    );

    if (uploadResult['success'] != true) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uploadResult['message'] ?? 'Gagal mengunggah foto.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String? uploadedUrl = uploadResult['url'];

    // 2. Simpan data kendaraan ke PUT /partners/me/vehicle (Tabel PartnerVehicle)
    final vehicleResult = await _apiService.updateVehicle(
      type: _selectedVehicleType,
      plateNumber: plateNumber,
      imageUrl: uploadedUrl,
    );

    // 3. Simpan juga ke POST /partners/me/documents (Tabel PartnerDocument)
    if (uploadedUrl != null) {
      await _apiService.uploadPartnerDocument(
        documentType: 'STNK',
        fileUrl: uploadedUrl,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (vehicleResult['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data STNK dan kendaraan berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vehicleResult['message'] ?? 'Gagal memperbarui data kendaraan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCart = _selectedVehicleType == 'CART';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        title: Text(
          isCart ? 'Unggah Foto Gerobak' : 'Unggah STNK',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _isLoading ? null : _showPickerBottomSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC5CEE0), width: 1.2),
                ),
                child: _pickedXFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            kIsWeb
                                ? Image.network(_pickedXFile!.path, fit: BoxFit.cover)
                                : Image.file(_selectedImage!, fit: BoxFit.cover),
                            Container(
                              color: Colors.black26,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCart ? 'Ganti Foto Fisik Gerobak' : 'Ganti Foto STNK',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: _navyColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isCart ? 'Ambil Foto Fisik Gerobak' : 'Ambil atau Pilih Foto STNK',
                            style: const TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

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
                  const Text(
                    'Detail Kendaraan Operasional',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _navyColor),
                  ),
                  const SizedBox(height: 14),

                  const Text('Jenis Kendaraan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MOTORCYCLE', child: Text('Sepeda Motor')),
                      DropdownMenuItem(value: 'CAR', child: Text('Mobil / Pick-up')),
                      DropdownMenuItem(value: 'CART', child: Text('Gerobak Motor / Tiga Roda')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedVehicleType = val);
                            }
                          },
                  ),
                  const SizedBox(height: 14),

                  if (!isCart) ...[
                    const Text('Nomor Plat Kendaraan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _plateController,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Contoh: D 1234 ABC',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitVehicleAndStnk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isCart ? 'Simpan & Unggah Gerobak' : 'Simpan & Unggah STNK',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}