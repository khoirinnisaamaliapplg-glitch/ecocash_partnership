import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import 'package:flutter/foundation.dart'; // <--- Tambahkan import ini jika belum ada

class DalamPerjalananRumahScreen extends StatefulWidget {
  final Map extraData;

  const DalamPerjalananRumahScreen({super.key, this.extraData = const {}});

  @override
  State<DalamPerjalananRumahScreen> createState() => _DalamPerjalananRumahScreenState();
}

class _DalamPerjalananRumahScreenState extends State<DalamPerjalananRumahScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  int _currentStep = 1; // 1: Menuju Lokasi, 2: Timbang, 3: Setor, 4: Selesai
  bool _isLoading = false;
  Timer? _statusCheckTimer;

  double _weightPet = 10.5;
  double _weightKarton = 8.2;
  String _qrCodeHandover = '';

  final LatLng _userLocation = const LatLng(-6.8915, 107.6101);
  final LatLng _customerLocation = const LatLng(-6.8985, 107.6151);

  double get _totalWeight => _weightPet + _weightKarton;
  double get _totalPayout => 20000 + (_totalWeight * 1000);

  dynamic get _jobId => widget.extraData['id'] ?? widget.extraData['rawJob']?['id'];

  bool get _isTargetContainer {
    final desc = (widget.extraData['description'] ?? widget.extraData['rawJob']?['description'] ?? '').toString();
    return desc.contains('Smart Container');
  }

  @override
  void initState() {
    super.initState();
    _initFlowState();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initFlowState() async {
    final rawJob = widget.extraData['rawJob'] ?? widget.extraData;
    final String status = (rawJob['status'] ?? '').toString().toUpperCase();

    if (status == 'CHECKED_IN' || status == 'PICKUP') {
      setState(() => _currentStep = 2);
    } else if (status == 'IN_TRANSIT' || status == 'HANDOVER') {
      setState(() => _currentStep = 3);
      _fetchExistingQr();
      _startStatusPolling();
    } else if (status == 'COMPLETED') {
      setState(() => _currentStep = 4);
    } else {
      if (_jobId != null) {
        await _apiService.startRoute(_jobId);
      }
    }
  }

  Future<void> _fetchExistingQr() async {
    if (_jobId == null) return;
    final res = await _apiService.generateHandoverQr(_jobId);
    if (res['success'] == true && res['data']?['qrCode'] != null) {
      if (mounted) {
        setState(() {
          _qrCodeHandover = res['data']['qrCode'];
        });
      }
    }
  }

  // Polling otomatis untuk mendeteksi kapan Smart Container selesai memindai QR tugas
  void _startStatusPolling() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _currentStep != 3 || _jobId == null) {
        timer.cancel();
        return;
      }

      try {
        final res = await _apiService.getJobDetail(_jobId);
        if (res['success'] == true && res['data'] != null) {
          final String currentStatus = (res['data']['status'] ?? '').toString().toUpperCase();
          if (currentStatus == 'COMPLETED') {
            timer.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Smart Container berhasil memverifikasi QR! Tugas selesai.'),
                  backgroundColor: Colors.teal,
                ),
              );
              setState(() => _currentStep = 4);
            }
          }
        }
      } catch (e) {
        debugPrint('Polling status error: $e');
      }
    });
  }

  Future<void> _handleStepNext() async {
    if (_jobId == null) {
      if (_currentStep < 4) setState(() => _currentStep++);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_currentStep == 1) {
        final res = await _apiService.checkIn(_jobId);
        if (res['success'] == true) {
          setState(() => _currentStep = 2);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Berhasil Check-In di lokasi penjemputan!')),
            );
          }
        } else {
          _showError(res['message'] ?? 'Gagal Check-In');
        }
      } else if (_currentStep == 2) {
        final materialsPayload = [
          {'materialId': 1, 'pickupWeight': _weightPet},
          {'materialId': 2, 'pickupWeight': _weightKarton},
        ];

        final resPickup = await _apiService.submitPickup(_jobId, materials: materialsPayload);
        if (resPickup['success'] == true) {
          final resQr = await _apiService.generateHandoverQr(_jobId);
          setState(() {
            _qrCodeHandover = resQr['data']?['qrCode'] ?? 'HANDOVER-#$_jobId';
            _currentStep = 3;
          });
          _startStatusPolling();
        } else {
          _showError(resPickup['message'] ?? 'Gagal menyimpan timbangan');
        }
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Membuka pemindai kamera untuk membaca QR fisik pada bodi Smart Container
  void _openCameraScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Pindai QR Fisik Smart Container',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) async {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                        final String scannedCode = barcode.rawValue!.trim();
                        Navigator.pop(ctx);
                        _submitMachineScanVerification(scannedCode);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Arahkan kamera ke stiker QR Code yang tertera di mesin kontainer',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMachineScanVerification(String scannedCode) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.completeToMachine(
        _jobId,
        machineCode: scannedCode,
        totalWeightKg: _totalWeight,
      );

      if (res['success'] == true) {
        _statusCheckTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kontainer $scannedCode terverifikasi! Muatan berhasil disetor.'),
              backgroundColor: Colors.teal,
            ),
          );
          setState(() => _currentStep = 4);
        }
      } else {
        _showError(res['message'] ?? 'Kode kontainer tidak cocok dengan penugasan');
      }
    } catch (e) {
      _showError('Gagal memverifikasi mesin: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rawTitle = widget.extraData['title'] ?? 'Penjemputan Warga';
    final String rawAddress = widget.extraData['address'] ??
        widget.extraData['rawJob']?['description'] ??
        'Lokasi Warga';

    final String cleanAddress = rawAddress.replaceAll(RegExp(r'\[PEMESAN_ID:\d+\]'), '').trim();

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
        title: const Text('Penjemputan Warga', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  _buildStepHeaderItem(1, 'Menuju Lokasi'),
                  _buildStepHeaderDivider(1),
                  _buildStepHeaderItem(2, 'Timbang'),
                  _buildStepHeaderDivider(2),
                  _buildStepHeaderItem(3, 'Setor'),
                  _buildStepHeaderDivider(3),
                  _buildStepHeaderItem(4, 'Selesai'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildActiveStepBody(rawTitle, cleanAddress),
              ),
            ),
            if (_currentStep < 3)
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
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _currentStep == 1 ? 'Konfirmasi Sampai & Check-In' : 'Simpan & Lanjutkan ke Penyetoran',
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
        return _buildStep2Timbang();
      case 3:
        return _buildStep3Handover();
      case 4:
        return _buildStep4Selesai();
      default:
        return Container();
    }
  }

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

  Widget _buildStep2Timbang() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Input Bobot Timbangan dari Warga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Text('KOMISI JASA ANGKUT', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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

  Widget _buildStep3Handover() {
    return Column(
      children: [
        const Text(
          'Verifikasi Mesin Smart Container',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Tunjukkan QR ini ke scanner kamera Smart Container untuk membuka pintu dan menyelesaikan tugas.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Container(
          width: 230,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF0F2C59), width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2, size: 140, color: Color(0xFF0F2C59)),
              const SizedBox(height: 8),
              Text(
                _qrCodeHandover.isNotEmpty ? _qrCodeHandover : 'HANDOVER-#$_jobId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E88A8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Polling Status Box (Menunggu Mesin Memindai)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB9D7F6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F2C59))),
              SizedBox(width: 10),
              Text(
                'Menunggu pemindaian dari Smart Container...',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Alternatif jika kamera mesin tidak membaca layar: Mitra memindai QR fisik mesin menggunakan HP
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _openCameraScannerModal,
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryCyan),
            label: const Text(
              'Pindai QR Fisik Mesin Kontainer',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bug_report, color: Colors.white),
              label: const Text(
                'Simulasi Scan Mesin Selesai (Debug)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : () => _submitMachineScanVerification('RVM-001'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep4Selesai() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Penjemputan Selesai!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Komisi Rp ${_totalPayout.toStringAsFixed(0)} telah ditambahkan ke dompet Anda.', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/main'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88A8)),
            child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

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