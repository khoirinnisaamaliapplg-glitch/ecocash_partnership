import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../services/api_service.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  Map<String, dynamic>? _vehicleData;
  bool _isLoading = true;

  // Warna identitas EcoCash
  static const Color _navy = Color(0xFF142D4E);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _background = Color(0xFFF4F6F9);
  static const Color _textSecondary = Color(0xFF778397);
  static const Color _border = Color(0xFFE9EDF2);
  static const Color _green = Color(0xFF27945D);

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  // =========================================================
  // AMBIL DATA KENDARAAN
  // =========================================================

  Future<void> _fetchVehicleData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final result = await _apiService.getMyVehicle();

    if (mounted) {
      setState(() {
        _isLoading = false;

        if (result['success'] == true && result['data'] != null) {
          _vehicleData = Map<String, dynamic>.from(result['data']);
        }
      });
    }
  }

  // =========================================================
  // NAVIGASI TAMBAH / EDIT
  // =========================================================

  Future<void> _openVehicleForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _vehicleData != null
            ? EditVehicleScreen(vehicleData: _vehicleData!)
            : const AddVehicleScreen(),
      ),
    );

    if (result == true && mounted) {
      _fetchVehicleData();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? AppLoading(
                      message: 'Menyiapkan informasi kendaraan kamu...',
                      size: 76,
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVehicleData,
                      color: _navy,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIntro(),
                            const SizedBox(height: 27),

                            _buildSectionHeader(
                              title: 'Kendaraan Terdaftar',
                              subtitle: _vehicleData != null
                                  ? 'Informasi kendaraan operasionalmu'
                                  : 'Belum ada kendaraan yang terdaftar',
                            ),

                            const SizedBox(height: 14),

                            if (_vehicleData != null)
                              _buildVehicleCard(_vehicleData!)
                            else
                              _buildEmptyState(),

                            const SizedBox(height: 23),

                            _buildActionButton(),

                            const SizedBox(height: 18),

                            _buildBottomInfo(),
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
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded, color: _navy, size: 21),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kendaraan Operasional',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola kendaraan partner EcoCash',
                  style: TextStyle(
                    color: _textSecondary,
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
  // INTRO DENGAN GAMBAR KENDARAAN
  // =========================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Lingkaran Kuning Background
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 2. Teks Informasi & Garis Kuning Memanjang ke Ujung Kanan
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge Label
                  Padding(
                    padding: const EdgeInsets.only(right: 158),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5D8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            color: _navy,
                            size: 12,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'PARTNER ECOCASH',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Judul
                  const Padding(
                    padding: EdgeInsets.only(right: 158),
                    child: Text(
                      'Siap untuk\nBeroperasi',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Garis Kuning Tanpa Padding Kanan (Sampai ke Ujung)
                  Container(
                    width: double.infinity,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Deskripsi
                  const Padding(
                    padding: EdgeInsets.only(right: 158),
                    child: Text(
                      'Pastikan kendaraan operasionalmu terdaftar dan memiliki informasi yang sesuai.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Gambar Kurir di Lapisan Atas Pojok Kanan Bawah
            Positioned(
              right: 0,
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  'assets/images/kendaraan.png',
                  width: 187,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 100,
                      width: 100,
                      child: Center(
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: _navy,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // KARTU KENDARAAN
  // =========================================================

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final String type = (vehicle['type'] ?? 'MOTORCYCLE').toString();
    final String status = (vehicle['status'] ?? 'PENDING').toString();
    final String plateStr = (vehicle['plateNumber'] ?? '').toString();

    IconData iconData = Icons.two_wheeler_rounded;
    String typeLabel = 'Sepeda Motor';

    if (type == 'CAR') {
      iconData = Icons.local_shipping_rounded;
      typeLabel = 'Mobil Pick-up';
    } else if (type == 'CART') {
      iconData = Icons.shopping_cart_rounded;
      typeLabel = 'Gerobak';
    } else if (plateStr.toLowerCase().contains('viar') ||
        plateStr.toLowerCase().contains('tossa') ||
        plateStr.toLowerCase().contains('karya')) {
      iconData = Icons.electric_rickshaw_rounded;
      typeLabel = 'Kendaraan Roda Tiga';
    }

    final bool isRejected = status == 'REJECTED';
    final bool isVerified = status == 'VERIFIED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.045),
            blurRadius: 17,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5D8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, color: _navy, size: 27),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        plateStr.isNotEmpty
                            ? plateStr
                            : 'Tanpa Plat / ID Pending',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 7),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 18),

          Container(height: 1, color: _border),

          const SizedBox(height: 15),

          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isRejected
                    ? const Color(0xFFD9473F)
                    : isVerified
                    ? _green
                    : const Color(0xFFBD8625),
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVerified
                      ? 'Kendaraan sudah terverifikasi dan siap digunakan.'
                      : isRejected
                      ? 'Kendaraan memerlukan perbaikan data.'
                      : 'Kendaraan sedang menunggu proses verifikasi.',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          if (isRejected &&
              vehicle['rejectionReason'] != null &&
              vehicle['rejectionReason'].toString().isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFFFD8D4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFD9473F),
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Alasan Penolakan',
                        style: TextStyle(
                          color: Color(0xFFD9473F),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    vehicle['rejectionReason'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF9F3731),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isVerified) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6ED),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: _green, size: 16),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Data kendaraan telah disetujui.',
                      style: TextStyle(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge(String status) {
    Color color;
    Color background;
    IconData icon;
    String label;

    if (status == 'VERIFIED') {
      color = const Color(0xFF21864B);
      background = const Color(0xFFEAF6ED);
      icon = Icons.check_circle_rounded;
      label = 'Terverifikasi';
    } else if (status == 'REJECTED') {
      color = const Color(0xFFD9473F);
      background = const Color(0xFFFFF0EF);
      icon = Icons.cancel_rounded;
      label = 'Ditolak';
    } else {
      color = const Color(0xFFBD8625);
      background = const Color(0xFFFFF5E3);
      icon = Icons.hourglass_top_rounded;
      label = 'Diproses';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 29),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5D8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.electric_rickshaw_outlined,
              size: 37,
              color: _navy,
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            'Belum Ada Kendaraan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Kamu belum mendaftarkan kendaraan operasional. Tambahkan kendaraan untuk mendukung aktivitas penjemputan material daur ulang.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 11, height: 1.6),
          ),

          const SizedBox(height: 17),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Motor  •  Mobil  •  Gerobak',
              style: TextStyle(
                color: _navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TOMBOL TAMBAH / PERBARUI
  // =========================================================

  Widget _buildActionButton() {
    final bool hasVehicle = _vehicleData != null;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _openVehicleForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(hasVehicle ? Icons.edit_rounded : Icons.add_rounded, size: 19),
            const SizedBox(width: 9),
            Text(
              hasVehicle
                  ? 'Ubah / Perbarui Kendaraan'
                  : 'Tambah Kendaraan Baru',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INFORMASI BAWAH
  // =========================================================

  Widget _buildBottomInfo() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, color: _textSecondary, size: 14),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Pastikan data kendaraan selalu sesuai dengan kondisi sebenarnya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 9, height: 1.4),
          ),
        ),
      ],
    );
  }
}
