import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import 'material_verification_screen.dart'; // Import halaman verifikasi material yang baru dibuat

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  
  String? _kodeKontainer;
  bool _isScanning = true;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false; 
          _kodeKontainer = barcode.rawValue ?? 'EC-BGD-021';
        });
        break;
      }
    }
  }

  void _konfirmasiCheckIn() {
    setState(() {
      _kodeKontainer = 'EC-BGD-021';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check-in Berhasil! Kontainer: $_kodeKontainer'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Kamera Scanner Memenuhi Seluruh Latar Belakang Layar
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),

          // 2. Overlay Kotak Area Scan di Tengah Atas Kamera
          Align(
            alignment: const Alignment(0, -0.3),
            child: CustomPaint(
              size: const Size(220, 220),
              painter: ScannerOverlayPainter(),
            ),
          ),

          // Tombol Kembali di Kiri Atas
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Tombol Flash Petir di Kanan Atas
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
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                  });
                },
              ),
            ),
          ),

          // 3. Bottom Sheet Panel Informasi Check-in di Bawah
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
                    'Check-in',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan QR pada Smart Container',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Kotak Kode Kontainer dengan Ikon Mata
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
                              const Text(
                                'Kode Kontainer',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _kodeKontainer ?? 'Belum ada kontainer dipindai',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _kodeKontainer != null ? AppColors.textPrimary : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
                          onPressed: () {
                            // Membuka halaman verifikasi material ketika ikon mata diklik
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MaterialVerificationScreen(
                                  kodeKontainer: _kodeKontainer ?? 'EC-BGD-021',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Konfirmasi Check-in dengan Gradasi Warna Biru
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF108A9E), 
                          Color(0xFF2980B9), 
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _konfirmasiCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Konfirmasi Check-in',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Masukkan Manual',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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
    
    // Sudut Kiri Atas
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(r + len, 0);

    path.moveTo(r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    path.lineTo(0, r + len);

    // Sudut Kanan Atas
    path.moveTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, r + len);

    path.moveTo(w - r - len, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);

    // Sudut Kiri Bawah
    path.moveTo(0, h - r);
    path.quadraticBezierTo(0, h, r, h);
    path.lineTo(r + len, h);

    path.moveTo(0, h - r - len);
    path.lineTo(0, h - r);
    path.quadraticBezierTo(0, h, r, h);

    // Sudut Kanan Bawah
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