import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class DetailPekerjaanRumahScreen extends StatefulWidget {
  final Map jobData;

  const DetailPekerjaanRumahScreen({super.key, required this.jobData});

  @override
  State<DetailPekerjaanRumahScreen> createState() => _DetailPekerjaanRumahScreenState();
}

class _DetailPekerjaanRumahScreenState extends State<DetailPekerjaanRumahScreen> {
  bool _isLoading = false;

  // SIMULASI TERIMA PEKERJAAN RUMAH (DUMMY MODE)
  Future<void> _handleAcceptJob() async {
    setState(() => _isLoading = true);

    // Simulasi delay jaringan 500ms
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('[DEMO] Pekerjaan penjemputan warga berhasil diterima!'),
        backgroundColor: Colors.teal,
      ),
    );

    // Pindah ke alur multi-step penjemputan rumah warga (Mode Demo)
    context.push('/dalam-perjalanan-rumah', extra: widget.jobData);
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.jobData['title'] ?? 'Rumah Ibu Ratna #BDG11';
    final String address = widget.jobData['address'] ?? 'Komplek Permata Blok C2/14';
    final String price = widget.jobData['price'] ?? 'Rp45.000';

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
        title: const Text(
          'Detail Pekerjaan (Rumah)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Jenis Pekerjaan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Penjemputan Warga (Demo Mode)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                ),
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

              // Preview Peta Lokasi Rumah
              Container(
                height: 170,
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
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Rincian Material & Berat
              Container(
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
                      children: [
                        const Icon(Icons.recycling, color: AppColors.primaryCyan, size: 20),
                        const SizedBox(width: 8),
                        const Text('Estimasi Material', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(Icons.inventory_2_outlined, 'Plastik PET ~12 kg'),
                        _buildChip(Icons.autorenew, 'Karton Box ~8 kg'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('~20 kg', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Estimasi Pendapatan
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
                    Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Jendela Waktu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.access_time, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jendela Waktu Pengambilan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        SizedBox(height: 2),
                        Text('12:00 - 15:00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Tolak & Terima Pekerjaan
              Row(
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Terima Pekerjaan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0F2C59)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
        ],
      ),
    );
  }
}