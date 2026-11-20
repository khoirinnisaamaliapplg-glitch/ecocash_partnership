import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/api_service.dart';
import 'detail_pelatihan_screen.dart';
import 'sertifikat_pelatihan_screen.dart';
import '../../../../core/widgets/app_loading.dart';

class EcocashAcademyScreen extends StatefulWidget {
  const EcocashAcademyScreen({super.key});

  @override
  State<EcocashAcademyScreen> createState() => _EcocashAcademyScreenState();
}

class _EcocashAcademyScreenState extends State<EcocashAcademyScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final TextEditingController _searchController = TextEditingController();

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

  // PENGATURAN GAMBAR BELAJAR
  static const double _belajarImageWidth = 350;
  static const double _belajarImageOpacity = 0.89;
  static const double _belajarImageLeft = 150;
  static const double _belajarImageTop = -15;
  static const double _belajarImageBottom = -15;

  int _selectedFilterIndex = 0;
  bool _isLoading = true;

  List<dynamic> _courses = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final result = await _apiService.getAcademyCourses();

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result['success'] == true && result['data'] is List) {
        _courses = result['data'];
      }
    });
  }

  List<dynamic> get _filteredCourses {
    return _courses.where((course) {
      final String status = (course['status'] ?? 'NOT_STARTED').toString();

      final String title = (course['title'] ?? '').toString().toLowerCase();

      final bool matchesSearch = title.contains(_searchQuery.toLowerCase());

      if (_selectedFilterIndex == 1) {
        return matchesSearch &&
            (status == 'IN_PROGRESS' || status == 'NOT_STARTED');
      }

      if (_selectedFilterIndex == 2) {
        return matchesSearch && status == 'COMPLETED';
      }

      return matchesSearch;
    }).toList();
  }

  int get _completedCount {
    return _courses.where((course) {
      return course['status'] == 'COMPLETED';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _ecoGreen,
              onRefresh: _fetchCourses,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroBanner(),
                          const SizedBox(height: 20),
                          _buildSectionTitle(
                            'Perjalanan Belajar',
                            'Pantau perkembangan pelatihan Anda',
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            'Temukan Pelatihan',
                            'Pilih materi untuk meningkatkan kemampuan',
                          ),
                          const SizedBox(height: 14),
                          _buildSearchField(),
                          const SizedBox(height: 16),
                          _buildFilterSection(),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoading(
                        message: 'Menyiapkan materi pelatihan kamu...',
                        size: 76,
                      ),
                    )
                  else if (_filteredCourses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final course = _filteredCourses[index];

                          return _buildCourseCard(course);
                        }, childCount: _filteredCourses.length),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
        'EcoCash Academy',
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
            size: 24,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // HERO BANNER

  // HERO BANNER
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _darkNavy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // GAMBAR BELAJAR SEBAGAI BACKGROUND DEKORASI
          Positioned(
            left: _belajarImageLeft,
            top: _belajarImageTop,
            bottom: _belajarImageBottom,
            child: IgnorePointer(
              child: Opacity(
                opacity: _belajarImageOpacity,
                child: Image.asset(
                  'assets/images/belajar.png',
                  width: _belajarImageWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // IKON DEKORASI KANAN ATAS
          Positioned(
            right: -15,
            top: -18,
            child: Icon(
              Icons.school_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),

          // KONTEN TEKS BANNER
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryYellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ECOCASH LEARNING',
                        style: TextStyle(
                          color: _darkText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Tingkatkan Skill,\nRaih Peluang Lebih Besar!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ikuti pelatihan dan tingkatkan kualitas '
                      'sebagai mitra EcoCash.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _darkNavy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  // SUMMARY CARD
  Widget _buildSummaryCard() {
    final int total = _courses.length;
    final int completed = _completedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            icon: Icons.menu_book_rounded,
            value: total.toString(),
            label: 'Total Materi',
            color: _darkNavy,
            background: const Color(0xFFEAF0F8),
          ),
          Container(width: 1, height: 43, color: const Color(0xFFE8EDF2)),
          _buildSummaryItem(
            icon: Icons.check_circle_rounded,
            value: completed.toString(),
            label: 'Selesai',
            color: _ecoGreen,
            background: const Color(0xFFE8F7EB),
          ),
          Container(width: 1, height: 43, color: const Color(0xFFE8EDF2)),
          _buildSummaryItem(
            icon: Icons.pending_actions_rounded,
            value: (total - completed).toString(),
            label: 'Belum Selesai',
            color: const Color(0xFFB49A00),
            background: const Color(0xFFFFF9CC),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _darkNavy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH FIELD
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: const TextStyle(color: _darkText, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari materi pelatihan...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _darkNavy,
            size: 21,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _secondaryText,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // FILTER
  Widget _buildFilterSection() {
    final filters = ['Semua', 'Dalam Proses', 'Selesai'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final bool selected = _selectedFilterIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                setState(() => _selectedFilterIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? _darkNavy : _surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? _darkNavy : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _primaryYellow,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      filters[index],
                      style: TextStyle(
                        color: selected ? Colors.white : _secondaryText,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // COURSE CARD
  Widget _buildCourseCard(dynamic course) {
    final String courseId = course['id'].toString();
    final String title = (course['title'] ?? 'Pelatihan EcoCash').toString();
    final String category = (course['category'] ?? 'SOP Mitra').toString();

    final String bannerUrl =
        (course['bannerUrl'] ??
                'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&auto=format&fit=crop&q=60')
            .toString();

    final num progressPercentage =
        num.tryParse((course['progressPercentage'] ?? 0).toString()) ?? 0;

    final double progressValue = (progressPercentage.toDouble() / 100).clamp(
      0.0,
      1.0,
    );

    final String status = (course['status'] ?? 'NOT_STARTED').toString();

    final bool isCompleted = status == 'COMPLETED';
    final bool isNotStarted = status == 'NOT_STARTED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE9EEF3)),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPelatihanScreen(courseId: courseId),
              ),
            );

            if (mounted) {
              _fetchCourses();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COURSE IMAGE
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                    child: Image.network(
                      bannerUrl,
                      width: double.infinity,
                      height: 155,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 155,
                          color: const Color(0xFFEAF0F8),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 45,
                            color: _darkNavy,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _darkNavy.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildStatusBadge(isCompleted, isNotStarted),
                  ),
                ],
              ),

              // COURSE INFORMATION
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.auto_stories_rounded,
                              size: 15,
                              color: isCompleted ? _ecoGreen : _darkNavy,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCompleted
                                  ? 'Pelatihan Selesai'
                                  : isNotStarted
                                  ? 'Belum Dimulai'
                                  : 'Progres Belajar',
                              style: const TextStyle(
                                color: _secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${progressPercentage.toString()}%',
                          style: TextStyle(
                            color: isCompleted ? _ecoGreen : _darkNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE9EEF3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? _ecoGreen : _emeraldGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Text(
                          'Lihat Materi',
                          style: TextStyle(
                            color: _darkNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _primaryYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: _darkText,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STATUS BADGE
  Widget _buildStatusBadge(bool isCompleted, bool isNotStarted) {
    final Color color = isCompleted
        ? _ecoGreen
        : isNotStarted
        ? _slate
        : _darkNavy;

    final String label = isCompleted
        ? 'SELESAI'
        : isNotStarted
        ? 'BELUM DIMULAI'
        : 'BERLANGSUNG';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
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
                size: 42,
                color: _darkNavy,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Materi Belum Tersedia',
              style: TextStyle(
                color: _darkNavy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ditemukan materi dengan kata kunci tersebut.'
                  : 'Belum ada materi pelatihan yang dapat ditampilkan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilterIndex = 0;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Pencarian'),
              style: TextButton.styleFrom(foregroundColor: _darkNavy),
            ),
          ],
        ),
      ),
    );
  }
}
