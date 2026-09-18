import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../data/app_storage.dart';
import 'detail_qr_screen.dart';

class RiwayatPekerjaanScreen extends StatefulWidget {
  final Map<String, dynamic>? dataBaru;

  const RiwayatPekerjaanScreen({super.key, this.dataBaru});

  @override
  State<RiwayatPekerjaanScreen> createState() => _RiwayatPekerjaanScreenState();
}

class _RiwayatPekerjaanScreenState extends State<RiwayatPekerjaanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _listSelesai = [
    {'company': 'PT. Green Packaging', 'material': 'PET (Botol)', 'weight': '44,80 kg', 'date': '10 Agu 2026 • 10:24', 'price': 'Rp82.000', 'status': 'Selesai'},
    {'company': 'PT. Green Packaging', 'material': 'PET (Campuran)', 'weight': '45,15 kg', 'date': '10 Agu 2026 • 08:57', 'price': 'Rp45.000', 'status': 'Selesai'},
    {'company': 'Bank Sampah Melati', 'material': 'Campuran', 'weight': '29,50 kg', 'date': '09 Agu 2026 • 15:12', 'price': 'Rp38.000', 'status': 'Selesai'},
  ];

  List<Map<String, dynamic>> _listDiproses = [];
  List<Map<String, dynamic>> _listDibatalkan = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gunakan didChangeDependencies agar aman saat membaca GoRouterState.of(context)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadDataStorage();
    }
  }

  Future<void> _loadDataStorage() async {
    final Map<String, dynamic>? extraData = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final Map<String, dynamic>? dataMasuk = widget.dataBaru ?? extraData;

    List<Map<String, dynamic>> diproses = await AppStorage.getDiproses();
    List<Map<String, dynamic>> dibatalkan = await AppStorage.getDibatalkan();

    if (dataMasuk != null) {
      final kodeBaru = dataMasuk['kode'] ?? 'EC-BGD-021';
      
      diproses.removeWhere((item) => item['kode'] == kodeBaru);
      
      diproses.insert(0, {
        'company': dataMasuk['title'] ?? 'PT. Green Packaging',
        'material': dataMasuk['material'] ?? 'PET (Botol)',
        'weight': dataMasuk['berat'] ?? '44,80 kg',
        'date': dataMasuk['tanggal'] ?? '10 Agu 2026 • 10:24',
        'price': dataMasuk['pendapatan'] ?? 'Rp82.000',
        'status': 'Diproses',
        'kode': kodeBaru,
      });

      await AppStorage.saveDiproses(diproses);
      _tabController.index = 1; // Pindah otomatis ke tab Diproses
    } 
    
    if (diproses.isEmpty && dibatalkan.isEmpty) {
      diproses = [
        {'company': 'PT. Green Packaging', 'material': 'PET (Botol)', 'weight': '44,80 kg', 'date': '10 Agu 2026 • 10:24', 'price': 'Rp82.000', 'status': 'Diproses', 'kode': 'EC-BGD-021'}
      ];
      await AppStorage.saveDiproses(diproses);
    }

    setState(() {
      _listDiproses = diproses;
      _listDibatalkan = dibatalkan;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _tampilkanDialogPembatalan(int index) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Alasan Pembatalan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: alasanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan pembatalan di sini...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFFF4F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (alasanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alasan pembatalan harus diisi!'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                setState(() {
                  final item = _listDiproses.removeAt(index);
                  item['status'] = 'Dibatalkan';
                  item['alasan'] = alasanController.text.trim();
                  _listDibatalkan.insert(0, item);
                });

                await AppStorage.saveDiproses(_listDiproses);
                await AppStorage.saveDibatalkan(_listDibatalkan);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pekerjaan berhasil dibatalkan'), backgroundColor: Colors.red),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Selesai
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listSelesai.length,
                  itemBuilder: (context, index) {
                    final item = _listSelesai[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildJobHistoryCard(item),
                    );
                  },
                ),
                // Tab 2: Diproses
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listDiproses.length,
                  itemBuilder: (context, index) {
                    final item = _listDiproses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailQrScreen(
                                kodeKontainer: item['kode'] ?? 'EC-BGD-021',
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _buildJobHistoryCard(
                          item,
                          showCancelButton: true,
                          onCancel: () => _tampilkanDialogPembatalan(index),
                        ),
                      ),
                    );
                  },
                ),
                // Tab 3: Dibatalkan
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listDibatalkan.length,
                  itemBuilder: (context, index) {
                    final item = _listDibatalkan[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildJobHistoryCard(item),
                    );
                  },
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
      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildJobHistoryCard(
    Map<String, dynamic> item, {
    bool showCancelButton = false,
    VoidCallback? onCancel,
  }) {
    final String company = item['company'] ?? '';
    final String material = item['material'] ?? '';
    final String weight = item['weight'] ?? '';
    final String date = item['date'] ?? '';
    final String price = item['price'] ?? '';
    final String status = item['status'] ?? '';
    final String? alasan = item['alasan'];

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
          if (isCancelled && alasan != null && alasan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alasan Pembatalan:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 2),
                  Text(alasan, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
          if (showCancelButton) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Batalkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}