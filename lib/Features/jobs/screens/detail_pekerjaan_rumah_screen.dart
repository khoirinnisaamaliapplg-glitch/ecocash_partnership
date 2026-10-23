import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class DetailPekerjaanRumahScreen extends StatefulWidget {
  final Map jobData;

  const DetailPekerjaanRumahScreen({super.key, required this.jobData});

  @override
  State<DetailPekerjaanRumahScreen> createState() => _DetailPekerjaanRumahScreenState();
}

class _DetailPekerjaanRumahScreenState extends State<DetailPekerjaanRumahScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  bool _isLoading = false;

  static const Color _navyColor = Color(0xFF0B3C5D);
  static const Color _tealColor = Color(0xFF178CA4);

  // Helper untuk mengambil object data utama backend
  Map get _rawJob => (widget.jobData['rawJob'] is Map) ? widget.jobData['rawJob'] : widget.jobData;

  // --- GETTER DATA DINAMIS DARI BACKEND ---
  String get _jobStatus {
    final status = widget.jobData['status'] ?? _rawJob['status'] ?? 'AVAILABLE';
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
    String strPrice = rawPrice.toString().trim();
    if (!strPrice.startsWith('Rp')) {
      return 'Rp$strPrice';
    }
    return strPrice;
  }

  String get _volume {
    final rawWeight = widget.jobData['volume'] ??
        widget.jobData['estimatedWeight'] ??
        _rawJob['estimatedWeight'] ??
        _rawJob['totalWeight'] ??
        _rawJob['weight'];

    if (rawWeight == null) return '0 kg';
    String strWeight = rawWeight.toString().trim();
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
    final double? lat = double.tryParse((_rawJob['latitude'] ?? _rawJob['lat'] ?? '').toString());
    final double? lng = double.tryParse((_rawJob['longitude'] ?? _rawJob['lng'] ?? '').toString());
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(-6.9175, 107.6191);
  }

  // --- LOGIKA TERIMA PEKERJAAN ---
  Future<void> _handleAcceptJob() async {
    final dynamic jobId = widget.jobData['id'] ?? _rawJob['id'];

    if (jobId == null) {
      context.push('/dalam-perjalanan-rumah', extra: widget.jobData);
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.acceptJob(jobId);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan penjemputan warga berhasil diterima!'),
          backgroundColor: Colors.teal,
        ),
      );
      context.push('/dalam-perjalanan-rumah', extra: widget.jobData);
    } else {
      final String msg = (res['message'] ?? '').toString();
      _showPrerequisiteDialog(msg);
    }
  }

  void _showPrerequisiteDialog(String errorMessage) {
    String title = "Prasyarat Belum Terpenuhi";
    String description = errorMessage;
    String buttonText = "Tutup";
    VoidCallback? onAction;

    if (errorMessage.contains("KYC_NOT_VERIFIED")) {
      title = "Verifikasi Data Diri (KYC)";
      description = "Akun Anda belum aktif. Harap lengkapi KTP dan dokumen identitas Anda untuk ditinjau oleh tim admin.";
      buttonText = "Lengkapi Dokumen";
      onAction = () {
        Navigator.pop(context);
        context.push('/dokumen-legalitas');
      };
    } else if (errorMessage.contains("VEHICLE_NOT_VERIFIED")) {
      title = "Verifikasi Kendaraan";
      description = "Kendaraan Anda belum terdaftar atau belum diverifikasi. Daftarkan plat nomor dan data kendaraan Anda.";
      buttonText = "Data Kendaraan";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    } else if (errorMessage.contains("ACADEMY_NOT_COMPLETED")) {
      title = "Pelatihan Mitra Wajib";
      description = "Anda belum menyelesaikan modul pelatihan di EcoCash Academy. Selesaikan pelatihan standar operasional sebelum menerima order.";
      buttonText = "Buka Academy";
      onAction = () {
        Navigator.pop(context);
        context.push('/academy');
      };
    } else if (errorMessage.contains("VEHICLE_OVERLOAD")) {
      title = "Kapasitas Armada Tidak Muat";
      description = errorMessage.replaceFirst(RegExp(r'^VEHICLE_OVERLOAD:\s*'), '');
      buttonText = "Ganti Armada";
      onAction = () {
        Navigator.pop(context);
        context.push('/kendaraan');
      };
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
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
            child: Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- RENDER DYNAMIC MATERIAL CHIPS ---
  List<Widget> _buildMaterialChips() {
    final List rawMaterials = (widget.jobData['materials'] is List)
        ? widget.jobData['materials']
        : ((_rawJob['materials'] is List) ? _rawJob['materials'] : []);

    List<Widget> chips = [];

    if (rawMaterials.isNotEmpty) {
      for (var mat in rawMaterials) {
        if (mat is Map) {
          String name = mat['name'] ?? mat['category'] ?? mat['materialName'] ?? 'Material';
          String weight = mat['weight'] != null
              ? '${mat['weight']} kg'
              : (mat['estimatedWeight'] != null ? '${mat['estimatedWeight']} kg' : '');
          chips.add(_buildMaterialChip(Icons.recycling, '$name $weight'.trim()));
        } else if (mat != null) {
          chips.add(_buildMaterialChip(Icons.recycling, mat.toString()));
        }
      }
    } else {
      final String tag = (widget.jobData['materialTag'] ?? _rawJob['materialTag'] ?? _rawJob['materialCategory'] ?? '').toString();
      if (tag.isNotEmpty) {
        chips.add(_buildMaterialChip(Icons.recycling, tag));
      } else {
        chips.add(_buildMaterialChip(Icons.recycling, 'Sampah Warga ($_volume)'));
      }
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final String status = _jobStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Pekerjaan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == 'COMPLETED' ? 'Selesai' : 'Pekerjaan Tersedia',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryCyan),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Judul Alamat & Lokasi dari Backend
                    Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(_cleanAddress, style: const TextStyle(fontSize: 13, color: Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Peta
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(initialCenter: _pickupLocation, initialZoom: 13.0),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.ecocash_partnership',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _pickupLocation,
                                  width: 32,
                                  height: 32,
                                  child: const Icon(Icons.location_pin, color: Colors.red, size: 32),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card Material & Total KG dari Backend
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
                          const Row(
                            children: [
                              Icon(Icons.recycling, color: _navyColor, size: 20),
                              SizedBox(width: 8),
                              Text('Material', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildMaterialChips(),
                          ),
                          const SizedBox(height: 12),
                          Text(_volume, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navyColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card Estimasi Pendapatan dari Backend
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
                          const Text('Estimasi Pendapatan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(_price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _navyColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card Jendela Waktu Pengambilan dari Backend
                    Container(
                      padding: const EdgeInsets.all(14),
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
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.access_time, color: Colors.black87, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jendela Waktu Pengambilan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(_timeWindow, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Banner Instruksi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF007A5E), width: 4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF007A5E), size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pastikan material diverifikasi sebelum pengambilan.',
                              style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
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

            // Tombol Aksi Bawah
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
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
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _tealColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(String status) {
    if (status == 'COMPLETED') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text(
            'Kembali',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      );
    }

    if (status == 'ACCEPTED' || status == 'IN_PROGRESS' || status == 'ON_THE_WAY' || status == 'PICKUP' || status == 'IN_TRANSIT') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => context.push('/dalam-perjalanan-rumah', extra: widget.jobData),
          style: ElevatedButton.styleFrom(
            backgroundColor: _tealColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text(
            'Lanjutkan Pekerjaan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: _navyColor, width: 1.2),
              ),
              child: const Text('Tolak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navyColor)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAcceptJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Terima Pekerjaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}