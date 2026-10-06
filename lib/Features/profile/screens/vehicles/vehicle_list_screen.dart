import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';
import 'add_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  Map<String, dynamic>? _vehicleData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getMyVehicle();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _vehicleData = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Kendaraan Operasional', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : RefreshIndicator(
              onRefresh: _fetchVehicleData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola spesifikasi kendaraan yang Anda gunakan untuk mengangkut material daur ulang.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    if (_vehicleData != null)
                      _buildVehicleCard(context, _vehicleData!)
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.electric_rickshaw_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Belum Ada Kendaraan Terdaftar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tambahkan kendaraan operasional Anda (ViAR, Motor, Mobil, Gerobak) untuk memulai penjemputan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                          );

                          if (result == true) {
                            _fetchVehicleData();
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: Text(
                          _vehicleData != null ? 'Ubah / Perbarui Kendaraan' : 'Tambah Kendaraan Baru',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28859B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
    final String type = (vehicle['type'] ?? 'MOTORCYCLE').toString();
    final String status = (vehicle['status'] ?? 'PENDING').toString();
    final String plateStr = (vehicle['plateNumber'] ?? '').toString();

    IconData iconData = Icons.two_wheeler;
    String typeLabel = 'Sepeda Motor';

    if (type == 'CAR') {
      iconData = Icons.local_shipping;
      typeLabel = 'Mobil Pick-up';
    } else if (type == 'CART') {
      iconData = Icons.shopping_cart;
      typeLabel = 'Gerobak';
    } else if (plateStr.toLowerCase().contains('viar') || plateStr.toLowerCase().contains('tossa') || plateStr.toLowerCase().contains('karya')) {
      iconData = Icons.electric_rickshaw;
      typeLabel = 'Kendaraan Roda Tiga';
    }

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: AppColors.primaryCyan, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      plateStr.isNotEmpty ? plateStr : 'Tanpa Plat / ID Pending',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (vehicle['rejectionReason'] != null && status == 'REJECTED') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Text(
              'Alasan Penolakan: ${vehicle['rejectionReason']}',
              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'VERIFIED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: Colors.green),
            SizedBox(width: 4),
            Text('Terverifikasi', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (status == 'REJECTED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 12, color: Colors.red),
            SizedBox(width: 4),
            Text('Ditolak', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 12, color: Colors.blue),
            SizedBox(width: 4),
            Text('Diproses', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }
}