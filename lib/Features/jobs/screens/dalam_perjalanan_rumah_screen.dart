import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';


// --- MODEL DATA BUKTI FOTO SAMPAH ---
class TrashPhotoItem {
  final String? path;
  final Uint8List? bytes;
  final String label;

  TrashPhotoItem({
    this.path,
    this.bytes,
    required this.label,
  });
}

class DalamPerjalananRumahScreen extends StatefulWidget {
  final Map extraData;

  const DalamPerjalananRumahScreen({super.key, this.extraData = const {}});

  @override
  State<DalamPerjalananRumahScreen> createState() => _DalamPerjalananRumahScreenState();
}

class _DalamPerjalananRumahScreenState extends State<DalamPerjalananRumahScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 1; // 1: Menuju Lokasi, 2: Timbang, 3: Kirim Ke Tong, 4: Selesai
  bool _isLoading = false;
  Timer? _statusCheckTimer;

  // State Bobot & Material
  double _weightPet = 10.5;
  double _weightKarton = 8.2;
  String _qrCodeHandover = '';

  // State Verifikasi QR Nasabah
  bool _isUserQrGenerated = false;
  String _generatedUserQrPayload = '';

  // State Daftar Bukti Foto Sampah
  final List<TrashPhotoItem> _trashPhotos = [];

  final LatLng _userLocation = const LatLng(-6.8915, 107.6101);
  LatLng get _customerLocation {
    final double? lat = double.tryParse(
      (_rawJob['latitude'] ?? _rawJob['lat'] ?? widget.extraData['latitude'] ?? '').toString(),
    );
    final double? lng = double.tryParse(
      (_rawJob['longitude'] ?? _rawJob['lng'] ?? widget.extraData['longitude'] ?? '').toString(),
    );
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(-6.8985, 107.6151); // Fallback default
  }
  
  static const Color _navyColor = Color(0xFF0B3C5D);
  static const Color _tealColor = Color(0xFF178CA4);
  static const Color _cyanHeader = Color(0xFF00C7C9);

  // --- GETTER DATA DINAMIS DARI BE ---
  dynamic get _jobId => widget.extraData['id'] ?? widget.extraData['rawJob']?['id'];
  Map get _rawJob => (widget.extraData['rawJob'] is Map) ? widget.extraData['rawJob'] : widget.extraData;

  String get _title => widget.extraData['title'] ?? _rawJob['title'] ?? _rawJob['customerName'] ?? 'Rumah Ibu Ratna';
  String get _rawAddress => widget.extraData['address'] ?? _rawJob['address'] ?? _rawJob['description'] ?? 'Jl. Cihampelas';
  String get _cleanAddress => _rawAddress.replaceAll(RegExp(r'\[.*?\]'), '').trim();

  double get _totalWeight => _weightPet + _weightKarton;
  double get _totalPayout => (_weightPet * 3000) + (_weightKarton * 2000);

  String get _wasteTypesSummary {
    List<String> items = [];
    if (_weightPet > 0) items.add('Plastik PET (${_weightPet.toStringAsFixed(1)} kg)');
    if (_weightKarton > 0) items.add('Karton Box (${_weightKarton.toStringAsFixed(1)} kg)');
    return items.isEmpty ? 'Belum Ada Material' : items.join(' • ');
  }

  String get _displayPrice {
    final raw = widget.extraData['price'] ?? _rawJob['price'] ?? _rawJob['estimatedReward'] ?? _rawJob['reward'];
    if (raw == null) return 'Rp 45.000';
    String str = raw.toString().trim();
    return str.startsWith('Rp') ? str : 'Rp $str';
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
    final String status = (_rawJob['status'] ?? '').toString().toUpperCase();

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

  void _generateCustomerVerificationQr() {
    List<Map<String, dynamic>> materialsList = [];
    if (_weightPet > 0) {
      materialsList.add({'type': 'Plastik PET', 'weightKg': _weightPet, 'ratePerKg': 3000});
    }
    if (_weightKarton > 0) {
      materialsList.add({'type': 'Kertas / Karton Box', 'weightKg': _weightKarton, 'ratePerKg': 2000});
    }

    final payloadMap = {
      'jobId': _jobId ?? 'EC-88392',
      'type': 'CUSTOMER_VERIFICATION',
      'totalWeightKg': _totalWeight,
      'totalPayoutRp': _totalPayout,
      'wasteTypesSummary': _wasteTypesSummary,
      'materials': materialsList,
      'photoProofCount': _trashPhotos.length,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _generatedUserQrPayload = jsonEncode(payloadMap);
      _isUserQrGenerated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code berhasil dibuat! Tunjukkan ke nasabah untuk dipindai.'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<void> _takeTrashPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        final Uint8List imageBytes = await photo.readAsBytes();
        _showPhotoLabelModal(imageBytes);
      }
    } catch (e) {
      _showError('Gagal membuka kamera: $e');
    }
  }

  void _showPhotoLabelModal(Uint8List imageBytes) {
    final TextEditingController labelController = TextEditingController(
      text: 'PET • ${_weightPet.toStringAsFixed(1)}kg',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_a_photo, color: _tealColor, size: 24),
            SizedBox(width: 10),
            Text('Keterangan Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pilih atau ketik jenis/kategori sampah:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickChip('PET • ${_weightPet.toStringAsFixed(1)}kg', labelController),
                _buildQuickChip('Karton • ${_weightKarton.toStringAsFixed(1)}kg', labelController),
                _buildQuickChip('Organik & Box', labelController),
                _buildQuickChip('Sampah Campur', labelController),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: labelController,
              decoration: InputDecoration(
                hintText: 'Contoh: Plastik PET / Kardus',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _tealColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final String labelText = labelController.text.trim();
              setState(() {
                _trashPhotos.add(TrashPhotoItem(
                  bytes: imageBytes,
                  label: labelText.isEmpty ? 'Foto Sampah' : labelText,
                ));
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto bukti sampah berhasil ditambahkan!'), backgroundColor: Colors.teal),
              );
            },
            child: const Text('Simpan Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        controller.text = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.cyan.shade200),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _navyColor)),
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: _cyanHeader,
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
        title: const Text('Detail Pekerjaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.cyan.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, size: 18, color: _navyColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tugas Penjemputan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('• Order #${_jobId ?? "EC-88392"} • Prioritas Tinggi', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        _buildStepHeaderItem(1, 'Menuju Lokasi'),
                        _buildStepHeaderDivider(1),
                        _buildStepHeaderItem(2, 'Timbang'),
                        _buildStepHeaderDivider(2),
                        _buildStepHeaderItem(3, 'Kirim Ke Tong'),
                        _buildStepHeaderDivider(3),
                        _buildStepHeaderItem(4, 'Selesai'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildActiveStepBody(),
              ),
            ),

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
                      backgroundColor: _tealColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _getBottomButtonText(),
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

  String _getBottomButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Konfirmasi sampai';
      case 2:
        return 'Lanjutkan';
      case 3:
        return 'Konfirmasi';
      default:
        return 'Lanjutkan';
    }
  }

  Widget _buildActiveStepBody() {
    switch (_currentStep) {
      case 1:
        return _buildStep1MenujuLokasi();
      case 2:
        return _buildStep2Timbang();
      case 3:
        return _buildStep3KirimKeTong();
      case 4:
        return _buildStep4Selesai();
      default:
        return Container();
    }
  }

  Widget _buildStep1MenujuLokasi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(initialCenter: _customerLocation, initialZoom: 14.5),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(
                      markers: [
                        Marker(point: _userLocation, width: 30, height: 30, child: const Icon(Icons.two_wheeler, color: _navyColor, size: 28)),
                        Marker(point: _customerLocation, width: 35, height: 35, child: const Icon(Icons.location_pin, color: Colors.teal, size: 35)),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF07485B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.turn_right, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BELOK KANAN DALAM 250M', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                            Text(_cleanAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('6 Menit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('1.4 km', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.my_location, size: 18, color: Colors.black87),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  height: 130,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/300?img=47'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF07485B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () => context.push('/chat/room/$_jobId'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.recycling, color: Colors.teal, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Muatan Jemputan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('~${_totalWeight.toStringAsFixed(0)} kg (Plastik, Organik, Karton)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF07485B), borderRadius: BorderRadius.circular(20)),
                child: Text('$_displayPrice (Est.)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Rincian Barang Pelanggan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('2 Kategori', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: const [
                    Icon(Icons.local_drink_outlined, color: _tealColor, size: 22),
                    SizedBox(height: 4),
                    Text('PET / Plastik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('18 kg', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: const [
                    Icon(Icons.inventory_2_outlined, color: _tealColor, size: 22),
                    SizedBox(height: 4),
                    Text('Kardus Tebal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('10 kg', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catatan User: "Sampah sudah dipilah dalam karung goni di teras depan pagar."',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Timbang() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Input Bobot Riil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                Text('Timbang dan sesuaikan estimasi lapangan', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: const [
                  Icon(Icons.hourglass_empty, size: 12, color: Colors.teal),
                  SizedBox(width: 4),
                  Text('TIMBANGAN DIGITAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _RealWeightInputCard(
          title: 'Plastik PET (Botol Bersih)',
          subRate: 'Rp 3.000 / kg',
          weight: _weightPet,
          ratePerKg: 3000,
          onChanged: (val) => setState(() => _weightPet = val),
        ),
        const SizedBox(height: 10),

        _RealWeightInputCard(
          title: 'Kertas / Karton Box',
          subRate: 'Rp 2.000 / kg',
          weight: _weightKarton,
          ratePerKg: 2000,
          onChanged: (val) => setState(() => _weightKarton = val),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFEEF7F8), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL BERAT TERKUMPUL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text('${_totalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navyColor)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL NILAI PAYOUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text('Rp ${_totalPayout.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bukti Foto Sampah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _trashPhotos.isEmpty ? Colors.red.shade50 : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _trashPhotos.isEmpty ? 'Wajib (Min. 1 Foto)' : 'Tersimpan (${_trashPhotos.length} Foto)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _trashPhotos.isEmpty ? Colors.red : Colors.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: _takeTrashPhoto,
                child: Container(
                  width: 90,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyan.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, color: _tealColor, size: 24),
                      SizedBox(height: 4),
                      Text('Ambil Foto\nTambahan', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey, height: 1.1)),
                    ],
                  ),
                ),
              ),
              if (_trashPhotos.isNotEmpty) const SizedBox(width: 8),

              ..._trashPhotos.map((photo) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildPhotoThumbnailItem(photo),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // --- METODE VERIFIKASI NASABAH ---
        const Text('Metode Verifikasi Nasabah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              OutlinedButton.icon(
                onPressed: _generateCustomerVerificationQr,
                icon: const Icon(Icons.qr_code, color: Colors.teal, size: 18),
                label: const Text('Buat QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isUserQrGenerated
                    ? 'Tunjukkan QR Code ini kepada nasabah untuk diverifikasi di aplikasi nasabah'
                    : 'Klik tombol di atas untuk membuat QR Code hasil penimbangan',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E2838), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUserQrGenerated) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _generatedUserQrPayload,
                          version: QrVersions.auto,
                          size: 150.0,
                          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _navyColor),
                          dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _navyColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.tealAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'QR Siap Scan • ${_totalWeight.toStringAsFixed(1)} kg • Rp ${_totalPayout.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Jenis Sampah: $_wasteTypesSummary',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Foto Bukti: ${_trashPhotos.length} foto tersimpan',
                        style: const TextStyle(fontSize: 9, color: Colors.white70),
                      ),
                    ] else ...[
                      const Icon(Icons.qr_code_2, size: 60, color: Colors.tealAccent),
                      const SizedBox(height: 10),
                      const Text('QR Code Belum Dibuat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Tekan tombol "Buat QR" untuk menampilkan kode verifikasi', style: TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.teal, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Penjemputan Tervalidasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                    Text('Data timbangan ${_totalWeight.toStringAsFixed(1)} kg tersinkronisasi offline & siap diantar ke Drop Point Mitra Daur Ulang.', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3KirimKeTong() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.factory_outlined, color: _tealColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('Mitra Resmi Terdaftar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('PT Green Packaging Recycler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Text('Kawasan Industri Soekarno-Hatta Km. 9, Bandung', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),

              Container(
                height: 90,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(initialCenter: _userLocation, initialZoom: 13),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.navigation, size: 12, color: Colors.white),
                        label: const Text('NAVIGASI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tealColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(12)),
                child: const Text('Validasi Handover Material', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
              const SizedBox(height: 8),
              const Text('Tunjukkan QR Ini ke Smart Container', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              const Text('Petugas Partner harus menunjukan QR ini ke smart Bin untuk di scan untuk validasi barang masuk', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 150, color: _navyColor),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tag, size: 12, color: Colors.grey),
                        Text(' #EC-TRX-2026-${_jobId ?? "89412"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 12, color: Colors.teal),
                        const Text(' 04:57', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Muatan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _navyColor)),
                        Text('${_totalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniMaterialChip('PET BENING', '${_weightPet.toStringAsFixed(1)} kg'),
                        _buildMiniMaterialChip('ORGANIK', '14.0 kg'),
                        _buildMiniMaterialChip('KARTON BOX', '${_weightKarton.toStringAsFixed(1)} kg'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _openCameraScannerModal,
            icon: const Icon(Icons.qr_code_scanner, color: _tealColor),
            label: const Text('Pindai QR Fisik Mesin Kontainer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _tealColor)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _tealColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
              onPressed: () => _submitMachineScanVerification('RVM-001'),
              child: const Text('Simulasi Scan Selesai (Debug)', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep4Selesai() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFF69F0AE),
          child: Icon(Icons.check, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),

        const Text('Pembayaran Diterima!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navyColor)),
        const SizedBox(height: 4),
        Text(_displayPrice, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildSummaryRow('Metode', 'EcoCash Wallet'),
              const Divider(height: 20),
              _buildSummaryRow('Pekerjaan', _title),
              const Divider(height: 20),
              _buildSummaryRow('Berat Final', '${_totalWeight.toStringAsFixed(1)} kg'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/main'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _tealColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          radius: 12,
          backgroundColor: isDone ? Colors.teal : (isActive ? _tealColor : Colors.grey.shade300),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$stepNumber', style: TextStyle(fontSize: 10, color: isActive ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive ? _tealColor : (isDone ? Colors.teal : Colors.grey),
          ),
        ),
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

  Widget _buildPhotoThumbnailItem(TrashPhotoItem photo) {
    Widget imageWidget;

    if (photo.bytes != null) {
      imageWidget = Image.memory(
        photo.bytes!,
        width: 90,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      );
    } else if (photo.path != null && photo.path!.isNotEmpty) {
      imageWidget = Image.network(
        photo.path!,
        width: 90,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      );
    } else {
      imageWidget = Container(color: Colors.grey.shade300);
    }

    return Container(
      width: 90,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(child: imageWidget),
            const Positioned(top: 4, right: 4, child: Icon(Icons.check_circle, color: Colors.teal, size: 16)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Text(
                  photo.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMaterialChip(String title, String weight) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey)),
          Text(weight, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

// --- WIDGET KOMPONEN HYBRID INPUT BOBOT TIMBANGAN ---
class _RealWeightInputCard extends StatefulWidget {
  final String title;
  final String subRate;
  final double weight;
  final double ratePerKg;
  final ValueChanged<double> onChanged;

  const _RealWeightInputCard({
    required this.title,
    required this.subRate,
    required this.weight,
    required this.ratePerKg,
    required this.onChanged,
  });

  @override
  State<_RealWeightInputCard> createState() => _RealWeightInputCardState();
}

class _RealWeightInputCardState extends State<_RealWeightInputCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.weight.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _RealWeightInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weight != widget.weight) {
      final newStr = widget.weight.toStringAsFixed(1);
      if (_controller.text != newStr && double.tryParse(_controller.text) != widget.weight) {
        _controller.text = newStr;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateWeight(double newWeight) {
    double clamped = newWeight.clamp(0.0, 999.0);
    _controller.text = clamped.toStringAsFixed(1);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    double totalPayout = widget.weight * widget.ratePerKg;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              Text('@ ${widget.subRate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 105,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    suffixText: 'KG ',
                    suffixStyle: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (val) {
                    double? parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null) {
                      widget.onChanged(parsed.clamp(0.0, 999.0));
                    }
                  },
                ),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => _updateWeight(widget.weight - 0.5)),
              IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _updateWeight(widget.weight + 0.5)),
              ElevatedButton(
                onPressed: () => _updateWeight(widget.weight + 5.0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade100,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('+5kg', style: TextStyle(fontSize: 10, color: Color(0xFF178CA4), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Rp ${totalPayout.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
        ],
      ),
    );
  }
}