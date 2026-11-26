import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/app_storage.dart';
import '../../../services/api_service.dart';
import 'vehicles/vehicle_list_screen.dart';
import 'documents/dokumen_identitas_screen.dart';
import 'academy/ecocash_academy_screen.dart';
import 'security/keamanan_screen.dart';
import 'notifications/notifikasi_screen.dart';
import '../../../core/widgets/app_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _impactData = {};

  bool _isLoading = true;
  String? _avatarUrl;
  String _ktpStatus = 'NOT_UPLOADED';

  static const Color _navy = AppColors.darkNavy;
  static const Color _yellow = AppColors.primaryYellow;
  static const Color _green = AppColors.ecoGreen;
  static const Color _background = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _text = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.cardBorder;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  String? _formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final Uri baseUri = Uri.parse(ApiConstants.baseUrl);
      final Uri imgUri = Uri.parse(url);

      return imgUri.replace(host: baseUri.host, port: baseUri.port).toString();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final String cleanBase = ApiConstants.baseUrl.replaceAll('/api/v1', '');

    return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
  }

  Future<void> _loadProfileData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _apiService.getPartnerProfile(),
        _apiService.getMyDocuments(),
        _apiService.getDashboard(),
        _apiService.getMyImpact(),
      ]);

      Map<String, dynamic> data = {};

      if (results[0]['success'] == true && results[0]['data'] != null) {
        data = Map<String, dynamic>.from(results[0]['data']);
        await AppStorage.saveProfile(data);
      } else {
        final localData = await AppStorage.getProfile();

        if (localData != null) {
          data = Map<String, dynamic>.from(localData);
        }
      }

      Map<String, dynamic> dashData = {};

      if (results[2]['success'] == true && results[2]['data'] != null) {
        dashData = Map<String, dynamic>.from(results[2]['data']);
      }

      Map<String, dynamic> impData = {};

      if (results[3]['success'] == true && results[3]['data'] != null) {
        impData = Map<String, dynamic>.from(results[3]['data']);
      }

      String ktpStat = 'NOT_UPLOADED';

      if (results[1]['success'] == true && results[1]['data'] is List) {
        final docs = results[1]['data'] as List;

        final ktpDoc = docs.firstWhere(
          (doc) =>
              (doc['documentType'] ?? '').toString().toUpperCase() == 'KTP',
          orElse: () => null,
        );

        if (ktpDoc != null &&
            ktpDoc['fileUrl'] != null &&
            (ktpDoc['fileUrl'] as String).isNotEmpty) {
          ktpStat = (ktpDoc['status'] ?? 'PENDING').toString().toUpperCase();
        }
      }

      if (!mounted) return;

      final String? rawAvatar =
          data['avatarUrl'] ?? data['avatar'] ?? data['user']?['avatarUrl'];

      setState(() {
        _profileData = data;
        _dashboardData = dashData;
        _impactData = impData;
        _avatarUrl = _formatImageUrl(rawAvatar);
        _ktpStatus = ktpStat;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat data profil. Silakan coba lagi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // HELPER DATA
  // =========================================================

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
    }

    return fallback;
  }

  Widget _buildAvatar({required double size, Uint8List? imageBytes}) {
    Widget fallback() {
      return Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return fallback();
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border.withOpacity(0.65), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: _navy.withOpacity(0.035),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // DEKORASI KARTU PROFIL
  // =========================================================

  Widget _buildProfileDecoration({
    required String asset,
    required double width,
    double? height,
  }) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileCardDecoration() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Bentuk organik kuning di kanan atas
              Positioned(
                top: -58,
                right: -42,
                child: Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    color: _yellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Bentuk lingkaran lembut di kanan bawah
              Positioned(
                bottom: -65,
                right: 55,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Daun dekoratif

              // Simbol recycle
              Positioned(
                top: 0,
                right: 0,
                child: _buildProfileDecoration(
                  asset: 'assets/images/profile/recycle.png',
                  width: 200,
                ),
              ),

              // Titik dekoratif
              Positioned(
                top: 115,
                right: 24,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _yellow.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STATUS KTP
  // =========================================================

  Widget _buildStatusBadge() {
    String label;
    Color color;
    Color background;
    IconData icon;

    if (_ktpStatus == 'APPROVED' || _ktpStatus == 'VERIFIED') {
      label = 'Terverifikasi';
      color = _green;
      background = const Color(0xFFE8F5E9);
      icon = Icons.verified_rounded;
    } else if (_ktpStatus == 'PENDING' || _ktpStatus == 'WAITING') {
      label = 'Menunggu Verifikasi';
      color = const Color(0xFFB78103);
      background = const Color(0xFFFFF7DF);
      icon = Icons.schedule_rounded;
    } else if (_ktpStatus == 'REJECTED') {
      label = 'Verifikasi Ditolak';
      color = Colors.redAccent;
      background = const Color(0xFFFFEEEE);
      icon = Icons.cancel_rounded;
    } else {
      label = 'Belum Terverifikasi';
      color = const Color(0xFFB78103);
      background = const Color(0xFFFFF7DF);
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun EcoCash Partner ini?',
            style: TextStyle(fontSize: 13, color: _muted, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await AppStorage.saveToken('');
                await AppStorage.saveUserData({});
                await AppStorage.saveProfile({});

                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ya, Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // DIALOG MATERIAL
  // =========================================================

  void _showMaterialInfoDialog(BuildContext context, String formattedMaterial) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.eco_rounded, color: _green),
              SizedBox(width: 9),
              Text(
                'Akumulasi Material',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Terkumpul',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedMaterial,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: _green, size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Otomatis bertambah setiap Anda menyelesaikan tugas penjemputan harian.',
                      style: TextStyle(fontSize: 12, color: _text, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Tutup',
                style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // KOMPONEN KARTU STATISTIK
  // =========================================================

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color iconBackground,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(radius: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(height: 13),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? iconBackground,
    bool showBadge = false,
  }) {
    final Color actualIconColor = iconColor ?? _navy;
    final Color actualBackground = iconBackground ?? const Color(0xFFF1F4F8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: actualBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: actualIconColor, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showBadge) ...[
                    const SizedBox(width: 7),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB5C0),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      height: 1,
      thickness: 0.7,
      indent: 67,
      endIndent: 15,
      color: _border,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final String name =
        _profileData['name'] ??
        _profileData['fullName'] ??
        _profileData['username'] ??
        'Mitra EcoCash';

    final String? base64Image = _profileData['imageBytes'];

    Uint8List? imageBytes;

    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64Image);
      } catch (_) {
        imageBytes = null;
      }
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: AppLoading(message: 'Menyiapkan profil kamu...', size: 76),
      );
    }

    final partnerProfile = _dashboardData['partnerProfile'] ?? _profileData;

    final stats = _dashboardData['performanceStats'] ?? {};

    final int score = (partnerProfile['score'] as num?)?.toInt() ?? 0;
    final String level = partnerProfile['level'] ?? 'Bronze';
    final int maxScore = (partnerProfile['maxScore'] as num?)?.toInt() ?? 300;
    final Color currentLevelColor;

    switch (level.trim().toUpperCase()) {
      case 'SILVER':
        currentLevelColor = const Color(0xFF8996A5);
        break;

      case 'GOLD':
        currentLevelColor = const Color(0xFFD4A017);
        break;

      case 'BRONZE':
      default:
        currentLevelColor = const Color(0xFFB77945);
        break;
    }

    String nextLevel = 'Silver';

    if (level.toUpperCase() == 'SILVER') {
      nextLevel = 'Gold';
    } else if (level.toUpperCase() == 'GOLD') {
      nextLevel = 'Maksimal';
    }

    final int remainingPoints = (maxScore - score).clamp(0, maxScore);

    final double progressValue = maxScore > 0
        ? (score / maxScore).clamp(0.0, 1.0)
        : 0.0;

    final int totalJobs = (stats['totalJobsCompleted'] as num?)?.toInt() ?? 0;

    final rawWeight =
        _impactData['totalMaterialKg'] ?? stats['totalWeightCollectedKg'];

    final double totalWeightKg = _toDouble(rawWeight);

    final double rating = _toDouble(stats['rating'], fallback: 4.89);

    final String formattedMaterial = totalWeightKg >= 1000
        ? '${(totalWeightKg / 1000).toStringAsFixed(1).replaceAll('.', ',')} Ton'
        : '${totalWeightKg.toStringAsFixed(1).replaceAll('.', ',')} kg';

    final String profileId = _profileData['id']?.toString() ?? 'ECO-PA-001928';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _navy,
          backgroundColor: _yellow,
          onRefresh: _loadProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP BAR MINIMALIS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AKUN SAYA',
                          style: TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Profil Partner',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: _surface,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotifikasiScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: _yellow,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // KARTU IDENTITAS PROFIL
                Container(
                  width: double.infinity,
                  decoration: _cardDecoration(radius: 20),
                  child: Stack(
                    children: [
                      // Dekorasi latar
                      _buildProfileCardDecoration(),

                      // Konten profil
                      Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // FOTO PROFIL
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: _yellow,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _navy.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _buildAvatar(
                                          size: 64,
                                          imageBytes: imageBytes,
                                        ),
                                      ),
                                    ),

                                    Container(
                                      width: 23,
                                      height: 23,
                                      decoration: BoxDecoration(
                                        color: _yellow,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.eco_rounded,
                                        size: 13,
                                        color: _navy,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),

                                // INFORMASI IDENTITAS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _navy,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.badge_outlined,
                                            color: _muted,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              profileId,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: _muted,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 9),

                                      _buildStatusBadge(),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 19),

                            // PEMBATAS
                            Container(
                              height: 1,
                              color: _border.withValues(alpha: 0.75),
                            ),

                            const SizedBox(height: 15),

                            // INFORMASI DAN TOMBOL EDIT
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Informasi akun',
                                        style: TextStyle(
                                          color: _navy,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Pastikan data profil selalu terbaru.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await context.push(
                                      '/edit-profile',
                                    );

                                    if (!mounted) return;

                                    if (result == true) {
                                      _loadProfileData();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Edit Profil',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _yellow,
                                    foregroundColor: _navy,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
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

                const SizedBox(height: 24),

                // SKOR PARTNER
                _sectionHeading(
                  'Performa Partner',
                  subtitle: 'Pantau perkembangan dan pencapaian Anda.',
                ),

                InkWell(
                  onTap: () => context.push('/skor-partner'),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: currentLevelColor.withValues(alpha: 0.30),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentLevelColor.withValues(alpha: 0.07),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEVEL PARTNER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.military_tech_rounded,
                                  color: currentLevelColor,
                                  size: 25,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Level $level',
                                  style: TextStyle(
                                    color: currentLevelColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: currentLevelColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                nextLevel == 'Maksimal'
                                    ? 'Level Maksimal'
                                    : 'Menuju $nextLevel',
                                style: TextStyle(
                                  color: currentLevelColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // INFORMASI SKOR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Skor Partner',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$score',
                                    style: TextStyle(
                                      color: currentLevelColor,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / $maxScore poin',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 11),

                        // PROGRESS BAR
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progressValue),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor: currentLevelColor.withValues(
                                  alpha: 0.13,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  currentLevelColor,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 13),

                        // INFORMASI KEMAJUAN
                        Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              color: currentLevelColor,
                              size: 15,
                            ),
                            const SizedBox(width: 7),

                            Expanded(
                              child: Text(
                                remainingPoints > 0
                                    ? '$remainingPoints poin lagi menuju $nextLevel'
                                    : 'Selamat! Level Anda sudah maksimal.',
                                style: TextStyle(
                                  color: currentLevelColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: currentLevelColor.withValues(alpha: 0.65),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(height: 24),

                // RINGKASAN KINERJA
                _sectionHeading(
                  'Ringkasan Kinerja',
                  subtitle: 'Kontribusi Anda bersama EcoCash.',
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.assignment_turned_in_rounded,
                        value: '$totalJobs',
                        label: 'Tugas Selesai',
                        iconColor: const Color(0xFF15803D),
                        iconBackground: const Color(0xFFDCFCE7),
                        onTap: () {
                          context.push('/riwayat-pekerjaan');
                        },
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.eco_rounded,
                        value: formattedMaterial,
                        label: 'Material Terkumpul',
                        iconColor: const Color(0xFF15803D),
                        iconBackground: const Color(0xFFDCFCE7),
                        onTap: () {
                          _showMaterialInfoDialog(context, formattedMaterial);
                        },
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.star_rounded,
                        value: rating.toStringAsFixed(2),
                        label: 'Rating',
                        iconColor: const Color(0xFFB78103),
                        iconBackground: const Color(0xFFFFF4CC),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // MENU AKUN
                _sectionHeading(
                  'Akun & Pengaturan',
                  subtitle: 'Kelola kebutuhan akun dan preferensi Anda.',
                ),

                Container(
                  decoration: _cardDecoration(radius: 18),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.account_balance_outlined,
                        title: 'Akun Bank',
                        iconColor: const Color(0xFF0369A1),
                        iconBackground: const Color(0xFFE0F2FE),
                        onTap: () {
                          context.push('/akun-bank');
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Dokumen Identitas',
                        iconColor: const Color(0xFF6B21A8),
                        iconBackground: const Color(0xFFF3E8FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DokumenIdentitasScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.school_outlined,
                        title: 'EcoCash Academy',
                        iconColor: const Color(0xFFBE185D),
                        iconBackground: const Color(0xFFFCE7F3),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EcocashAcademyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.emoji_events_outlined,
                        title: 'Dampak Saya',
                        iconColor: const Color(0xFF15803D),
                        iconBackground: const Color(0xFFDCFCE7),
                        onTap: () {
                          context.push('/dampak-saya');
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.directions_car_outlined,
                        title: 'Kendaraan',
                        iconColor: const Color(0xFF0369A1),
                        iconBackground: const Color(0xFFE0F2FE),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VehicleListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.security_outlined,
                        title: 'Keamanan',
                        iconColor: const Color(0xFFB45309),
                        iconBackground: const Color(0xFFFFEDD5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KeamananScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        iconColor: const Color(0xFF9333EA),
                        iconBackground: const Color(0xFFF3E8FF),
                        showBadge: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotifikasiScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuDivider(),

                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan',
                        iconColor: _navy,
                        iconBackground: const Color(0xFFF1F4F8),
                        onTap: () {
                          context.push('/pengaturan');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // KELUAR AKUN
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded, size: 17),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.2),
                      ),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Center(
                  child: Text(
                    'EcoCash Partner',
                    style: TextStyle(
                      color: Color(0xFFADB5C0),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
