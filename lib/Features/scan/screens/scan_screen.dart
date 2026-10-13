import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import 'material_verification_screen.dart';

class ScanScreen extends StatefulWidget {
  final Map? jobData;

  const ScanScreen({super.key, this.jobData});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final PartnerApiService _apiService = PartnerApiService();

  String? _kodeKontainer;
  bool _isScanning = true;
  bool _isTorchOn = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isLoading) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _isScanning = false;
          _kodeKontainer = barcode.rawValue!.trim();
        });
        _prosesCheckInOtomatis(_kodeKontainer!);
        break;
      }
    }
  }

  Future<void> _prosesCheckInOtomatis(String scannedCode) async {
    final dynamic jobId = widget.jobData?['id'] ?? widget.jobData?['rawJob']?['id'];

    if (jobId == null) {
      // Jika dibuka mandiri tanpa job, langsung buka verifikasi visual
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaterialVerificationScreen(
            kodeKontainer: scannedCode,
            jobData: widget.jobData,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Validasi check-in fisik di mesin target
    final res = await _apiService.checkIn(
      jobId,
      qrCode: scannedCode,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true || res['status'] == 'CHECKED_IN' || res['data']?['status'] == 'CHECKED_IN') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi Mesin $scannedCode Terverifikasi! Pintu kontainer dibuka.'),
          backgroundColor: Colors.teal,
        ),
      );

      // 2. Buka layar verifikasi muatan dan penentuan bobot angkut
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MaterialVerificationScreen(
            kodeKontainer: scannedCode,
            jobData: widget.jobData,
          ),
        ),
      );
    } else {
      setState(() => _isScanning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Kode mesin tidak cocok dengan penugasan Smart Container ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _inputManualDialog() {
    final String defaultCode = widget.jobData?['machine']?['machineCode'] ?? 'RVM-001';
    final controller = TextEditingController(text: _kodeKontainer ?? defaultCode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Manual Kode Mesin'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Contoh: RVM-001',
            labelText: 'Kode Smart Container',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
            onPressed: () {
              Navigator.pop(ctx);
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                setState(() {
                  _kodeKontainer = input;
                  _isScanning = false;
                });
                _prosesCheckInOtomatis(input);
              }
            },
            child: const Text('Verifikasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String targetCode = widget.jobData?['machine']?['machineCode'] ?? 'RVM-001';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.3),
            child: CustomPaint(
              size: const Size(230, 230),
              painter: ScannerOverlayPainter(),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? Colors.amber : Colors.black,
                ),
                onPressed: () async {
                  await _scannerController.toggleTorch();
                  setState(() => _isTorchOn = !_isTorchOn);
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan Smart Container',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Arahkan kamera ke barcode fisik mesin untuk membuka kompartemen',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_2, color: AppColors.primaryCyan, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Mesin Penugasan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                _kodeKontainer ?? targetCode,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                            onPressed: () => setState(() => _isScanning = true),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _prosesCheckInOtomatis(_kodeKontainer ?? targetCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Konfirmasi & Buka Pintu Mesin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _inputManualDialog,
                    child: const Text('Masukkan Kode Manual', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;
    const double r = 20.0;
    const double len = 30.0;

    final path = Path();
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(r + len, 0);

    path.moveTo(r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    path.lineTo(0, r + len);

    path.moveTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, r + len);

    path.moveTo(w - r - len, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);

    path.moveTo(0, h - r);
    path.quadraticBezierTo(0, h, r, h);
    path.lineTo(r + len, h);

    path.moveTo(0, h - r - len);
    path.lineTo(0, h - r);
    path.quadraticBezierTo(0, h, r, h);

    path.moveTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(w - r - len, h);

    path.moveTo(w, h - r - len);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}