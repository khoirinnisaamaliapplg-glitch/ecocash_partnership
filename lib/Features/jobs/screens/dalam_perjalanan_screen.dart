import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class DalamPerjalananScreen extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const DalamPerjalananScreen({super.key, required this.jobData});

  @override
  Widget build(BuildContext context) {
    final String material = jobData['materialTag'] ?? 'PET (Botol)';
    final String volume = jobData['volume'] ?? '44,80 kg';

    // Titik Koordinat Sesuai Referensi Gambar (Area Bandung)
    final LatLng startLocation = const LatLng(-6.9220, 107.6100); // Titik Asal (Pin Merah)
    final LatLng destinationLocation = const LatLng(-6.9200, 107.6350); // Titik Tujuan (Pin Hijau)

    // Titik jalur rute siku-siku/berkelok mengikuti jalan raya di gambar
    final List<LatLng> routePoints = [
      startLocation,
      const LatLng(-6.9150, 107.6100), // Belok ke utara
      const LatLng(-6.9150, 107.6220), // Belok ke timur melewati Jl. Sunda/Jawa
      const LatLng(-6.9210, 107.6250), // Belok ke tenggara menuju Jl. Laswi
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
          // --- 1. PETA INTERAKTIF LEAFLET DENGAN RUTE & LABEL ECO CASH ---
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
                
                // Garis Rute (Polyline) Berwarna Toska/Cyan Gelap
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF00838F),
                    ),
                  ],
                ),

                // Marker Pin & Label "EcoCash"
                MarkerLayer(
                  markers: [
                    // Marker Awal (Merah) dengan Label EcoCash
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
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                            ),
                            child: const Text(
                              'EcoCash',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Marker Tujuan (Hijau) dengan Label EcoCash
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
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                            ),
                            child: const Text(
                              'EcoCash',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. KARTU INFORMASI DI BAGIAN BAWAH ---
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
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryCyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Menuju Lokasi', style: TextStyle(fontSize: 12, color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 8),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.alt_route, size: 16, color: AppColors.textPrimary),
                          label: const Text('Lihat Rute', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryButtonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Anda telah sampai di lokasi penjemputan!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Sudah Sampai', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
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