import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart'; // <-- IMPORT LEAFLET
import 'package:latlong2/latlong.dart';     // <-- IMPORT KOORDINAT
import '../../../core/theme/app_colors.dart';
import 'dalam_perjalanan_screen.dart';

class DetailPekerjaanScreen extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const DetailPekerjaanScreen({super.key, required this.jobData});

  @override
  Widget build(BuildContext context) {
    final String title = jobData['title'] ?? 'EcoCash Valen #BGD-021';
    final String address = jobData['address'] ?? 'Institut Teknologi Bandung';
    final String material = jobData['materialTag'] ?? 'PET (Botol)';
    final String volume = jobData['volume'] ?? '42 kg';
    final String price = jobData['price'] ?? 'Rp82.000';

    // Koordinat contoh (Bandung/Singaparna)
    final LatLng pickupLocation = const LatLng(-6.9175, 107.6191);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Pekerjaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER INFORMASI TUGAS ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyan.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Pekerjaan Tersedia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),

            // --- 2. INTEGRASI LEAFLET MAP ---
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
                  options: MapOptions(
                    initialCenter: pickupLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    // Lapisan Peta OpenStreetMap
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ecocash_partnership',
                    ),
                    // Lapisan Marker / Pin Lokasi
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickupLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 3. KARTU MATERIAL DINAMIS ---
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
                    child: const Icon(Icons.recycling, color: AppColors.primaryCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Material', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

            // --- 4. ESTIMASI PENDAPATAN ---
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
                  const Text('Estimasi Pendapatan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary2)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- 5. JENDELA WAKTU PENGAMBILAN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Jendela Waktu Pengambilan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('12:00 - 15:00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- 6. KOTAK PERINGATAN / INFO ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Colors.green, width: 4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pastikan material diverifikasi sebelum pengambilan.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 7. TOMBOL AKSI (TOLAK & TERIMA) ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DalamPerjalananScreen(
                              jobData: jobData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Terima Pekerjaan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}