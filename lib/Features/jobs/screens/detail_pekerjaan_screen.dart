import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/job_socket_service.dart';

class DetailPekerjaanScreen extends StatefulWidget {
  final Map jobData;

  const DetailPekerjaanScreen({super.key, required this.jobData});

  @override
  State<DetailPekerjaanScreen> createState() => _DetailPekerjaanScreenState();
}

class _DetailPekerjaanScreenState extends State<DetailPekerjaanScreen> {
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

  Map? get _machine {
    if (widget.jobData['machine'] is Map) {
      return widget.jobData['machine'] as Map;
    }
    if (_rawJob['machine'] is Map) {
      return _rawJob['machine'] as Map;
    }
    return null;
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

  LatLng get _pickupLocation {
    final double? lat = double.tryParse(
      (_machine?['latitude'] ?? _rawJob['latitude'] ?? widget.jobData['latitude'] ?? '').toString(),
    );
    final double? lng = double.tryParse(
      (_machine?['longitude'] ?? _rawJob['longitude'] ?? widget.jobData['longitude'] ?? '').toString(),
    );
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
      if (event.type == 'job:claimed' &&
          event.payload['jobId']?.toString() == _resolvedJobId.toString() &&
          !_isLoading) {
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
          content: Text('Pekerjaan pengosongan kontainer berhasil diambil!'),
          backgroundColor: AppColors.ecoGreen,
        ),
      );
      context.push('/dalam-perjalanan', extra: updatedJobData);
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

  @override
  Widget build(BuildContext context) {
    final String title = (widget.jobData['title'] ?? _rawJob['title'] ?? _machine?['name'] ?? 'Smart Container').toString();
    final String address = (widget.jobData['address'] ??
            _rawJob['address'] ??
            _machine?['address'] ??
            _machine?['placeName'] ??
            'Lokasi Smart Container')
        .toString();
    final String descCat = RegExp(r'\[CATEGORY:([^\]]+)\]').firstMatch((_rawJob['description'] ?? '').toString())?.group(1)?.trim() ?? '';
    final String material = (widget.jobData['materialTag'] ?? _rawJob['materialTag'] ?? (descCat.isNotEmpty ? descCat : 'Kontainer Penuh')).toString();
    final String volume = (widget.jobData['volume'] ?? _rawJob['volume'] ?? (_rawJob['estimatedWeight'] != null ? "${_rawJob['estimatedWeight']} kg" : '20.0 kg')).toString();
    final String price = (widget.jobData['price'] ?? _rawJob['price'] ?? 'Rp115.000').toString();
    final String status = _jobStatus;
    final LatLng pickupLocation = _pickupLocation;

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
          'Detail Pengosongan Kontainer',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isClaimedByOther) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tugas kontainer ini sudah diambil mitra lain.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Smart Container B2B',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'COMPLETED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'SELESAI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ecoGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: FlutterMap(
                  options: MapOptions(initialCenter: pickupLocation, initialZoom: 15.0),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ecocash_partnership',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickupLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin, color: AppColors.error, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: AppColors.ecoGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kapasitas Tersedia di Mesin', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(material, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.darkNavy)),
                      const SizedBox(height: 2),
                      Text(volume, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ecoGreen)),
                    ],
                  ),
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
                  const Text('Skema Komisi B2B (Rp 35.000 + Rp 2.000/kg)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.ecoGreen)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(status),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (status == 'COMPLETED') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.ecoGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Pengosongan Mesin Selesai',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ecoGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.darkNavy),
              ),
              child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            ),
          ),
        ],
      );
    }

    const activeStatuses = ['ACCEPTED', 'IN_PROGRESS', 'ON_THE_WAY', 'CHECKED_IN', 'PICKUP', 'IN_TRANSIT', 'HANDOVER'];
    if (activeStatuses.contains(status)) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => context.push('/dalam-perjalanan', extra: widget.jobData),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Lanjutkan Perjalanan ke Mesin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.darkNavy),
              ),
              child: const Text('Kembali', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            ),
          ),
        ),
        const SizedBox(width: 14),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2))
                  : Text(
                      _isClaimedByOther ? 'Sudah Diambil' : 'Terima Tugas Mesin',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}