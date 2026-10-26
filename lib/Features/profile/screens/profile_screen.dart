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

    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final String cleanBase = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

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
      if (localData != null) data = Map<String, dynamic>.from(localData);
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
        (doc) => (doc['documentType'] ?? '').toString().toUpperCase() == 'KTP',
        orElse: () => null,
      );
      if (ktpDoc != null && ktpDoc['fileUrl'] != null && (ktpDoc['fileUrl'] as String).isNotEmpty) {
        ktpStat = (ktpDoc['status'] ?? 'PENDING').toString().toUpperCase();
      }
    }

    if (!mounted) return;

    final String? rawAvatar = data['avatarUrl'] ?? data['avatar'] ?? data['user']?['avatarUrl'];

    setState(() {
      _profileData = data;
      _dashboardData = dashData;
      _impactData = impData;
      _avatarUrl = _formatImageUrl(rawAvatar);
      _ktpStatus = ktpStat;
      _isLoading = false;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Konfirmasi Keluar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun EcoCash Partner ini?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
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
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Ya, Keluar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG INTERAKTIF INFORMASI MATERIAL ---
  void _showMaterialInfoDialog(BuildContext context, String formattedMaterial) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.eco, color: AppColors.primaryCyan),
              SizedBox(width: 10),
              Text(
                'Akumulasi Material',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Terkumpul:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      formattedMaterial,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Otomatis bertambah setiap Anda menyelesaikan tugas penjemputan harian.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
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
                style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color color;
    IconData icon;

    if (_ktpStatus == 'APPROVED' || _ktpStatus == 'VERIFIED') {
      label = 'Terverifikasi';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (_ktpStatus == 'PENDING' || _ktpStatus == 'WAITING') {
      label = 'Menunggu Verifikasi';
      color = Colors.blue;
      icon = Icons.hourglass_top;
    } else if (_ktpStatus == 'REJECTED') {
      label = 'Verifikasi Ditolak';
      color = Colors.redAccent;
      icon = Icons.cancel;
    } else {
      label = 'Belum Terverifikasi';
      color = const Color(0xFFB78103);
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = _profileData['name'] ??
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    final partnerProfile = _dashboardData['partnerProfile'] ?? _profileData;
    final stats = _dashboardData['performanceStats'] ?? {};

    final int score = partnerProfile['score'] ?? 0;
    final String level = partnerProfile['level'] ?? 'Bronze';
    final int maxScore = partnerProfile['maxScore'] ?? 300;

    String nextLevel = 'Silver';
    if (level.toUpperCase() == 'SILVER') {
      nextLevel = 'Gold';
    } else if (level.toUpperCase() == 'GOLD') {
      nextLevel = 'Maksimal';
    }

    final int remainingPoints = (maxScore - score).clamp(0, maxScore);
    final double progressValue = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;

    final int totalJobs = stats['totalJobsCompleted'] ?? 0;

    // --- PARSING AMAN DATA MATERIAL & RATING ---
    final rawWeight = _impactData['totalMaterialKg'] ?? stats['totalWeightCollectedKg'];
    double totalWeightKg = 0.0;
    if (rawWeight is num) {
      totalWeightKg = rawWeight.toDouble();
    } else if (rawWeight is String) {
      totalWeightKg = double.tryParse(rawWeight.replaceAll(',', '.')) ?? 0.0;
    }

    final rawRating = stats['rating'];
    double rating = 4.89;
    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String) {
      rating = double.tryParse(rawRating.replaceAll(',', '.')) ?? 4.89;
    }

    final String formattedMaterial = totalWeightKg >= 1000
        ? '${(totalWeightKg / 1000).toStringAsFixed(1).replaceAll('.', ',')} Ton'
        : '${totalWeightKg.toStringAsFixed(1).replaceAll('.', ',')} kg';

    Widget avatarWidget(double size) {
      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
        );
      }
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        return Image.network(
          _avatarUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        );
      }
      return Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: ClipOval(child: avatarWidget(32)),
            ),
            const SizedBox(width: 10),
            Text(
              'Halo, $name',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: AppColors.primaryCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil Partner',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola akun dan pantau pencapaian Anda.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Kartu Profil Utama
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryCyan,
                        border: Border.all(color: AppColors.primaryCyan, width: 2),
                      ),
                      child: ClipOval(child: avatarWidget(72)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profileData['id'] != null ? 'ID: ${_profileData['id']}' : 'ID: ECO-PA-001928',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),

                    _buildStatusBadge(),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await context.push('/edit-profile');
                          if (result == true) {
                            _loadProfileData();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryCyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Edit Profil', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Skor Partner
              InkWell(
                onTap: () => context.push('/skor-partner'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Skor Partner', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.military_tech, size: 14, color: Colors.black87),
                                const SizedBox(width: 4),
                                Text(
                                  'Level $level',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$score', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 4),
                            child: Text('/ $maxScore', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: const Color(0xFFE0E0E0),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primaryCyan),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          remainingPoints > 0 ? '$remainingPoints poin menuju $nextLevel' : 'Selamat! Level Anda sudah maksimal',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Statistik Kinerja
              InkWell(
                onTap: () => context.push('/riwayat-pekerjaan'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pekerjaan Selesai', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text('$totalJobs Tugas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.trending_up, color: AppColors.primaryCyan, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      // --- PENYESUAIAN ONTAP MATERIAL: POPUP INFO INTERAKTIF ---
                      onTap: () => _showMaterialInfoDialog(context, formattedMaterial),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.eco, color: AppColors.primaryCyan, size: 22),
                            const SizedBox(height: 12),
                            Text(formattedMaterial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            const Text('Material', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 22),
                          const SizedBox(height: 12),
                          Text(
                            '${rating.toStringAsFixed(2).replaceAll('.', ',')} / 5',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          const Text('Rating', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu Pengaturan
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.account_balance_outlined, 'Akun Bank', () {
                        context.push('/akun-bank');
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.description_outlined, 'Dokumen', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DokumenIdentitasScreen()),
                        );
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.school_outlined, 'EcoCash Academy', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EcocashAcademyScreen()),
                        );
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.emoji_events_outlined, 'Dampak saya', () {
                        context.push('/dampak-saya');
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.directions_car_outlined, 'Kendaraan', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VehicleListScreen()),
                        );
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.security_outlined, 'Keamanan', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const KeamananScreen()),
                        );
                      }),
                      _buildDivider(),
                      _buildMenuItemWithBadge(Icons.notifications_outlined, 'Notifikasi', true, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
                        );
                      }),
                      _buildDivider(),
                      _buildMenuItem(Icons.settings_outlined, 'Pengaturan', () {
                        context.push('/pengaturan');
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Keluar Akun dengan Popup Dialog
              Center(
                child: TextButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text('Keluar Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildMenuItemWithBadge(IconData icon, String title, bool hasBadge, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          if (hasBadge) ...[
            const SizedBox(width: 8),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ]
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 56, endIndent: 16);
  }
}