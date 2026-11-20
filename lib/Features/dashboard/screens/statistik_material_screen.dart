import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/api_service.dart';
import '../../../core/widgets/app_loading.dart';

class StatistikMaterialScreen extends StatefulWidget {
  const StatistikMaterialScreen({super.key});

  @override
  State<StatistikMaterialScreen> createState() =>
      _StatistikMaterialScreenState();
}

class _StatistikMaterialScreenState extends State<StatistikMaterialScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _today = {
    'totalWeight': 0.0,
    'percentageVsYesterday': 0.0,
    'trendText': '0% dari kemarin',
    'trend': 'EQUAL',
  };

  List<dynamic> _breakdown = [];
  List<dynamic> _recentSessions = [];

  static const Color _navy = Color(0xFF142B45);
  static const Color _green = Color(0xFF27845B);
  static const Color _darkGreen = Color(0xFF185C40);
  static const Color _yellow = Color(0xFFFFC857);
  static const Color _background = Color(0xFFF3F7F4);
  static const Color _muted = Color(0xFF87938B);
  static const Color _border = Color(0xFFE9EDE8);

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  // =========================================================
  // PENGAMBILAN DATA API
  // =========================================================

  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _apiService.getMaterialStatistics();

    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'];

      setState(() {
        _today = data['today'] ?? _today;
        _breakdown = data['breakdown'] ?? [];
        _recentSessions = data['recentSessions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['message'];
        _isLoading = false;
      });
    }
  }

  IconData _getMaterialIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'PET':
        return Icons.local_drink_outlined;
      case 'HDPE':
        return Icons.recycling;
      case 'PAPER':
      case 'KARDUS':
        return Icons.inventory_2_outlined;
      case 'ALUMINIUM':
        return Icons.view_in_ar_outlined;
      case 'GLASS':
        return Icons.wine_bar_outlined;
      default:
        return Icons.delete_outline;
    }
  }

  String _formatWeight(dynamic value) {
    if (value == null) return '0';

    final number = double.tryParse(value.toString());

    if (number == null) {
      return value.toString().replaceAll('.', ',');
    }

    return number
        .toStringAsFixed(number.truncateToDouble() == number ? 0 : 2)
        .replaceAll('.', ',');
  }

  // =========================================================
  // TAMPILAN UTAMA
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final trend = _today['trend']?.toString().toUpperCase() ?? 'EQUAL';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const AppLoading(
                      message: 'Menyiapkan statistik material kamu...',
                      size: 76,
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      color: _green,
                      onRefresh: _fetchStatistics,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTotalCard(trend),
                            const SizedBox(height: 25),

                            _buildSectionTitle(
                              'Rincian Material',
                              'Komposisi material terkumpul',
                            ),
                            const SizedBox(height: 13),
                            _buildBreakdownCard(),
                            const SizedBox(height: 25),

                            _buildHistoryHeader(),
                            const SizedBox(height: 13),
                            _buildHistoryCard(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER ECO NATURE
  // =========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECOCASH PARTNER',
                      style: TextStyle(
                        color: _yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Statistik Material',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: _navy,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Pantau jumlah dan komposisi material '
                  'yang berhasil dikumpulkan',
                  style: TextStyle(
                    color: Color(0xFFD5E1E8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(Icons.eco_rounded, color: Color(0xFF55C878), size: 19),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KARTU TOTAL MATERIAL
  // =========================================================

  Widget _buildTotalCard(String trend) {
    final isDown = trend == 'DOWN';
    final isEqual = trend == 'EQUAL';

    final trendColor = isDown
        ? const Color(0xFFD85B5B)
        : isEqual
        ? _muted
        : _green;

    final trendBackground = isDown
        ? const Color(0xFFFFEEEE)
        : isEqual
        ? const Color(0xFFF0F2F0)
        : const Color(0xFFE8F5EC);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // GAMBAR DAUN SEBAGAI DEKORASI LATAR
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/daun-eco.png',
                  width: 320,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox(
                      width: 300,
                      child: CustomPaint(painter: _PlantSilhouettePainter()),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 135,
                height: 135,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.035),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _yellow.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _yellow.withOpacity(0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco_rounded, color: _yellow, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'STATISTIK MATERIAL',
                              style: TextStyle(
                                color: _yellow,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Total material terkumpul hari ini',
                    style: TextStyle(
                      color: Color(0xFFD0DCE8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.only(right: 55),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatWeight(_today['totalWeight']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 7, bottom: 5),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Hasil pengumpulan hari ini',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 22),
                  Container(height: 1, color: Colors.white.withOpacity(0.17)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(
                        isDown
                            ? Icons.trending_down_rounded
                            : isEqual
                            ? Icons.trending_flat_rounded
                            : Icons.trending_up_rounded,
                        color: _yellow,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Perbandingan dengan kemarin',
                          style: TextStyle(
                            color: Color(0xFFD0DCE8),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: trendBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _today['trendText'] ?? '0% dari kemarin',
                          style: TextStyle(
                            color: trendColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // JUDUL BAGIAN
  // =========================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }

  // =========================================================
  // RINCIAN MATERIAL DALAM SATU KARTU
  // =========================================================

  Widget _buildBreakdownCard() {
    if (_breakdown.isEmpty) {
      return _buildEmptyState(
        Icons.recycling_outlined,
        'Belum ada material yang ditimbang hari ini',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(_breakdown.length, (index) {
          final item = _breakdown[index];
          final weight = _formatWeight(item['totalWeight']);

          final double percentage =
              (item['percentage'] as num?)?.toDouble() ?? 0.0;

          return Column(
            children: [
              _buildMaterialRow(
                icon: _getMaterialIcon(item['materialType']?.toString()),
                title: (item['name'] ?? item['materialType'] ?? '-').toString(),
                weight: '$weight kg',
                percent: percentage,
              ),
              if (index != _breakdown.length - 1)
                const Divider(height: 1, color: _border),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMaterialRow({
    required IconData icon,
    required String title,
    required String weight,
    required double percent,
  }) {
    final progress = percent.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                weight,
                style: const TextStyle(
                  color: _darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFEDF1ED),
                    valueColor: const AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 39,
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // JUDUL RIWAYAT
  // =========================================================

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Timbangan',
                style: TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Aktivitas penimbangan terbaru',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/riwayat-pekerjaan');
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DAFTAR RIWAYAT
  // =========================================================

  Widget _buildHistoryCard() {
    if (_recentSessions.isEmpty) {
      return _buildEmptyState(
        Icons.scale_outlined,
        'Belum ada sesi timbangan hari ini',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentSessions.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: _border),
        itemBuilder: (context, index) {
          final session = _recentSessions[index];

          return _buildHistoryItem(
            session['sessionName'] ?? 'Sesi Penjemputan',
            session['subtitle'] ?? '-',
            session['weight'] ?? '0 kg',
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, dynamic weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF5EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.scale_outlined, color: _green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            weight.toString(),
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green.withOpacity(0.65), size: 27),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFD85B5B),
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Data belum dapat dimuat',
              style: TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat mengambil data.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStatistics,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// FALLBACK SILUET TANAMAN JIKA GAMBAR TIDAK DAPAT DIMUAT
// =============================================================

class _PlantSilhouettePainter extends CustomPainter {
  const _PlantSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF70A984).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = const Color(0xFF70A984).withOpacity(0.38)
      ..style = PaintingStyle.fill;

    final stem = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.68,
        size.width * 0.78,
        size.height * 0.35,
        size.width * 0.52,
        size.height * 0.06,
      );

    canvas.drawPath(stem, stemPaint);

    void drawLeaf(
      double x,
      double y,
      double rotation,
      double width,
      double height,
    ) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(width, -height * 0.8, width, -height)
        ..quadraticBezierTo(width * 0.1, -height * 1.1, 0, 0);

      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }

    drawLeaf(size.width * 0.48, size.height * 0.78, -0.8, 28, 33);
    drawLeaf(size.width * 0.53, size.height * 0.64, 2.4, 28, 32);
    drawLeaf(size.width * 0.48, size.height * 0.51, -0.8, 27, 31);
    drawLeaf(size.width * 0.55, size.height * 0.38, 2.4, 26, 30);
    drawLeaf(size.width * 0.49, size.height * 0.25, -0.8, 24, 28);
    drawLeaf(size.width * 0.54, size.height * 0.14, 2.4, 22, 25);
  }

  @override
  bool shouldRepaint(covariant _PlantSilhouettePainter oldDelegate) {
    return false;
  }
}
