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
    ]);

    Map<String, dynamic> data = {};
    if (results[0]['success'] == true && results[0]['data'] != null) {
      data = Map<String, dynamic>.from(results[0]['data']);
      await AppStorage.saveProfile(data);
    } else {
      final localData = await AppStorage.getProfile();
      if (localData != null) data = Map<String, dynamic>.from(localData);
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
      _avatarUrl = _formatImageUrl(rawAvatar);
      _ktpStatus = ktpStat;
      _isLoading = false;
    });
  }

  // --- POPUP KONFIRMASI KELUAR AKUN ---
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
                Navigator.pop(dialogContext); // Tutup dialog
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
      body: SingleChildScrollView(
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
            Container(
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.military_tech, size: 14, color: Colors.black87),
                            SizedBox(width: 4),
                            Text('Level Silver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('876', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4, left: 4),
                        child: Text('/ 1000', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.876,
                      backgroundColor: Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryCyan),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('124 poin menuju Gold', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kartu Statistik Kinerja
            Container(
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pekerjaan Selesai', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          SizedBox(height: 2),
                          Text('426 Tugas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.trending_up, color: AppColors.primaryCyan, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.eco, color: AppColors.primaryCyan, size: 22),
                        SizedBox(height: 12),
                        Text('8,4 Ton', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Material', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 22),
                        SizedBox(height: 12),
                        Text('4,89 / 5', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Rating', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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