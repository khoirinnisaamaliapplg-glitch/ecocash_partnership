import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final PartnerApiService _apiService = PartnerApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _listSelesai = [];
  List<Map<String, dynamic>> _listDiproses = [];
  List<Map<String, dynamic>> _listDibatalkan = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _loadJobHistory();
  }

  // Helper agar aman terhadap konversi String / int / double / Decimal dari Prisma
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<void> _loadJobHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _apiService.getMyJobs(status: 'COMPLETED'),
        _apiService.getMyJobs(status: 'IN_PROGRESS'),
        _apiService.getMyJobs(status: 'CANCELLED'),
      ]);

      final List rawSelesai = (results[0]['success'] == true && results[0]['data'] is List)
          ? results[0]['data'] as List
          : [];
      final List rawDiproses = (results[1]['success'] == true && results[1]['data'] is List)
          ? results[1]['data'] as List
          : [];
      final List rawDibatalkan = (results[2]['success'] == true && results[2]['data'] is List)
          ? results[2]['data'] as List
          : [];

      if (mounted) {
        setState(() {
          _listSelesai = rawSelesai
              .map((item) => _formatJobItem(Map<String, dynamic>.from(item)))
              .toList();
          _listDiproses = rawDiproses
              .map((item) => _formatJobItem(Map<String, dynamic>.from(item)))
              .toList();
          _listDibatalkan = rawDibatalkan
              .map((item) => _formatJobItem(Map<String, dynamic>.from(item)))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[RiwayatPekerjaan] ERROR PARSING: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _formatJobItem(Map<String, dynamic> assignment) {
    final job = assignment['job'] ?? {};
    final machine = job['machine'];
    final weights = (job['weights'] as List?) ?? [];

    String locationName = job['title'] ?? 'Penjemputan Sampah';
    if (machine != null && machine['placeName'] != null && machine['placeName'].toString().isNotEmpty) {
      locationName = machine['placeName'].toString();
    }

    double totalKg = 0.0;
    List<String> materialNames = [];
    for (var w in weights) {
      final double weightVal = _toDouble(w['pickupWeight'] ?? w['handoverWeight']);
      totalKg += weightVal;
      if (w['material'] != null && w['material']['name'] != null) {
        materialNames.add(w['material']['name'].toString());
      }
    }

    String materialText = materialNames.isNotEmpty
        ? materialNames.take(2).join(', ')
        : 'Material Campuran';

    String dateStr = (assignment['assignedAt'] ?? job['createdAt'] ?? '').toString();
    if (dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
      } catch (_) {}
    }

    final int earning = (15000 + (totalKg * 2000)).toInt();
    final String priceText =
        'Rp${earning.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return {
      'id': job['id'],
      'assignmentId': assignment['id'],
      'company': locationName,
      'material': materialText,
      'weight': '${totalKg.toStringAsFixed(1)} kg',
      'date': dateStr,
      'price': priceText,
      'status': _mapJobStatus(job['status'] ?? assignment['status']),
      'kode': machine?['machineCode'] ?? 'JOB-#${job['id']}',
      'alasan': assignment['cancelReason'],
    };
  }

  String _mapJobStatus(dynamic rawStatus) {
    final statusStr = rawStatus?.toString() ?? '';
    switch (statusStr) {
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return 'Diproses';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _tampilkanDialogPembatalan(dynamic jobId, int index) {
    final TextEditingController alasanController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Alasan Pembatalan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: alasanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan pembatalan pekerjaan ini...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F8),
                      errorText: dialogError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String alasan = alasanController.text.trim();
                    if (alasan.isEmpty) {
                      setStateDialog(() => dialogError = 'Alasan tidak boleh kosong.');
                      return;
                    }

                    try {
                      final res = await _apiService.cancelJob(jobId, reason: alasan);
                      if (res['success'] == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadJobHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pekerjaan berhasil dibatalkan'), backgroundColor: Colors.red),
                          );
                        }
                      } else {
                        setStateDialog(() => dialogError = res['message'] ?? 'Gagal membatalkan pekerjaan');
                      }
                    } catch (e) {
                      setStateDialog(() => dialogError = 'Gagal membatalkan pekerjaan: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : Navigator.pop(context),
        ),
        title: const Text('Riwayat Pekerjaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobHistory,
        color: AppColors.primaryCyan,
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
                tabs: [
                  Tab(text: 'Selesai (${_listSelesai.length})'),
                  Tab(text: 'Diproses (${_listDiproses.length})'),
                  Tab(text: 'Dibatalkan (${_listDibatalkan.length})'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJobListTab(_listSelesai),
                  _buildJobListTab(_listDiproses, isProcessing: true),
                  _buildJobListTab(_listDibatalkan, isCancelled: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListTab(List<Map<String, dynamic>> list, {bool isProcessing = false, bool isCancelled = false}) {
    if (list.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada pekerjaan pada kategori ini', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: isProcessing
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailQrScreen(kodeKontainer: item['kode']),
                      ),
                    );
                  }
                : null,
            child: _buildJobHistoryCard(
              item,
              showCancelButton: isProcessing,
              onCancel: () => _tampilkanDialogPembatalan(item['id'], index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobHistoryCard(Map<String, dynamic> item, {bool showCancelButton = false, VoidCallback? onCancel}) {
    final String status = item['status'] ?? '';
    final bool isCancelled = status == 'Dibatalkan';
    Color badgeColor = Colors.green.shade50;
    Color textColor = Colors.green;
    IconData badgeIcon = Icons.check_circle;

    if (status == 'Diproses') {
      badgeColor = Colors.cyan.shade50;
      textColor = Colors.cyan.shade700;
      badgeIcon = Icons.access_time_filled;
    } else if (isCancelled) {
      badgeColor = Colors.red.shade50;
      textColor = Colors.red;
      badgeIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item['company'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Material', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(item['material'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Berat', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(item['weight'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
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
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(item['date'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Pendapatan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    item['price'],
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
          if (isCancelled && item['alasan'] != null) ...[
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
                  const Text('Alasan Pembatalan:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 2),
                  Text(item['alasan'], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
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
                child: const Text('Batalkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}