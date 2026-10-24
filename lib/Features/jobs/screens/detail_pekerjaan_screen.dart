import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class DetailPekerjaanScreen extends StatefulWidget {
  final Map jobData;

  const DetailPekerjaanScreen({super.key, required this.jobData});

  @override
  State<DetailPekerjaanScreen> createState() => _DetailPekerjaanScreenState();
}

class _DetailPekerjaanScreenState extends State<DetailPekerjaanScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  bool _isLoading = false;

  static const Color _tealColor = Color(0xFF178CA4);

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
          backgroundColor: Colors.teal,
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
      iconColor = Colors.orange;
      buttonText = "Unggah KTP";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("KYC_KTP_PENDING")) {
      title = "KTP Menunggu Verifikasi";
      icon = Icons.pending_actions_rounded;
      iconColor = _tealColor;
      buttonText = "Cek Dokumen";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("KYC_KTP_REJECTED")) {
      title = "KTP Ditolak Admin";
      icon = Icons.error_outline_rounded;
      iconColor = Colors.redAccent;
      buttonText = "Unggah Ulang KTP";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("KYC_NOT_VERIFIED")) {
      title = "Akun Belum Aktif";
      icon = Icons.verified_user_outlined;
      iconColor = Colors.orange;
      buttonText = "Lengkapi Dokumen";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("VEHICLE_MISSING")) {
      title = "Kendaraan Belum Terdaftar";
      icon = Icons.two_wheeler_outlined;
      iconColor = Colors.orange;
      buttonText = "Daftar Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("VEHICLE_PENDING")) {
      title = "Kendaraan Menunggu Verifikasi";
      icon = Icons.hourglass_top_rounded;
      iconColor = _tealColor;
      buttonText = "Cek Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("VEHICLE_REJECTED")) {
      title = "Kendaraan Ditolak Admin";
      icon = Icons.cancel_outlined;
      iconColor = Colors.redAccent;
      buttonText = "Perbarui Armada";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("VEHICLE_NOT_VERIFIED")) {
      title = "Kendaraan Belum Terverifikasi";
      icon = Icons.two_wheeler_outlined;
      iconColor = Colors.orange;
      buttonText = "Data Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("ACADEMY_NOT_COMPLETED")) {
      title = "Pelatihan Wajib Belum Selesai";
      icon = Icons.school_outlined;
      iconColor = _tealColor;
      buttonText = "Buka Academy";
      onAction = () {
        Navigator.pop(context);
        context.push('/academy');
      };
    } else if (errorMessage.contains("VEHICLE_OVERLOAD")) {
      title = "Muatan Melebihi Kapasitas";
      icon = Icons.scale_rounded;
      iconColor = Colors.orange;
      buttonText = "Ganti Armada";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("LIMIT_EXCEEDED") || errorMessage.contains("3 pekerjaan aktif")) {
      title = "Batas Pekerjaan Tercapai";
      icon = Icons.assignment_late_outlined;
      iconColor = Colors.orange;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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
              backgroundColor: AppColors.primaryCyan,
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
    final String material = (widget.jobData['materialTag'] ?? _rawJob['materialTag'] ?? 'PET (Botol)').toString();
    final String volume = (widget.jobData['volume'] ?? _rawJob['volume'] ?? '40.0 kg').toString();
    final String price = (widget.jobData['price'] ?? _rawJob['price'] ?? 'Rp115.000').toString();
    final String status = _jobStatus;
    final LatLng pickupLocation = _pickupLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Pengosongan Kontainer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                  ),
                  child: const Text('Smart Container B2B', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                ),
                const SizedBox(width: 8),
                if (status == 'COMPLETED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text('SELESAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_sweep_outlined, color: AppColors.primaryCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kapasitas Tersedia di Mesin', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(material, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(volume, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryCyan)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Skema Komisi B2B (Rp 35.000 + Rp 2.000/kg)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
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
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                SizedBox(width: 8),
                Text(
                  'Pengosongan Mesin Selesai',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
          ),
        ],
      );
    }

    const activeStatuses = ['ACCEPTED', 'IN_PROGRESS', 'ON_THE_WAY', 'CHECKED_IN', 'PICKUP', 'IN_TRANSIT', 'HANDOVER'];
    if (activeStatuses.contains(status)) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryButtonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: () => context.push('/dalam-perjalanan', extra: widget.jobData),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Lanjutkan Perjalanan ke Mesin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('Tolak', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryButtonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAcceptJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Terima Tugas Mesin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}