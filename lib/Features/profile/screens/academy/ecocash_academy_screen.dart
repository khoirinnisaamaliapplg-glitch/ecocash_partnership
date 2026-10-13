import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';
import 'detail_pelatihan_screen.dart';
import 'sertifikat_pelatihan_screen.dart';

class EcocashAcademyScreen extends StatefulWidget {
  const EcocashAcademyScreen({super.key});

  @override
  State<EcocashAcademyScreen> createState() => _EcocashAcademyScreenState();
}

class _EcocashAcademyScreenState extends State<EcocashAcademyScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  static const Color _navyColor = Color(0xFF0F2C59);

  int _selectedFilterIndex = 0; // 0: Semua, 1: Dalam Proses, 2: Selesai
  bool _isLoading = true;
  List<dynamic> _courses = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAcademyCourses();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] is List) {
          _courses = result['data'];
        }
      });
    }
  }

  List<dynamic> get _filteredCourses {
    return _courses.where((course) {
      final String status = (course['status'] ?? 'NOT_STARTED').toString();
      final String title = (course['title'] ?? '').toString().toLowerCase();
      final bool matchesSearch = title.contains(_searchQuery.toLowerCase());

      if (_selectedFilterIndex == 1) {
        return matchesSearch && (status == 'IN_PROGRESS' || status == 'NOT_STARTED');
      } else if (_selectedFilterIndex == 2) {
        return matchesSearch && status == 'COMPLETED';
      }
      return matchesSearch;
    }).toList();
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'EcoCash Academy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // BARIS PENCARIAN & FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari materi pembelajaran...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip(0, 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Dalam Proses'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Selesai'),
                  ],
                ),
              ],
            ),
          ),

          // LIST MATERI DARI BACKEND
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
                : RefreshIndicator(
                    onRefresh: _fetchCourses,
                    child: _filteredCourses.isEmpty
                        ? const Center(child: Text('Belum ada materi pembelajaran.', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20.0),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = _filteredCourses[index];
                              final String courseId = course['id'].toString();
                              final String title = course['title'] ?? 'Pelatihan EcoCash';
                              final String category = course['category'] ?? 'Modul Pelatihan';
                              final String bannerUrl = course['bannerUrl'] ??
                                  'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60';
                              final num progressPercentage = course['progressPercentage'] ?? 0;
                              final String status = (course['status'] ?? 'NOT_STARTED').toString();
                              final bool isCompleted = status == 'COMPLETED';
                              final bool isNotStarted = status == 'NOT_STARTED';

                              return _buildCourseCard(
                                imageUrl: bannerUrl,
                                title: title,
                                subtitle: category,
                                progressText: '$progressPercentage%',
                                progressValue: progressPercentage / 100.0,
                                isCompleted: isCompleted,
                                isNotStarted: isNotStarted,
                                buttonLabel: isCompleted
                                    ? 'Lihat Sertifikat'
                                    : (isNotStarted ? 'Mulai Belajar' : 'Lanjutkan'),
                                buttonIcon: isCompleted
                                    ? Icons.workspace_premium_outlined
                                    : (isNotStarted ? Icons.play_circle_outline : Icons.arrow_forward),
                                onCardTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPelatihanScreen(courseId: courseId),
                                    ),
                                  );
                                  _fetchCourses();
                                },
                                onPressed: () async {
                                  if (isCompleted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SertifikatPelatihanScreen()),
                                    );
                                  } else {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPelatihanScreen(courseId: courseId),
                                      ),
                                    );
                                    _fetchCourses();
                                  }
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    bool isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navyColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _navyColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String progressText,
    required double progressValue,
    required bool isCompleted,
    bool isNotStarted = false,
    required String buttonLabel,
    required IconData buttonIcon,
    VoidCallback? onCardTap,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isCompleted) ...[
                        const Icon(Icons.check_circle, size: 18, color: AppColors.primaryCyan),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isNotStarted ? 'Belum dimulai' : 'Progres Belajar',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isNotStarted ? AppColors.textSecondary : (isCompleted ? Colors.green : AppColors.primaryCyan),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: const Color(0xFFE8ECEF),
                      valueColor: AlwaysStoppedAnimation(isCompleted ? Colors.green : AppColors.primaryCyan),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(buttonIcon, size: 18, color: Colors.white),
                      label: Text(buttonLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88A8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
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
}