import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class HargaMaterialScreen extends StatelessWidget {
  const HargaMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Harga Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CYAN (Menyambung dengan AppBar) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
              decoration: const BoxDecoration(
                color: AppColors.primaryCyan,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Harga material hari ini', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.update, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Terakhir diperbarui: 10 Agustus 2026 - 10:30', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // --- DAFTAR HARGA ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        _buildPriceItem(Icons.local_drink, 'PET Clear', 'Plastik Bening', 'Rp5.200', '+3.2%', Colors.green),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        _buildPriceItem(Icons.recycling, 'PET Colored', 'Plastik Warna', 'Rp3.800', '+2.0%', Colors.green),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        _buildPriceItem(Icons.inventory_2_outlined, 'HDPE', 'Plastik Keras', 'Rp6.100', '+1.5%', Colors.green),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        _buildPriceItem(Icons.delete_outline, 'Aluminium', 'Kaleng Bekas', 'Rp18.500', '-0%', Colors.grey),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        _buildPriceItem(Icons.archive_outlined, 'Cardboard', 'Kardus / Karton', 'Rp2.100', '-1.0%', Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- TREN HARGA (MOCKUP CHART) ---
                  const Text('Tren Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        // Tabs 7 Hari / 30 Hari / 3 Bulan
                        Row(
                          children: [
                            _buildTabItem('7 Hari', true),
                            const SizedBox(width: 8),
                            _buildTabItem('30 Hari', false),
                            const SizedBox(width: 8),
                            _buildTabItem('3 Bulan', false),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Mockup Grafik
                        SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _ChartMockupPainter(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Sen', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Text('Sel', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Text('Rab', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Text('Kam', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Text('Jum', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Text('Sab', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Text('Min', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Footer Note
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Harga dapat berubah berdasarkan kualitas material, lokasi, dan kondisi pasar.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
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
    );
  }

  Widget _buildPriceItem(IconData icon, String title, String subtitle, String price, String change, Color changeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF455A64), size: 20),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$price / kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  changeColor == Colors.green ? Icons.trending_up : (changeColor == Colors.red ? Icons.trending_down : Icons.trending_flat),
                  color: changeColor, 
                  size: 12
                ),
                const SizedBox(width: 2),
                Text(change, style: TextStyle(fontSize: 11, color: changeColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabItem(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryCyan : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Painter sederhana untuk menggambar grafik garis lengkung seperti di Figma
class _ChartMockupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.primaryCyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryCyan.withOpacity(0.3), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.9, size.width * 0.3, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width * 0.65, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.7, size.width, size.height * 0.2);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Titik-titik pada grafik
    final paintDot = Paint()..color = AppColors.primaryCyan..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 4, paintDot);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.5), 4, paintDot);
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}