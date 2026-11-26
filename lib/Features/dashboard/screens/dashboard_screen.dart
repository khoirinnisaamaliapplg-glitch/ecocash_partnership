import 'dart:convert';
import 'dart:typed_data';
import 'package:ecocash_partnership/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/app_storage.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/app_loading.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, this.userData = const {}});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;

  // State Data Dashboard & Profil Partner
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _partnerProfileData;
  List<dynamic> _availableJobs = [];
  num _todayMaterialWeight = 0;
  int _completedJobsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// Helper untuk Memformat URL Foto Profil dari API / Localhost / Relative Path
  String? _formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final Uri baseUri = Uri.parse(ApiConstants.baseUrl);
      final Uri imgUri = Uri.parse(url);
      return imgUri.replace(host: baseUri.host, port: baseUri.port).toString();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final String cleanBase = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Memanggil Dashboard, Statistik Material, dan Partner Profile secara paralel
      final results = await Future.wait([
        _apiService.getDashboard(),
        _apiService.getMaterialStatistics(),
        _apiService.getPartnerProfile(),
        _apiService
            .getMyJobs(status: 'COMPLETED')
            .catchError(
              (error) => <String, dynamic>{
                'success': false,
                'data': <dynamic>[],
              },
            ),
      ]);

      if (!mounted) return;

      final dashboardRes = results[0];
      final statsRes = results[1];
      final profileRes = results[2];
      final completedJobsRes = results[3];

      final List completedJobs =
          completedJobsRes['success'] == true &&
              completedJobsRes['data'] is List
          ? completedJobsRes['data'] as List
          : [];

      num weightToday = 0;
      if (statsRes['success'] == true && statsRes['data']?['today'] != null) {
        weightToday = statsRes['data']['today']['totalWeight'] ?? 0;
      }

      Map<String, dynamic> profData = {};
      if (profileRes['success'] == true && profileRes['data'] != null) {
        profData = Map<String, dynamic>.from(profileRes['data']);
        await AppStorage.saveProfile(profData);
      } else {
        final localData = await AppStorage.getProfile();
        if (localData != null) profData = Map<String, dynamic>.from(localData);
      }

      if (dashboardRes['success'] == true) {
        setState(() {
          _dashboardData = dashboardRes['data'];
          _partnerProfileData = profData;
          _availableJobs = dashboardRes['data']?['availableJobsPreview'] ?? [];
          _todayMaterialWeight = weightToday;
          _isLoading = false;
          _completedJobsCount = completedJobs.length;
        });
      } else {
        setState(() {
          _errorMessage =
              dashboardRes['message'] ?? 'Gagal mengambil data dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final localData = await AppStorage.getProfile();
      setState(() {
        if (localData != null)
          _partnerProfileData = Map<String, dynamic>.from(localData);
        _errorMessage = 'Terjadi kesalahan koneksi ke server';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptJob(int jobId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: AppLoading(message: 'Sedang mengambil pekerjaan...', size: 64),
        ),
      ),
    );

    final res = await _apiService.acceptJob(jobId);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan berhasil diambil!'),
          backgroundColor: AppColors.ecoGreen,
        ),
      );
      _fetchDashboardData();
      context.push('/riwayat-pekerjaan');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengambil pekerjaan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Color _getLevelColor(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'SILVER':
        return const Color(0xFF64748B);
      case 'GOLD':
        return const Color(0xFFEAB308);
      case 'BRONZE':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoading(message: 'Menyiapkan dashboard kamu...', size: 76),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _fetchDashboardData,
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile =
        _partnerProfileData ??
        _dashboardData?['partnerProfile'] ??
        _dashboardData?['partner'] ??
        _dashboardData?['profile'] ??
        widget.userData;

    final wallet = _dashboardData?['walletSummary'] ?? {};
    final stats = _dashboardData?['performanceStats'] ?? {};

    final String namaUser =
        profile['name'] ??
        profile['fullName'] ??
        profile['username'] ??
        widget.userData['name'] ??
        widget.userData['nama'] ??
        'Mitra';

    final num monthlyEarnings = wallet['monthlyEarnings'] ?? 0;
    final int jobsCompleted = _completedJobsCount;
    final String level = profile['level'] ?? 'Bronze';
    final int score = profile['score'] ?? 0;
    final int maxScore = profile['maxScore'] ?? 300;
    final double progressValue = maxScore > 0
        ? (score / maxScore).clamp(0.0, 1.0)
        : 0.0;

    // Ekstraksi Foto Profil dari URL Network maupun Base64 (imageBytes)
    final String? rawAvatar =
        profile['avatarUrl'] ??
        profile['avatar'] ??
        profile['photoUrl'] ??
        profile['user']?['avatarUrl'] ??
        widget.userData['avatarUrl'] ??
        widget.userData['avatar'];
    final String? avatarUrl = _formatImageUrl(rawAvatar);

    final String? base64Image =
        profile['imageBytes'] ?? widget.userData['imageBytes'];
    Uint8List? imageBytes;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64Image);
      } catch (_) {
        imageBytes = null;
      }
    }

    String nextLevel = 'Silver';
    if (level.toUpperCase() == 'SILVER') {
      nextLevel = 'Gold';
    } else if (level.toUpperCase() == 'GOLD') {
      nextLevel = 'Maksimal';
    }

    final Color currentLevelColor = _getLevelColor(level);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.darkNavy,
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. BANNER HEADER UTAMA & KARTU PENGHASILAN
                // ==========================================
                Container(
                  width: double.infinity,
                  color: AppColors.primaryYellow,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.two_wheeler_rounded,
                                  color: AppColors.primaryYellow,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'EcoCashPartner',
                                  style: TextStyle(
                                    color: AppColors.primaryYellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: currentLevelColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      level,
                                      style: TextStyle(
                                        color: currentLevelColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Avatar Lingkaran Profil Dinamis
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.darkNavy,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildAvatarWidget(
                                    avatarUrl,
                                    imageBytes,
                                    namaUser,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kartu Banner Ilustrasi
                      Container(
                        width: double.infinity,
                        height: 145,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Gambar ilustrasi digeser ke kanan menggunakan Transform.translate
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: const Offset(35, 0), // Geser gambar ke kanan sejauh 35 pixel
                                  child: Image.asset(
                                    'assets/images/ecocash_partner_banner.png',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.centerRight,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFFE0F2FE),
                                        child: const Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: EdgeInsets.only(right: 20),
                                            child: Icon(
                                              Icons.two_wheeler_rounded,
                                              color: AppColors.darkNavy,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 190,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.85),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      stops: const [0.0, 0.65, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Bagian Text Overlay Banner yang Diperbaiki agar Responsif
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.52, // Batasi area teks maksimal 52% layar
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryYellow,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.eco_rounded,
                                                color: AppColors.primaryDark,
                                                size: 12,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'EcoCash',
                                                style: TextStyle(
                                                  color: AppColors.primaryDark,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Hi, $namaUser! 👋',
                                          maxLines:
                                              2, // Diubah ke 2 baris agar nama panjang otomatis turun ke bawah
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize:
                                                15, // Disesuaikan sedikit agar proporsional
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Pilih, Pilah, Setor!',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryDark
                                                .withOpacity(0.75),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () => context.push(
                                            '/daftar-pekerjaan',
                                            extra: {'fromDashboard': true},
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryDark,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Ambil Tugas',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 2),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Kartu Saldo Penghasilan
                      InkWell(
                        onTap: () => context.push('/detail-penghasilan'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Penghasilan Bulan Ini',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(monthlyEarnings),
                                      style: const TextStyle(
                                        color: AppColors.darkNavy,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.ecoGreen.withOpacity(
                                          0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt_rounded,
                                            color: AppColors.ecoGreen,
                                            size: 12,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Real-time',
                                            style: TextStyle(
                                              color: AppColors.ecoGreen,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildQuickActionButton(
                                    icon: Icons.history_rounded,
                                    label: 'Riwayat',
                                    onTap: () =>
                                        context.push('/riwayat-pekerjaan'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickActionButton(
                                    icon: Icons.insights_rounded,
                                    label: 'Detail',
                                    onTap: () =>
                                        context.push('/detail-penghasilan'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // 2. GRID FITUR SQUIRCLE PASTEL (4 MENU UTAMA)
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSquircleMenuItem(
                          icon: Icons.local_shipping_rounded,
                          label: 'Tugas',
                          bgColor: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF15803D),
                          badge: 'Aktif',
                          badgeColor: const Color(0xFFEF4444),
                          onTap: () => context.push(
                            '/daftar-pekerjaan',
                            extra: {'fromDashboard': true},
                          ),
                        ),
                        _buildSquircleMenuItem(
                          icon: Icons.scale_rounded,
                          label: 'Material',
                          bgColor: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0369A1),
                          badge:
                              '${_todayMaterialWeight.toString().replaceAll('.', ',')}kg',
                          badgeColor: const Color(0xFF0284C7),
                          onTap: () => context.push('/statistik-material'),
                        ),
                        _buildSquircleMenuItem(
                          icon: Icons.receipt_long_rounded,
                          label: 'Riwayat',
                          bgColor: const Color(0xFFF3E8FF),
                          iconColor: const Color(0xFF6B21A8),
                          badge: '$jobsCompleted',
                          badgeColor: const Color(0xFF9333EA),
                          onTap: () => context.push('/riwayat-pekerjaan'),
                        ),
                        _buildSquircleMenuItem(
                          icon: Icons.school_rounded,
                          label: 'Academy',
                          bgColor: const Color(0xFFFCE7F3),
                          iconColor: const Color(0xFFBE185D),
                          badge: 'Kuis',
                          badgeColor: const Color(0xFFDB2777),
                          onTap: () => context.push('/academy'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // 3. KARTU BAR LEVEL SKOR INTERAKTIF
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () => context.push('/skor-partner'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: currentLevelColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentLevelColor.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.military_tech_rounded,
                                    color: currentLevelColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Level $level',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: currentLevelColor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: currentLevelColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  nextLevel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: currentLevelColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Skor Partner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$score / $maxScore',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: currentLevelColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: currentLevelColor.withOpacity(
                                0.15,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                currentLevelColor,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // 4. DAFTAR PEKERJAAN TERSEDIA
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Pekerjaan Tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          if (_availableJobs.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ecoGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_availableJobs.length}',
                                style: const TextStyle(
                                  color: AppColors.ecoGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push(
                          '/daftar-pekerjaan',
                          extra: {'fromDashboard': true},
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: AppColors.darkNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _availableJobs.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada pekerjaan tersedia saat ini',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ..._availableJobs.take(3).map((job) {
                              final machine = job['machine'] ?? {};
                              final int jobId = job['id'];
                              final String rawCode =
                                  job['code'] ?? 'JOB-#$jobId';
                              final String code = rawCode.length > 10
                                  ? '#${rawCode.substring(0, 8).toUpperCase()}'
                                  : rawCode;
                              final String title =
                                  job['title'] ?? 'Penjemputan Sampah';
                              final String address =
                                  machine['placeName'] ??
                                  machine['address'] ??
                                  'Lokasi Penjemputan';
                              final String priority =
                                  job['priority'] ?? 'MEDIUM';
                              final String jobPrice =
                                  job['price'] ??
                                  (job['machineId'] == null
                                      ? 'Rp20.000+'
                                      : 'Rp35.000+');

                              return _buildModernVerticalJobCard(
                                jobId: jobId,
                                code: code,
                                title: title,
                                distance: address,
                                price: jobPrice,
                                priority: priority,
                              );
                            }).toList(),

                            if (_availableJobs.length > 3) ...[
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => context.push(
                                    '/daftar-pekerjaan',
                                    extra: {'fromDashboard': true},
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.darkNavy,
                                    side: BorderSide(
                                      color: AppColors.darkNavy.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    'Lihat ${_availableJobs.length - 3} Pekerjaan Lainnya',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER COMPONENTS ---

  Widget _buildAvatarWidget(
    String? avatarUrl,
    Uint8List? imageBytes,
    String namaUser,
  ) {
    if (imageBytes != null) {
      return Image.memory(imageBytes, fit: BoxFit.cover, width: 36, height: 36);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'M',
              style: const TextStyle(
                color: AppColors.darkNavy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.darkNavy,
              ),
            ),
          );
        },
      );
    }
    return Center(
      child: Text(
        namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'M',
        style: const TextStyle(
          color: AppColors.darkNavy,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkNavy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.darkNavy),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquircleMenuItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    String? badge,
    Color badgeColor = const Color(0xFFEF4444),
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 24)),
                ),
                if (badge != null && badge.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernVerticalJobCard({
    required int jobId,
    required String code,
    required String title,
    required String distance,
    required String price,
    required String priority,
  }) {
    final bool isUrgent = priority == 'HIGH' || priority == 'URGENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 9,
                    color: isUrgent
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.12), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimasi Imbalan',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.ecoGreen,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _acceptJob(jobId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ambil Pekerjaan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
