
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
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final res = await _apiService.getWallet();

      if (res['success'] == true || res['data'] != null) {
        final data = res['data'] ?? res;
        List<dynamic> list = [];

        if (data is List) {
          list = data;
        } else if (data is Map && data['transactions'] is List) {
          list = data['transactions'];
        } else if (data is Map && data['data'] is List) {
          list = data['data'];
        }

        if (mounted) {
          setState(() {
            _transactions = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil riwayat transaksi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    if (dateStr == null) return 'Waktu tidak tersedia';

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

  bool _isDeposit(Map<String, dynamic> item) {
    final type = (item['type'] ?? 'DEPOSIT').toString().toUpperCase();

    return type == 'DEPOSIT';
  }

  String _getDescription(Map<String, dynamic> item, bool isDeposit) {
    return (item['description'] ??
            (isDeposit ? 'Komisi Penjemputan' : 'Penarikan Saldo'))
        .toString();
  }

  Map<String, dynamic> _getStatusInfo(Map<String, dynamic> item) {
    final rawStatus = (item['status'] ??
            item['withdrawalStatus'] ??
            '')
        .toString()
        .toUpperCase();

    switch (rawStatus) {
      case 'PENDING':
      case 'WAITING':
      case 'WAITING_APPROVAL':
        return {
          'label': 'Menunggu Validasi',
          'color': const Color(0xFFD69B18),
          'background': const Color(0xFFFFF5D9),
          'icon': Icons.access_time_rounded,
        };

      case 'APPROVED':
      case 'COMPLETED':
      case 'SUCCESS':
        return {
          'label': 'Disetujui',
          'color': const Color(0xFF16865B),
          'background': const Color(0xFFE4F6ED),
          'icon': Icons.check_circle_outline_rounded,
        };

      case 'REJECTED':
      case 'FAILED':
        return {
          'label': 'Ditolak',
          'color': const Color(0xFFD94848),
          'background': const Color(0xFFFFEEEE),
          'icon': Icons.cancel_outlined,
        };

      default:
        return {
          'label': '',
          'color': AppColors.textSecondary,
          'background': Colors.transparent,
          'icon': Icons.info_outline,
        };
    }
  }

  List<dynamic> _getFilteredTransactions() {
    return _transactions.where((transaction) {
      if (transaction is! Map) return false;

      final item = Map<String, dynamic>.from(transaction);

      final isDeposit = _isDeposit(item);
      final desc = _getDescription(item, isDeposit).toLowerCase();
      final idStr = (item['id'] ?? '').toString();

      final matchesSearch =
          desc.contains(_searchQuery.toLowerCase()) ||
          idStr.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'Semua' ||
          (_selectedFilter == 'Masuk' && isDeposit) ||
          (_selectedFilter == 'Keluar' && !isDeposit);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();

    final totalTransactions = _transactions.length;
    final totalIncoming = _transactions.where((item) {
      if (item is! Map) return false;
      return _isDeposit(Map<String, dynamic>.from(item));
    }).length;

    final totalOutgoing = totalTransactions - totalIncoming;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
              decoration: const BoxDecoration(
                color: AppColors.darkNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktivitas Dompet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Pantau seluruh transaksi EcoCash kamu.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'Total Transaksi',
                          value: totalTransactions.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.south_west_rounded,
                          label: 'Uang Masuk',
                          value: totalIncoming.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.north_east_rounded,
                          label: 'Uang Keluar',
                          value: totalOutgoing.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SEARCH DAN FILTER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi atau ID...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primaryCyan,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      _buildFilterChip('Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Masuk'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Keluar'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DAFTAR TRANSAKSI
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryCyan,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      color: AppColors.primaryCyan,
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 75),
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 65,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 14),
                                const Center(
                                  child: Text(
                                    'Belum ada riwayat transaksi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Center(
                                  child: Text(
                                    'Transaksi kamu akan muncul di sini.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20, 0, 20, 25,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 11),
                              itemBuilder: (context, index) {
                                final item = Map<String, dynamic>.from(
                                  filtered[index],
                                );

                                return _buildTransactionCard(item);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 19,
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final bool isDeposit = _isDeposit(item);

    final num amount =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

    final String desc = _getDescription(item, isDeposit);
    final String date = _formatDateShort(item['createdAt']);

    final String amountText =
        '${isDeposit ? '+' : '-'}Rp ${_formatCurrency(amount)}';

    final status = _getStatusInfo(item);

    String badgeText = isDeposit ? 'Komisi' : 'Tarik Saldo';
    Color badgeColor =
        isDeposit ? AppColors.primaryCyan : const Color(0xFFD94848);

    final String lowerDesc = desc.toLowerCase();

    if (isDeposit) {
      if (lowerDesc.contains('warga') ||
          lowerDesc.contains('jemput') ||
          lowerDesc.contains('penjemputan')) {
        badgeText = 'Jemput Warga';
        badgeColor = AppColors.darkNavy;
      } else if (lowerDesc.contains('smart container') ||
          lowerDesc.contains('kontainer') ||
          lowerDesc.contains('rvm')) {
        badgeText = 'Smart Container';
        badgeColor = Colors.teal;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailTransactionScreen(
              isWithdrawal: !isDeposit,
              transactionData: item,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.grey.withOpacity(0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ICON TRANSAKSI
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: (isDeposit
                        ? const Color(0xFF16865B)
                        : const Color(0xFFD94848))
                    .withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isDeposit
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: isDeposit
                    ? const Color(0xFF16865B)
                    : const Color(0xFFD94848),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // DETAIL TRANSAKSI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // STATUS KHUSUS PENARIKAN
                  if (!isDeposit && status['label'] != '') ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status['background'] as Color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status['icon'] as IconData,
                            size: 11,
                            color: status['color'] as Color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status['label'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: status['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // NOMINAL
            Text(
              amountText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDeposit
                    ? const Color(0xFF16865B)
                    : const Color(0xFFD94848),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 21,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.darkNavy
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
