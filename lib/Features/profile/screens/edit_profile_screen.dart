import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/app_storage.dart';
import '../../../services/api_service.dart';
import 'documents/dokumen_identitas_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedXFile;
  Uint8List? _imageBytes;
  String? _avatarUrl; // State URL foto dari API Backend

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;

  bool _isLoading = true;
  bool _isSaving = false;
  String _ktpStatus = 'NOT_UPLOADED';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    _loadProfileData();
  }

  /// Helper untuk memformat URL gambar dari backend
  String? _formatImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  // Jika backend mengembalikan URL localhost / 127.0.0.1, ganti host-nya sesuai IP ApiConstants
  if (url.contains('localhost') || url.contains('127.0.0.1')) {
    final Uri baseUri = Uri.parse(ApiConstants.baseUrl);
    final Uri imgUri = Uri.parse(url);
    return imgUri.replace(host: baseUri.host, port: baseUri.port).toString();
  }

  if (url.startsWith('http://') || url.startsWith('https://')) return url;

  final String cleanBase = ApiConstants.baseUrl.replaceAll('/api/v1', '');
  return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
}

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _apiService.getPartnerProfile(),
      _apiService.getMyDocuments(),
    ]);

    Map<String, dynamic> profile = {};
    if (results[0]['success'] == true && results[0]['data'] != null) {
      profile = Map<String, dynamic>.from(results[0]['data']);
    } else {
      final localData = await AppStorage.getProfile();
      if (localData != null) profile = Map<String, dynamic>.from(localData);
    }

    // Ambil status KTP
    String ktpStat = 'NOT_UPLOADED';
    if (results[1]['success'] == true && results[1]['data'] is List) {
      final docs = results[1]['data'] as List;
      final ktpDoc = docs.firstWhere(
        (doc) => (doc['documentType'] ?? '').toString().toUpperCase() == 'KTP',
        orElse: () => null,
      );
      if (ktpDoc != null && ktpDoc['fileUrl'] != null && (ktpDoc['fileUrl'] as String).isNotEmpty) {
        ktpStat = (ktpDoc['status'] ?? 'PENDING').toString().toUpperCase();
      }
    }

    if (!mounted) return;

    // Ambil URL avatar dari backend (dukung berbagai alias key)
    final String? rawAvatar = profile['avatarUrl'] ?? profile['avatar'] ?? profile['user']?['avatarUrl'];

    setState(() {
      nameController.text = profile['name'] ?? profile['fullName'] ?? '';
      phoneController.text = profile['phone'] ?? profile['phoneNumber'] ?? '';
      emailController.text = profile['email'] ?? '';
      addressController.text = profile['address'] ?? '';
      _ktpStatus = ktpStat;
      _avatarUrl = _formatImageUrl(rawAvatar);

      final String? base64Str = profile['imageBytes'];
      if (base64Str != null && base64Str.isNotEmpty) {
        try {
          _imageBytes = base64Decode(base64Str);
        } catch (_) {}
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryCyan),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _selectedXFile = image;
                      _imageBytes = bytes;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryCyan),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _selectedXFile = image;
                      _imageBytes = bytes;
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

  Future<void> _simpanPerubahan() async {
    setState(() => _isSaving = true);

    String? uploadedAvatarUrl;

    if (_selectedXFile != null) {
      final uploadRes = await _apiService.uploadSingleFile(
        _selectedXFile!.path,
        xFile: _selectedXFile,
        category: 'avatar',
      );

      if (uploadRes['success'] == true) {
        uploadedAvatarUrl = uploadRes['url'];
      }
    }

    final String finalAvatarUrl = uploadedAvatarUrl ?? _avatarUrl ?? '';

    final updateRes = await _apiService.updatePartnerProfile(
      name: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
      avatarUrl: finalAvatarUrl,
    );

    if (!mounted) return;

    if (updateRes['success'] == true) {
      final profileBaru = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'avatarUrl': finalAvatarUrl,
        'imageBytes': _imageBytes != null ? base64Encode(_imageBytes!) : null,
      };
      await AppStorage.saveProfile(profileBaru);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateRes['message'] ?? 'Perubahan profil berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateRes['message'] ?? 'Gagal memperbarui profil'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    if (_ktpStatus == 'APPROVED' || _ktpStatus == 'VERIFIED') {
      statusLabel = 'Telah Terverifikasi';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outlined;
    } else if (_ktpStatus == 'PENDING' || _ktpStatus == 'WAITING') {
      statusLabel = 'Menunggu Verifikasi';
      statusColor = Colors.blue;
      statusIcon = Icons.hourglass_top_outlined;
    } else if (_ktpStatus == 'REJECTED') {
      statusLabel = 'Ditolak (Unggah Ulang)';
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusLabel = 'Belum Diunggah';
      statusColor = const Color(0xFFB78103);
      statusIcon = Icons.pending_outlined;
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
            // Lingkaran Foto Avatar (Dukung memory bytes, network URL, dan placeholder)
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
                            : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    _avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 96,
                                    height: 96,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondary,
                                      size: 50,
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondary,
                                      size: 50,
                                    ),
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

            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DokumenIdentitasScreen()),
                );
                _loadProfileData();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verifikasi Identitas (KTP)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpanPerubahan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28859B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
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