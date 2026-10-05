import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class DalamPerjalananRumahScreen extends StatefulWidget {
  final Map extraData;

  const DalamPerjalananRumahScreen({super.key, this.extraData = const {}});

  @override
  State<DalamPerjalananRumahScreen> createState() => _DalamPerjalananRumahScreenState();
}

class _DalamPerjalananRumahScreenState extends State<DalamPerjalananRumahScreen> {
  int _currentStep = 1; // 1: Menuju Lokasi, 2: Timbang, 3: Kirim ke Tong, 4: Selesai
  bool _isLoading = false;

  double _weightPet = 10.5;
  double _weightKarton = 8.2;

  final LatLng _userLocation = const LatLng(-6.8915, 107.6101);
  final LatLng _customerLocation = const LatLng(-6.8985, 107.6151);

  double get _totalWeight => _weightPet + _weightKarton;
  double get _totalPayout => (_weightPet * 3000) + (_weightKarton * 2000);

  Map get _job => widget.extraData;

  // SIMULASI DUMMY TRANSISI STEP (MOCK API DELAY)
  Future<void> _handleStepNext() async {
    setState(() => _isLoading = true);

    // Memberikan efek loading 800ms seolah-olah sedang memproses data ke server
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_currentStep < 4) {
          _currentStep++;
        }
      });

      // Tampilkan notifikasi singkat sesuai langkahnya
      if (_currentStep == 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[DUMMY] Berhasil Check-In di rumah warga!')),
        );
      } else if (_currentStep == 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[DUMMY] Data timbangan tersimpan di lokal!')),
        );
      }
    }
  }

  String _getStepButtonLabel() {
    switch (_currentStep) {
      case 1:
        return 'Konfirmasi Sampai & Check-In';
      case 2:
        return 'Simpan & Lanjutkan Handover';
      case 3:
        return 'Konfirmasi Handover Selesai';
      default:
        return 'Selesai';
    }
  }

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
          'Penjemputan Rumah (Mode Demo)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                  _buildStepHeaderItem(3, 'Setor Mitra'),
                  _buildStepHeaderDivider(3),
                  _buildStepHeaderItem(4, 'Selesai'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            // --- KONTEN STEP ACTIVE ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildActiveStepBody(title, address),
              ),
            ),

            // --- TOMBOL AKSI BAWAH ---
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
                    onPressed: _isLoading ? null : _handleStepNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88A8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
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

  Widget _buildActiveStepBody(String title, String address) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Navigasi(title, address);
      case 2:
        return _buildStep2Timbang(title, address);
      case 3:
        return _buildStep3Handover();
      case 4:
        return _buildStep4Selesai();
      default:
        return Container();
    }
  }

  // STEP 1: NAVIGASI
  Widget _buildStep1Navigasi(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(initialCenter: _customerLocation, initialZoom: 14.5),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
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
      ],
    );
  }

  // STEP 2: TIMBANG
  Widget _buildStep2Timbang(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Input Bobot Timbangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildWeightInputCard('Plastik PET (Botol)', _weightPet, (v) => setState(() => _weightPet = v)),
        const SizedBox(height: 10),
        _buildWeightInputCard('Kertas / Karton Box', _weightKarton, (v) => setState(() => _weightKarton = v)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL BERAT', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text('${_totalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('ESTIMASI PAYOUT', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text('Rp ${_totalPayout.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInputCard(String title, double weight, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () => onChanged((weight - 0.5).clamp(0.0, 100.0))),
              Text('${weight.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, color: Color(0xFF1E88A8)), onPressed: () => onChanged(weight + 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 3: HANDOVER / SETOR
  Widget _buildStep3Handover() {
    return Column(
      children: [
        const Text('Tunjukkan QR Handover ke Mitra Daur Ulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F2C59), width: 2), borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Icon(Icons.qr_code_2, size: 150, color: Color(0xFF0F2C59))),
        ),
      ],
    );
  }

  // STEP 4: SELESAI
  Widget _buildStep4Selesai() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Penjemputan Selesai!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Rp ${_totalPayout.toStringAsFixed(0)} telah ditambahkan ke dompet', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/jobs'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88A8)),
            child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // UI STEPPER HEADER
  Widget _buildStepHeaderItem(int stepNumber, String title) {
    bool isDone = _currentStep > stepNumber;
    bool isActive = _currentStep == stepNumber;
    return Column(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: isDone ? Colors.teal : (isActive ? const Color(0xFF1E88A8) : Colors.grey.shade300),
          child: Text('$stepNumber', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 8, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepHeaderDivider(int stepNumber) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > stepNumber ? Colors.teal : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }
}