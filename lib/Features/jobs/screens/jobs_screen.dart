import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  String _selectedFilter = 'Semua';
  
  List<dynamic> _jobsList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const Color _navyColor = Color(0xFF0F2C59);
  static const Color _tealColor = Color(0xFF1E88A8);

  @override
  void initState() {
    super.initState();
    _fetchAvailableJobs();
  }

  Future<void> _fetchAvailableJobs() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAvailableJobs();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _jobsList = result['data'] is List ? result['data'] : [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter pencarian dan chip
    final filteredJobs = _jobsList.where((job) {
      final String title = (job['title'] ?? job['machine']?['name'] ?? '').toString().toLowerCase();
      final String address = (job['address'] ?? job['machine']?['address'] ?? '').toString().toLowerCase();
      final String type = (job['type'] ?? 'SMART_CONTAINER').toString().toUpperCase();

      bool matchesSearch = title.contains(_searchQuery.toLowerCase()) || address.contains(_searchQuery.toLowerCase());
      bool matchesFilter = true;

      if (_selectedFilter == 'Rumah') {
        matchesFilter = type == 'RESIDENTIAL' || type == 'RUMAH';
      } else if (_selectedFilter == 'Smart Container') {
        matchesFilter = type == 'SMART_CONTAINER' || type == 'RVM';
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text(
          'Pekerjaan Tersedia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR & FILTER CHIPS ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari pekerjaan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rumah'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Smart Container'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // --- DAFTAR TUGAS DINAMIS ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAvailableJobs,
                    child: filteredJobs.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada pekerjaan tersedia saat ini.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredJobs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
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

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navyColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _navyColor : Colors.grey.shade300),
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

  Widget _buildDynamicJobCard(BuildContext context, Map<String, dynamic> job) {
    final dynamic jobId = job['id'];
    final String title = job['title'] ?? job['machine']?['name'] ?? 'Tugas Penjemputan #$jobId';
    final String address = job['address'] ?? job['machine']?['address'] ?? job['machine']?['placeName'] ?? 'Lokasi Penjemputan';
    final String materialTag = job['materialTag'] ?? job['materialCategory'] ?? 'Plastik / Karton';
    final String volume = job['estimatedWeight'] != null ? '${job['estimatedWeight']} kg' : (job['volume'] ?? '20 kg');
    final String price = job['estimatedReward'] != null ? 'Rp${job['estimatedReward']}' : (job['price'] ?? 'Rp45.000');
    final String type = (job['type'] ?? 'SMART_CONTAINER').toString().toUpperCase();

    final bool isResidential = type == 'RESIDENTIAL' || type == 'RUMAH';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
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
              border: Border.all(color: isResidential ? AppColors.primaryCyan : Colors.grey.shade300),
            ),
            child: Text(
              isResidential ? 'Penjemputan Warga' : materialTag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isResidential ? AppColors.primaryCyan : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Pendapatan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    final targetRoute = isResidential ? '/detail-pekerjaan-rumah' : '/detail-pekerjaan';
                    context.push(
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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