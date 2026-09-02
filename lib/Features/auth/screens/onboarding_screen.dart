import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan MediaQuery untuk mendapatkan lebar layar agar responsif
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih bersih
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Jarak Atas ---
              const SizedBox(height: 30),

              // --- LOGO ECOBAS / ECO CASH (Diambil dari asset logo.png) ---
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Pastikan path asset benar
                      width: 40, // Sedikit diperbesar agar lebih terlihat
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
            
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- ILUSTRASI DENGAN EFEK LENGKUNG DI BAWAHNYA ---
              // Kita gunakan ClipPath untuk memotong gambar menjadi melengkung
              ClipPath(
                clipper: BottomCurveClipper(),
                child: Container(
                  height: screenWidth * 1.05, // Tinggi responsif berdasarkan lebar
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/onboarding.png'), // Pastikan path asset benar
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              // Jarak antara gambar dan teks
              const SizedBox(height: 5),

              // --- KONTEN TEKS & TOMBOL (Padding horizontal agar rapi) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // --- JUDUL ---
                    const Text(
                      'Selamat Datang di EcoCash',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // --- DESKRIPSI ---
                    const Text(
                      'Hubungkan, kelola, dan tumbuhkan ekosistem ekonomi sirkular bersama EcoCash.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5, // Line height agar mudah dibaca
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // --- 4 FITUR BADGE KECIL (Ditata dalam Row) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureBadge(Icons.all_inclusive, 'Terhubung'),
                        _buildFeatureBadge(Icons.verified_outlined, 'Terverifikasi'),
                        _buildFeatureBadge(Icons.bar_chart, 'Terukur'),
                        _buildFeatureBadge(Icons.volunteer_activism_outlined, 'Bernilai'),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // --- TOMBOL LOGIN DENGAN GRADASI (Menggunakan AppColors.primaryButtonGradient) ---
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryButtonGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Wajib transparan agar gradient Container terlihat
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- FOOTER DAFTAR ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Aksi ke halaman register/daftar
                            context.push('/register');
                          },
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLink,
                              decoration: TextDecoration.underline, // Opsional, sesuai mockup
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk membuat badge fitur kecil
  Widget _buildFeatureBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Warna latar icon box yang sangat terang
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primaryCyan, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// --- CUSTOM CLIPPER UNTUK MEMBUAT LENGKUNGAN DI BAWAH GAMBAR ---
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    
    // Mulai dari sudut kiri atas (0, 0)
    path.lineTo(0, size.height - 50); // Garis ke bawah sampai dekat sudut kiri bawah

    // Buat titik kontrol untuk kurva kuadratik (melengkung ke bawah)
    var firstControlPoint = Offset(size.width / 2, size.height + 30);
    var firstEndPoint = Offset(size.width, size.height - 50);

    // Terapkan kurva dari kiri bawah ke kanan bawah
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Garis ke atas sampai sudut kanan atas
    path.lineTo(size.width, 0);
    
    // Tutup path
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}