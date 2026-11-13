import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DetailQrScreen extends StatelessWidget {
  final String kodeKontainer;

  const DetailQrScreen({super.key, this.kodeKontainer = 'EC-BGD-021'});

  static const Color _primaryYellow = Color(0xFFFFE600);
  static const Color _darkNavy = Color(0xFF0F2C59);
  static const Color _appBackground = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackground,
      appBar: AppBar(
        backgroundColor: _primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QR Code Kontainer',
          style: TextStyle(color: _darkNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, size: 140, color: _darkNavy),
                const SizedBox(height: 16),
                Text(
                  kodeKontainer,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tunjukkan QR ini kepada mitra untuk dipindai ulang',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}