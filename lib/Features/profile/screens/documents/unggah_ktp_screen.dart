import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class UnggahKtpScreen extends StatefulWidget {
  const UnggahKtpScreen({super.key});

  @override
  State<UnggahKtpScreen> createState() => _UnggahKtpScreenState();
}

class _UnggahKtpScreenState extends State<UnggahKtpScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedXFile;
  File? _selectedImage;
  bool _isUploading = false;
  static const Color _navyColor = Color(0xFF0F2C59);

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

  Future<void> _submitUploadKtp() async {
    if (_pickedXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih foto KTP terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    // 1. Upload berkas fisik ke /upload/single
    final uploadResult = await _apiService.uploadSingleFile(
      _pickedXFile!.path,
      xFile: _pickedXFile,
      category: 'document',
    );

    if (uploadResult['success'] == true && uploadResult['url'] != null) {
      final String uploadedUrl = uploadResult['url'];

      // 2. Simpan ke tabel Prisma PartnerDocument (POST /partners/me/documents)
      final docResult = await _apiService.uploadPartnerDocument(
        documentType: 'KTP',
        fileUrl: uploadedUrl,
      );

      // 3. Simpan URL KTP ke profil backend (PATCH /users/me)
      await _apiService.updateProfile(
        ktpImageUrl: uploadedUrl,
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (docResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto KTP berhasil diunggah dan disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, uploadedUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docResult['message'] ?? 'Gagal menyimpan dokumen KTP ke database.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uploadResult['message'] ?? 'Gagal mengunggah KTP.'),
          backgroundColor: Colors.red,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isUploading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        title: const Text(
          'Unggah Dokumen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KTP (Kartu Tanda Penduduk)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navyColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pastikan foto KTP terlihat jelas untuk mempercepat proses verifikasi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: _isUploading ? null : _showPickerBottomSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 200,
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ganti Foto',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ambil atau Pilih Foto KTP',
                            style: TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 13),
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
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.primaryCyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Panduan Foto',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _navyColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem('Foto harus jelas dan tidak buram.'),
                  _buildCheckItem('Semua sudut KTP harus terlihat.'),
                  _buildCheckItem('Tidak ada pantulan cahaya atau bayangan.'),
                  _buildCheckItem('KTP harus asli dan masih berlaku.'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitUploadKtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Simpan & Unggah Dokumen',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}