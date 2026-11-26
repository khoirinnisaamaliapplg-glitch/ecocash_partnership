import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import 'unggah_ktp_screen.dart';
import 'unggah_stnk_screen.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import '../../../../core/widgets/app_loading.dart';

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

  static const Color _navy = Color(0xFF0F2C59);
  static const Color _pageBackground = Color(0xFFF5F7FA);
  static const Color _borderColor = Color(0xFFE9EDF2);
  // Ganti path ini dengan lokasi gambar yang digunakan di menu Profil.
  static const String _headerImage = 'assets/images/banneridentitas.png';

  @override
  void initState() {
    super.initState();
    _fetchDokumenStatus();
  }

  // =========================================================
  // LOAD DOCUMENTS
  // =========================================================

  Future<void> _fetchDokumenStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _apiService.getMe(),
        _apiService.getMyDocuments(),
      ]);

      if (!mounted) return;

      final profileResult = results[0];
      final docsResult = results[1];

      setState(() {
        _isLoading = false;

        if (profileResult['success'] == true) {
          _partnerProfile = profileResult['data'];
        }

        if (docsResult['success'] == true && docsResult['data'] is List) {
          _myDocuments = docsResult['data'];
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat dokumen identitas.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, dynamic>? _findDoc(String type) {
    try {
      final result = _myDocuments.firstWhere(
        (doc) =>
            (doc['documentType'] ?? '').toString().toUpperCase() ==
            type.toUpperCase(),
      );

      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  String _getDocumentUrl(Map<String, dynamic>? document) {
    return (document?['fileUrl'] ?? '').toString();
  }

  String _getDocumentStatus(Map<String, dynamic>? document) {
    return (document?['status'] ?? '').toString().toUpperCase();
  }

  // =========================================================
  // UPLOAD SIM
  // =========================================================

  Future<void> _uploadSimPhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengunggah foto SIM...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final uploadRes = await _apiService.uploadSingleFile(
        pickedFile.path,
        xFile: pickedFile,
        category: 'document',
      );

      if (!mounted) return;

      if (uploadRes['success'] == true && uploadRes['url'] != null) {
        final docRes = await _apiService.uploadPartnerDocument(
          documentType: 'SIM',
          fileUrl: uploadRes['url'],
        );

        if (!mounted) return;

        if (docRes['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto SIM berhasil diunggah.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await _fetchDokumenStatus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                docRes['message'] ?? 'Gagal menyimpan dokumen SIM.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadRes['message'] ?? 'Gagal mengunggah foto SIM.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat mengunggah SIM.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _openKtpUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UnggahKtpScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      await _fetchDokumenStatus();
    }
  }

  Future<void> _openStnkUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UnggahStnkScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      await _fetchDokumenStatus();
    }
  }

  // =========================================================
  // DOCUMENT PREVIEW
  // =========================================================

  void _showDocumentPreview(String title, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: _navy),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 340,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _navy,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 35,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Dokumen tidak dapat ditampilkan.',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final ktpDoc = _findDoc('KTP');
    final stnkDoc = _findDoc('STNK');
    final simDoc = _findDoc('SIM');

    final String userKtpUrl =
        (_partnerProfile?['user']?['ktpImageUrl'] ??
                _partnerProfile?['user']?['ktpUrl'] ??
                _partnerProfile?['ktpImageUrl'] ??
                '')
            .toString();

    final String ktpUrl = _getDocumentUrl(ktpDoc).isNotEmpty
        ? _getDocumentUrl(ktpDoc)
        : userKtpUrl;

    final String stnkUrl = _getDocumentUrl(stnkDoc);
    final String simUrl = _getDocumentUrl(simDoc);

    final String ktpStatus = _getDocumentStatus(ktpDoc);
    final String stnkStatus = _getDocumentStatus(stnkDoc);
    final String simStatus = _getDocumentStatus(simDoc);

    // KTP dan STNK merupakan dokumen utama.
    final int mainUploadedCount = [
      ktpUrl,
      stnkUrl,
    ].where((url) => url.isNotEmpty).length;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 55,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _navy,
            size: 18,
          ),
        ),
        title: const Text(
          'Dokumen Identitas',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
     body: _isLoading
    ? AppLoading(
        message: 'Menyiapkan dokumen identitas kamu...',
        size: 76,
      )
    : RefreshIndicator(
              color: _navy,
              onRefresh: _fetchDokumenStatus,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(17, 5, 17, 28),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 17),

                  _buildProgressCard(mainUploadedCount),
                  const SizedBox(height: 23),

                  _buildSectionHeader(),
                  const SizedBox(height: 11),

                  // KTP
                  _buildDocumentItem(
                    title: 'Kartu Tanda Penduduk',
                    type: 'KTP',
                    subtitle: 'Identitas pribadi pemilik akun',
                    icon: Icons.badge_outlined,
                    iconColor: const Color(0xFF3766A5),
                    iconBackground: const Color(0xFFEAF1FC),
                    status: ktpStatus,
                    imageUrl: ktpUrl,
                    onUpload: _openKtpUpload,
                  ),

                  const SizedBox(height: 11),

                  // STNK
                  _buildDocumentItem(
                    title: 'Surat Tanda Nomor Kendaraan',
                    type: 'STNK',
                    subtitle: 'Dokumen kendaraan mitra',
                    icon: Icons.directions_car_outlined,
                    iconColor: const Color(0xFF238477),
                    iconBackground: const Color(0xFFE7F5F1),
                    status: stnkStatus,
                    imageUrl: stnkUrl,
                    onUpload: _openStnkUpload,
                  ),

                  const SizedBox(height: 11),

                  // SIM
                  _buildDocumentItem(
                    title: 'Surat Izin Mengemudi',
                    type: 'SIM',
                    subtitle: 'Dokumen pendukung pengemudi',
                    icon: Icons.drive_eta_outlined,
                    iconColor: const Color(0xFF96702A),
                    iconBackground: const Color(0xFFFFF4DE),
                    status: simStatus,
                    imageUrl: simUrl,
                    isOptional: true,
                    onUpload: _uploadSimPhoto,
                  ),

                  const SizedBox(height: 18),
                  _buildSecurityNote(),
                ],
              ),
            ),
    );
  }

  // =========================================================
  // HEADING
  // =========================================================

  // =========================================================
  // HEADER BANNER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      height: 178,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _headerImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _navy,
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 125,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                );
              },
            ),

            // Overlay agar tulisan tetap terbaca.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _navy.withValues(alpha: 0.96),
                    _navy.withValues(alpha: 0.78),
                    _navy.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Text(
                      'VERIFIKASI MITRA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Dokumen\nIdentitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Lengkapi dokumen untuk menjaga\nkeamanan akun mitra EcoCash.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.5,
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

  // =========================================================
  // PROGRESS CARD
  // =========================================================

  Widget _buildProgressCard(int uploadedCount) {
    final double progress = uploadedCount / 2;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dokumen utama',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$uploadedCount/2',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryYellow,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            uploadedCount == 2
                ? 'Semua dokumen utama sudah diunggah.'
                : '$uploadedCount dari 2 dokumen utama sudah diunggah.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION HEADER
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar dokumen',
          style: TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '3 jenis dokumen',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  // =========================================================
  // DOCUMENT ITEM
  // =========================================================

  Widget _buildDocumentItem({
    required String title,
    required String type,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String status,
    required String imageUrl,
    required VoidCallback onUpload,
    bool isOptional = false,
  }) {
    final bool isUploaded = imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isOptional) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OPSIONAL',
                              style: TextStyle(
                                color: Color(0xFF78818D),
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              _buildStatusBadge(status, isUploaded: isUploaded),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: _borderColor),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: isUploaded
                    ? InkWell(
                        onTap: () {
                          _showDocumentPreview(type, imageUrl);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              color: _navy,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Lihat dokumen',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: AppColors.textMuted,
                              size: 13,
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.textMuted,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isOptional
                                  ? 'Belum ada dokumen'
                                  : 'Dokumen belum diunggah',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: onUpload,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    side: BorderSide(color: _navy.withValues(alpha: 0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    isUploaded ? 'Ubah' : 'Unggah',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge(String status, {required bool isUploaded}) {
    final bool isApproved = status == 'APPROVED' || status == 'VERIFIED';

    final bool isRejected = status == 'REJECTED' || status == 'REJECT';

    final bool isPending = status == 'PENDING' || isUploaded;

    Color background;
    Color foreground;
    IconData icon;
    String label;

    if (isApproved) {
      background = const Color(0xFFE6F6EF);
      foreground = const Color(0xFF21845B);
      icon = Icons.check_circle_rounded;
      label = 'Valid';
    } else if (isRejected) {
      background = const Color(0xFFFFEEEE);
      foreground = const Color(0xFFD34D4D);
      icon = Icons.error_outline_rounded;
      label = 'Ditolak';
    } else if (isPending) {
      background = const Color(0xFFFFF5E5);
      foreground = const Color(0xFFB78103);
      icon = Icons.schedule_rounded;
      label = 'Diproses';
    } else {
      background = const Color(0xFFF0F2F5);
      foreground = const Color(0xFF78818D);
      icon = Icons.remove_circle_outline_rounded;
      label = 'Kosong';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY NOTE
  // =========================================================

  Widget _buildSecurityNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: _navy, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pastikan foto dokumen terlihat jelas dan tidak terpotong. Dokumen digunakan untuk keperluan verifikasi mitra EcoCash.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
