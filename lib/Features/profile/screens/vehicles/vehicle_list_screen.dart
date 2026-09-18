import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/app_storage.dart';
import 'vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  // Memuat data kendaraan dari penyimpanan lokal
  Future<void> _loadVehicles() async {
    final savedVehicles = await AppStorage.getVehicles();
    setState(() {
      if (savedVehicles.isNotEmpty) {
        _vehicles = savedVehicles;
      } else {
        // Data default jika belum ada data tersimpan
        _vehicles = [
          {
            'title': 'Honda Supra',
            'subtitle': 'Motor • B 1234 ABC',
            'type': 'Sepeda Motor',
            'plat': 'B 1234 ABC',
            'capacity': '150 kg',
            'tahun': '2021',
            'iconCode': Icons.two_wheeler.codePoint,
            'stnk': 'STNK_Honda_Supra.jpg',
          },
          {
            'title': 'Suzuki Carry',
            'subtitle': 'Mobil Pick-up • D 5678 EFG',
            'type': 'Mobil Pick-up',
            'plat': 'D 5678 EFG',
            'capacity': '800 kg',
            'tahun': '2023',
            'iconCode': Icons.local_shipping.codePoint,
            'stnk': 'STNK_Suzuki_Carry.jpg',
          },
          {
            'title': 'Gerobak Standar',
            'subtitle': 'Gerobak • ID: GBK-001',
            'type': 'Gerobak',
            'plat': 'GBK-001',
            'capacity': '300 kg',
            'tahun': '2022',
            'iconCode': Icons.shopping_cart.codePoint,
            'stnk': 'STNK_Gerobak_001.jpg',
          },
        ];
      }
      _isLoading = false;
    });
  }

  // Menyimpan daftar kendaraan ke penyimpanan lokal
  Future<void> _saveVehicles() async {
    await AppStorage.saveVehicles(_vehicles);
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
        title: const Text('Transportasi Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola kendaraan yang Anda gunakan untuk mengangkut material daur ulang.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // --- LIST KENDARAAN DINAMIS ---
            ..._vehicles.map((vehicle) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildVehicleCard(context, vehicle),
              );
            }).toList(),

            const SizedBox(height: 20),

            // --- TOMBOL TAMBAH KENDARAAN BARU ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newVehicle = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                  );

                  if (newVehicle != null && newVehicle is Map<String, dynamic>) {
                    setState(() {
                      _vehicles.add(newVehicle);
                    });
                    await _saveVehicles(); // Simpan ke local storage
                    await _loadVehicles(); // Muat ulang agar UI langsung merender data terbaru
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kendaraan baru berhasil ditambahkan!'), backgroundColor: Colors.green),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Tambah Kendaraan Baru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
    );
  }

  Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
    IconData iconData = Icons.directions_car;
    if (vehicle['iconCode'] != null) {
      iconData = IconData(vehicle['iconCode'], fontFamily: 'MaterialIcons');
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailScreen(vehicleData: vehicle),
          ),
        );
        
        // Menangani hasil kembalian dari halaman detail (Edit atau Hapus)
        if (result != null) {
          if (result == 'delete') {
            // Aksi jika sinyal yang dikembalikan adalah 'delete' (Hapus Kendaraan)
            setState(() {
              _vehicles.removeWhere((v) => v['plat'] == vehicle['plat']);
            });
            await _saveVehicles();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kendaraan berhasil dihapus'), backgroundColor: Colors.red),
              );
            }
          } else if (result is Map<String, dynamic>) {
            // Aksi jika yang dikembalikan adalah data Map baru (Edit Kendaraan)
            setState(() {
              int index = _vehicles.indexWhere((v) => v['plat'] == vehicle['plat'] || v['title'] == vehicle['title']);
              if (index != -1) {
                _vehicles[index] = result;
              }
            });
            await _saveVehicles();
          }
          
          // Panggil fungsi load ulang agar tampilan data tersinkronisasi 100%
          await _loadVehicles();
        }
      },
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
                      Text(vehicle['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(vehicle['subtitle'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Terverifikasi', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kapasitas Maksimal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(vehicle['capacity'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}