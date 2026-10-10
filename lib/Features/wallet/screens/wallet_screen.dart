import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'withdraw_screen.dart';
import 'history_screen.dart';
import 'top_up_screen.dart';
import 'detail_transaction_screen.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  bool _isLoading = true;
  double _balance = 0.0;
  double _totalEarned = 0.0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getWallet();

      if (res['success'] == true || res['data'] != null) {
        final data = res['data'] ?? res;
        final rawBal = data['balance'] ?? 0;
        _balance = double.tryParse(rawBal.toString()) ?? 0.0;

        List<dynamic> list = [];
        if (data['transactions'] is List) {
          list = data['transactions'];
        } else if (data['data'] is List) {
          list = data['data'];
        }

        double totalKomisi = 0.0;
        for (var t in list) {
          final isDeposit = (t['type'] ?? 'DEPOSIT') == 'DEPOSIT';
          if (isDeposit) {
            totalKomisi += double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
          }
        }

        setState(() {
          _transactions = list;
          _totalEarned = totalKomisi;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat dompet mitra: $e");
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('EcoCash Partner Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('Siap Angkut', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        color: AppColors.primaryCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Saldo Utama
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Dapat Ditarik', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    _isLoading
                        ? const SizedBox(height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            'Rp ${_formatCurrency(_balance)}',
                            style: const TextStyle(color: Color(0xFF0F2C59), fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWalletAction(context, Icons.account_balance_wallet, 'Tarik Saldo', const WithdrawScreen()),
                        _buildWalletAction(context, Icons.history, 'Riwayat', const HistoryScreen()),
                        _buildWalletAction(context, Icons.add_circle_outline, 'Top Up', const TopUpScreen()),
                        _buildWalletAction(context, Icons.help_outline, 'Bantuan', null),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Analisis Komisi & Skema Pendapatan Resmi (Satu Kesatuan Alur)
              const Text('Akumulasi & Skema Komisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Container(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Komisi Masuk', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${_formatCurrency(_totalEarned)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E88A8)),
                            ),
                          ],
                        ),
                        const Icon(Icons.insights, color: Color(0xFF1E88A8), size: 30),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),
                    _buildIncomeItem('Tarif Dasar Jemput Warga', 'Rp 20.000 / order'),
                    const SizedBox(height: 10),
                    _buildIncomeItem('Insentif Muatan Timbangan', 'Rp 1.000 / kg', valueColor: Colors.teal),
                    const SizedBox(height: 10),
                    _buildIncomeItem('Penyelesaian & Validasi', 'Scan Barcode Smart Container', valueColor: AppColors.primaryCyan),
                    const SizedBox(height: 10),
                    _buildIncomeItem('Batas Armada Motor Roda 3', 'Maks. 35 kg / order', valueColor: Colors.orange.shade800),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daftar Transaksi Terbaru
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaksi Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                      _fetchWalletData();
                    },
                    child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: Text('Belum ada riwayat transaksi komisi.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                )
              else
                ..._transactions.take(5).map((t) {
                  final amount = double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
                  final isPlus = (t['type'] ?? 'DEPOSIT') == 'DEPOSIT';
                  final date = _formatDateShort(t['createdAt']);
                  final title = t['description'] ?? (isPlus ? 'Komisi Penjemputan' : 'Penarikan Saldo');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: _buildTransactionItem(
                      context,
                      isPlus ? Icons.arrow_downward : Icons.arrow_upward,
                      isPlus ? Colors.green : Colors.red,
                      title,
                      date,
                      "${isPlus ? '+' : '-'}Rp ${_formatCurrency(amount)}",
                      isPlus ? Colors.green.shade800 : Colors.red,
                      !isPlus,
                      transactionData: Map<String, dynamic>.from(t is Map ? t : {}),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAction(BuildContext context, IconData icon, String label, Widget? targetScreen) {
    return GestureDetector(
      onTap: () async {
        if (targetScreen != null) {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
          _fetchWalletData();
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Icon(icon, color: AppColors.primaryCyan, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildIncomeItem(String title, String value, {Color valueColor = AppColors.textPrimary}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    IconData icon,
    Color iconBgColor,
    String title,
    String date,
    String amount,
    Color amountColor,
    bool isWithdrawal, {
    Map<String, dynamic>? transactionData,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailTransactionScreen(
            isWithdrawal: isWithdrawal,
            transactionData: transactionData,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBgColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconBgColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: Text(
                        title,
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
            Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor)),
          ],
        ),
      ),
    );
  }
}