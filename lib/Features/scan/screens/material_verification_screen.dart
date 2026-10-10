import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class MaterialVerificationScreen extends StatefulWidget {
  final String kodeKontainer;
  final Map? jobData;

  const MaterialVerificationScreen({
    super.key,
    this.kodeKontainer = 'RVM-001',
    this.jobData,
  });

  @override
  State<MaterialVerificationScreen> createState() => _MaterialVerificationScreenState();
}

class _MaterialVerificationScreenState extends State<MaterialVerificationScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  bool _isLoading = false;

  late double _availableInMachine;
  late double _maxVehicleCapacity;
  late double _selectedWeight;

  @override
  void initState() {
    super.initState();
    // Ekstraksi bobot aktual di mesin (misal 40.0 kg)
    final dynamic rawWeight = widget.jobData?['estimatedWeight'] ??
        widget.jobData?['machine']?['currentWeight'];

    if (rawWeight != null) {
      _availableInMachine = double.tryParse(rawWeight.toString()) ?? 40.0;
    } else {
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(widget.jobData?['volume'] ?? '');
      _availableInMachine = match != null ? (double.tryParse(match.group(1)!) ?? 40.0) : 40.0;
    }

    // Kapasitas armada motor (35 kg)
    _maxVehicleCapacity = 35.0;

    // Batas pengambilan: tidak boleh melebihi sisa mesin dan batas motor
    final double maxAllowed = _availableInMachine < _maxVehicleCapacity
        ? _availableInMachine
        : _maxVehicleCapacity;

    _selectedWeight = maxAllowed;
  }

  String _formatCurrency(num number) {
    final str = number.toStringAsFixed(0);
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> _selesaikanPengambilanMuatan() async {
    final dynamic jobId = widget.jobData?['id'] ?? widget.jobData?['rawJob']?['id'];

    if (jobId == null) {
      context.go('/tugas');
      return;
    }

    setState(() => _isLoading = true);

    // Kirim timbangan parsial ke backend (status job -> IN_TRANSIT, bobot mesin berkurang)
    final res = await _apiService.submitPickup(
      jobId,
      materials: [
        {
          'materialId': 1,
          'pickupWeight': _selectedWeight,
        },
      ],
      notes: 'Muatan kontainer ${widget.kodeKontainer} (${_selectedWeight.toStringAsFixed(1)} kg) berhasil dimuat ke armada.',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true || res['status'] == 'IN_TRANSIT' || res['data']?['status'] == 'IN_TRANSIT') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Muatan ${_selectedWeight.toStringAsFixed(1)} kg dimuat! Menuju Pos Mitra Daur Ulang.'),
          backgroundColor: Colors.teal,
        ),
      );

      // Navigasi ke daftar tugas "Sedang Diproses" untuk lanjut ke QR Handover
      context.go('/tugas');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal memproses muatan kontainer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String machineName = widget.jobData?['machine']?['name'] ??
        widget.jobData?['title'] ??
        'Smart Container Stasiun Sudirman';
    final String displayCode = widget.kodeKontainer;

    // Perhitungan komisi B2B: Rp 35.000 + (Bobot x Rp 2.000/kg)
    final int estimatedReward = 35000 + (_selectedWeight * 2000).round();
    final double maxAllowed = _availableInMachine < _maxVehicleCapacity
        ? _availableInMachine
        : _maxVehicleCapacity;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi & Muat Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Pintu Mesin Terbuka
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_open_rounded, size: 55, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    displayCode,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    machineName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text('Kompartemen Mesin Terbuka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pilihan Muatan yang Diangkut Armada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tentukan Muatan Diangkut', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text('Tersedia: ${_availableInMachine.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Muatan Armada', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedWeight.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Estimasi Komisi B2B', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${_formatCurrency(estimatedReward)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _selectedWeight,
                    min: 5.0,
                    max: maxAllowed,
                    divisions: ((maxAllowed - 5.0) / 5.0).clamp(1, 10).toInt(),
                    activeColor: AppColors.primaryCyan,
                    onChanged: (val) {
                      setState(() => _selectedWeight = val);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Min: 5 kg', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('Batas Motor: ${_maxVehicleCapacity.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Rincian Formula B2B: Rp 35.000 + (Rp 2.000/kg)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Konfirmasi Muat
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _selesaikanPengambilanMuatan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Muat ke Armada & Menuju Recycler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}