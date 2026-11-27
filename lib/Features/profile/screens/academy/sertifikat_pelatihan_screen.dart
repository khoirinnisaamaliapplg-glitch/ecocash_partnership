
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/api_service.dart';

class SertifikatPelatihanScreen extends StatefulWidget {
  const SertifikatPelatihanScreen({super.key});

  @override
  State<SertifikatPelatihanScreen> createState() =>
      _SertifikatPelatihanScreenState();
}

class _SertifikatPelatihanScreenState
    extends State<SertifikatPelatihanScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  // EcoCash Brand Colors
  static const Color _primaryYellow = Color(0xFFFFE600);
  static const Color _darkText = Color(0xFF1C1C1E);
  static const Color _ecoGreen = Color(0xFF00AA13);
  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkNavy = Color(0xFF0F2C59);
  static const Color _slate = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8F9FA);
  static const Color _secondaryText = Color(0xFF64748B);

  bool _isLoading = true;
  List<dynamic> _certificates = [];

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final result = await _apiService.getAcademyCertificates();

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result['success'] == true && result['data'] is List) {
        _certificates = result['data'];
      }
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _darkNavy,
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              color: _darkNavy,
              onRefresh: _fetchCertificates,
              child: _certificates.isEmpty
                  ? _buildEmptyState()
                  : _buildCertificateList(),
            ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _darkNavy,
      elevation: 0,
      leading: IconButton(
        onPressed: _goBack,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 19,
        ),
      ),
      title: const Text(
        'Sertifikat Saya',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _fetchCertificates,
          tooltip: 'Muat ulang',
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // CERTIFICATE LIST
  Widget _buildCertificateList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      children: [
        _buildPageHeader(),

        const SizedBox(height: 20),

        _buildAchievementSummary(),

        const SizedBox(height: 24),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Sertifikat yang Diperoleh',
                style: TextStyle(
                  color: _darkNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9CC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_certificates.length} Sertifikat',
                style: const TextStyle(
                  color: _darkNavy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ..._certificates.map((cert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _buildCertificateCard(
              Map<String, dynamic>.from(cert as Map),
            ),
          );
        }),

        const SizedBox(height: 4),

        _buildFooterInformation(),
      ],
    );
  }

  // PAGE HEADER
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9CC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: _darkNavy,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PENCAPAIAN ANDA',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        const Text(
          'Sertifikat Pelatihan',
          style: TextStyle(
            color: _darkNavy,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Kumpulan sertifikat digital resmi sebagai bukti keberhasilan Anda menyelesaikan program pelatihan Mitra EcoCash.',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ACHIEVEMENT SUMMARY
  Widget _buildAchievementSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkNavy, _slate],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -22,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 115,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),

          Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: const BoxDecoration(
                  color: _primaryYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: _darkNavy,
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pencapaian',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${_certificates.length} Sertifikat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Terus tingkatkan kompetensi Anda!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.verified_rounded,
                color: _primaryYellow,
                size: 27,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 45),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 30,
          ),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8EDF2),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF9CC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: _darkNavy,
                  size: 51,
                ),
              ),

              const SizedBox(height: 21),

              const Text(
                'Belum Ada Sertifikat',
                style: TextStyle(
                  color: _darkNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Anda belum memiliki sertifikat pelatihan. Selesaikan seluruh modul dan evaluasi pelatihan untuk mendapatkan sertifikat digital.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 21),

              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(
                    Icons.school_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Lihat Pelatihan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // CERTIFICATE CARD
  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    final String certNumber =
        (cert['certificateNumber'] ?? 'ECA-2026-UNKNOWN').toString();

    final String courseTitle =
        (cert['course']?['title'] ?? 'Program Pelatihan Mitra').toString();

    final String issueDate = cert['createdAt'] != null
        ? cert['createdAt'].toString().split('T')[0]
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: _primaryYellow,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 19,
          vertical: 23,
        ),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE7ECF1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // BRAND HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F7EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 23,
                    color: _ecoGreen,
                  ),
                ),

                const SizedBox(width: 9),

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EcoCash',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _darkNavy,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ACADEMY PARTNER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                        color: _ecoGreen,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 21),

            // DECORATIVE LINE
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: _primaryYellow,
                    thickness: 2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: _darkNavy,
                    size: 21,
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: _primaryYellow,
                    thickness: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'SERTIFIKAT PENCAPAIAN',
              style: TextStyle(
                color: _darkNavy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Diberikan sebagai bentuk apresiasi atas keberhasilan menyelesaikan program pelatihan:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 11,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              courseTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkNavy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: 55,
              height: 3,
              decoration: BoxDecoration(
                color: _ecoGreen,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            // ISSUE DATE
            const Text(
              'TANGGAL PENERBITAN',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              issueDate,
              style: const TextStyle(
                color: _darkText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 19),

            // CERTIFICATE NUMBER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'NOMOR SERTIFIKAT',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    certNumber,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _darkNavy,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // VERIFIED LABEL
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: _ecoGreen,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Sertifikat Digital EcoCash',
                  style: TextStyle(
                    color: _emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FOOTER INFORMATION
  Widget _buildFooterInformation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _ecoGreen,
            size: 19,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simpan nomor sertifikat Anda sebagai referensi pencapaian pelatihan di EcoCash Academy.',
              style: TextStyle(
                color: _slate,
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
