import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'detail_transaction_screen.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getWallet();
      if (res['success'] == true || res['data'] != null) {
        final data = res['data'] ?? res;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data['transactions'] is List) {
          list = data['transactions'];
        } else if (data['data'] is List) {
          list = data['data'];
        }

        setState(() {
          _transactions = list;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil riwayat transaksi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num number) {
    final str = number.toStringAsFixed(0);
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDateShort(dynamic dateStr) {
    if (dateStr == null) return 'Tercatat';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$minute';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _transactions.where((item) {
      final String desc = (item['description'] ?? 'Transaksi').toString().toLowerCase();
      final String idStr = (item['id'] ?? '').toString();
      final String type = (item['type'] ?? 'DEPOSIT').toString().toUpperCase();
      final bool isDeposit = type == 'DEPOSIT';

      final bool matchesSearch = desc.contains(_searchQuery.toLowerCase()) || idStr.contains(_searchQuery);
      final bool matchesFilter = _selectedFilter == 'Semua' ||
          (_selectedFilter == 'Masuk' && isDeposit) ||
          (_selectedFilter == 'Keluar' && !isDeposit);

      return matchesSearch && matchesFilter;
    }).toList();

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
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari transaksi / No. Job...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      color: AppColors.primaryCyan,
                      child: filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 55, color: Colors.grey),
                                      SizedBox(height: 10),
                                      Text('Belum ada riwayat transaksi yang sesuai.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final num amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
                                final bool isDeposit = (item['type'] ?? 'DEPOSIT') == 'DEPOSIT';
                                final String desc = item['description'] ?? (isDeposit ? 'Komisi Penjemputan' : 'Penarikan Saldo');
                                final String date = _formatDateShort(item['createdAt']);
                                final String amountText = "${isDeposit ? '+' : '-'}Rp ${_formatCurrency(amount)}";

                                // Prioritas penentuan badge: Penjemputan warga diprioritaskan utama
                                String badgeText = isDeposit ? 'Komisi' : 'Tarik Saldo';
                                Color badgeColor = isDeposit ? const Color(0xFF1E88A8) : Colors.red;

                                final String lowerDesc = desc.toLowerCase();
                                if (!isDeposit) {
                                  badgeText = 'Tarik Saldo';
                                  badgeColor = Colors.red;
                                } else if (lowerDesc.contains('warga') || lowerDesc.contains('jemput') || lowerDesc.contains('penjemputan')) {
                                  badgeText = 'Jemput Warga';
                                  badgeColor = const Color(0xFF0F2C59);
                                } else if (lowerDesc.contains('smart container') || lowerDesc.contains('kontainer') || lowerDesc.contains('rvm')) {
                                  badgeText = 'Smart Container';
                                  badgeColor = Colors.teal;
                                }

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailTransactionScreen(
                                          isWithdrawal: !isDeposit,
                                          transactionData: Map<String, dynamic>.from(item is Map ? item : {}),
                                        ),
                                      ),
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
                                                color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                                color: isDeposit ? Colors.green : Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: badgeColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        badgeText,
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width * 0.42,
                                                  child: Text(
                                                    desc,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          amountText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDeposit ? Colors.green.shade800 : Colors.red,
                                          ),
                                        ),
                                      ],
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

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
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
}