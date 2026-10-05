import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart'; // Sesuaikan path import ini
import 'vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  Map<String, dynamic>? _vehicle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  // --- AMBIL DATA DARI API BACKEND ---
  Future<void> _fetchVehicleData() async {
    setState(() => _isLoading = true);

    final res = await _apiService.getMyVehicle();

    if (mounted) {
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        setState(() {
          _vehicle = _mapBackendToUi(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _vehicle = null;
          _isLoading = false;
        });
      }
    }
  }

  // Helper memetakan JSON Backend ke Format UI
  Map<String, dynamic> _mapBackendToUi(Map<String, dynamic> data) {
    String typeLabel = 'Sepeda Motor';
    IconData icon = Icons.two_wheeler;

    if (data['type'] == 'CART') {
      typeLabel = 'Gerobak';
      icon = Icons.shopping_cart;
    } else if (data['type'] == 'CAR') {
      typeLabel = 'Mobil Pick-up';
      icon = Icons.local_shipping;
    } else if (data['type'] == 'MOTORCYCLE') {
      if (data['plateNumber'] != null && data['plateNumber'].contains('VIAR')) {
        typeLabel = 'Motor Roda 3 (Viar)';
        icon = Icons.electric_rickshaw;
      }
    }

    return {
      'id': data['id'],
      'title': data['type'] == 'CART' ? (data['cartIdCode'] ?? 'Gerobak Mitra') : (data['plateNumber'] ?? 'Kendaraan Mitra'),
      'subtitle': '$typeLabel • ${data['plateNumber'] ?? data['cartIdCode'] ?? 'Terdaftar'}',
      'type': typeLabel,
      'backendType': data['type'],
      'plat': data['plateNumber'] ?? data['cartIdCode'] ?? '-',
      'capacity': '300 kg',
      'status': data['status'] ?? 'PENDING',
      'rejectionReason': data['rejectionReason'],
      'iconCode': icon.codePoint,
      'stnk': data['stnkPhotoUrl'] ?? 'Tidak Memerlukan STNK',
      'vehiclePhotoUrl': data['vehiclePhotoUrl'],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

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
      body: RefreshIndicator(
        onRefresh: _fetchVehicleData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kelola kendaraan aktif yang Anda gunakan untuk operasional penjemputan material daur ulang.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              if (_vehicle != null) ...[
                _buildActiveVehicleCard(context, _vehicle!),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Anda hanya dapat mengaktifkan 1 kendaraan operasional. Edit data untuk memperbarui dokumen.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Empty state jika belum daftar kendaraan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.no_drinks_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Belum Ada Kendaraan Terdaftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text('Daftarkan 1 kendaraan operasional Anda untuk mulai menerima tugas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                            );
                            if (result != null) {
                              _fetchVehicleData(); // Reload data dari API
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text('Daftarkan Kendaraan Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28859B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
    IconData iconData = IconData(vehicle['iconCode'], fontFamily: 'MaterialIcons');
    String status = vehicle['status'] ?? 'PENDING';

    Color statusBg = Colors.orange.shade50;
    Color statusText = Colors.orange;
    String statusLabel = 'Menunggu Verifikasi';

    if (status == 'VERIFIED') {
      statusBg = Colors.green.shade50;
      statusText = Colors.green;
      statusLabel = 'Terverifikasi';
    } else if (status == 'REJECTED') {
      statusBg = Colors.red.shade50;
      statusText = Colors.red;
      statusLabel = 'Ditolak';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: AppColors.primaryCyan, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(vehicle['subtitle'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusText, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (status == 'REJECTED' && vehicle['rejectionReason'] != null) ...[
            const SizedBox(height: 10),
            Text('Alasan Ditolak: ${vehicle['rejectionReason']}', style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VehicleDetailScreen(vehicleData: vehicle)),
                );
                if (result != null) _fetchVehicleData();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF28859B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Kelola / Edit Kendaraan', style: TextStyle(color: Color(0xFF28859B), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}