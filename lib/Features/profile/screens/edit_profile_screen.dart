
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/app_storage.dart';
import '../../../services/api_service.dart';
import 'documents/dokumen_identitas_screen.dart';
import '../../../core/widgets/app_loading.dart';

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
  String? _avatarUrl;

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;

  bool _isLoading = true;
  bool _isSaving = false;
  String _ktpStatus = 'NOT_UPLOADED';

  static const Color _navy = Color(0xFF142B45);
  static const Color _green = Color.fromARGB(255, 255, 213, 0);
  static const Color _darkGreen = Color(0xFFF8F8F6);
  static const Color _yellow = Color(0xFFFFC857);
  static const Color _background = Color(0xFFF8F8F6);
  static const Color _muted = Color(0xFF87938B);
  static const Color _border = Color(0xFFECECE8);

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();

    _loadProfileData();
  }

  // =========================================================
  // FORMAT URL FOTO PROFIL
  // =========================================================

  String? _formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final Uri baseUri = Uri.parse(ApiConstants.baseUrl);
      final Uri imgUri = Uri.parse(url);

      return imgUri
          .replace(host: baseUri.host, port: baseUri.port)
          .toString();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final String cleanBase =
        ApiConstants.baseUrl.replaceAll('/api/v1', '');

    return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
  }

  // =========================================================
  // AMBIL DATA PROFIL
  // =========================================================

  Future<void> _loadProfileData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final results = await Future.wait([
      _apiService.getPartnerProfile(),
      _apiService.getMyDocuments(),
    ]);

    Map<String, dynamic> profile = {};

    if (results[0]['success'] == true &&
        results[0]['data'] != null) {
      profile = Map<String, dynamic>.from(results[0]['data']);
    } else {
      final localData = await AppStorage.getProfile();

      if (localData != null) {
        profile = Map<String, dynamic>.from(localData);
      }
    }

    String ktpStat = 'NOT_UPLOADED';

    if (results[1]['success'] == true &&
        results[1]['data'] is List) {
      final docs = results[1]['data'] as List;

      final ktpDoc = docs.firstWhere(
        (doc) =>
            (doc['documentType'] ?? '').toString().toUpperCase() ==
            'KTP',
        orElse: () => null,
      );

      if (ktpDoc != null &&
          ktpDoc['fileUrl'] != null &&
          (ktpDoc['fileUrl'] as String).isNotEmpty) {
        ktpStat =
            (ktpDoc['status'] ?? 'PENDING').toString().toUpperCase();
      }
    }

    if (!mounted) return;

    final String? rawAvatar = profile['avatarUrl'] ??
        profile['avatar'] ??
        profile['user']?['avatarUrl'];

    setState(() {
      nameController.text =
          profile['name'] ?? profile['fullName'] ?? '';

      phoneController.text =
          profile['phone'] ?? profile['phoneNumber'] ?? '';

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

  // =========================================================
  // PILIH FOTO PROFIL
  // =========================================================

  Future<void> _pilihSumberFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Pilih sumber foto yang ingin digunakan',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoOption(
                        icon: Icons.camera_alt_rounded,
                        title: 'Kamera',
                        onTap: () async {
                          Navigator.pop(sheetContext);

                          final XFile? image =
                              await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );

                          if (image != null) {
                            final bytes = await image.readAsBytes();

                            if (!mounted) return;

                            setState(() {
                              _selectedXFile = image;
                              _imageBytes = bytes;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPhotoOption(
                        icon: Icons.photo_library_rounded,
                        title: 'Galeri',
                        onTap: () async {
                          Navigator.pop(sheetContext);

                          final XFile? image =
                              await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );

                          if (image != null) {
                            final bytes = await image.readAsBytes();

                            if (!mounted) return;

                            setState(() {
                              _selectedXFile = image;
                              _imageBytes = bytes;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: _green,
                size: 22,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SIMPAN PERUBAHAN PROFIL
  // =========================================================

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

    final String finalAvatarUrl =
        uploadedAvatarUrl ?? _avatarUrl ?? '';

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
        'imageBytes':
            _imageBytes != null ? base64Encode(_imageBytes!) : null,
      };

      await AppStorage.saveProfile(profileBaru);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updateRes['message'] ??
                'Perubahan profil berhasil disimpan!',
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop(true);
    } else {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updateRes['message'] ?? 'Gagal memperbarui profil',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // STATUS KTP
  // =========================================================

  Map<String, dynamic> _getKtpStatus() {
    if (_ktpStatus == 'APPROVED' ||
        _ktpStatus == 'VERIFIED') {
      return {
        'label': 'Telah Terverifikasi',
        'description': 'Identitas kamu sudah berhasil diverifikasi',
        'color': const Color(0xFF27845B),
        'background': const Color(0xFFE8F5EC),
        'icon': Icons.verified_rounded,
      };
    }

    if (_ktpStatus == 'PENDING' ||
        _ktpStatus == 'WAITING') {
      return {
        'label': 'Menunggu Verifikasi',
        'description': 'Dokumen sedang diperiksa oleh admin',
        'color': const Color(0xFFCA8A04),
        'background': const Color(0xFFFFF7DF),
        'icon': Icons.hourglass_top_rounded,
      };
    }

    if (_ktpStatus == 'REJECTED') {
      return {
        'label': 'Ditolak',
        'description': 'Silakan periksa dan unggah ulang dokumen',
        'color': const Color(0xFFD85B5B),
        'background': const Color(0xFFFFEEEE),
        'icon': Icons.cancel_rounded,
      };
    }

    return {
      'label': 'Belum Diunggah',
      'description': 'Lengkapi identitas untuk verifikasi akun',
      'color': const Color(0xFFCA8A04),
      'background': const Color(0xFFFFF7DF),
      'icon': Icons.assignment_ind_rounded,
    };
  }

  // =========================================================
  // TOP BAR MINIMALIS - TANPA HEADER
  // =========================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _navy,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Profil Saya',
              style: TextStyle(
                color: _navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  color: _green,
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'Partner',
                  style: TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FOTO PROFIL
  // =========================================================

  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pilihSumberFoto,
            child: Stack(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: 104,
                            height: 104,
                          )
                        : (_avatarUrl != null &&
                                _avatarUrl!.isNotEmpty)
                            ? Image.network(
                                _avatarUrl!,
                                fit: BoxFit.cover,
                                width: 104,
                                height: 104,
                                errorBuilder: (_, __, ___) =>
                                    _buildAvatarPlaceholder(),
                              )
                            : _buildAvatarPlaceholder(),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _background,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nameController.text.trim().isEmpty
                ? 'Nama Partner'
                : nameController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ketuk foto untuk mengganti',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFEAF2EC),
      child: const Icon(
        Icons.person_rounded,
        color: _green,
        size: 55,
      ),
    );
  }

  // =========================================================
  // FIELD FORM
  // =========================================================

  Widget _buildFormField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFADB6B0),
              fontSize: 12,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? 36 : 0,
              ),
              child: Icon(
                icon,
                color: _green,
                size: 19,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: _green,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // KARTU FORM PROFIL
  // =========================================================

  Widget _buildProfileForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Informasi Pribadi',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.edit_note_rounded,
                color: _green,
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Pastikan informasi akunmu selalu diperbarui.',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 22),

          _buildFormField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_outline_rounded,
            controller: nameController,
          ),
          const SizedBox(height: 17),

          _buildFormField(
            label: 'Nomor Telepon',
            hint: 'Masukkan nomor telepon',
            icon: Icons.phone_android_rounded,
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 17),

          _buildFormField(
            label: 'Email',
            hint: 'Masukkan alamat email',
            icon: Icons.email_outlined,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 17),

          _buildFormField(
            label: 'Alamat Saat Ini',
            hint: 'Masukkan alamat lengkap',
            icon: Icons.location_on_outlined,
            controller: addressController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KARTU VERIFIKASI IDENTITAS
  // =========================================================

  Widget _buildIdentityCard() {
    final status = _getKtpStatus();

    final Color statusColor = status['color'] as Color;
    final Color statusBackground = status['background'] as Color;
    final IconData statusIcon = status['icon'] as IconData;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const DokumenIdentitasScreen(),
          ),
        );

        if (mounted) {
          _loadProfileData();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verifikasi Identitas',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dokumen KTP',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          status['label'] as String,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _muted,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TOMBOL SIMPAN
  // =========================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _simpanPerubahan,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withOpacity(0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoadingState() {
  return Scaffold(
    backgroundColor: _background,
    body: AppLoading(
      message: 'Menyiapkan profil kamu...',
      size: 76,
    ),
  );
}

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfilePhoto(),
                    const SizedBox(height: 28),

                    _buildProfileForm(),
                    const SizedBox(height: 18),

                    _buildIdentityCard(),
                    const SizedBox(height: 24),

                    _buildSaveButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
