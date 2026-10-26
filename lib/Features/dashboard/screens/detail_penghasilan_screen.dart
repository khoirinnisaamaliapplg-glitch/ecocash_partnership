import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class DetailPenghasilanScreen extends StatefulWidget {
  const DetailPenghasilanScreen({super.key});

  @override
  State<DetailPenghasilanScreen> createState() => _DetailPenghasilanScreenState();
}

class _DetailPenghasilanScreenState extends State<DetailPenghasilanScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  bool _isLoading = true;
  String? _errorMessage;

  num _monthlyEarnings = 0;
  num _balance = 0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getDashboard(),
        _apiService.getMyJobs(status: 'COMPLETED'),
      ]);

      if (!mounted) return;

      final dashboardRes = results[0];
      final jobsRes = results[1];

      if (dashboardRes['success'] == true) {
        final walletSummary = dashboardRes['data']?['walletSummary'] ?? {};
        _monthlyEarnings = walletSummary['monthlyEarnings'] ?? 0;
        _balance = walletSummary['balance'] ?? 0;
      }

      if (jobsRes['success'] == true && jobsRes['data'] is List) {
        final List rawJobs = jobsRes['data'];
        _recentTransactions = rawJobs.map((item) {
          final job = item['job'] ?? {};
          final String title = job['title'] ?? 'Penjemputan Sampah';
          final String code = job['code'] != null
              ? '#${job['code'].toString().substring(0, 8).toUpperCase()}'
              : 'JOB-#${job['id']}';
          
          double totalKg = 0.0;
          final weights = (job['weights'] as List?) ?? [];
          for (var w in weights) {
            totalKg += double.tryParse((w['handoverWeight'] ?? w['pickupWeight'] ?? 0).toString()) ?? 0.0;
          }

          final int earning = (15000 + (totalKg * 2000)).toInt();

          String dateStr = (item['completedAt'] ?? item['assignedAt'] ?? '').toString();
          if (dateStr.isNotEmpty) {
            try {
              final dt = DateTime.parse(dateStr).toLocal();
              dateStr = DateFormat('HH:mm').format(dt);
            } catch (_) {
              dateStr = 'Hari ini';
            }
          }

          return {
            'title': '$title $code',
            'subtitle': '${totalKg.toStringAsFixed(1)} kg • $dateStr',
            'amount': '+Rp${_formatNumber(earning)}',
          };
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data detail penghasilan';
        _isLoading = false;
      });
    }
  }

  String _formatNumber(num number) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(number);
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
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
        title: const Text(
          'Detail Penghasilan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                        onPressed: _fetchEarningsData,
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchEarningsData,
                  color: AppColors.primaryCyan,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // --- KARTU TOTAL PENGHASILAN ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4D8), AppColors.primaryCyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Penghasilan Bulan Ini',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(
                                _formatCurrency(_monthlyEarnings),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Saldo Dompet: ${_formatCurrency(_balance)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- GRAFIK PENDAPATAN ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Grafik Pendapatan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textPrimary)),
                                  Text('Per Jam',
                                      style: TextStyle(
                                          fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 120,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildBar(40, '08:00', false),
                                    _buildBar(60, '10:00', false),
                                    _buildBar(50, '12:00', false),
                                    _buildBar(100, '14:00', true),
                                    _buildBar(70, '16:00', false),
                                    _buildBar(30, '18:00', false),
                                    _buildBar(10, '20:00', false),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- RINCIAN TRANSAKSI ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rincian Transaksi Selesai',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              if (_recentTransactions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'Belum ada transaksi pekerjaan selesai bulan ini',
                                      style: TextStyle(
                                          color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recentTransactions.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 24, color: Color(0xFFEEEEEE)),
                                  itemBuilder: (context, index) {
                                    final tx = _recentTransactions[index];
                                    return _buildTransactionItem(
                                      tx['title'],
                                      tx['subtitle'],
                                      tx['amount'],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBar(double heightPercentage, String label, bool isHighlighted) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: (heightPercentage / 100) * 90,
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primaryCyan : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.recycling, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('Selesai',
                  style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}