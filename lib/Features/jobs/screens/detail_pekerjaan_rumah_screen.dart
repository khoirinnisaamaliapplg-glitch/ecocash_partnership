import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/job_socket_service.dart';

class DetailPekerjaanRumahScreen extends StatefulWidget {
  final Map jobData;

  const DetailPekerjaanRumahScreen({super.key, required this.jobData});

  @override
  State<DetailPekerjaanRumahScreen> createState() => _DetailPekerjaanRumahScreenState();
}

class _DetailPekerjaanRumahScreenState extends State<DetailPekerjaanRumahScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final JobSocketService _socketService = JobSocketService.instance;
  StreamSubscription<JobSocketEvent>? _socketSub;
  bool _isLoading = false;
  bool _isClaimedByOther = false;

  Map get _rawJob {
    if (widget.jobData['rawJob'] is Map) {
      return widget.jobData['rawJob'] as Map;
    }
    if (widget.jobData['job'] is Map) {
      return widget.jobData['job'] as Map;
    }
    return widget.jobData;
  }

  dynamic get _resolvedJobId {
    if (widget.jobData['job'] is Map && widget.jobData['job']['id'] != null) {
      return widget.jobData['job']['id'];
    }
    return widget.jobData['jobId'] ?? _rawJob['id'] ?? widget.jobData['id'];
  }

  String get _jobStatus {
    final status = _rawJob['status'] ?? widget.jobData['status'] ?? 'AVAILABLE';
    return status.toString().toUpperCase();
  }

  String get _title {
    return widget.jobData['title'] ??
        _rawJob['title'] ??
        _rawJob['customerName'] ??
        _rawJob['user']?['name'] ??
        'Penjemputan Warga';
  }

  String get _rawAddress {
    return widget.jobData['address'] ??
        _rawJob['address'] ??
        _rawJob['user']?['address'] ??
        _rawJob['description'] ??
        'Lokasi Penjemputan';
  }

  String get _cleanAddress {
    return _rawAddress
        .replaceAll(RegExp(r'\[PEMESAN_ID:\d+\]'), '')
        .replaceAll(RegExp(r'\[WEIGHT:[\d.]+\]'), '')
        .replaceAll(RegExp(r'\[VEHICLE:\w+\]'), '')
        .trim();
  }

  String get _price {
    final rawPrice = widget.jobData['price'] ??
        _rawJob['price'] ??
        _rawJob['estimatedReward'] ??
        _rawJob['actualReward'] ??
        _rawJob['reward'];

    if (rawPrice == null) return 'Rp0';
    final String strPrice = rawPrice.toString().trim();
    if (!strPrice.startsWith('Rp')) {
      return 'Rp$strPrice';
    }
    return strPrice;
  }

  String get _volume {
    final rawWeight = widget.jobData['volume'] ??
        widget.jobData['estimatedWeight'] ??
        _rawJob['volume'] ??
        _rawJob['estimatedWeight'] ??
        _rawJob['totalWeight'] ??
        _rawJob['weight'];

    if (rawWeight == null) return '0 kg';
    final String strWeight = rawWeight.toString().trim();
    if (!strWeight.toLowerCase().contains('kg')) {
      return '$strWeight kg';
    }
    return strWeight;
  }

  String get _timeWindow {
    return widget.jobData['timeWindow'] ??
        _rawJob['timeWindow'] ??
        _rawJob['pickupWindow'] ??
        '12:00 - 15:00';
  }

  LatLng get _pickupLocation {
    final double? lat = double.tryParse((_rawJob['latitude'] ?? _rawJob['lat'] ?? widget.jobData['latitude'] ?? '').toString());
    final double? lng = double.tryParse((_rawJob['longitude'] ?? _rawJob['lng'] ?? widget.jobData['longitude'] ?? '').toString());
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(-6.9175, 107.6191);
  }

  @override
  void initState() {
    super.initState();
    _initJobSocket();
  }

  @override
  void dispose() {
    if (_resolvedJobId != null) {
      _socketService.leaveJobRoom(_resolvedJobId);
    }
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _initJobSocket() async {
    await _socketService.connect();
    if (_resolvedJobId != null) {
      _socketService.joinJobRoom(_resolvedJobId);
    }
    _socketSub = _socketService.events.listen((event) {
      if (!mounted || _resolvedJobId == null) return;
      final String targetId = _resolvedJobId.toString();
      if (event.type == 'job:claimed' && event.payload['jobId']?.toString() == targetId && !_isLoading) {
        setState(() => _isClaimedByOther = true);
      }
    });
  }

  Future<void> _handleAcceptJob() async {
    final dynamic jobId = _resolvedJobId;

    if (jobId == null) {
      _showPrerequisiteDialog('ID Pekerjaan tidak ditemukan atau format data pekerjaan tidak valid.');
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.acceptJob(jobId);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final Map<String, dynamic> updatedJobData = Map<String, dynamic>.from(widget.jobData);
      updatedJobData['status'] = 'ACCEPTED';
      if (updatedJobData['rawJob'] is Map) {
        final Map<String, dynamic> updatedRaw = Map<String, dynamic>.from(updatedJobData['rawJob']);
        updatedRaw['status'] = 'ACCEPTED';
        updatedJobData['rawJob'] = updatedRaw;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan penjemputan warga berhasil diterima!'),
          backgroundColor: AppColors.ecoGreen,
        ),
      );
      context.push('/dalam-perjalanan-rumah', extra: updatedJobData);
    } else {
      final String msg = (res['message'] ?? 'Gagal menerima pekerjaan.').toString();
      _showPrerequisiteDialog(msg);
    }
  }

  void _showPrerequisiteDialog(String errorMessage) {
    String title = "Prasyarat Belum Terpenuhi";
    String description = errorMessage;
    String buttonText = "Tutup";
    IconData icon = Icons.warning_amber_rounded;
    Color iconColor = Colors.orange;
    VoidCallback? onAction;

    if (errorMessage.contains("KYC_KTP_MISSING")) {
      title = "KTP Belum Diunggah";
      icon = Icons.badge_outlined;
      buttonText = "Unggah KTP";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("KYC_KTP_PENDING")) {
      title = "KTP Menunggu Verifikasi";
      icon = Icons.pending_actions_rounded;
      iconColor = AppColors.darkNavy;
      buttonText = "Cek Dokumen";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("KYC_KTP_REJECTED")) {
      title = "KTP Ditolak Admin";
      icon = Icons.error_outline_rounded;
      iconColor = AppColors.error;
      buttonText = "Unggah Ulang KTP";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("KYC_NOT_VERIFIED")) {
      title = "Akun Belum Aktif";
      icon = Icons.verified_user_outlined;
      buttonText = "Lengkapi Dokumen";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("VEHICLE_MISSING")) {
      title = "Kendaraan Belum Terdaftar";
      icon = Icons.two_wheeler_outlined;
      buttonText = "Daftar Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("VEHICLE_PENDING")) {
      title = "Kendaraan Menunggu Verifikasi";
      icon = Icons.hourglass_top_rounded;
      iconColor = AppColors.darkNavy;
      buttonText = "Cek Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("VEHICLE_REJECTED")) {
      title = "Kendaraan Ditolak Admin";
      icon = Icons.cancel_outlined;
      iconColor = AppColors.error;
      buttonText = "Perbarui Armada";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("VEHICLE_NOT_VERIFIED")) {
      title = "Kendaraan Belum Terverifikasi";
      icon = Icons.two_wheeler_outlined;
      buttonText = "Data Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("ACADEMY_NOT_COMPLETED")) {
      title = "Pelatihan Wajib Belum Selesai";
      icon = Icons.school_outlined;
      iconColor = AppColors.darkNavy;
      buttonText = "Buka Academy";
      onAction = () {
        Navigator.pop(context);
        context.push('/academy');
      };
    } else if (errorMessage.contains("VEHICLE_OVERLOAD")) {
      title = "Muatan Melebihi Kapasitas";
      icon = Icons.scale_rounded;
      buttonText = "Ganti Armada";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("LIMIT_EXCEEDED") || errorMessage.contains("3 pekerjaan aktif")) {
      title = "Batas Pekerjaan Tercapai";
      icon = Icons.assignment_late_outlined;
      buttonText = "Kembali";
      onAction = () {
        Navigator.pop(context);
        context.pop();
      };
    } else if (errorMessage.contains("JOB_NOT_AVAILABLE") || errorMessage.contains("sudah diambil")) {
      title = "Pekerjaan Tidak Tersedia";
      icon = Icons.info_outline_rounded;
      iconColor = Colors.grey;
      buttonText = "Pilih Pekerjaan Lain";
      onAction = () {
        Navigator.pop(context);
        context.pop();
      };
    }

    description = description.replaceAll(RegExp(r'^[A-Z_]+:\s*'), '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          ],
        ),
        content: Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onAction ?? () => Navigator.pop(ctx),
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMaterialChips() {
    final List rawMaterials = (widget.jobData['materials'] is List)
        ? widget.jobData['materials']
        : ((_rawJob['materials'] is List) ? _rawJob['materials'] : []);

    final List<Widget> chips = [];

    if (rawMaterials.isNotEmpty) {
      for (var mat in rawMaterials) {
        if (mat is Map) {
          final String name = mat['name'] ?? mat['category'] ?? mat['materialName'] ?? mat['material']?['name'] ?? 'Material';
          final String weight = mat['weight'] != null
              ? '${mat['weight']} kg'
              : (mat['estimatedWeight'] != null ? '${mat['estimatedWeight']} kg' : '');
          chips.add(_buildMaterialChip(Icons.recycling_rounded, '$name $weight'.trim()));
        } else if (mat != null) {
          chips.add(_buildMaterialChip(Icons.recycling_rounded, mat.toString()));
        }
      }
    } else {
      final String tag = (widget.jobData['materialTag'] ?? _rawJob['materialTag'] ?? _rawJob['materialCategory'] ?? '').toString();
      if (tag.isNotEmpty) {
        chips.add(_buildMaterialChip(Icons.recycling_rounded, tag));
      } else {
        chips.add(_buildMaterialChip(Icons.recycling_rounded, 'Sampah Warga ($_volume)'));
      }
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final String status = _jobStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Pekerjaan',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isClaimedByOther)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFFEE2E2),
                child: const Row(
                  children: [
                    Icon(Icons.info_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pekerjaan ini baru saja diambil oleh mitra lain.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: status == 'COMPLETED' ? const Color(0xFFDCFCE7) : AppColors.primaryYellow.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == 'COMPLETED' ? 'Selesai' : 'Penjemputan Rumah Warga',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: status == 'COMPLETED' ? AppColors.ecoGreen : AppColors.darkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(_title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(_cleanAddress, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: FlutterMap(
                          options: MapOptions(initialCenter: _pickupLocation, initialZoom: 13.5),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.ecocash_partnership',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _pickupLocation,
                                  width: 34,
                                  height: 34,
                                  child: const Icon(Icons.location_pin, color: AppColors.error, size: 34),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.recycling_rounded, color: AppColors.ecoGreen, size: 20),
                              SizedBox(width: 8),
                              Text('Material & Estimasi Bobot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildMaterialChips(),
                          ),
                          const SizedBox(height: 12),
                          Text(_volume, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimasi Pendapatan Mitra', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(_price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ecoGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.access_time_rounded, color: AppColors.darkNavy, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jendela Waktu Pengambilan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(_timeWindow, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7).withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: const Border(
                          left: BorderSide(color: AppColors.ecoGreen, width: 4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.ecoGreen, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pastikan material diverifikasi dan ditimbang sebelum pengambilan.',
                              style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: _buildBottomActions(status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.ecoGreen),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(String status) {
    if (status == 'COMPLETED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: AppColors.darkNavy),
          ),
          child: const Text(
            'Kembali',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
        ),
      );
    }

    const activeStatuses = ['ACCEPTED', 'IN_PROGRESS', 'ON_THE_WAY', 'CHECKED_IN', 'PICKUP', 'IN_TRANSIT', 'HANDOVER'];
    if (activeStatuses.contains(status)) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => context.push('/dalam-perjalanan-rumah', extra: widget.jobData),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text(
            'Lanjutkan Pekerjaan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.darkNavy, width: 1.2),
              ),
              child: const Text('Kembali', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_isLoading || _isClaimedByOther) ? null : _handleAcceptJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2.2),
                    )
                  : Text(
                      _isClaimedByOther ? 'Sudah Diambil Mitra Lain' : 'Terima Pekerjaan',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}