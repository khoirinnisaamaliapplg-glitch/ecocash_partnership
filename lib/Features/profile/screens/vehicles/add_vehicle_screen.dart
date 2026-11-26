
import 'dart:io';

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

  static const Color _navy = Color(0xFF142D4E);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _background = Color(0xFFF4F6F9);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFE9EDF2);
  static const Color _green = Color(0xFF27945D);

  String _selectedJenis = 'Motor';

  final TextEditingController _brandModelController =
      TextEditingController();
  final TextEditingController _platController =
      TextEditingController();

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
      if (!mounted) return;

      _showMessage(
        'Gagal memilih berkas: $e',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _simpanKendaraan() async {
    // Mapping jenis kendaraan ke enum backend.
    String backendType = 'MOTORCYCLE';

    if (_selectedJenis == 'Mobil') {
      backendType = 'CAR';
    } else if (_selectedJenis == 'Roda Tiga') {
      backendType = 'MOTORCYCLE';
    } else if (_selectedJenis == 'Gerobak') {
      backendType = 'CART';
    }

    // Validasi input.
    if (backendType != 'CART') {
      if (_platController.text.trim().isEmpty) {
        _showMessage(
          'Nomor plat wajib diisi!',
          isError: true,
        );
        return;
      }

      if (_pickedXFile == null) {
        _showMessage(
          'Foto STNK wajib diunggah!',
          isError: true,
        );
        return;
      }
    } else {
      if (_pickedXFile == null) {
        _showMessage(
          'Foto fisik gerobak wajib diunggah!',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Upload berkas.
      String? uploadedUrl;

      if (_pickedXFile != null) {
        final uploadRes = await _apiService.uploadSingleFile(
          _pickedXFile!.path,
          xFile: _pickedXFile,
          category: 'document',
        );

        if (uploadRes['success'] == true &&
            uploadRes['url'] != null) {
          uploadedUrl = uploadRes['url'];
        } else {
          if (!mounted) return;

          setState(() => _isLoading = false);

          _showMessage(
            uploadRes['message'] ?? 'Gagal mengunggah foto.',
            isError: true,
          );
          return;
        }
      }

      // Kirim data kendaraan ke API.
      final result = await _apiService.registerOrUpdateVehicle(
        type: backendType,
        plateNumber: backendType != 'CART'
            ? _platController.text.trim()
            : null,
        stnkPhotoUrl:
            backendType != 'CART' ? uploadedUrl : null,
        vehiclePhotoUrl:
            backendType == 'CART' ? uploadedUrl : null,
      );

      // Sinkronisasi dokumen partner agar tampil di panel admin.
      if (uploadedUrl != null) {
        await _apiService.uploadPartnerDocument(
          documentType:
              backendType == 'CART' ? 'GEROBAK' : 'STNK',
          fileUrl: uploadedUrl,
          documentNumber: backendType != 'CART'
              ? _platController.text.trim()
              : null,
        );
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showMessage(
          result['message'] ?? 'Data kendaraan berhasil disimpan!',
        );

        Navigator.pop(context, true);
      } else {
        _showMessage(
          result['message'] ?? 'Gagal menyimpan kendaraan.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(
        'Terjadi kesalahan: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),

                    const SizedBox(height: 26),

                    _buildSectionHeading(
                      'Jenis kendaraan',
                      'Pilih kendaraan operasional Anda',
                      number: '01',
                    ),

                    const SizedBox(height: 14),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.65,
                      children: [
                        _buildJenisOption(
                          'Motor',
                          Icons.two_wheeler_rounded,
                          'Kendaraan roda dua',
                        ),
                        _buildJenisOption(
                          'Mobil',
                          Icons.directions_car_rounded,
                          'Kendaraan roda empat',
                        ),
                        _buildJenisOption(
                          'Roda Tiga',
                          Icons.electric_rickshaw_rounded,
                          'Kendaraan roda tiga',
                        ),
                        _buildJenisOption(
                          'Gerobak',
                          Icons.shopping_cart_rounded,
                          'Gerobak operasional',
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _buildSectionHeading(
                      'Detail kendaraan',
                      'Lengkapi informasi kendaraan',
                      number: '02',
                    ),

                    const SizedBox(height: 14),

                    _buildDetailCard(),

                    const SizedBox(height: 28),

                    _buildSectionHeading(
                      'Dokumen kendaraan',
                      'Unggah foto untuk proses verifikasi',
                      number: '03',
                    ),

                    const SizedBox(height: 14),

                    _buildUploadCard(),

                    const SizedBox(height: 28),

                    _buildSaveButton(),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'Pastikan informasi yang Anda masukkan sudah benar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 14),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _navy,
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
                  'Tambah Kendaraan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Daftarkan kendaraan operasional',
                  style: TextStyle(
                    fontSize: 11,
                    color: _secondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.add_road_rounded,
              color: _navy,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // INTRO CARD
  // ---------------------------------------------------------

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.045),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DATA KENDARAAN',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    const Text(
                      'Daftarkan kendaraan Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Lengkapi data agar kendaraan dapat diverifikasi oleh tim EcoCash.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: _yellow,
                  size: 43,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // SECTION HEADING
  // ---------------------------------------------------------

  Widget _buildSectionHeading(
    String title,
    String subtitle, {
    required String number,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _yellow.withOpacity(0.22),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w900,
              fontSize: 11,
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
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _secondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // VEHICLE TYPE OPTIONS
  // ---------------------------------------------------------

  Widget _buildJenisOption(
    String jenis,
    IconData icon,
    String description,
  ) {
    final bool isSelected = _selectedJenis == jenis;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: _isLoading
            ? null
            : () {
                setState(() {
                  _selectedJenis = jenis;
                  _pickedXFile = null;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isSelected ? _navy : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isSelected ? _navy : _border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isSelected ? 0.07 : 0.025,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.12)
                          : _background,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? _yellow : _navy,
                      size: 21,
                    ),
                  ),

                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _yellow,
                      size: 19,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: Colors.grey.shade300,
                      size: 19,
                    ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jenis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.65)
                          : _secondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // VEHICLE DETAILS
  // ---------------------------------------------------------

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(
            'Nama / Merk / Model Kendaraan',
            required: false,
          ),

          const SizedBox(height: 9),

          TextField(
            controller: _brandModelController,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(
              hint: _selectedJenis == 'Roda Tiga'
                  ? 'Contoh: Viar Karya 200 / Tossa'
                  : _selectedJenis == 'Motor'
                      ? 'Contoh: Honda Beat 2022'
                      : _selectedJenis == 'Mobil'
                          ? 'Contoh: Suzuki Carry'
                          : 'Contoh: Gerobak Kayu',
              icon: Icons.directions_car_filled_rounded,
            ),
          ),

          if (_selectedJenis != 'Gerobak') ...[
            const SizedBox(height: 19),

            _buildFieldLabel(
              'Nomor Plat Kendaraan',
              required: true,
            ),

            const SizedBox(height: 9),

            TextField(
              controller: _platController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
              decoration: _inputDecoration(
                hint: 'Contoh: B 1234 XYZ',
                icon: Icons.pin_rounded,
              ),
            ),

            const SizedBox(height: 9),

            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: _secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Masukkan nomor plat sesuai STNK kendaraan.',
                    style: TextStyle(
                      color: _secondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(
    String label, {
    required bool required,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        color: _secondary,
        size: 18,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
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
          color: _navy,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  // ---------------------------------------------------------
  // UPLOAD DOCUMENT
  // ---------------------------------------------------------

  Widget _buildUploadCard() {
    final bool isCart = _selectedJenis == 'Gerobak';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isCart
                      ? Icons.shopping_cart_rounded
                      : Icons.description_rounded,
                  color: _navy,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCart
                          ? 'Foto Fisik Gerobak'
                          : 'Foto Dokumen STNK',
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCart
                          ? 'Foto kondisi gerobak Anda'
                          : 'Foto STNK asli kendaraan',
                      style: const TextStyle(
                        color: _secondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'WAJIB',
                  style: TextStyle(
                    color: Color(0xFFCB7730),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_pickedXFile == null)
            _buildEmptyUpload()
          else
            _buildSelectedUpload(),
        ],
      ),
    );
  }

  Widget _buildEmptyUpload() {
    return InkWell(
      onTap: _isLoading ? null : _pilihBerkas,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 25,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD9E0E8),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: _yellow.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: _navy,
                size: 27,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Pilih foto dari galeri',
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Pastikan foto terlihat jelas dan tidak buram',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondary,
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: _yellow,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Pilih Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUpload() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD5EBDD),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              File(_pickedXFile!.path),
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  color: _background,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: _secondary,
                    size: 35,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: _green,
                size: 19,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _pickedXFile!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),

              TextButton(
                onPressed: _isLoading ? null : _pilihBerkas,
                child: const Text(
                  'Ganti Foto',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // SAVE BUTTON
  // ---------------------------------------------------------

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _simpanKendaraan,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          disabledBackgroundColor: _secondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  ),
                  SizedBox(width: 11),
                  Text(
                    'Menyimpan data...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    color: _yellow,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Simpan Kendaraan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------
  // COMMON CARD DECORATION
  // ---------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
