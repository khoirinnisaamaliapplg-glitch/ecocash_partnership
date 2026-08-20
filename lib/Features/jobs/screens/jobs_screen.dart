import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
        title: const Text('Daftar Tugas Mitra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primaryCyan,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Tersedia'),
                Tab(text: 'Dalam Proses'),
                Tab(text: 'Selesai'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: TERSEDIA ---
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildAvailableTaskCard(
                title: 'Setor Botol Plastik PET',
                address: 'Jl. Merdeka No. 45, Singaparna',
                distance: '1.8 km',
                estimate: 'Estimasi: 15 Kg',
              ),
              const SizedBox(height: 14),
              _buildAvailableTaskCard(
                title: 'Setor Kardus & Kertas Bekas',
                address: 'Jl. KH. Zainal Mustofa No. 12',
                distance: '3.2 km',
                estimate: 'Estimasi: 25 Kg',
              ),
              const SizedBox(height: 14),
              _buildAvailableTaskCard(
                title: 'Setor Kaleng Aluminium',
                address: 'Jl. Cikunten Indah No. 8',
                distance: '4.5 km',
                estimate: 'Estimasi: 10 Kg',
              ),
            ],
          ),
          
          // --- TAB 2: DALAM PROSES ---
          const Center(
            child: Text('Belum ada tugas dalam proses', style: TextStyle(color: AppColors.textSecondary)),
          ),

          // --- TAB 3: SELESAI ---
          const Center(
            child: Text('Belum ada tugas selesai', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // Widget Kartu Tugas Tersedia
  Widget _buildAvailableTaskCard({
    required String title,
    required String address,
    required String distance,
    required String estimate,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Baru', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              Text(distance, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.eco_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(estimate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Ambil Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}