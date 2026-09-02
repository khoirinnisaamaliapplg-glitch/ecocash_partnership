import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RiwayatPekerjaanScreen extends StatefulWidget {
  const RiwayatPekerjaanScreen({super.key});

  @override
  State<RiwayatPekerjaanScreen> createState() => _RiwayatPekerjaanScreenState();
}

class _RiwayatPekerjaanScreenState extends State<RiwayatPekerjaanScreen> with SingleTickerProviderStateMixin {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Riwayat Pekerjaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Online', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- KOTAK PENCARIAN & TAB BAR ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat pekerjaan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryCyan,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryCyan,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Selesai'),
                    Tab(text: 'Diproses'),
                    Tab(text: 'Dibatalkan'),
                  ],
                ),
              ],
            ),
          ),

          // --- FILTER CHIPS ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Status'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Material'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tanggal'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // --- DAFTAR KARTU RIWAYAT PER TAB ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Selesai
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildJobHistoryCard('PT. Green Packaging', 'PET (Botol)', '44,80 kg', '10 Agu 2026 • 10:24', 'Rp82.000', 'Selesai'),
                    const SizedBox(height: 12),
                    _buildJobHistoryCard('PT. Green Packaging', 'PET (Campuran)', '45,15 kg', '10 Agu 2026 • 08:57', 'Rp45.000', 'Selesai'),
                    const SizedBox(height: 12),
                    _buildJobHistoryCard('Bank Sampah Melati', 'Campuran', '29,50 kg', '09 Agu 2026 • 15:12', 'Rp38.000', 'Selesai'),
                  ],
                ),
                // Tab 2: Diproses
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildJobHistoryCard('PT. Green Packaging', 'PET (Botol)', '44,80 kg', '10 Agu 2026 • 10:24', 'Rp82.000', 'Diproses'),
                  ],
                ),
                // Tab 3: Dibatalkan
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildJobHistoryCard('Bank Sampah Melati', 'Campuran', '29,50 kg', '09 Agu 2026 • 15:12', 'Rp38.000', 'Dibatalkan'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildJobHistoryCard(String company, String material, String weight, String date, String price, String status) {
    Color badgeColor;
    Color textColor;
    IconData badgeIcon;
    bool isCancelled = status == 'Dibatalkan';

    if (status == 'Selesai') {
      badgeColor = Colors.green.shade50;
      textColor = Colors.green;
      badgeIcon = Icons.check_circle;
    } else if (status == 'Diproses') {
      badgeColor = Colors.cyan.shade50;
      textColor = Colors.cyan.shade700;
      badgeIcon = Icons.access_time_filled;
    } else {
      badgeColor = Colors.red.shade50;
      textColor = Colors.red;
      badgeIcon = Icons.cancel;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Material', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(material, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Berat', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(weight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Pendapatan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCancelled ? AppColors.textSecondary : AppColors.successGreen,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}