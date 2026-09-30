import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State createState() => _JobsScreenState();
}

class _JobsScreenState extends State {
  String _selectedFilter = 'Smart Container'; // Set default ke Smart Container sesuai screenshot

  static const Color _navyColor = Color(0xFF0F2C59);
  static const Color _tealColor = Color(0xFF1E88A8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text(
          'Pekerjaan Tersedia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // --- KOTAK PENCARIAN & FILTER CHIPS ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pekerjaan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rumah'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Smart Container'),
                  ],
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
                // 1. KARTU PENJEMPUTAN WARGA (Hanya tampil di filter 'Semua' & 'Rumah')
                if (_selectedFilter == 'Semua' || _selectedFilter == 'Rumah') ...[
                  _buildResidentJobCard(context),
                  const SizedBox(height: 14),
                ],

                // 2. KARTU SMART CONTAINER 1 - EcoCash Valen (Tampil di 'Semua' & 'Smart Container')
                if (_selectedFilter == 'Semua' || _selectedFilter == 'Smart Container') ...[
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
                ],

                // 3. KARTU SMART CONTAINER 2 - EcoCash Residen (Tampil di 'Semua' & 'Smart Container')
                if (_selectedFilter == 'Semua' || _selectedFilter == 'Smart Container') ...[
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Filter Chip Horizontal
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navyColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _navyColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // Widget Kartu Penjemputan Warga (Ibu Ratna Dewi)
  Widget _buildResidentJobCard(BuildContext context) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.network(
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Ibu Ratna Dewi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                        SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Komplek Permata Blok C2/14 (0.8 km)',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'EST. REWARD',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rp 45.000',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B8A90)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMaterialChip(Icons.inventory_2_outlined, 'Karton Box 8 kg'),
              _buildMaterialChip(Icons.autorenew, 'Plastik PET 12 kg'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF3FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.track_changes, size: 18, color: Color(0xFF1E88A8)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      children: [
                        TextSpan(
                          text: 'TUJUAN SETOR MITRA\n',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88A8), fontSize: 10),
                        ),
                        TextSpan(
                          text: 'Mesin RVM Coblong A-02 • ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: '1.2 km dari warga',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/detail-pekerjaan', extra: {
                        'title': 'Ibu Ratna Dewi',
                        'address': 'Komplek Permata Blok C2/14',
                        'materialTag': 'Karton / Plastik PET',
                        'volume': '20 kg',
                        'price': 'Rp 45.000',
                      });
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 16, color: Colors.white),
                    label: const Text(
                      'Terima & Mulai Rute',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tealColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 18, color: _navyColor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menghubungi Ibu Ratna Dewi...')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper Badge Material
  Widget _buildMaterialChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _navyColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _navyColor),
          ),
        ],
      ),
    );
  }

  // Widget Kartu Tugas Standar (Smart Container)
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Volume', volume),
                Container(height: 20, width: 1, color: Colors.grey.shade300),
                _buildDetailColumn('Jarak', distance),
                Container(height: 20, width: 1, color: Colors.grey.shade300),
                _buildDetailColumn('Estimasi', estimate),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _navyColor),
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(
                      '/detail-pekerjaan',
                      extra: {
                        'title': title,
                        'address': address,
                        'materialTag': materialTag,
                        'volume': volume,
                        'price': price,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Terima Pekerjaan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}