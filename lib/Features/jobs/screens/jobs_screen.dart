import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'detail_pekerjaan_screen.dart'; // Pastikan path import ini sesuai dengan lokasi file detail_pekerjaan_screen.dart

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Pekerjaan Tersedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // --- KOTAK PENCARIAN & FILTER CHIPS DI ATAS ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pekerjaan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Terdekat', isSelected: true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Penghasilan', isSelected: false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Material', isSelected: false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Terbaru', isSelected: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // --- DAFTAR KARTU TUGAS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildJobCard(
                  context: context,
                  materialTag: 'PET (Botol)',
                  title: 'EcoCash Valen #BGD-021',
                  address: 'Institut Teknologi Bandung',
                  volume: '42 kg',
                  distance: '2,3 km',
                  estimate: '15 mnt',
                  price: 'Rp82.000',
                ),
                const SizedBox(height: 14),
                _buildJobCard(
                  context: context,
                  materialTag: 'Kardus (Corrugated)',
                  title: 'EcoCash Mitra #BGD-045',
                  address: 'Pasar Baru Trade Center',
                  volume: '115 kg',
                  distance: '4,1 km',
                  estimate: '25 mnt',
                  price: 'Rp145.000',
                ),
                const SizedBox(height: 14),
                _buildJobCard(
                  context: context,
                  materialTag: 'Campur (Plastik/Kertas)',
                  title: 'EcoCash Residen #CMA-012',
                  address: 'Kawasan Perumahan Cimahi',
                  volume: '28 kg',
                  distance: '1,2 km',
                  estimate: '8 mnt',
                  price: 'Rp35.500',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Filter Chip Horizontal
  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F3057) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  // Widget Kartu Tugas Sesuai Mockup Gambar
  Widget _buildJobCard({
    required BuildContext context,
    required String materialTag,
    required String title,
    required String address,
    required String volume,
    required String distance,
    required String estimate,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag Jenis Material
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              materialTag,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),

          // Nama / Kode Tugas
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),

          // Alamat Lokasi
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kotak Rincian (Volume, Jarak, Estimasi)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Volume', volume),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                _buildDetailColumn('Jarak', distance),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                _buildDetailColumn('Estimasi', estimate),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estimasi Pendapatan & Tombol Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Pendapatan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary2),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryButtonGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Menghubungkan ke halaman DetailPekerjaanScreen dengan mengirim data dinamis
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPekerjaanScreen(
                          jobData: {
                            'title': title,
                            'address': address,
                            'materialTag': materialTag,
                            'volume': volume,
                            'price': price,
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    'Terima Pekerjaan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper untuk kolom rincian (Volume, Jarak, Estimasi)
  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}