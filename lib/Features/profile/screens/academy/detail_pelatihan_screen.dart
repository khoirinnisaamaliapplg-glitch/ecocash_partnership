import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';
import 'kuis_pelatihan_screen.dart';
import 'sertifikat_pelatihan_screen.dart';

class DetailPelatihanScreen extends StatefulWidget {
  final String courseId;

  const DetailPelatihanScreen({super.key, required this.courseId});

  @override
  State<DetailPelatihanScreen> createState() => _DetailPelatihanScreenState();
}

class _DetailPelatihanScreenState extends State<DetailPelatihanScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  static const Color _navyColor = Color(0xFF0F2C59);

  bool _isLoading = true;
  Map<String, dynamic>? _courseDetail;
  List<dynamic> _completedModuleIds = [];

  @override
  void initState() {
    super.initState();
    _fetchCourseDetail();
  }

  Future<void> _fetchCourseDetail() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAcademyCourseById(widget.courseId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          _courseDetail = result['data'];
          _completedModuleIds = _courseDetail?['completedModuleIds'] ?? [];
        }
      });
    }
  }

  // Ekstrak ID Video YouTube dari URL Admin
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

  Future<void> _bukaVideoYouTube(String? url) async {
    final String targetUrl = url ?? 'https://www.youtube.com';
    final Uri uri = Uri.parse(targetUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka video: $targetUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(backgroundColor: AppColors.primaryCyan, title: const Text('EcoCash Academy')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    if (_courseDetail == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primaryCyan),
        body: const Center(child: Text('Materi pelatihan tidak ditemukan.')),
      );
    }

    final String title = _courseDetail!['title'] ?? 'Detail Pelatihan';
    final String description = _courseDetail!['description'] ?? 'Tidak ada deskripsi.';
    final String? courseVideoUrl = _courseDetail!['videoUrl'];
    final String? youtubeThumb = _getYouTubeThumbnail(courseVideoUrl);
    final String bannerUrl = youtubeThumb ??
        _courseDetail!['bannerUrl'] ??
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60';

    final num progressPercentage = _courseDetail!['progressPercentage'] ?? 0;
    final bool isCompleted = progressPercentage >= 100;
    final List<dynamic> modules = _courseDetail!['modules'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('EcoCash Academy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PLAYER / BANNER VIDEO YOUTUBE
            InkWell(
              onTap: () => _bukaVideoYouTube(courseVideoUrl),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      bannerUrl,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 190,
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.red)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TOMBOL PUTAR VIDEO YOUTUBE
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _bukaVideoYouTube(courseVideoUrl),
                icon: const Icon(Icons.smart_display_rounded, color: Colors.white, size: 22),
                label: const Text('Putar Video Pembelajaran (YouTube)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // INFORMASI KURIKULUM
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navyColor)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 20),

            // TOMBOL SERTIFIKAT JIKA SELESAI
            if (isCompleted) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SertifikatPelatihanScreen()),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 20),
                  label: const Text('Lihat Sertifikat Kelulusan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // LIST MODUL & KUIS
            const Text('Modul & Evaluasi Kuis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor)),
            const SizedBox(height: 12),

            if (modules.isEmpty)
              const Text('Belum ada modul untuk pelatihan ini.', style: TextStyle(color: AppColors.textSecondary))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final module = modules[index];
                  final String moduleId = module['id'].toString();
                  final String moduleTitle = module['title'] ?? 'Modul ${index + 1}';
                  final String duration = module['duration'] ?? '10 Menit';
                  final String? moduleVideoUrl = module['videoUrl'];
                  final bool isDone = _completedModuleIds.contains(moduleId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: ListTile(
                      onTap: () => _bukaVideoYouTube(moduleVideoUrl ?? courseVideoUrl),
                      leading: Icon(
                        isDone ? Icons.check_circle : Icons.play_circle_fill,
                        color: isDone ? Colors.green : AppColors.primaryCyan,
                        size: 28,
                      ),
                      title: Text(moduleTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      trailing: isDone
                          ? const Text('Selesai', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))
                          : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // TOMBOL IKUTI KUIS (MANDATORI SERTIFIKAT)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
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
                  _fetchCourseDetail();
                },
                icon: const Icon(Icons.assignment_outlined, color: Colors.white),
                label: const Text('Ikuti Kuis Pelatihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}