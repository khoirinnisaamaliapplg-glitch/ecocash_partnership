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

  @override
  void initState() {
    super.initState();
    _initStartRoute();
  }

  Future<void> _initStartRoute() async {
    final dynamic jobId = widget.jobData['id'];
    if (jobId != null) {
      await _apiService.startRoute(jobId);
    }
  }

  Future<void> _handleCheckIn() async {
    final dynamic jobId = widget.jobData['id'];
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda telah sampai di lokasi penjemputan!')),
      );
      return;
    }

    setState(() => _isActionLoading = true);
    final res = await _apiService.checkIn(jobId);
    setState(() => _isActionLoading = false);

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in lokasi berhasil tervalidasi!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal melakukan check-in')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String material = widget.jobData['materialTag'] ?? 'PET (Botol)';
    final String volume = widget.jobData['volume'] ?? '44,80 kg';

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
        title: const Text('Dalam Perjalanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(-6.9180, 107.6220),
                initialZoom: 14.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecocash_partnership',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF00838F),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: startLocation,
                      width: 100,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 40),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('EcoCash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),
                    Marker(
                      point: destinationLocation,
                      width: 100,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on, color: Colors.teal, size: 40),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('EcoCash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ],
                      ),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('EcoCash Mitra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.near_me, size: 14, color: AppColors.textSecondary),
                              SizedBox(width: 4),
                              Text('2,1 km / 20 menit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.recycling, color: AppColors.primaryCyan, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Material', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(material, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Estimasi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(volume, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sudah Sampai & Check-In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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