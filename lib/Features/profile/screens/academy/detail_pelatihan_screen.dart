import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';
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

  Future<void> _bukaVideo(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link video tidak tersedia untuk materi ini.')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka link video: $url')),
        );
      }
    }
  }

  Future<void> _completeModule(String moduleId) async {
    final result = await _apiService.completeAcademyModule(widget.courseId, moduleId);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modul berhasil diselesaikan!'), backgroundColor: Colors.green),
        );
        _fetchCourseDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal memperbarui modul'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
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
    final String bannerUrl = _courseDetail!['bannerUrl'] ??
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60';
    final String? courseVideoUrl = _courseDetail!['videoUrl'];
    final num progressPercentage = _courseDetail!['progressPercentage'] ?? 0;
    final bool isCompleted = progressPercentage >= 100;
    final List<dynamic> modules = _courseDetail!['modules'] ?? [];

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
        title: const Text('EcoCash Academy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BANNER PEMUTAR VIDEO (KLIK UNTUK NONTON)
            InkWell(
              onTap: () => _bukaVideo(courseVideoUrl ?? 'https://www.youtube.com'),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      bannerUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, size: 38, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TOMBOL TONTON VIDEO PELATIHAN
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _bukaVideo(courseVideoUrl ?? 'https://www.youtube.com'),
                icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                label: const Text('Tonton Video Pelatihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // BADGE STATUS
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade50 : const Color(0xFFCEF5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isCompleted ? Icons.check_circle : Icons.hourglass_top, size: 14, color: isCompleted ? Colors.green : AppColors.primaryCyan),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? 'Selesai' : 'Dalam Proses',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : AppColors.primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('$progressPercentage% Modul Diselesaikan', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),

            // JUDUL & DESKRIPSI
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navyColor)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 16),

            if (isCompleted)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SertifikatPelatihanScreen()),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 20),
                  label: const Text('Lihat Sertifikat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88A8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // LIST MODUL
            const Text('Kurikulum Pelatihan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor)),
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      onTap: () => _bukaVideo(moduleVideoUrl ?? courseVideoUrl ?? 'https://www.youtube.com'),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFFCEF5F5) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isDone ? Icons.check : Icons.play_arrow, size: 16, color: isDone ? AppColors.primaryCyan : Colors.grey),
                      ),
                      title: Text(moduleTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.access_time, size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      trailing: isDone
                          ? const Text('Selesai', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))
                          : ElevatedButton(
                              onPressed: () => _completeModule(moduleId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88A8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Selesaikan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}