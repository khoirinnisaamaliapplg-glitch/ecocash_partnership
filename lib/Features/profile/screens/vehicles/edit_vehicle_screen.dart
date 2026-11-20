
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const EditVehicleScreen({
    super.key,
    required this.vehicleData,
  });

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

    final String type =
        (widget.vehicleData['type'] ?? 'MOTORCYCLE').toString();

    if (type == 'CAR') {
      _selectedJenis = 'Mobil';
    } else if (type == 'CART') {
      _selectedJenis = 'Gerobak';
    } else {
      _selectedJenis = 'Motor';
    }

    _platController = TextEditingController(
      text: widget.vehicleData['plateNumber'] ?? '',
    );

    _existingPhotoUrl = type == 'CART'
        ? widget.vehicleData['vehiclePhotoUrl']
        : widget.vehicleData['stnkPhotoUrl'];
  }

  @override
  void dispose() {
    _platController.dispose();
    super.dispose();
  }

  // =========================================================
  // PILIH FOTO
  // =========================================================

  Future<void> _pilihFotoBaru() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _pickedXFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================
  // SIMPAN PERUBAHAN
  // =========================================================

  Future<void> _simpanPerubahan() async {
    String backendType = 'MOTORCYCLE';

    if (_selectedJenis == 'Mobil') {
      backendType = 'CAR';
    } else if (_selectedJenis == 'Gerobak') {
      backendType = 'CART';
    }

    if (backendType != 'CART' &&
        _platController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor plat wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? finalPhotoUrl = _existingPhotoUrl;

    if (_pickedXFile != null) {
      final uploadRes = await _apiService.uploadSingleFile(
        _pickedXFile!.path,
        xFile: _pickedXFile,
        category: 'document',
      );

      if (uploadRes['success'] == true &&
          uploadRes['url'] != null) {
        finalPhotoUrl = uploadRes['url'];
      } else {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadRes['message'] ??
                  'Gagal mengunggah foto baru.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final result = await _apiService.registerOrUpdateVehicle(
      type: backendType,
      plateNumber: backendType != 'CART'
          ? _platController.text.trim()
          : null,
      stnkPhotoUrl: backendType != 'CART'
          ? finalPhotoUrl
          : null,
      vehiclePhotoUrl: backendType == 'CART'
          ? finalPhotoUrl
          : null,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Perubahan kendaraan berhasil disimpan!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Gagal memperbarui kendaraan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      number: '01',
                      title: 'Jenis Kendaraan',
                      subtitle: 'Pilih kendaraan yang ingin diperbarui',
                    ),
                    const SizedBox(height: 13),
                    _buildVehicleTypeSelector(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      number: '02',
                      title: 'Informasi Kendaraan',
                      subtitle: 'Periksa kembali informasi kendaraanmu',
                    ),
                    const SizedBox(height: 13),
                    _buildVehicleForm(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      number: '03',
                      title: 'Dokumen Kendaraan',
                      subtitle: 'Pastikan foto yang digunakan terlihat jelas',
                    ),
                    const SizedBox(height: 13),
                    _buildDocumentCard(),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
                    _buildBottomNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: 43,
                height: 43,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.darkNavy,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Kendaraan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Perbarui data kendaraan partner',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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
  // INTRO
  // =========================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4EC),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.ecoGreen,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Kendaraanmu',
                  style: TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pastikan informasi dan dokumen kendaraan selalu sesuai.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
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
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 29,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ecoGreen.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.ecoGreen,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PILIHAN JENIS KENDARAAN
  // =========================================================

  Widget _buildVehicleTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildJenisOption(
            'Motor',
            Icons.two_wheeler_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildJenisOption(
            'Mobil',
            Icons.directions_car_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildJenisOption(
            'Gerobak',
            Icons.shopping_cart_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildJenisOption(String jenis, IconData icon) {
    final bool isSelected = _selectedJenis == jenis;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              setState(() {
                _selectedJenis = jenis;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F4EC)
              : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected
                ? AppColors.ecoGreen
                : const Color(0xFFE8ECE9),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected
                      ? AppColors.ecoGreen
                      : AppColors.textSecondary,
                ),
                if (isSelected)
                  Positioned(
                    right: -9,
                    top: -7,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.ecoGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              jenis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? AppColors.ecoGreen
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FORM INFORMASI KENDARAAN
  // =========================================================

  Widget _buildVehicleForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFEDF0EE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedJenis != 'Gerobak') ...[
            const Text(
              'Nomor Plat Kendaraan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: _platController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: Z 1234 ABC',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB6B0),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.ecoGreen,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFFE8ECE9),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: AppColors.ecoGreen,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Masukkan nomor plat sesuai dokumen kendaraan.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.ecoGreen,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pendaftaran gerobak tidak memerlukan nomor plat.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // DOKUMEN KENDARAAN
  // =========================================================

  Widget _buildDocumentCard() {
    final bool isCart = _selectedJenis == 'Gerobak';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFEDF0EE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.ecoGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isCart
                      ? Icons.photo_camera_back_rounded
                      : Icons.description_outlined,
                  color: AppColors.ecoGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCart
                          ? 'Foto Fisik Gerobak'
                          : 'Foto Dokumen STNK',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Dokumen atau foto kendaraan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pickedXFile != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Foto baru',
                    style: TextStyle(
                      color: AppColors.ecoGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Area preview foto
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 175,
              width: double.infinity,
              color: const Color(0xFFF4F7F5),
              child: _pickedXFile != null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.ecoGreen,
                            size: 43,
                          ),
                          SizedBox(height: 9),
                          Text(
                            'Foto baru berhasil dipilih',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Foto akan diunggah saat disimpan',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  : (_existingPhotoUrl != null &&
                          _existingPhotoUrl!.isNotEmpty
                      ? Image.network(
                          _existingPhotoUrl!,
                          width: double.infinity,
                          height: 175,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildEmptyPhoto();
                          },
                          loadingBuilder:
                              (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.ecoGreen,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : _buildEmptyPhoto()),
            ),
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _pilihFotoBaru,
              icon: const Icon(
                Icons.add_a_photo_outlined,
                size: 17,
              ),
              label: Text(
                _pickedXFile != null
                    ? 'Pilih Foto Lain'
                    : 'Ubah Foto',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ecoGreen,
                backgroundColor: const Color(0xFFF8FAF8),
                side: BorderSide(
                  color: AppColors.ecoGreen.withOpacity(0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhoto() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          color: Color(0xFF9AA9A0),
          size: 42,
        ),
        SizedBox(height: 9),
        Text(
          'Belum ada foto kendaraan',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Silakan pilih foto dari galeri',
          style: TextStyle(
            color: Color(0xFF9AA9A0),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TOMBOL SIMPAN
  // =========================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _simpanPerubahan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ecoGreen,
          disabledBackgroundColor:
              AppColors.ecoGreen.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.3,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
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

  Widget _buildBottomNote() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 6),
        Text(
          'Informasi kendaraan digunakan untuk keperluan verifikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
