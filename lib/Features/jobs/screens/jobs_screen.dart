import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/app_storage.dart';
import '../../../services/api_service.dart';
import '../../../services/job_socket_service.dart';

class JobsScreen extends StatefulWidget {
  final bool isFromDashboard;

  const JobsScreen({super.key, this.isFromDashboard = false});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final JobSocketService _socketService = JobSocketService.instance;
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<JobSocketEvent>? _socketSub;
  String _selectedStatusTab = 'Tersedia';
  String _selectedCategoryFilter = 'Semua';

  List<dynamic> _jobsList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initLiveSocket();
    _fetchJobs();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLiveSocket() async {
    await _socketService.connect();
    _socketSub = _socketService.events.listen((event) {
      if (!mounted) return;

      if (event.type == 'job:created') {
        if (_selectedStatusTab == 'Tersedia') {
          _fetchJobs(silent: true);
          _showLiveToast('Tugas penjemputan baru tersedia!', AppColors.ecoGreen);
        }
      } else if (event.type == 'job:claimed') {
        final dynamic claimedId = event.payload['jobId'];
        if (_selectedStatusTab == 'Tersedia' && claimedId != null) {
          setState(() {
            _jobsList.removeWhere((j) => j['id'].toString() == claimedId.toString());
          });
        } else {
          _fetchJobs(silent: true);
        }
      } else if (event.type == 'job:cancelled' || event.type == 'job:status') {
        _fetchJobs(silent: true);
      }
    });
  }

  void _showLiveToast(String message, Color accentColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.bolt_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _fetchJobs({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    double? courierLat;
    double? courierLng;
    final profile = await AppStorage.getProfile();
    if (profile != null) {
      courierLat = double.tryParse((profile['latitude'] ?? profile['lat'] ?? '').toString());
      courierLng = double.tryParse((profile['longitude'] ?? profile['lng'] ?? '').toString());
    }

    Map<String, dynamic> result;
    if (_selectedStatusTab == 'Tersedia') {
      result = await _apiService.getAvailableJobs(lat: courierLat, lng: courierLng);
    } else if (_selectedStatusTab == 'Di Proses' || _selectedStatusTab == 'Sedang Diproses') {
      result = await _apiService.getMyJobs(status: 'IN_PROGRESS');
    } else {
      result = await _apiService.getMyJobs(status: 'COMPLETED');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] is List) {
          final rawList = result['data'] as List;
          final Map<dynamic, dynamic> uniqueJobsMap = {};

          for (var item in rawList) {
            Map<String, dynamic> jobData;
            if (item is Map && item.containsKey('job')) {
              jobData = Map<String, dynamic>.from(item['job'] ?? {});
              jobData['assignmentStatus'] = item['status'];
              jobData['assignmentId'] = item['id'];
            } else if (item is Map) {
              jobData = Map<String, dynamic>.from(item);
            } else {
              continue;
            }

            final dynamic jobId = jobData['id'];
            if (jobId != null && !uniqueJobsMap.containsKey(jobId)) {
              final bool hasMachine = jobData['machineId'] != null || jobData['machine'] != null;
              jobData['type'] ??= hasMachine ? 'SMART_CONTAINER' : 'RESIDENTIAL';
              uniqueJobsMap[jobId] = jobData;
            }
          }

          _jobsList = uniqueJobsMap.values.toList();
        } else if (!silent) {
          _jobsList = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _jobsList.where((job) {
      final String title =
          (job['title'] ?? job['customerName'] ?? job['user']?['name'] ?? job['machine']?['name'] ?? '')
              .toString()
              .toLowerCase();
      final String rawAddress =
          (job['address'] ?? job['user']?['address'] ?? job['machine']?['address'] ?? job['description'] ?? '')
              .toString();

      final String cleanAddress = rawAddress
          .replaceAll(RegExp(r'\[PEMESAN_ID:\d+\]'), '')
          .replaceAll(RegExp(r'\[WEIGHT:[\d.]+\]'), '')
          .replaceAll(RegExp(r'\[VEHICLE:\w+\]'), '')
          .toLowerCase();

      final String type = (job['type'] ??
              (job['machineId'] != null || job['machine'] != null ? 'SMART_CONTAINER' : 'RESIDENTIAL'))
          .toString()
          .toUpperCase();
      final String status = (job['status'] ?? job['assignmentStatus'] ?? 'AVAILABLE').toString().toUpperCase();

      final bool matchesSearch =
          title.contains(_searchQuery.toLowerCase()) || cleanAddress.contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_selectedStatusTab == 'Tersedia') {
        matchesStatus = status == 'AVAILABLE' || status == 'OPEN' || status == 'PENDING';
      } else if (_selectedStatusTab == 'Di Proses' || _selectedStatusTab == 'Sedang Diproses') {
        matchesStatus = status == 'ACCEPTED' ||
            status == 'ON_THE_WAY' ||
            status == 'CHECKED_IN' ||
            status == 'PICKUP' ||
            status == 'IN_TRANSIT' ||
            status == 'HANDOVER';
      } else if (_selectedStatusTab == 'Selesai') {
        matchesStatus = status == 'COMPLETED';
      }

      bool matchesCategory = true;
      if (_selectedCategoryFilter == 'Rumah') {
        matchesCategory = type == 'RESIDENTIAL' || type == 'RUMAH';
      } else if (_selectedCategoryFilter == 'Smart Container') {
        matchesCategory = type == 'SMART_CONTAINER' || type == 'RVM';
      }

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ==========================================
          // 1. HEADER KUNING IDENTITAS BRAND + LIVE BADGE
          // ==========================================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (widget.isFromDashboard) ...[
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.primaryDark,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pekerjaan Mitra',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Ambil penjemputan warga & kontainer',
                                style: TextStyle(
                                  color: AppColors.slateNavy,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live Socket Status Indicator Pill
                        ValueListenableBuilder<bool>(
                          valueListenable: _socketService.connectionNotifier,
                          builder: (_, connected, __) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: connected ? AppColors.primaryDark : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: connected ? const Color(0xFF22C55E) : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    connected ? 'LIVE' : 'SYNC',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: connected ? AppColors.primaryYellow : AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Bar Modern
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Cari nama warga, alamat, atau lokasi mesin...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.darkNavy),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================
          // 2. TAB STATUS & FILTER KATEGORI
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      _buildTopTabItem('Tersedia'),
                      _buildTopTabItem('Di Proses'),
                      _buildTopTabItem('Selesai'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildCategoryChip('Semua', Icons.apps_rounded),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Rumah', Icons.home_work_rounded),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Smart Container', Icons.recycling_rounded),
                  ],
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. DAFTAR PEKERJAAN
          // ==========================================
          Expanded(
            child: _isLoading
                ? const AppLoading(message: 'Memuat daftar pekerjaan...', size: 72)
                : RefreshIndicator(
                    onRefresh: _fetchJobs,
                    color: AppColors.darkNavy,
                    backgroundColor: AppColors.primaryYellow,
                    child: filteredJobs.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryYellow.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.work_outline_rounded,
                                        size: 38,
                                        color: AppColors.darkNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Belum ada pekerjaan ditemukan',
                                      style: TextStyle(
                                        color: AppColors.darkNavy,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tugas baru akan muncul otomatis secara real-time.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredJobs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              return _buildJobCardByDesign(context, job);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabItem(String label) {
    final bool isSelected =
        _selectedStatusTab == label || (_selectedStatusTab == 'Sedang Diproses' && label == 'Di Proses');
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedStatusTab = label);
          _fetchJobs();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final bool isSelected = _selectedCategoryFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.cardBorder,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCardByDesign(BuildContext context, Map job) {
    final String type = (job['type'] ??
            (job['machineId'] != null || job['machine'] != null ? 'SMART_CONTAINER' : 'RESIDENTIAL'))
        .toString()
        .toUpperCase();

    final bool isResidential = type == 'RESIDENTIAL' || type == 'RUMAH' || job['machineId'] == null;
    return isResidential ? _buildWargaProfileCard(context, job) : _buildContainerCard(context, job);
  }

  // --- CARD 1: PEKERJAAN RUMAH WARGA ---
  Widget _buildWargaProfileCard(BuildContext context, Map job) {
    final dynamic jobId = job['id'];
    final String status = (job['status'] ?? job['assignmentStatus'] ?? 'AVAILABLE').toString().toUpperCase();
    final bool isCompleted = status == 'COMPLETED';
    final bool isInProgress = [
      'ACCEPTED',
      'ON_THE_WAY',
      'CHECKED_IN',
      'PICKUP',
      'IN_TRANSIT',
      'HANDOVER'
    ].contains(status);

    final String userName = job['customerName'] ?? job['user']?['name'] ?? job['title'] ?? 'Warga EcoCash';
    final String rawAddress = job['address'] ?? job['user']?['address'] ?? job['description'] ?? 'Lokasi Penjemputan';
    final String address = rawAddress.replaceAll(RegExp(r'\[.*?\]'), '').trim();

    String distanceStr;
    if (job['distanceText'] != null) {
      distanceStr = job['distanceText'].toString();
    } else if (job['distanceKm'] != null) {
      distanceStr = '${double.tryParse(job['distanceKm'].toString())?.toStringAsFixed(1) ?? job['distanceKm']} km';
    } else if (job['distance'] != null) {
      final double rawDist = double.tryParse(job['distance'].toString()) ?? 0;
      distanceStr = rawDist > 100 ? '${(rawDist / 1000).toStringAsFixed(1)} km' : '${rawDist.toStringAsFixed(1)} km';
    } else {
      distanceStr = 'Terdekat';
    }

    final String addressWithDistance = address.contains('(') ? address : '$address ($distanceStr)';

    final String rewardPrice = job['price'] ??
        (job['actualReward'] != null
            ? 'Rp ${job['actualReward']}'
            : (job['estimatedReward'] != null ? 'Rp ${job['estimatedReward']}' : 'Rp 0'));

    final String avatarUrl = job['user']?['avatarUrl'] ?? job['avatarUrl'] ?? '';

    final List<Widget> materialChips = [];
    if (job['materials'] is List && (job['materials'] as List).isNotEmpty) {
      for (var mat in job['materials']) {
        if (mat is Map) {
          final String name = mat['name'] ?? mat['category'] ?? mat['materialName'] ?? 'Material';
          final String weight = mat['weight'] != null ? '${mat['weight']} kg' : '';
          materialChips.add(_buildMaterialChip(Icons.recycling_rounded, '$name $weight'.trim()));
        } else if (mat != null) {
          materialChips.add(_buildMaterialChip(Icons.recycling_rounded, mat.toString()));
        }
      }
    } else {
      final String weightStr = job['volume'] ?? (job['estimatedWeight'] != null ? '${job['estimatedWeight']} kg' : '');
      final String tag = (job['materialTag'] ?? job['materialCategory'] ?? 'Material Sampah').toString();
      materialChips.add(_buildMaterialChip(
        Icons.recycling_rounded,
        weightStr.isNotEmpty ? '$tag $weightStr'.trim() : tag,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.35),
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'W',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.ecoGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.darkNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            addressWithDistance,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isCompleted ? 'REWARD DITERIMA' : 'EST. REWARD',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rewardPrice,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ecoGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: materialChips,
          ),
          const SizedBox(height: 12),

          // Banner Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFDCFCE7)
                  : AppColors.primaryYellow.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                  size: 18,
                  color: isCompleted ? AppColors.ecoGreen : AppColors.darkNavy,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'STATUS PENJEMPUTAN' : 'JEMPUT RUMAH WARGA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isCompleted ? AppColors.ecoGreen : AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      isCompleted ? 'SELESAI & SALDO BERHASIL MASUK' : 'PRIORITAS PENJEMPUTAN',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Aksi Dinamis
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: isCompleted
                      ? OutlinedButton.icon(
                          onPressed: () => _navigateToDetail(context, job, true),
                          icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.ecoGreen),
                          label: const Text(
                            'Lihat Rincian Selesai',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ecoGreen),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.ecoGreen, width: 1.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _navigateToDetail(context, job, true),
                          icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
                          label: Text(
                            isInProgress ? 'Lanjutkan Pekerjaan' : 'Terima & Mulai Rute',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isCompleted ? AppColors.ecoGreen : AppColors.darkNavy,
                    size: 20,
                  ),
                  onPressed: () => context.push('/chat/room/$jobId', extra: job),
                  tooltip: 'Chat Warga',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 2: SMART CONTAINER ---
  Widget _buildContainerCard(BuildContext context, Map job) {
    final String status = (job['status'] ?? job['assignmentStatus'] ?? 'AVAILABLE').toString().toUpperCase();
    final bool isCompleted = status == 'COMPLETED';
    final bool isInProgress = [
      'ACCEPTED',
      'ON_THE_WAY',
      'CHECKED_IN',
      'PICKUP',
      'IN_TRANSIT',
      'HANDOVER'
    ].contains(status);

    final String title = job['title'] ?? job['machine']?['name'] ?? 'EcoCash Container';
    final String rawAddress = job['address'] ?? job['machine']?['address'] ?? 'Lokasi Container';
    final String address = rawAddress.replaceAll(RegExp(r'\[.*?\]'), '').trim();

    final String categoryTag = job['materialTag'] ?? 'Smart Container';
    final String volume = job['volume'] ?? (job['estimatedWeight'] != null ? '${job['estimatedWeight']} kg' : '0 kg');
    final String distance = job['distanceText'] ?? job['distance'] ?? 'Terdekat';
    final String duration = job['duration'] ?? '15 mnt';
    final String price = job['price'] ?? (job['estimatedReward'] != null ? 'Rp ${job['estimatedReward']}' : 'Rp 35.000+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  categoryTag,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.ecoGreen, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'SELESAI',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ecoGreen),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Volume', volume),
                _buildStatColumn('Jarak', distance),
                _buildStatColumn('Estimasi', duration),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'Total Diterima' : 'Estimasi Pendapatan',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ecoGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 42,
                child: isCompleted
                    ? OutlinedButton(
                        onPressed: () => _navigateToDetail(context, job, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.ecoGreen, width: 1.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ecoGreen),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _navigateToDetail(context, job, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          elevation: 0,
                        ),
                        child: Text(
                          isInProgress ? 'Lanjut Tugas' : 'Terima Tugas',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.ecoGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, Map job, bool isResidential) async {
    final dynamic jobId = job['id'];
    final String status = (job['status'] ?? job['assignmentStatus'] ?? 'AVAILABLE').toString().toUpperCase();

    String targetRoute;
    if (status == 'ACCEPTED' ||
        status == 'ON_THE_WAY' ||
        status == 'CHECKED_IN' ||
        status == 'PICKUP' ||
        status == 'IN_TRANSIT' ||
        status == 'HANDOVER') {
      targetRoute = isResidential ? '/dalam-perjalanan-rumah' : '/dalam-perjalanan';
    } else {
      targetRoute = isResidential ? '/detail-pekerjaan-rumah' : '/detail-pekerjaan';
    }

    await context.push(targetRoute, extra: {'id': jobId, 'rawJob': job});
    _fetchJobs();
  }
}
