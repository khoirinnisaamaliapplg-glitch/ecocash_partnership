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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'EcoCash Academy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white),
            tooltip: 'Sertifikat Saya',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SertifikatPelatihanScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // HEADER PROMO / HERO BANNER
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_navyColor, AppColors.primaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primaryCyan.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sertifikasi Mitra Resmi',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tingkatkan Performa & Raih Bonus Reputasi',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.school, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // PENCARIAN & FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari materi pelatihan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
          const SizedBox(height: 12),

          // DAFTAR KURSUS DARI ADMIN
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
                : RefreshIndicator(
                    onRefresh: _fetchCourses,
                    child: _filteredCourses.isEmpty
                        ? const Center(child: Text('Belum ada materi pembelajaran.', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = _filteredCourses[index];
                              final String courseId = course['id'].toString();
                              final String title = course['title'] ?? 'Pelatihan EcoCash';
                              final String category = course['category'] ?? 'SOP Mitra';
                              final String bannerUrl = course['bannerUrl'] ??
                                  'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60';
                              final num progressPercentage = course['progressPercentage'] ?? 0;
                              final String status = (course['status'] ?? 'NOT_STARTED').toString();
                              final bool isCompleted = status == 'COMPLETED';
                              final bool isNotStarted = status == 'NOT_STARTED';

                              return _buildModernCourseCard(
                                imageUrl: bannerUrl,
                                title: title,
                                subtitle: category,
                                progressText: '$progressPercentage%',
                                progressValue: progressPercentage / 100.0,
                                isCompleted: isCompleted,
                                isNotStarted: isNotStarted,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DetailPelatihanScreen(courseId: courseId)),
                                  );
                                  _fetchCourses();
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

  Widget _buildModernCourseCard({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String progressText,
    required double progressValue,
    required bool isCompleted,
    required bool isNotStarted,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 130,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.school, size: 40, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('SELESAI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isNotStarted ? 'Belum Dimulai' : 'Progres Belajar',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(progressText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : AppColors.primaryCyan)),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}