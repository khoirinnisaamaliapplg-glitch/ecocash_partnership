import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'detail_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- SEARCH BAR ---
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // --- FILTER CHIPS (Hanya bagian ini yang disesuaikan warnanya) ---
            Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Masuk'),
                const SizedBox(width: 8),
                _buildFilterChip('Keluar'),
              ],
            ),
            const SizedBox(height: 16),

            // --- LIST TRANSAKSI (Sesuai kode awal Anda tanpa diubah) ---
            Expanded(
              child: ListView(
                children: [
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Masuk') ...[
                    const Text('Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _buildHistoryCard(context, Icons.account_balance_wallet, Colors.green, 'Penghasilan Pekerjaan', '14:30 WIB', '+Rp82.000', Colors.green),
                    const SizedBox(height: 8),
                    _buildHistoryCard(context, Icons.add_circle_outline, Colors.green, 'Top Up', '15:30 WIB', '+Rp100.000', Colors.green),
                  ],
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Keluar') ...[
                    const SizedBox(height: 8),
                    _buildHistoryCard(context, Icons.account_balance, Colors.red, 'Penarikan Saldo', '09:15 WIB', '-Rp100.000', Colors.red),
                    const SizedBox(height: 8),
                    _buildHistoryCard(context, Icons.account_balance, Colors.red, 'Penarikan Saldo', '10:15 WIB', '-Rp300.000', Colors.red),
                  ],
                  const SizedBox(height: 16),
                  const Text('12 Okt 2025', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Masuk') ...[
                    _buildHistoryCard(context, Icons.account_balance_wallet, Colors.green, 'Penghasilan Pekerjaan', '16:45 WIB', '+Rp45.000', Colors.green),
                    const SizedBox(height: 8),
                    _buildHistoryCard(context, Icons.card_giftcard, Colors.green, 'Bonus Target Mingguan', '10:00 WIB', '+Rp50.000', Colors.green),
                  ],
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Keluar') ...[
                    const SizedBox(height: 8),
                    _buildHistoryCard(context, Icons.account_balance, Colors.red, 'Penarikan Saldo', '11:15 WIB', '-Rp100.000', Colors.red),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Filter Chip (Warna Navy gelap saat aktif)
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF112C56) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF112C56) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // Widget Kartu Riwayat Transaksi (Sesuai kode awal Anda)
  Widget _buildHistoryCard(BuildContext context, IconData icon, Color iconBgColor, String title, String time, String amount, Color amountColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DetailTransactionScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconBgColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor)),
          ],
        ),
      ),
    );
  }
}