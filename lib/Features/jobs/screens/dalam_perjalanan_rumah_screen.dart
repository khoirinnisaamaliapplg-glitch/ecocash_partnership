import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class DalamPerjalananRumahScreen extends StatefulWidget {
  final Map extraData;

  const DalamPerjalananRumahScreen({super.key, this.extraData = const {}});

  @override
  State createState() => _DalamPerjalananRumahScreenState();
}

class _DalamPerjalananRumahScreenState extends State {
  int _currentStep = 1; // 1: Menuju Lokasi, 2: Timbang, 3: Kirim ke Tong, 4: Selesai

  double _weightPet = 10.5;
  double _weightKarton = 8.2;

  final LatLng _userLocation = const LatLng(-6.8915, 107.6101);
  final LatLng _customerLocation = const LatLng(-6.8985, 107.6151);

  double get _totalWeight => _weightPet + _weightKarton;
  double get _totalPayout => (_weightPet * 3000) + (_weightKarton * 2000);

  Map get _job => (widget as DalamPerjalananRumahScreen).extraData;

  @override
  Widget build(BuildContext context) {
    final String title = _job['title'] ?? 'Ibu Ratna Dewi';
    final String address = _job['address'] ?? 'Komplek Permata Blok C2/14';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Detail Pekerjaan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- STEPPER HEADER ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  _buildStepHeaderItem(1, 'Menuju Lokasi'),
                  _buildStepHeaderDivider(1),
                  _buildStepHeaderItem(2, 'Timbang'),
                  _buildStepHeaderDivider(2),
                  _buildStepHeaderItem(3, 'Kirim ke Tong'),
                  _buildStepHeaderDivider(3),
                  _buildStepHeaderItem(4, 'Selesai'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            // --- ISI KONTEN UTAMA ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildActiveStepBody(title, address),
              ),
            ),

            // --- TOMBOL AKSI BAWAH (Hanya tampil untuk Step 1, 2, dan 3) ---
            if (_currentStep < 4)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleStepNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88A8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _getStepButtonLabel(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleStepNext() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  String _getStepButtonLabel() {
    switch (_currentStep) {
      case 1:
        return 'Konfirmasi sampai';
      case 2:
        return 'Lanjutkan';
      case 3:
        return 'Konfirmasi';
      default:
        return 'Selesai';
    }
  }

  Widget _buildActiveStepBody(String title, String address) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Navigasi(title, address);
      case 2:
        return _buildStep2Timbang(title, address);
      case 3:
        return _buildStep3Handover();
      case 4:
        return _buildStep4Selesai(title);
      default:
        return Container();
    }
  }

  // ================= STEP 1: MENUJU LOKASI =================
  Widget _buildStep1Navigasi(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tugas Penjemputan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Order #EC-88392 • Prioritas Tinggi', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2C59),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.turn_right, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BELOK KANAN DALAM 250M', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text('Jl. Cihampelas', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('6 Menit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('1.4 km', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(initialCenter: _customerLocation, initialZoom: 14.5),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                PolylineLayer(
                  polylines: [
                    Polyline(points: [_userLocation, _customerLocation], color: const Color(0xFF1E88A8), strokeWidth: 4),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(point: _userLocation, width: 30, height: 30, child: const Icon(Icons.two_wheeler, color: Color(0xFF0F2C59), size: 28)),
                    Marker(point: _customerLocation, width: 35, height: 35, child: const Icon(Icons.location_pin, color: Colors.red, size: 35)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1E88A8), size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.recycling, color: Color(0xFF1E88A8)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target Muatan Jemputan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text('~33 kg (Plastik, Organik, Karton)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0F2C59), borderRadius: BorderRadius.circular(8)),
                child: const Text('Rp 54.000 (Est.)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Rincian Barang Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildItemCategoryCard(Icons.local_drink_outlined, 'PET / Plastik', '18 kg')),
            const SizedBox(width: 10),
            Expanded(child: _buildItemCategoryCard(Icons.inventory_2_outlined, 'Kardus Tebal', '10 kg')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1E88A8), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catatan User: "Sampah sudah dipilah dalam karung goni di teras depan pagar."',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCategoryCard(IconData icon, String title, String weight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1E88A8), size: 22),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(weight, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= STEP 2: TIMBANG =================
  Widget _buildStep2Timbang(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(4)),
                          child: const Text('RUMAH TANGGA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                        ),
                      ],
                    ),
                    Text(address, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.phone_outlined, color: Color(0xFF1E88A8), size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Input Bobot Riil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Timbang dan sesuaikan estimasi lapangan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(6)),
              child: const Row(
                children: [
                  Icon(Icons.scale, size: 12, color: Color(0xFF1E88A8)),
                  SizedBox(width: 4),
                  Text('TIMBANGAN DIGITAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWeightInputCard('Plastik PET (Botol Bersih)', 'Rp 3.000 / kg', _weightPet, 3000, (v) => setState(() => _weightPet = v)),
        const SizedBox(height: 10),
        _buildWeightInputCard('Kertas / Karton Box', 'Rp 2.000 / kg', _weightKarton, 2000, (v) => setState(() => _weightKarton = v)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL BERAT TERKUMPUL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  Text('${_totalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL NILAI PAYOUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  Text('Rp ${_totalPayout.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bukti Foto Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('Wajib (2 Foto)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Color(0xFF1E88A8)),
                  SizedBox(height: 4),
                  Text('Ambil Foto\nTambahan', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: Color(0xFF1E88A8))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildPhotoItem('https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=150', 'PET • 10.5kg'),
            const SizedBox(width: 10),
            _buildPhotoItem('https://images.unsplash.com/photo-1605600659908-0ef719419d41?w=150', 'Organik & Box'),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              CircleAvatar(backgroundColor: Color(0xFF1E88A8), radius: 14, child: Icon(Icons.check, size: 16, color: Colors.white)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penjemputan Tervalidasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F2C59))),
                    Text('Data timbangan 32.7 kg tersinkronisasi offline & siap diantar ke Drop Point Mitra Daur Ulang.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInputCard(String title, String priceTag, double weight, int pricePerKg, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1E88A8), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text(priceTag, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(8)),
                child: Text('${weight.toStringAsFixed(1)} KG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: () => onChanged((weight - 0.5).clamp(0.0, 100.0)),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF1E88A8)),
                onPressed: () => onChanged(weight + 0.5),
              ),
              ElevatedButton(
                onPressed: () => onChanged(weight + 5.0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEBF3FC),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('+5kg', style: TextStyle(color: Color(0xFF1E88A8), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Rp ${(weight * pricePerKg).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88A8), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String imgUrl, String label) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(imgUrl, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8)),
          ),
        ),
      ],
    );
  }

  // ================= STEP 3: KIRIM KE TONG =================
  Widget _buildStep3Handover() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.store, color: Color(0xFF1E88A8), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.teal),
                            SizedBox(width: 4),
                            Text('Mitra Resmi Terdaftar', style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('PT Green Packaging Recycler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Kawasan Industri Soekarno-Hatta Km. 9, Bandung', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 90,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(initialCenter: _customerLocation, initialZoom: 13.0),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.navigation, size: 12, color: Colors.white),
                          label: const Text('NAVIGASI', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88A8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(6)),
                child: const Text('Validasi Handover Material', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8))),
              ),
              const SizedBox(height: 8),
              const Text('Tunjukkan QR Ini ke Smart Container', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Petugas Partner harus menunjukan QR ini ke smart Bin untuk di scan untuk validasi barang masuk', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0F2C59), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 130, color: Color(0xFF0F2C59)),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text('#EC-TRX-2026-89412 • ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Icon(Icons.timer, size: 12, color: Color(0xFF1E88A8)),
                  SizedBox(width: 2),
                  Text('04:57', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.scale, size: 16, color: Color(0xFF1E88A8)),
                      SizedBox(width: 6),
                      Text('Total Muatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Text('32.7 kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F2C59))),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniBreakdown('PET BENING', '10.5 kg'),
                  _buildMiniBreakdown('ORGANIK', '14.0 kg'),
                  _buildMiniBreakdown('KARTON BOX', '8.2 kg'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBreakdown(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ================= STEP 4: PEMBAYARAN DITERIMA (SELESAI) =================
  Widget _buildStep4Selesai(String title) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Circle Checklist Hijau
        CircleAvatar(
          radius: 45,
          backgroundColor: const Color(0xFF69F0AE).withOpacity(0.4),
          child: const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFF00E676),
            child: Icon(Icons.check, size: 45, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Pembayaran Diterima!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
        ),
        const SizedBox(height: 8),
        Text(
          'Rp45.000',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
        ),
        const SizedBox(height: 24),

        // Detail Transaksi Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow('Metode', 'EcoCash Wallet'),
              const Divider(height: 24, color: Color(0xFFF0F0F0)),
              _buildSummaryRow('Pekerjaan', 'EcoCash Valen #BGD-021'),
              const Divider(height: 24, color: Color(0xFFF0F0F0)),
              _buildSummaryRow('Berat Final', '32.7 kg'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Tombol Lihat Detail
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88A8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Lihat Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol Kembali ke Beranda
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              context.go('/jobs');
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFF0F2C59)),
            ),
            child: const Text('Kembali ke Beranda', style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
      ],
    );
  }

  // --- STEPPER HEADER COMPONENTS ---
  Widget _buildStepHeaderItem(int stepNumber, String title) {
    bool isDone = _currentStep > stepNumber;
    bool isActive = _currentStep == stepNumber;

    Color circleBg = (isDone || (isActive && stepNumber == 4))
        ? Colors.teal
        : (isActive ? const Color(0xFF1E88A8) : Colors.grey.shade200);
    Color textCol = isDone || isActive ? Colors.white : Colors.grey;

    return Column(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: circleBg,
          child: (isDone || (isActive && stepNumber == 4))
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text('$stepNumber', style: TextStyle(fontSize: 10, color: textCol, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 8, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.textPrimary : Colors.grey)),
      ],
    );
  }

  Widget _buildStepHeaderDivider(int stepNumber) {
    bool isDone = _currentStep > stepNumber;
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? Colors.teal : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }
}