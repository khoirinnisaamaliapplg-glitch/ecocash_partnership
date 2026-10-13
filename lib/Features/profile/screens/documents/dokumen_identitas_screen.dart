import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'unggah_ktp_screen.dart';
import 'unggah_stnk_screen.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class DokumenIdentitasScreen extends StatefulWidget {
  const DokumenIdentitasScreen({super.key});

  @override
  State<DokumenIdentitasScreen> createState() => _DokumenIdentitasScreenState();
}

class _DokumenIdentitasScreenState extends State<DokumenIdentitasScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  Map<String, dynamic>? _partnerProfile;
  List<dynamic> _myDocuments = [];

  static const Color _navyColor = Color(0xFF0F2C59);

  @override
  void initState() {
    super.initState();
    _fetchDokumenStatus();
  }

  Future<void> _fetchDokumenStatus() async {
    setState(() => _isLoading = true);

    final profileResult = await _apiService.getMe();
    final docsResult = await _apiService.getMyDocuments();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (profileResult['success'] == true) {
          _partnerProfile = profileResult['data'];
        }
        if (docsResult['success'] == true && docsResult['data'] is List) {
          _myDocuments = docsResult['data'];
        }
      });
    }
  }

  Map<String, dynamic>? _findDoc(String type) {
    try {
      return _myDocuments.firstWhere(
        (doc) => (doc['documentType'] ?? '').toString().toUpperCase() == type.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadSimPhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunggah foto SIM...')),
    );

    final uploadRes = await _apiService.uploadSingleFile(
      pickedFile.path,
      xFile: pickedFile,
      category: 'document',
    );

    if (uploadRes['success'] == true && uploadRes['url'] != null) {
      final docRes = await _apiService.uploadPartnerDocument(
        documentType: 'SIM',
        fileUrl: uploadRes['url'],
      );

      if (mounted) {
        if (docRes['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto SIM berhasil diunggah!'), backgroundColor: Colors.green),
          );
          _fetchDokumenStatus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(docRes['message'] ?? 'Gagal menyimpan SIM'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Dapatkan URL KTP dari PartnerDocument ATAU dari UserModel
    final ktpDoc = _findDoc('KTP');
    final String userKtpUrl = _partnerProfile?['user']?['ktpImageUrl'] ??
        _partnerProfile?['user']?['ktpUrl'] ??
        _partnerProfile?['ktpImageUrl'] ??
        '';
    final String ktpUrl = (ktpDoc?['fileUrl'] != null && (ktpDoc!['fileUrl'] as String).isNotEmpty)
        ? ktpDoc['fileUrl']
        : userKtpUrl;
    final String ktpStatus = (ktpDoc?['status'] ?? '').toString().toUpperCase();

    // 2. Dapatkan URL STNK
    final stnkDoc = _findDoc('STNK');
    final String stnkUrl = stnkDoc?['fileUrl'] ?? '';
    final String stnkStatus = (stnkDoc?['status'] ?? '').toString().toUpperCase();

    // 3. Dapatkan URL SIM
    final simDoc = _findDoc('SIM');
    final String simUrl = simDoc?['fileUrl'] ?? '';
    final String simStatus = (simDoc?['status'] ?? '').toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Dokumen Identitas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDokumenStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pastikan dokumen Anda valid dan terbaru untuk kelancaran verifikasi sebagai mitra EcoCash.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // --- 1. KARTU KTP ---
                    _buildCardWrapper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildIconCircle(Icons.badge_outlined, const Color(0xFFDDE9FA), _navyColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('KTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                    Text('Kartu Tanda Penduduk', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              _buildStatusBadgeByStatus(ktpStatus, isUploaded: ktpUrl.isNotEmpty),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UnggahKtpScreen()),
                              );
                              if (res != null) {
                                _fetchDokumenStatus();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: _buildKtpPreview(ktpUrl: ktpUrl),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 2. KARTU STNK ---
                    _buildCardWrapper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildIconCircle(Icons.directions_car_outlined, const Color(0xFFEFEFEF), Colors.grey.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('STNK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                    Text('Surat Tanda Nomor Kendaraan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              _buildStatusBadgeByStatus(stnkStatus, isUploaded: stnkUrl.isNotEmpty),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // TAMPILAN PRATINJAU FOTO STNK (JIKA ADA)
                          if (stnkUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Image.network(
                                  stnkUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          InkWell(
                            onTap: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UnggahStnkScreen()),
                              );
                              if (res == true) {
                                _fetchDokumenStatus();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC5CEE0), width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.description_outlined, color: _navyColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    stnkUrl.isNotEmpty ? 'Ubah Foto STNK' : 'Unggah Foto STNK',
                                    style: const TextStyle(color: _navyColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 3. KARTU SIM ---
                    _buildCardWrapper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildIconCircle(Icons.subtitles_outlined, const Color(0xFFEFEFEF), Colors.grey.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('SIM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('OPSIONAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        ),
                                      ],
                                    ),
                                    const Text('Surat Izin Mengemudi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              _buildStatusBadgeByStatus(simStatus, isUploaded: simUrl.isNotEmpty),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // TAMPILAN PRATINJAU FOTO SIM (JIKA ADA)
                          if (simUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Image.network(
                                  simUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _uploadSimPhoto,
                              icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.textSecondary),
                              label: Text(
                                simUrl.isNotEmpty ? 'Ganti Foto SIM' : 'Tambah Foto SIM',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadgeByStatus(String status, {required bool isUploaded}) {
    if (status == 'APPROVED' || status == 'VERIFIED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFD0F4F4), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: AppColors.primaryCyan),
            SizedBox(width: 4),
            Text('Terverifikasi', style: TextStyle(fontSize: 11, color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (isUploaded || status == 'PENDING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 12, color: Colors.blue),
            SizedBox(width: 4),
            Text('Diproses', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFFF7D6), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, size: 12, color: Color(0xFFB78103)),
            SizedBox(width: 4),
            Text('Belum\nDiunggah', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xFFB78103), fontWeight: FontWeight.bold, height: 1.1)),
          ],
        ),
      );
    }
  }

  Widget _buildKtpPreview({required String ktpUrl}) {
    final String partnerName = (_partnerProfile?['user']?['name'] ?? _partnerProfile?['name'] ?? 'MITRA ECOCASH').toString().toUpperCase();

    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBBE2EC), Color(0xFFE0F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF88AB8E).withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 75,
            height: 105,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: ktpUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      ktpUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 40, color: Colors.white),
                      SizedBox(height: 2),
                      Text('FOTO KTP', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('REPUBLIK INDONESIA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _navyColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(3)),
                      child: const Text('e-KTP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _navyColor)),
                    ),
                  ],
                ),
                const Divider(height: 8, thickness: 0.8, color: Colors.black26),
                Text('Nama : $partnerName', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 3),
                Text(
                  ktpUrl.isNotEmpty ? 'Dokumen KTP Terlampir' : 'Tekan untuk mengunggah foto KTP',
                  style: TextStyle(fontSize: 8, color: ktpUrl.isNotEmpty ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconCircle(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}