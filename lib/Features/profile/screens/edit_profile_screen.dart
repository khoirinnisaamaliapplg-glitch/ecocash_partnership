import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../data/app_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    _loadStoredProfile();
  }

  Future<void> _loadStoredProfile() async {
    final profile = await AppStorage.getProfile();
    setState(() {
      nameController.text = profile['name'] ?? 'Budi Santoso';
      phoneController.text = profile['phone'] ?? '+62 812-3456-7890';
      emailController.text = profile['email'] ?? 'budi.s@email.com';
      addressController.text = profile['address'] ?? 'Jl. Merdeka Raya No. 45, Kebayoran Baru,\nJakarta Selatan, 12110';
      
      final String? base64Str = profile['imageBytes'];
      if (base64Str != null && base64Str.isNotEmpty) {
        _imageBytes = base64Decode(base64Str);
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pilihSumberFoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryCyan),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _imageBytes = bytes;
                      if (!kIsWeb) {
                        _imageFile = File(image.path);
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryCyan),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _imageBytes = bytes;
                      if (!kIsWeb) {
                        _imageFile = File(image.path);
                      }
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

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
          'Edit Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. FOTO PROFIL & TOMBOL KAMERA ---
            Center(
              child: GestureDetector(
                onTap: _pilihSumberFoto,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppColors.primaryCyan, width: 2),
                      ),
                      child: ClipOval(
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover, width: 96, height: 96)
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person, color: AppColors.textSecondary, size: 50),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap untuk ubah foto',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. FORM INPUT DATA ---
            const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Nomor Telepon', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.phone_android, size: 20, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Email', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Alamat Saat Ini', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. KARTU VERIFIKASI IDENTITAS (KTP) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: AppColors.primaryCyan, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Verifikasi Identitas (KTP)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Telah Terverifikasi',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 4. TOMBOL SIMPAN PERUBAHAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final profileBaru = {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'address': addressController.text,
                    'imageBytes': _imageBytes != null ? base64Encode(_imageBytes!) : null,
                  };

                  await AppStorage.saveProfile(profileBaru);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perubahan profil berhasil disimpan!'), backgroundColor: Colors.green),
                  );
                  context.pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B), // Warna disamakan dengan tombol konfirmasi penarikan & unduh bukti
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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