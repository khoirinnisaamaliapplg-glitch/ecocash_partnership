import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class LaporkanMasalahScreen extends StatefulWidget {
  const LaporkanMasalahScreen({super.key});

  @override
  State<LaporkanMasalahScreen> createState() => _LaporkanMasalahScreenState();
}

class _LaporkanMasalahScreenState extends State<LaporkanMasalahScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategoryUi;
  XFile? _attachmentFile;
  bool _isSubmitting = false;

  static const Color _navy = Color(0xFF142D4E);
  static const Color _cyan = Color(0xFF118D9B);
  static const Color _blue = Color(0xFF257EB3);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _textPrimary = Color(0xFF24364B);
  static const Color _textSecondary = Color(0xFF8492A5);
  static const Color _border = Color(0xFFE5EAF0);

  final Map<String, String> _categoryEnumMap = {
    'Masalah Scan': 'MACHINE_BROKEN',
    'Masalah Pembayaran': 'WITHDRAWAL_ISSUE',
    'Masalah Pekerjaan': 'WEIGHING_DISCREPANCY',
    'Lainnya': 'OTHER',
  };

  final Map<String, IconData> _categoryIcons = {
    'Masalah Scan': Icons.qr_code_scanner_rounded,
    'Masalah Pembayaran': Icons.account_balance_wallet_outlined,
    'Masalah Pekerjaan': Icons.work_outline_rounded,
    'Lainnya': Icons.more_horiz_rounded,
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (!mounted || image == null) return;

      setState(() {
        _attachmentFile = image;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih gambar. Silakan coba lagi.'),
        ),
      );
    }
  }

  Future<void> _submitTicket() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryUi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori masalah')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final backendCategory = _categoryEnumMap[_selectedCategoryUi!] ?? 'OTHER';

      final result = await _apiService.createTicket(
        category: backendCategory,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        attachmentFile: _attachmentFile,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Laporan berhasil dikirim!'),
            backgroundColor: const Color(0xFF188B62),
          ),
        );

        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengirim laporan'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan. Silakan coba kembali.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionTitle(
    String title, {
    String? subtitle,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Kategori Masalah',
          subtitle: 'Pilih kategori yang paling sesuai dengan kendala Anda.',
          required: true,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categoryEnumMap.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.65,
          ),
          itemBuilder: (context, index) {
            final category = _categoryEnumMap.keys.elementAt(index);
            final isSelected = _selectedCategoryUi == category;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryUi = category;
                });
              },
              borderRadius: BorderRadius.circular(13),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF6F8) : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSelected ? _cyan : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected ? _cyan : const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _categoryIcons[category],
                        size: 17,
                        color: isSelected ? Colors.white : _navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? _navy : _textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _cyan,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: _textSecondary,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      prefixIconColor: _textSecondary,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
        borderSide: const BorderSide(color: _cyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
  }

  Widget _buildAttachmentSection() {
    final hasAttachment = _attachmentFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Lampiran Foto',
          subtitle: 'Tambahkan bukti foto jika diperlukan (opsional).',
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasAttachment ? _cyan : _border,
                width: hasAttachment ? 1.3 : 1,
              ),
            ),
            child: hasAttachment
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: kIsWeb
                              ? Image.network(
                                  _attachmentFile!.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                )
                              : Image.file(
                                  File(_attachmentFile!.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Foto berhasil dipilih',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _attachmentFile!.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Ketuk untuk mengganti foto',
                              style: TextStyle(
                                fontSize: 10,
                                color: _cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _attachmentFile = null;
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 21,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: _cyan,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unggah bukti foto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pilih gambar dari galeri perangkat Anda.',
                              style: TextStyle(
                                fontSize: 10,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: _textSecondary,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0F4F8),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: _textSecondary,
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FA),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD8EAF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Laporan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jelaskan kendala yang Anda alami secara lengkap '
                  'agar tim kami dapat melakukan pemeriksaan dengan tepat.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: _navy.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 53,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_cyan, _blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 21,
                width: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 17, color: Colors.white),
                  SizedBox(width: 9),
                  Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Laporkan Masalah',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informasi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _navy,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PUSAT BANTUAN',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFFFD45A),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Ada kendala?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Sampaikan masalah Anda kepada tim '
                              'kami melalui formulir ini.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      SizedBox(
                        width: 85,
                        height: 85,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -60,
                              width: 200,
                              height: 200,
                              child: Image.asset(
                                'assets/images/bantuan.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                _buildInformationCard(),

                const SizedBox(height: 24),

                _buildCategorySelector(),

                const SizedBox(height: 22),

                _buildSectionTitle(
                  'Judul Masalah',
                  subtitle: 'Tuliskan ringkasan kendala yang dialami.',
                  required: true,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Judul masalah wajib diisi';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    hint: 'Contoh: Aplikasi sering keluar sendiri',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),

                const SizedBox(height: 20),

                _buildSectionTitle(
                  'Deskripsi Masalah',
                  subtitle: 'Ceritakan kendala secara lebih terperinci.',
                  required: true,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Deskripsi masalah wajib diisi';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    hint:
                        'Jelaskan kapan masalah terjadi, apa yang '
                        'Anda lakukan, dan kendala yang muncul...',
                  ),
                ),

                const SizedBox(height: 22),

                _buildAttachmentSection(),

                const SizedBox(height: 22),

                _buildSubmitButton(),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Pastikan informasi yang Anda masukkan sudah benar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: _textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
