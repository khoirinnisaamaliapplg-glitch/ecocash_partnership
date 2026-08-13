import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data dummy untuk konten Onboarding. Nanti gambarnya bisa disesuaikan.
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Temukan Pekerjaan Terdekat",
      "text": "Lihat daftar pekerjaan pengumpulan material di sekitar lokasi Anda secara real-time.",
      "image": "assets/images/logo.png" // Sementara pakai logo, nanti diganti ilustrasi
    },
    {
      "title": "Kumpulkan & Verifikasi",
      "text": "Kumpulkan material dan verifikasi pekerjaan Anda dengan mudah melalui aplikasi.",
      "image": "assets/images/logo.png" 
    },
    {
      "title": "Dapatkan Penghasilan",
      "text": "Ubah sampah menjadi uang dan pantau saldo Anda di dalam dompet digital.",
      "image": "assets/images/logo.png" 
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Tombol "Lewati" di kanan atas
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Lewati',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            
            // Konten PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Placeholder Gambar (Jangan pakai const di sini jika pakai Image.asset)
                      Image.asset(
                        onboardingData[index]["image"]!,
                        height: 250,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        onboardingData[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        onboardingData[index]["text"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bagian Bawah: Indikator & Tombol Lanjut
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indikator Titik (Dots)
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index: index),
                    ),
                  ),
                  
                  // Tombol Lanjut / Mulai
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        // Jika di halaman terakhir, pergi ke Login
                        context.go('/login');
                      } else {
                        // Jika belum, geser ke halaman berikutnya
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1 ? 'Mulai' : 'Lanjut ->',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuat titik indikator
  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8, // Memanjang jika aktif
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary2 : AppColors.textSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}