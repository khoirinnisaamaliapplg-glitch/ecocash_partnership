import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/app_storage.dart'; // Import penyimpanan status onboarding

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Memberikan jeda 3 detik untuk animasi/logo
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Cek apakah user sudah pernah melihat onboarding sebelumnya
    bool seen = await AppStorage.hasSeenOnboarding();

    if (seen) {
      // Jika sudah pernah, langsung arahkan ke Login
      context.go('/login');
    } else {
      // Jika belum (pengguna baru), arahkan ke Onboarding
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // Pastikan nama file sesuai
              width: 150,
              height: 150,
            ),
           const SizedBox(height: 24),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'EcoCash ',
                    style: TextStyle(color: AppColors.primary2), // Biru Navy
                  ),
                  TextSpan(
                    text: 'Partner',
                    style: TextStyle(color: AppColors.primaryGreen), // Hijau
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Collect. Verify. Earn. Grow.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}