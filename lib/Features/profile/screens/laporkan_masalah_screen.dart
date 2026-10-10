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

  // Mapping Kategori UI -> Enum Backend
  final Map<String, String> _categoryEnumMap = {
    'Masalah Scan': 'MACHINE_BROKEN',
    'Masalah Pembayaran': 'WITHDRAWAL_ISSUE',
    'Masalah Pekerjaan': 'WEIGHING_DISCREPANCY',
    'Lainnya': 'OTHER',
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachmentFile = image;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryUi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori masalah')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final backendCategory = _categoryEnumMap[_selectedCategoryUi!] ?? 'OTHER';

    final result = await _apiService.createTicket(
      category: backendCategory,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      attachmentFile: _attachmentFile,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Laporan berhasil dikirim!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal mengirim laporan')),
        );
      }
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Laporkan Masalah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silakan isi formulir di bawah ini dengan detail yang jelas agar tim kami dapat membantu Anda secepatnya.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Kategori Masalah
              const Text('Kategori Masalah', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategoryUi,
                    hint: const Text('Pilih kategori...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    items: _categoryEnumMap.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategoryUi = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Judul Masalah
              const Text('Judul Masalah', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Judul masalah wajib diisi' : null,
                decoration: InputDecoration(
                  hintText: 'Contoh: Aplikasi sering keluar sendiri',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Deskripsi
              const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi masalah wajib diisi' : null,
                decoration: InputDecoration(
                  hintText: 'Jelaskan masalah secara detail...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Lampiran Foto
              const Text('Lampiran (Opsional)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _attachmentFile != null
                      ? Row(
                          children: [
                            const Icon(Icons.image, color: AppColors.primaryCyan),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _attachmentFile!.name,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: () => setState(() => _attachmentFile = null),
                            ),
                          ],
                        )
                      : Column(
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.primaryCyan),
                            SizedBox(height: 6),
                            Text('Tambahkan foto atau bukti', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Kirim Laporan dengan Gradien Warna Sesuai Gambar
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF118D9B), // Toska / Cyan (Sisi Kiri)
                      Color(0xFF257EB3), // Biru (Sisi Kanan)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Kirim Laporan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}