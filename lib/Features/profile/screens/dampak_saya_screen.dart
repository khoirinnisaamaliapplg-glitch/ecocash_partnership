
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../services/api_service.dart';
class DampakSayaScreen extends StatefulWidget {
  const DampakSayaScreen({super.key});

  @override
  State<DampakSayaScreen> createState() => _DampakSayaScreenState();
}

class _DampakSayaScreenState extends State<DampakSayaScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _impactData;

  @override
  void initState() {
    super.initState();
    _fetchImpactData();
  }

  Future<void> _fetchImpactData() async {
    final result = await _apiService.getMyImpact();

    if (mounted) {
      setState(() {
        _isLoading = false;

        if (result['success'] == true) {
          _impactData = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const AppLoading(
                      message: 'Menghitung dampak kontribusimu...',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchImpactData,
                      color: AppColors.ecoGreen,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIntro(),
                            const SizedBox(height: 20),
                            _buildMainImpactCard(),
                            const SizedBox(height: 27),
                            _buildSectionHeader(
                              title: 'Riwayat Dampak',
                              subtitle:
                                  'Pantau rincian kontribusi lingkunganmu',
                            ),
                            const SizedBox(height: 13),
                            _buildDetailButton(),
                            const SizedBox(height: 26),
                            _buildSectionHeader(
                              title: 'Bagikan Pencapaian',
                              subtitle:
                                  'Sebarkan inspirasi dari kontribusi positifmu',
                            ),
                            const SizedBox(height: 13),
                            _buildShareButton(),
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
  // HEADER MINIMALIS
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.pop(),
              child: SizedBox(
                width: 43,
                height: 43,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.darkNavy,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dampak Saya',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jejak positif kontribusimu untuk bumi.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INTRO
  // =========================================================

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kontribusi Nyata untuk Bumi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Lihat seberapa besar dampak positif yang sudah kamu hasilkan.',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // KARTU DAMPAK UTAMA
  // =========================================================

  Widget _buildMainImpactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.darkNavy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PENCAPAIAN PARTNER',
                      style: TextStyle(
                        color: Color(0xFFD5E1E8),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _impactData?['levelBadge'] ??
                          'Pahlawan Lingkungan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.primaryYellow,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 21),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 17),
          const Text(
            'TOTAL KONTRIBUSI LINGKUNGAN',
            style: TextStyle(
              color: Color(0xFFD5E1E8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _buildImpactItem(
                  icon: Icons.recycling_rounded,
                  title: 'Material terkumpul',
                  value: '${_impactData?['totalMaterialKg'] ?? 0}',
                  unit: 'kg',
                  iconColor: AppColors.ecoGreen,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _buildImpactItem(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Sampah dialihkan',
                  value: '${_impactData?['divertedWasteTon'] ?? 0}',
                  unit: 'Ton',
                  iconColor: const Color(0xFFE5A928),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _buildImpactItem(
                  icon: Icons.cloud_done_rounded,
                  title: 'Emisi CO₂ dikurangi',
                  value: '${_impactData?['co2ReducedTon'] ?? 0}',
                  unit: 'Ton',
                  iconColor: const Color(0xFF46B9D0),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _buildImpactItem(
                  icon: Icons.school_rounded,
                  title: 'Pelatihan selesai',
                  value: '${_impactData?['completedTrainings'] ?? 0}',
                  unit: 'Pelatihan',
                  iconColor: const Color(0xFFB49AE8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: AppColors.primaryYellow,
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Terus lanjutkan kontribusi baikmu!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION HEADER
  // =========================================================

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TOMBOL DETAIL
  // =========================================================

  Widget _buildDetailButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          context.push('/statistik-material');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ecoGreen,
          side: BorderSide(
            color: AppColors.ecoGreen.withOpacity(0.45),
          ),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 19),
            SizedBox(width: 8),
            Text(
              'Lihat Detail Statistik',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TOMBOL BAGIKAN
  // =========================================================

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ecoGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, size: 18),
            SizedBox(width: 9),
            Text(
              'Bagikan Pencapaian',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
