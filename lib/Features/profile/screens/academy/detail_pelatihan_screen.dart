import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/api_service.dart';
import 'kuis_pelatihan_screen.dart';
import 'sertifikat_pelatihan_screen.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_colors.dart';

class DetailPelatihanScreen extends StatefulWidget {
  final String courseId;

  const DetailPelatihanScreen({super.key, required this.courseId});

  @override
  State<DetailPelatihanScreen> createState() => _DetailPelatihanScreenState();
}

class _DetailPelatihanScreenState extends State<DetailPelatihanScreen> {
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
  Map<String, dynamic>? _courseDetail;
  List<dynamic> _completedModuleIds = [];

  @override
  void initState() {
    super.initState();
    _fetchCourseDetail();
  }

  Future<void> _fetchCourseDetail() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final result = await _apiService.getAcademyCourseById(widget.courseId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result['success'] == true && result['data'] != null) {
        _courseDetail = result['data'];
        _completedModuleIds = _courseDetail?['completedModuleIds'] ?? [];
      }
    });
  }

  // Ekstrak ID Video YouTube
  String? _getYouTubeThumbnail(String? url) {
    if (url == null || url.isEmpty) return null;

    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return null;

    String? videoId;

    if (uri.host.contains('youtube.com')) {
      videoId = uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (videoId != null && videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }

    return null;
  }

  // Membuka video YouTube
  Future<void> _bukaVideoYouTube(String? url) async {
    final String targetUrl = url ?? 'https://www.youtube.com';

    final Uri uri = Uri.parse(targetUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak dapat membuka video pembelajaran.'),
            backgroundColor: _darkNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoading(
          message: 'Menyiapkan detail pelatihan kamu...',
          size: 76,
        ),
      );
    }

    if (_courseDetail == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: _buildAppBar(),
        body: _buildNotFoundState(),
      );
    }

    final String title = (_courseDetail!['title'] ?? 'Detail Pelatihan')
        .toString();

    final String description =
        (_courseDetail!['description'] ?? 'Tidak ada deskripsi.').toString();

    final String? courseVideoUrl = _courseDetail!['videoUrl']?.toString();

    final String? youtubeThumb = _getYouTubeThumbnail(courseVideoUrl);

    final String bannerUrl =
        youtubeThumb ??
        (_courseDetail!['bannerUrl'] ??
                'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60')
            .toString();

    final num progressPercentage =
        num.tryParse((_courseDetail!['progressPercentage'] ?? 0).toString()) ??
        0;

    final double progressValue = (progressPercentage.toDouble() / 100).clamp(
      0.0,
      1.0,
    );

    final bool isCompleted = progressPercentage >= 100;

    final List<dynamic> modules = _courseDetail!['modules'] ?? [];

    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: _ecoGreen,
        onRefresh: _fetchCourseDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VIDEO BANNER
              _buildVideoBanner(bannerUrl, courseVideoUrl),

              const SizedBox(height: 20),

              // INFORMASI PELATIHAN
              _buildCourseInformation(title: title, description: description),

              const SizedBox(height: 18),

              // PROGRESS PELATIHAN
              _buildProgressCard(
                progressPercentage: progressPercentage,
                progressValue: progressValue,
                isCompleted: isCompleted,
              ),

              const SizedBox(height: 20),

              // TOMBOL SERTIFIKAT
              if (isCompleted) ...[
                _buildCertificateButton(),
                const SizedBox(height: 22),
              ],

              // DAFTAR MODUL
              _buildModuleHeader(modules.length),

              const SizedBox(height: 12),

              if (modules.isEmpty)
                _buildEmptyModuleState()
              else
                ...List.generate(
                  modules.length,
                  (index) => _buildModuleCard(
                    module: modules[index],
                    index: index,
                    courseVideoUrl: courseVideoUrl,
                  ),
                ),

              const SizedBox(height: 12),

              // TOMBOL KUIS
              _buildQuizButton(title),

              const SizedBox(height: 12),

              // INFORMASI BAWAH
              _buildInformationNote(),
            ],
          ),
        ),
      ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _darkNavy,
          size: 20,
        ),
      ),
      title: const Text(
        'Detail Pelatihan',
        style: TextStyle(
          color: _darkNavy,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Sertifikat Saya',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SertifikatPelatihanScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.workspace_premium_outlined,
            color: _darkNavy,
            size: 23,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // VIDEO BANNER
  Widget _buildVideoBanner(String bannerUrl, String? courseVideoUrl) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: _darkNavy,
            child: InkWell(
              onTap: () => _bukaVideoYouTube(courseVideoUrl),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    bannerUrl,
                    width: double.infinity,
                    height: 205,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 205,
                        color: const Color(0xFFEAF0F8),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 55,
                          color: _darkNavy,
                        ),
                      );
                    },
                  ),

                  // Overlay
                  Container(
                    width: double.infinity,
                    height: 205,
                    color: _darkNavy.withValues(alpha: 0.25),
                  ),

                  // Play Button
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _primaryYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: _darkText,
                      size: 39,
                    ),
                  ),

                  // Label
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _darkNavy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.smart_display_rounded,
                            color: _primaryYellow,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'VIDEO PEMBELAJARAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // BUTTON YOUTUBE
        SizedBox(
          width: double.infinity,
          height: 47,
          child: ElevatedButton.icon(
            onPressed: () => _bukaVideoYouTube(courseVideoUrl),
            icon: const Icon(
              Icons.play_circle_outline_rounded,
              size: 21,
              color: _darkText,
            ),
            label: const Text(
              'Putar Video Pembelajaran',
              style: TextStyle(
                color: _darkText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryYellow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // COURSE INFORMATION
  Widget _buildCourseInformation({
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'MATERI PELATIHAN',
              style: TextStyle(
                color: _darkNavy,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: _darkNavy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            description,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // PROGRESS CARD
  Widget _buildProgressCard({
    required num progressPercentage,
    required double progressValue,
    required bool isCompleted,
  }) {
    final Color progressColor = isCompleted ? _ecoGreen : _emeraldGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: _ecoGreen,
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progres Pembelajaran',
                      style: TextStyle(
                        color: _darkNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Terus tingkatkan kemampuan Anda',
                      style: TextStyle(color: _secondaryText, fontSize: 10),
                    ),
                  ],
                ),
              ),

              Text(
                '${progressPercentage.toString()}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 9,
              backgroundColor: const Color(0xFFE9EEF3),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: progressColor,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                isCompleted
                    ? 'Pelatihan berhasil diselesaikan!'
                    : 'Selesaikan materi dan ikuti evaluasi kuis.',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CERTIFICATE BUTTON
  Widget _buildCertificateButton() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7EB),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFB9E8C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.celebration_rounded, color: _ecoGreen, size: 21),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selamat! Pelatihan Selesai',
                  style: TextStyle(
                    color: _darkNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Anda telah menyelesaikan pelatihan ini. '
            'Sertifikat kelulusan dapat dilihat melalui menu berikut.',
            style: TextStyle(color: _secondaryText, fontSize: 11, height: 1.5),
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SertifikatPelatihanScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 19,
              ),
              label: const Text(
                'Lihat Sertifikat Kelulusan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ecoGreen,
                elevation: 0,
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

  // MODULE HEADER
  Widget _buildModuleHeader(int totalModules) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: _darkNavy,
            size: 21,
          ),
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modul & Evaluasi Kuis',
                style: TextStyle(
                  color: _darkNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Pelajari setiap materi secara berurutan',
                style: TextStyle(color: _secondaryText, fontSize: 10),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _primaryYellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalModules Modul',
            style: const TextStyle(
              color: _darkText,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // MODULE CARD
  Widget _buildModuleCard({
    required dynamic module,
    required int index,
    required String? courseVideoUrl,
  }) {
    final String moduleId = module['id'].toString();

    final String moduleTitle = (module['title'] ?? 'Modul ${index + 1}')
        .toString();

    final String duration = (module['duration'] ?? '10 Menit').toString();

    final String? moduleVideoUrl = module['videoUrl']?.toString();

    final bool isDone = _completedModuleIds.contains(moduleId);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFC9EBD0) : const Color(0xFFE8EDF2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _bukaVideoYouTube(moduleVideoUrl ?? courseVideoUrl);
          },
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                // MODULE NUMBER / STATUS
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFE8F7EB)
                        : const Color(0xFFEAF0F8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isDone ? _ecoGreen : _darkNavy,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // MODULE INFORMATION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODUL ${index + 1}',
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        moduleTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: _secondaryText,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // STATUS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7EB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            color: _ecoGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _secondaryText,
                        size: 14,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // EMPTY MODULE STATE
  Widget _buildEmptyModuleState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book_outlined, color: _darkNavy, size: 38),
          SizedBox(height: 10),
          Text(
            'Belum Ada Modul',
            style: TextStyle(
              color: _darkNavy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Modul pembelajaran untuk pelatihan ini '
            'belum tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  // QUIZ BUTTON
  Widget _buildQuizButton(String title) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KuisPelatihanScreen(
                courseId: widget.courseId,
                courseTitle: title,
              ),
            ),
          );

          if (mounted) {
            _fetchCourseDetail();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkNavy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_rounded, color: _primaryYellow, size: 20),
            SizedBox(width: 9),
            Text(
              'Ikuti Kuis Pelatihan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 7),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
          ],
        ),
      ),
    );
  }

  // INFORMATION NOTE
  Widget _buildInformationNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCE5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFF1A3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: _slate, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Pelajari materi yang tersedia dan ikuti kuis '
              'untuk menyelesaikan evaluasi pelatihan.',
              style: TextStyle(color: _slate, fontSize: 10, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // NOT FOUND STATE
  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: _darkNavy,
                size: 42,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Materi Tidak Ditemukan',
              style: TextStyle(
                color: _darkNavy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Data pelatihan tidak tersedia atau gagal dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchCourseDetail,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkNavy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
