import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import 'detail_qr_screen.dart';

class RiwayatPekerjaanScreen extends StatefulWidget {
  final Map? dataBaru;

  const RiwayatPekerjaanScreen({super.key, this.dataBaru});

  @override
  State<RiwayatPekerjaanScreen> createState() => _RiwayatPekerjaanScreenState();
}

class _RiwayatPekerjaanScreenState extends State<RiwayatPekerjaanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PartnerApiService _apiService = PartnerApiService();

  List<dynamic> _listSelesai = [];
  List<dynamic> _listDiproses = [];
  List<dynamic> _listDibatalkan = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _fetchJobsFromApi();
  }

  /// Mengambil data pekerjaan mitra dari backend
  Future<void> _fetchJobsFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _apiService.getMyJobs();

    if (!mounted) return;

    if (res['success'] == true) {
      final List<dynamic> rawAssignments = res['data'] ?? [];

      List<dynamic> selesai = [];
      List<dynamic> diproses = [];
      List<dynamic> dibatalkan = [];

      for (var item in rawAssignments) {
        final job = item['job'] ?? {};
        final String jobStatus = job['status'] ?? item['status'] ?? '';

        if (jobStatus == 'COMPLETED' || item['status'] == 'COMPLETED') {
          selesai.add(item);
        } else if (jobStatus == 'CANCELLED' || item['status'] == 'CANCELLED') {
          dibatalkan.add(item);
        } else {
          diproses.add(item);
        }
      }

      setState(() {
        _listSelesai = selesai;
        _listDiproses = diproses;
        _listDibatalkan = dibatalkan;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Gagal memuat riwayat pekerjaan';
        _isLoading = false;
      });
    }
  }

  /// Membatalkan pekerjaan via API
  Future<void> _batalPekerjaan(int jobId, String alasan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
      ),
    );

    final res = await _apiService.cancelJob(jobId, reason: alasan);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog loading

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan berhasil dibatalkan'),
          backgroundColor: Colors.red,
        ),
      );
      _fetchJobsFromApi(); // Refresh data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal membatalkan pekerjaan'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _tampilkanDialogPembatalan(int jobId) {
    final TextEditingController alasanController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Alasan Pembatalan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: alasanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan pembatalan di sini...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F8),
                      errorText: errorMessage,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryCyan)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red)),
                    ),
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setStateDialog(() => errorMessage = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    String alasan = alasanController.text.trim();
                    var words =
                        alasan.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

                    if (alasan.isEmpty) {
                      setStateDialog(() => errorMessage = 'Alasan tidak boleh kosong.');
                      return;
                    } else if (words.length < 3) {
                      setStateDialog(
                          () => errorMessage = 'Alasan terlalu singkat (min. 3 kata).');
                      return;
                    }

                    Navigator.pop(context);
                    _batalPekerjaan(jobId, alasan);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '-';
    try {
      final DateTime dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy • HH:mm').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Riwayat Pekerjaan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                        onPressed: _fetchJobsFromApi,
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryCyan,
                  onRefresh: _fetchJobsFromApi,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primaryCyan,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primaryCyan,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Selesai'),
                            Tab(text: 'Diproses'),
                            Tab(text: 'Dibatalkan'),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Selesai
                            _buildJobList(_listSelesai, isDiproses: false),
                            // Tab 2: Diproses
                            _buildJobList(_listDiproses, isDiproses: true),
                            // Tab 3: Dibatalkan
                            _buildJobList(_listDibatalkan, isDiproses: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildJobList(List<dynamic> items, {required bool isDiproses}) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada riwayat pekerjaan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final assignment = items[index];
        final job = assignment['job'] ?? {};
        final machine = job['machine'] ?? {};
        final List weights = job['weights'] ?? [];

        final int jobId = job['id'] ?? 0;
        final String company = machine['placeName'] ?? job['title'] ?? 'Lokasi Penjemputan';
        final String material = weights.isNotEmpty
            ? weights.map((w) => w['material']?['name'] ?? 'Material').join(', ')
            : 'Sampah Daur Ulang';

        double totalKg = 0;
        for (var w in weights) {
          totalKg += (w['handoverWeight'] ?? w['pickupWeight'] ?? 0).toDouble();
        }

        final String weightStr = '${totalKg.toStringAsFixed(1).replaceAll('.', ',')} kg';
        final String dateStr = _formatDate(assignment['assignedAt'] ?? job['createdAt']);
        final String statusStr = isDiproses ? 'Diproses' : (job['status'] ?? assignment['status']);
        final String? cancelReason = assignment['cancelReason'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: isDiproses
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailQrScreen(
                          kodeKontainer: job['code'] ?? 'JOB-$jobId',
                        ),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: _buildJobHistoryCard(
              company: company,
              material: material,
              weight: weightStr,
              date: dateStr,
              price: 'Rp15.000+',
              status: statusStr,
              alasan: cancelReason,
              showCancelButton: isDiproses,
              onCancel: () => _tampilkanDialogPembatalan(jobId),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobHistoryCard({
    required String company,
    required String material,
    required String weight,
    required String date,
    required String price,
    required String status,
    String? alasan,
    bool showCancelButton = false,
    VoidCallback? onCancel,
  }) {
    Color badgeColor;
    Color textColor;
    IconData badgeIcon;
    bool isCancelled = status == 'Dibatalkan' || status == 'CANCELLED';

    if (status == 'Selesai' || status == 'COMPLETED') {
      badgeColor = Colors.green.shade50;
      textColor = Colors.green;
      badgeIcon = Icons.check_circle;
    } else if (isCancelled) {
      badgeColor = Colors.red.shade50;
      textColor = Colors.red;
      badgeIcon = Icons.cancel;
    } else {
      badgeColor = Colors.cyan.shade50;
      textColor = Colors.cyan.shade700;
      badgeIcon = Icons.access_time_filled;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      isCancelled ? 'Dibatalkan' : (status == 'COMPLETED' ? 'Selesai' : status),
                      style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Material',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(material,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Berat',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(weight,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(date,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Estimasi',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCancelled ? AppColors.textSecondary : AppColors.successGreen,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isCancelled && alasan != null && alasan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alasan Pembatalan:',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 2),
                  Text(alasan,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
          if (showCancelButton) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Batalkan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}