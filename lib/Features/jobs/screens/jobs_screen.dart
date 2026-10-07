import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class JobsScreen extends StatefulWidget {
  final bool isFromDashboard; // 1. Tambahkan baris ini

  const JobsScreen({super.key, this.isFromDashboard = false});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  String _selectedStatusTab =
      'Tersedia'; // Options: 'Tersedia', 'Sedang Diproses', 'Selesai'
  String _selectedCategoryFilter = 'Semua';

  List<dynamic> _jobsList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const Color _navyColor = Color(0xFF0F2C59);
  static const Color _tealColor = Color(0xFF1E88A8);

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
    } else {
      result = await _apiService.getMyJobs();
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
              jobData = Map<String, dynamic>.from(item['job']);
              jobData['assignmentStatus'] = item['status'];
            } else if (item is Map) {
              jobData = Map<String, dynamic>.from(item);
            } else {
              continue;
            }

            final dynamic jobId = jobData['id'];
            if (jobId != null && !uniqueJobsMap.containsKey(jobId)) {
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
      final String title = (job['title'] ?? job['machine']?['name'] ?? '')
          .toString()
          .toLowerCase();
      final String address =
          (job['address'] ?? job['machine']?['address'] ?? '')
              .toString()
              .toLowerCase();
      final String type = (job['type'] ?? 'SMART_CONTAINER')
          .toString()
          .toUpperCase();
      final String status = (job['status'] ?? 'AVAILABLE')
          .toString()
          .toUpperCase();

      bool matchesSearch =
          title.contains(_searchQuery.toLowerCase()) ||
          address.contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_selectedStatusTab == 'Tersedia') {
        matchesStatus =
            status == 'AVAILABLE' || status == 'OPEN' || status == 'PENDING';
      } else if (_selectedStatusTab == 'Sedang Diproses') {
        matchesStatus =
            status == 'ACCEPTED' ||
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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.isFromDashboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Daftar Pekerjaan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari pekerjaan...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildTopTabItem('Tersedia'),
                    _buildTopTabItem('Sedang Diproses'),
                    _buildTopTabItem('Selesai'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryChip('Semua'),
                const SizedBox(width: 8),
                _buildCategoryChip('Rumah'),
                const SizedBox(width: 8),
                _buildCategoryChip('Smart Container'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchJobs,
                    child: filteredJobs.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada pekerjaan yang sesuai dengan filter.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredJobs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              return _buildDynamicJobCard(context, job);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabItem(String label) {
    bool isSelected = _selectedStatusTab == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatusTab = label;
          });
          _fetchJobs();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primaryCyan : Colors.transparent,
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
              color: isSelected
                  ? AppColors.primaryCyan
                  : AppColors.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicJobCard(BuildContext context, Map job) {
    final dynamic jobId = job['id'];
    final String title =
        job['title'] ?? job['machine']?['name'] ?? 'Tugas Penjemputan #$jobId';
    final String address =
        job['address'] ??
        job['machine']?['address'] ??
        job['machine']?['placeName'] ??
        'Lokasi Penjemputan';
    final String materialTag =
        job['materialTag'] ?? job['materialCategory'] ?? 'Plastik / Karton';
    final String volume = job['estimatedWeight'] != null
        ? '${job['estimatedWeight']} kg'
        : (job['volume'] ?? '20 kg');
    final String price = job['estimatedReward'] != null
        ? 'Rp${job['estimatedReward']}'
        : (job['price'] ?? 'Rp45.000');
    final String type = (job['type'] ?? 'SMART_CONTAINER')
        .toString()
        .toUpperCase();
    final bool isResidential = type == 'RESIDENTIAL' || type == 'RUMAH';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isResidential ? Colors.cyan.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isResidential
                    ? AppColors.primaryCyan
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              isResidential ? 'Penjemputan Warga' : materialTag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isResidential
                    ? AppColors.primaryCyan
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimasi Pendapatan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _navyColor,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () async {
                    final String status = (job['status'] ?? 'AVAILABLE')
                        .toString()
                        .toUpperCase();
                    String targetRoute;

                    if (status == 'ACCEPTED' ||
                        status == 'ON_THE_WAY' ||
                        status == 'CHECKED_IN' ||
                        status == 'PICKUP' ||
                        status == 'IN_TRANSIT' ||
                        status == 'HANDOVER') {
                      targetRoute = isResidential
                          ? '/dalam-perjalanan-rumah'
                          : '/dalam-perjalanan';
                    } else {
                      targetRoute = isResidential
                          ? '/detail-pekerjaan-rumah'
                          : '/detail-pekerjaan';
                    }

                    await context.push(
                      targetRoute,
                      extra: {
                        'id': jobId,
                        'title': title,
                        'address': address,
                        'materialTag': materialTag,
                        'volume': volume,
                        'price': price,
                        'rawJob': job,
                      },
                    );
                    _fetchJobs();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedStatusTab == 'Sedang Diproses'
                        ? 'Lanjutkan'
                        : 'Lihat Detail',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
