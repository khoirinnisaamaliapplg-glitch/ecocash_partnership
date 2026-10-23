import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';


class JobsScreen extends StatefulWidget {
  final bool isFromDashboard;

  const JobsScreen({super.key, this.isFromDashboard = false});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  String _selectedStatusTab = 'Tersedia';
  String _selectedCategoryFilter = 'Semua';

  List<dynamic> _jobsList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const Color _navyColor = Color(0xFF0B3C5D);
  static const Color _tealColor = Color(0xFF178CA4);
  static const Color _cyanHeader = Color(0xFF00C7C9);

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (_selectedStatusTab == 'Tersedia') {
      result = await _apiService.getAvailableJobs();
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
        } else {
          _jobsList = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _jobsList.where((job) {
      final String title = (job['title'] ?? job['customerName'] ?? job['user']?['name'] ?? job['machine']?['name'] ?? '').toString().toLowerCase();
      final String rawAddress = (job['address'] ??
              job['user']?['address'] ??
              job['machine']?['address'] ??
              job['description'] ??
              '')
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
      final String status = (job['status'] ?? 'AVAILABLE').toString().toUpperCase();

      bool matchesSearch = title.contains(_searchQuery.toLowerCase()) || cleanAddress.contains(_searchQuery.toLowerCase());

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
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: _cyanHeader,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.isFromDashboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Pekerjaan Tersedia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Header Tab Status & Category Chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Floating Card Tab Status
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTopTabItem('Tersedia'),
                      _buildTopTabItem('Di Proses'),
                      _buildTopTabItem('Selesai'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Category Chips (Centered)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCategoryChip('Semua'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Rumah'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Smart Container'),
                  ],
                ),
              ],
            ),
          ),

          // Job List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _cyanHeader))
                : RefreshIndicator(
                    onRefresh: _fetchJobs,
                    color: _cyanHeader,
                    child: filteredJobs.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada pekerjaan yang tersedia.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: filteredJobs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
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
    bool isSelected = _selectedStatusTab == label || (_selectedStatusTab == 'Sedang Diproses' && label == 'Di Proses');
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatusTab = label;
          });
          _fetchJobs();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _cyanHeader : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? _cyanHeader : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategoryFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _navyColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _navyColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
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

    if (isResidential) {
      return _buildWargaProfileCard(context, job);
    } else {
      return _buildContainerCard(context, job);
    }
  }

  // --- CARD 1: PEKERJAAN DARI RUMAH WARGA (DINAMIS SAMA DENGAN DESAIN GAMBAR) ---
  Widget _buildWargaProfileCard(BuildContext context, Map job) {
    final dynamic jobId = job['id'];
    final String userName = job['customerName'] ?? job['user']?['name'] ?? job['title'] ?? 'Warga EcoCash';
    final String rawAddress = job['address'] ?? job['user']?['address'] ?? job['description'] ?? 'Lokasi Penjemputan';
    final String address = rawAddress.replaceAll(RegExp(r'\[.*?\]'), '').trim();

    // Mengambil Distance & Price Dinamis dari BE
    final String distanceStr = job['distanceText'] ?? job['distance'] ?? '0.8 km';
    final String addressWithDistance = address.contains('(') ? address : '$address ($distanceStr)';

    final String rewardPrice = job['price'] ??
        (job['estimatedReward'] != null
            ? 'Rp ${job['estimatedReward']}'
            : (job['actualReward'] != null ? 'Rp ${job['actualReward']}' : 'Rp 0'));

    final String avatarUrl = job['user']?['avatarUrl'] ?? job['avatarUrl'] ?? '';

    // Parsing Chips Material Dinamis dari BE
    List<Widget> materialChips = [];
    if (job['materials'] is List && (job['materials'] as List).isNotEmpty) {
      for (var mat in job['materials']) {
        if (mat is Map) {
          String name = mat['name'] ?? mat['category'] ?? mat['materialName'] ?? 'Material';
          String weight = mat['weight'] != null ? '${mat['weight']} kg' : '';
          materialChips.add(_buildMaterialChip(Icons.recycling, '$name $weight'.trim()));
        } else if (mat != null) {
          materialChips.add(_buildMaterialChip(Icons.recycling, mat.toString()));
        }
      }
    } else {
      // Fallback jika array materials kosong tapi ada volume/estimatedWeight
      final String weightStr = job['volume'] ?? (job['estimatedWeight'] != null ? '${job['estimatedWeight']} kg' : '');
      final String tag = (job['materialTag'] ?? job['materialCategory'] ?? 'Material Sampah').toString();
      
      if (weightStr.isNotEmpty) {
        materialChips.add(_buildMaterialChip(Icons.recycling, '$tag $weightStr'.trim()));
      } else {
        materialChips.add(_buildMaterialChip(Icons.recycling, tag));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Avatar, Name, Distance & Reward
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'W',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.teal,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.circle, color: Colors.teal, size: 8),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            addressWithDistance,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                  const Text('EST. REWARD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    rewardPrice,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips Material
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: materialChips,
          ),
          const SizedBox(height: 12),

          // Banner Prioritas Setor Mitra
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.center_focus_strong, size: 18, color: Colors.teal),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TUJUAN SETOR MITRA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
                    Text('PRIORITAS UTAMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Aksi: Terima & Mulai Rute + Pesan Chat
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDetail(context, job, true),
                    icon: const Icon(Icons.navigation_outlined, size: 18, color: Colors.white),
                    label: const Text('Terima & Mulai Rute', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tealColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: _tealColor, size: 20),
                  onPressed: () => context.push('/chat/room/$jobId'),
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
    final String title = job['title'] ?? job['machine']?['name'] ?? 'EcoCash Container';
    final String rawAddress = job['address'] ?? job['machine']?['address'] ?? 'Lokasi Container';
    final String address = rawAddress.replaceAll(RegExp(r'\[.*?\]'), '').trim();

    final String categoryTag = job['materialTag'] ?? 'PET (Botol)';
    final String volume = job['volume'] ?? (job['estimatedWeight'] != null ? '${job['estimatedWeight']} kg' : '0 kg');
    final String distance = job['distanceText'] ?? job['distance'] ?? '2,3 km';
    final String duration = job['duration'] ?? '15 mnt';
    final String price = job['price'] ?? (job['estimatedReward'] != null ? 'Rp${job['estimatedReward']}' : 'Rp0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400, width: 0.8),
            ),
            child: Text(
              categoryTag,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  const Text('Estimasi Pendapatan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _navigateToDetail(context, job, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Terima\nPekerjaan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _navyColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _navyColor)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, Map job, bool isResidential) async {
    final dynamic jobId = job['id'];
    final String status = (job['status'] ?? 'AVAILABLE').toString().toUpperCase();

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