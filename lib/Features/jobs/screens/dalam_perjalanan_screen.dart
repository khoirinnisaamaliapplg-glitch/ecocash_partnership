import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class DalamPerjalananScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const DalamPerjalananScreen({super.key, required this.jobData});

  @override
  State<DalamPerjalananScreen> createState() => _DalamPerjalananScreenState();
}

class _DalamPerjalananScreenState extends State<DalamPerjalananScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  bool _isActionLoading = false;

  dynamic get _jobId => widget.jobData['id'] ?? widget.jobData['rawJob']?['id'];

  @override
  void initState() {
    super.initState();
    _initStartRoute();
  }

  Future<void> _initStartRoute() async {
    if (_jobId != null) {
      await _apiService.startRoute(_jobId);
    }
  }

  // Dialog Penentuan Muatan Pengosongan Parsial Mesin
  void _showEmptyingDialog(double machineWeight) {
    const double vehicleLimit = 35.0; // Kapasitas maksimal motor
    double maxTake = machineWeight < vehicleLimit ? machineWeight : vehicleLimit;
    double selectedWeight = maxTake;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int estReward = 35000 + (selectedWeight * 2000).round();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Konfirmasi Pengosongan Mesin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                  const SizedBox(height: 6),
                  Text(
                    'Tersedia di mesin: ${machineWeight.toStringAsFixed(1)} kg • Batas armada: ${vehicleLimit.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${selectedWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                      Text(
                        'Komisi: Rp ${estReward.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedWeight,
                    min: 5.0,
                    max: maxTake,
                    divisions: ((maxTake - 5.0) / 5.0).clamp(1, 10).toInt(),
                    activeColor: AppColors.primaryCyan,
                    onChanged: (val) {
                      setModalState(() => selectedWeight = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _processEmptyingPickup(selectedWeight);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Buka Kompartemen & Muat Sampah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processEmptyingPickup(double takenWeight) async {
    setState(() => _isActionLoading = true);
    try {
      final res = await _apiService.submitPickup(
        _jobId,
        materials: [
          {'materialId': 1, 'pickupWeight': takenWeight}
        ],
        notes: 'Muatan kontainer berhasil diangkut ke armada',
      );

      if (!mounted) return;
      setState(() => _isActionLoading = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Muatan ${takenWeight.toStringAsFixed(1)} kg dinaikkan ke kendaraan! Menuju Pabrik Daur Ulang.'),
            backgroundColor: Colors.teal,
          ),
        );
        // Navigasi ke daftar tugas aktif
        context.go('/tugas');
      }
    } catch (_) {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleCheckIn() async {
    if (_jobId == null) {
      context.push('/scan', extra: widget.jobData);
      return;
    }

    setState(() => _isActionLoading = true);
    final res = await _apiService.checkIn(_jobId);
    setState(() => _isActionLoading = false);

    if (!mounted) return;

    if (res['success'] == true || res['status'] == 'CHECKED_IN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiba di lokasi Smart Container! Pintu siap dibuka.'),
          backgroundColor: Colors.teal,
        ),
      );
      // Tampilkan bottom sheet untuk menentukan berat muatan yang diangkut
      _showEmptyingDialog(40.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal melakukan check-in')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String machineName = widget.jobData['title'] ?? widget.jobData['machine']?['name'] ?? 'Smart Container';
    final String address = widget.jobData['address'] ??
        widget.jobData['machine']?['address'] ??
        widget.jobData['machine']?['placeName'] ??
        'Lokasi Mesin';
    final String material = widget.jobData['materialTag'] ?? 'PET (Botol)';
    final String volume = widget.jobData['volume'] ?? '40,0 kg';

    final LatLng startLocation = const LatLng(-6.9220, 107.6100);
    final LatLng destinationLocation = const LatLng(-6.9200, 107.6350);

    final List<LatLng> routePoints = [
      startLocation,
      const LatLng(-6.9150, 107.6100),
      const LatLng(-6.9150, 107.6220),
      const LatLng(-6.9210, 107.6250),
      destinationLocation,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Menuju Smart Container', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 250,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-6.9180, 107.6220),
                initialZoom: 14.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecocash_partnership',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: routePoints, strokeWidth: 4.5, color: const Color(0xFF00838F)),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: startLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.local_shipping, color: Color(0xFF0F2C59), size: 36),
                    ),
                    Marker(
                      point: destinationLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(machineName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primaryCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.recycling, color: AppColors.primaryCyan, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Material Mesin', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(material, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Estimasi Muatan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(volume, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryCyan)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isActionLoading ? null : _handleCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isActionLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sampai di Mesin & Buka Kontainer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}