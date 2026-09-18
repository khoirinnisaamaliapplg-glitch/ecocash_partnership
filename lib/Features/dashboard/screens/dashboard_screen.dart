import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, this.userData = const {}});

  @override
  Widget build(BuildContext context) {
    final String namaUser = userData['name'] ?? userData['nama'] ?? 'Budi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DENGAN EFEK GELOMBANG WARNA (SWEEP/RADIAL GRADIENT) ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Header Kotak Dasar dengan Kurva di Bawah Saja
                ClipPath(
                  clipper: HeaderWaveClipper(),
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryCyan,
                    ),
                  ),
                ),

                // 2. Lapisan Kedua untuk Efek Garis Gelombang Warna (Curved Color Wave Overlay)
                ClipPath(
                  clipper: CurvedColorWaveClipper(),
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5FF).withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),

                // 3. Teks Sapaan
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $namaUser!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready to recycle?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Kartu Total Penghasilan (Berwarna Putih)
                Positioned(
                  top: 150,
                  left: 20,
                  right: 20,
                  child: InkWell(
                    onTap: () => context.push('/detail-penghasilan'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Total Penghasilan Hari Ini',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Rp187.500',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '+12% dari kemarin',
                                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Jarak kosong agar konten di bawah kartu tidak bertumpuk
            const SizedBox(height: 80),

            // --- KONTEN BERANDA BERIKUTNYA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STATISTIK KARTU HANYA 2 (Material & Pekerjaan) ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Material', '48,6 kg', 'Terkumpul', Icons.recycling, const Color(0xFF1565C0),
                          onTap: () => context.push('/statistik-material'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Pekerjaan', '3 Selesai', 'Hari ini', Icons.local_shipping_outlined, Colors.green,
                          onTap: () => context.push('/riwayat-pekerjaan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- KARTU LEVEL PARTNER ---
                  InkWell(
                    onTap: () => context.push('/skor-partner'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Level Silver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                              Text('Gold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text('Skor Partner: 876/1000', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: LinearProgressIndicator(
                              value: 0.876,
                              backgroundColor: Color(0xFFE0E0E0),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLink2),
                              minHeight: 8,
                            ),
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('124 poin lagi ke Level Gold', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- PEKERJAAN TERSEDIA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pekerjaan Tersedia',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildJobCard('EcoCash Vision #BDG-021', 'PET (Botol)', '2.3 km (Jln. Braga)', 'Rp82.000', 'High'),
                        const SizedBox(width: 12),
                        _buildJobCard('Reguler #BDG-022', 'Kardus & Kertas', '3.1 km (Jl. Asia Afrika)', 'Rp45.000', 'Medium'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- AKTIVITAS TERBARU ---
                  const Text(
                    'Aktivitas Terbaru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem(Icons.check_circle_outline, Colors.green, 'Pekerjaan Selesai', '12:30 • #BDG-019', '+Rp65.000', Colors.green),
                  const SizedBox(height: 10),
                  _buildActivityItem(Icons.swap_horiz, Colors.blueGrey, 'Withdrawal Diproses', '09:15 • Ke Rek. BCA', '-Rp150.000', AppColors.textPrimary),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color iconColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(String code, String title, String distance, String price, String priority) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(priority, style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(distance, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryCyan)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ambil', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, Color iconColor, String title, String subtitle, String amount, Color amountColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor)),
        ],
      ),
    );
  }
}

// --- CLIPPER UNTUK BENTUK UTAMA HEADER (HANYA MELENGKUNG DI BAWAH) ---
class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 35);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 25);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 50);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// --- CLIPPER UNTUK GARIS PEMISAH GRADASI WARNA MIRING KE KANAN BAWAH ---
class CurvedColorWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Memulai dari kiri atas di atas teks, lalu melandai turun ke sisi kanan
    path.moveTo(0, size.height * 0.12);

    var controlPoint = Offset(size.width * 0.6, size.height * 0.45);
    var endPoint = Offset(size.width, size.height * 0.22);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}