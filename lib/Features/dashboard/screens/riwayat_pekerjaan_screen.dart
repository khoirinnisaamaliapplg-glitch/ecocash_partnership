import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import 'detail_qr_screen.dart';
import '../../../core/widgets/app_loading.dart';

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

  List<Map<String, dynamic>> _listSelesai = [];
  List<Map<String, dynamic>> _listDiproses = [];
  List<Map<String, dynamic>> _listDibatalkan = [];

  bool _isLoading = true;
  String? _errorMessage;

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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _loadJobHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<void> _loadJobHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.getMyJobs(status: 'COMPLETED'),
        _apiService.getMyJobs(status: 'IN_PROGRESS'),
        _apiService.getMyJobs(status: 'CANCELLED'),
      ]);

      final List rawSelesai =
          (results[0]['success'] == true && results[0]['data'] is List)
          ? results[0]['data'] as List
          : [];

      final List rawDiproses =
          (results[1]['success'] == true && results[1]['data'] is List)
          ? results[1]['data'] as List
          : [];

      final List rawDibatalkan =
          (results[2]['success'] == true && results[2]['data'] is List)
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
      debugPrint('[RiwayatPekerjaan] ERROR: $e');
      debugPrint('$stack');

      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat riwayat pekerjaan: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _formatJobItem(Map<String, dynamic> assignment) {
    final job = assignment['job'] ?? {};
    final machine = job['machine'];

    final weights =
        (job['weights'] as List?) ?? (assignment['weights'] as List?) ?? [];

    String locationName = job['title'] ?? 'Penjemputan Sampah';

    if (machine != null &&
        machine['placeName'] != null &&
        machine['placeName'].toString().isNotEmpty) {
      locationName = machine['placeName'].toString();
    }

    double totalKg = 0.0;
    List<String> materialNames = [];

    for (var w in weights) {
      final double weightVal = _toDouble(
        w['pickupWeight'] ?? w['handoverWeight'] ?? w['weight'],
      );

      totalKg += weightVal;

      if (w['material'] != null && w['material']['name'] != null) {
        materialNames.add(w['material']['name'].toString());
      }
    }

    String materialText = materialNames.isNotEmpty
        ? materialNames.take(2).join(', ')
        : 'Material Campuran';

    String dateStr =
        (assignment['completedAt'] ??
                assignment['assignedAt'] ??
                job['createdAt'] ??
                '')
            .toString();

    if (dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        dateStr = DateFormat('dd MMM yyyy • HH:mm').format(dt);
      } catch (_) {}
    }

    final dynamic rawReward =
        assignment['actualReward'] ??
        job['actualReward'] ??
        assignment['estimatedReward'] ??
        job['estimatedReward'] ??
        job['price'];

    num actualReward = 0;

    if (rawReward != null && _toDouble(rawReward) > 0) {
      actualReward = _toDouble(rawReward);
    } else {
      final String jobType =
          (job['type'] ??
                  (job['machineId'] != null || job['machine'] != null
                      ? 'SMART_CONTAINER'
                      : 'RESIDENTIAL'))
              .toString()
              .toUpperCase();

      final bool isResidential = jobType == 'RESIDENTIAL' || jobType == 'RUMAH';

      actualReward = isResidential
          ? (20000 + (totalKg * 1000))
          : (35000 + (totalKg * 2000));
    }

    final String priceText =
        'Rp${NumberFormat('#,##0', 'id_ID').format(actualReward)}';

    return {
      'id': job['id'],
      'assignmentId': assignment['id'],
      'company': locationName,
      'material': materialText,
      'weight': '${totalKg.toStringAsFixed(1).replaceAll('.', ',')} kg',
      'date': dateStr,
      'price': priceText,
      'status': _mapJobStatus(job['status'] ?? assignment['status']),
      'kode': machine?['machineCode'] ?? job['code'] ?? 'JOB-#${job['id']}',
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

  void _tampilkanDialogPembatalan(dynamic jobId) {
    final TextEditingController alasanController = TextEditingController();

    String? dialogError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Alasan Pembatalan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              content: TextField(
                controller: alasanController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: _text),
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan pembatalan pekerjaan ini...',
                  hintStyle: const TextStyle(fontSize: 12, color: _muted),
                  filled: true,
                  fillColor: _background,
                  errorText: dialogError,
                  contentPadding: const EdgeInsets.all(13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  if (dialogError != null) {
                    setStateDialog(() => dialogError = null);
                  }
                },
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: _muted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String alasan = alasanController.text.trim();

                    final words = alasan
                        .split(RegExp(r'\s+'))
                        .where((w) => w.isNotEmpty)
                        .toList();

                    if (alasan.isEmpty) {
                      setStateDialog(
                        () => dialogError = 'Alasan tidak boleh kosong.',
                      );
                      return;
                    } else if (words.length < 3) {
                      setStateDialog(
                        () => dialogError =
                            'Alasan terlalu singkat (min. 3 kata).',
                      );
                      return;
                    }

                    try {
                      final res = await _apiService.cancelJob(
                        jobId,
                        reason: alasan,
                      );

                      if (res['success'] == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadJobHistory();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pekerjaan berhasil dibatalkan'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        setStateDialog(
                          () => dialogError =
                              res['message'] ?? 'Gagal membatalkan pekerjaan',
                        );
                      }
                    } catch (e) {
                      setStateDialog(
                        () => dialogError = 'Gagal membatalkan pekerjaan: $e',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => alasanController.dispose());
  }

  // =========================================================
  // STYLE STATUS
  // =========================================================

  Map<String, dynamic> _getStatusStyle(String status) {
    if (status == 'Selesai') {
      return {
        'color': _green,
        'background': const Color(0xFFEAF6ED),
        'icon': Icons.check_circle_rounded,
      };
    }

    if (status == 'Diproses') {
      return {
        'color': const Color(0xFF1976A5),
        'background': const Color(0xFFEAF5FA),
        'icon': Icons.schedule_rounded,
      };
    }

    return {
      'color': const Color(0xFFD64B4B),
      'background': const Color(0xFFFFEEEE),
      'icon': Icons.cancel_rounded,
    };
  }

  // =========================================================
  // APP BAR
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _navy, size: 21),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Riwayat Pekerjaan',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const AppLoading(
              message: 'Menyiapkan riwayat pekerjaan kamu...',
              size: 76,
            )
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadJobHistory,
              color: _navy,
              backgroundColor: _yellow,
              child: Column(
                children: [
                  _buildTabBar(),
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

  // =========================================================
  // TAB BAR
  // =========================================================

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _muted,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(height: 38, text: 'Selesai (${_listSelesai.length})'),
          Tab(height: 38, text: 'Proses (${_listDiproses.length})'),
          Tab(height: 38, text: 'Batal (${_listDibatalkan.length})'),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.redAccent,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Riwayat belum dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadJobHistory,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _navy,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // JOB LIST
  // =========================================================

  Widget _buildJobListTab(
    List<Map<String, dynamic>> list, {
    bool isProcessing = false,
    bool isCancelled = false,
  }) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 105),
          Center(
            child: Column(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.inbox_rounded,
                    size: 34,
                    color: Color(0xFFADB5C0),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Belum ada pekerjaan',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Pekerjaan pada kategori ini akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isProcessing
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailQrScreen(kodeKontainer: item['kode']),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: _buildJobHistoryCard(
                item,
                showCancelButton: isProcessing,
                onCancel: () => _tampilkanDialogPembatalan(item['id']),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // JOB CARD
  // =========================================================

  Widget _buildJobHistoryCard(
    Map<String, dynamic> item, {
    bool showCancelButton = false,
    VoidCallback? onCancel,
  }) {
    final String status = item['status'] ?? '';
    final bool isCancelled = status == 'Dibatalkan';
    final bool isFinished = status == 'Selesai';

    final statusStyle = _getStatusStyle(status);
    final Color statusColor = statusStyle['color'];
    final Color statusBackground = statusStyle['background'];
    final IconData statusIcon = statusStyle['icon'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.75), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOKASI DAN STATUS
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6D9),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFB68A16),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['company']?.toString() ?? 'Penjemputan Sampah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 11, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // MATERIAL DAN BERAT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MATERIAL',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['material']?.toString() ?? 'Material Campuran',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 29,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: _border,
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BERAT',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['weight']?.toString() ?? '0 kg',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // TANGGAL DAN KOMISI
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: _muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['date']?.toString() ?? '-',
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
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isFinished ? 'Komisi Diterima' : 'Estimasi Komisi',
                    style: TextStyle(
                      color: isFinished ? _green : _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['price']?.toString() ?? 'Rp0',
                    style: TextStyle(
                      color: isCancelled ? _muted : _green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ALASAN PEMBATALAN
          if (isCancelled &&
              item['alasan'] != null &&
              item['alasan'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF5D5D5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.redAccent,
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Alasan Pembatalan',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['alasan'].toString(),
                    style: const TextStyle(
                      color: _text,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // TOMBOL BATALKAN
          if (showCancelButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text(
                  'Batalkan Pekerjaan',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // PETUNJUK BUKA DETAIL
          if (showCancelButton) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Ketuk kartu untuk melihat detail pekerjaan',
                style: TextStyle(color: _muted, fontSize: 9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
