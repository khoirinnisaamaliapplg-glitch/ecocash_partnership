
import 'package:ecocash_partnership/Features/profile/screens/chat_cs_screen.dart';
import 'package:flutter/material.dart';

import 'withdraw_screen.dart';
import 'history_screen.dart';
import 'detail_transaction_screen.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import '../../../core/widgets/app_loading.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  // ECOCASH BRAND COLORS
  static const Color _primaryYellow = Color(0xFFFFE600);
  static const Color _darkNavy = Color(0xFF0F2C59);
  static const Color _ecoGreen = Color(0xFF00AA13);
  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkText = Color(0xFF1C1C1E);
  static const Color _background = Color(0xFFF8F9FA);
  static const Color _secondaryText = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE8EDF2);

  bool _isLoading = true;

  double _balance = 0.0;
  double _totalEarned = 0.0;

  List<dynamic> _transactions = [];
  Map<String, dynamic>? _vehicleData;
  List<dynamic> _adminMaterials = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  // FETCH DATA
  Future<void> _fetchWalletData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getWallet(),
        _apiService.getMyVehicle(),
        _apiService.getMaterials(),
      ]);

      final resWallet = results[0];
      final resVehicle = results[1];
      final resMaterials = results[2];

      // DATA DOMPET DAN TRANSAKSI
      if (resWallet['success'] == true || resWallet['data'] != null) {
        final data = resWallet['data'] ?? resWallet;

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
            totalKomisi +=
                double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
          }
        }

        _transactions = list;
        _totalEarned = totalKomisi;
      }

      // DATA KENDARAAN
      if (resVehicle['success'] == true && resVehicle['data'] != null) {
        _vehicleData = Map<String, dynamic>.from(resVehicle['data']);
      }

      // DATA MASTER MATERIAL
      if (resMaterials['success'] == true || resMaterials['data'] != null) {
        final dynamic matData = resMaterials['data'] ?? resMaterials;

        if (matData is List) {
          _adminMaterials = matData;
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat dompet mitra: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // LABEL KENDARAAN
  String get _vehicleTitleLabel {
    if (_vehicleData == null) return 'Batas Armada Motor Roda 3';

    final String type = (_vehicleData!['type'] ?? 'MOTORCYCLE')
        .toString()
        .toUpperCase();

    final String plateStr = (_vehicleData!['plateNumber'] ?? '')
        .toString()
        .toLowerCase();

    if (type == 'CAR') {
      return 'Batas Armada Mobil Pickup';
    } else if (type == 'CART') {
      return 'Batas Armada Gerobak Motor';
    } else if (plateStr.contains('viar') ||
        plateStr.contains('tossa') ||
        plateStr.contains('karya')) {
      return 'Batas Armada Motor Roda 3';
    }

    return 'Batas Armada Sepeda Motor';
  }

  String get _vehicleCapacityLabel {
    if (_vehicleData == null) return 'Maks. 35 kg / order';

    final String type = (_vehicleData!['type'] ?? 'MOTORCYCLE')
        .toString()
        .toUpperCase();

    if (type == 'CAR') {
      return 'Maks. 600 kg / order';
    } else if (type == 'CART') {
      return 'Maks. 150 kg / order';
    }

    return 'Maks. 35 kg / order';
  }

  // FORMAT RUPIAH
  String _formatCurrency(num number) {
    final str = number.toStringAsFixed(0);

    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // FORMAT TANGGAL
  String _formatDateShort(dynamic dateStr) {
    if (dateStr == null) return 'Tercatat';

    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
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
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? AppLoading(
              message: 'Menyiapkan informasi dompet kamu...',
              size: 76,
            )
          : RefreshIndicator(
              color: _ecoGreen,
              backgroundColor: Colors.white,
              onRefresh: _fetchWalletData,
              child: _buildWalletContent(),
            ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EcoCash Wallet',
            style: TextStyle(
              color: _darkNavy,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Kelola saldo dan pendapatan Anda',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 18),
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: _ecoGreen, size: 8),
              SizedBox(width: 6),
              Text(
                'Siap Angkut',
                style: TextStyle(
                  color: _ecoGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MAIN CONTENT
  Widget _buildWalletContent() {
    return SingleChildScrollView(
      key: const ValueKey('wallet-content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 28),

          _buildSectionTitle(
            'Akumulasi & Skema Komisi',
            'Rincian pendapatan dan batas operasional mitra',
          ),
          const SizedBox(height: 14),
          _buildCommissionCard(),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Harga Beli Sampah Admin',
            'Daftar harga material yang sedang berlaku',
          ),
          const SizedBox(height: 14),
          _buildMaterialsCard(),

          const SizedBox(height: 28),

          _buildTransactionHeader(),
          const SizedBox(height: 14),
          _buildTransactionList(),
        ],
      ),
    );
  }

  // BALANCE CARD
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryYellow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -55,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _darkNavy.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 65,
              top: 45,
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _darkNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EcoCash Wallet',
                              style: TextStyle(
                                color: _darkNavy,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Saldo mitra Anda',
                              style: TextStyle(
                                color: _darkNavy,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user_rounded,
                        color: _darkNavy,
                        size: 19,
                      ),
                    ],
                  ),

                  const SizedBox(height: 19),

                  const Text(
                    'Saldo Dapat Ditarik',
                    style: TextStyle(
                      color: _darkNavy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rp ${_formatCurrency(_balance)}',
                      style: const TextStyle(
                        color: _darkNavy,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: _ecoGreen,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Total komisi masuk Rp ${_formatCurrency(_totalEarned)}',
                            style: const TextStyle(
                              color: _darkNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    height: 1,
                    color: _darkNavy.withValues(alpha: 0.18),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWalletAction(
                        Icons.account_balance_rounded,
                        'Tarik Saldo',
                        const WithdrawScreen(),
                      ),
                      _buildWalletAction(
                        Icons.history_rounded,
                        'Riwayat',
                        const HistoryScreen(),
                      ),
                      _buildWalletAction(
                        Icons.help_outline_rounded,
                        'Bantuan',
                        const ChatCsScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WALLET ACTION
  Widget _buildWalletAction(
    IconData icon,
    String label,
    Widget? targetScreen,
  ) {
    return GestureDetector(
      onTap: () async {
        if (targetScreen != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );

          if (mounted) {
            _fetchWalletData();
          }
        }
      },
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: _darkNavy.withValues(alpha: 0.09),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: _darkNavy,
                size: 19,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkNavy,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _darkNavy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // COMMISSION CARD
  Widget _buildCommissionCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: _darkNavy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Komisi Masuk',
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(_totalEarned)}',
                      style: const TextStyle(
                        color: _darkNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: _ecoGreen,
                  size: 20,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: _borderColor),
          ),

          _buildIncomeItem(
            Icons.local_shipping_outlined,
            'Tarif Dasar Jemput Warga',
            'Rp 20.000 / order',
          ),
          _buildIncomeItem(
            Icons.scale_outlined,
            'Insentif Muatan Warga',
            'Rp 1.000 / kg',
            valueColor: _emeraldGreen,
          ),
          _buildIncomeItem(
            Icons.factory_outlined,
            'Tarif Dasar Angkut Pabrik',
            'Rp 35.000 / order',
          ),
          _buildIncomeItem(
            Icons.inventory_2_outlined,
            'Insentif Muatan Pabrik',
            'Rp 2.000 / kg',
            valueColor: _emeraldGreen,
          ),

          const SizedBox(height: 3),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _primaryYellow.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: _primaryYellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: _darkNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vehicleTitleLabel,
                        style: const TextStyle(
                          color: _darkNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Kapasitas maksimal kendaraan',
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _vehicleCapacityLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _darkNavy,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // INCOME ITEM
  Widget _buildIncomeItem(
    IconData icon,
    String title,
    String value, {
    Color valueColor = _darkNavy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _secondaryText,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _darkText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // MATERIALS CARD
  Widget _buildMaterialsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _adminMaterials.isEmpty
          ? _buildMaterialRow('Semua Kategori Material', 'Rp 500 / kg')
          : Column(
              children: _adminMaterials.take(5).map((m) {
                final double price =
                    double.tryParse(
                      (m['pricePerKg'] ?? '500').toString(),
                    ) ??
                    500.0;

                final String name = (m['name'] ?? 'Material').toString();

                return _buildMaterialRow(
                  name,
                  'Rp ${_formatCurrency(price)} / kg',
                );
              }).toList(),
            ),
    );
  }

  // MATERIAL ROW
  Widget _buildMaterialRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: _ecoGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: _darkText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              price,
              style: const TextStyle(
                color: _ecoGreen,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TRANSACTION HEADER
  Widget _buildTransactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  color: _darkNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pantau aktivitas saldo Anda',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryScreen(),
              ),
            );

            if (mounted) {
              _fetchWalletData();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: _darkNavy,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.arrow_forward_ios_rounded, size: 10),
            ],
          ),
        ),
      ],
    );
  }

  // TRANSACTION LIST
  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF94A3B8),
              size: 38,
            ),
            SizedBox(height: 12),
            Text(
              'Belum Ada Transaksi',
              style: TextStyle(
                color: _darkNavy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Riwayat transaksi Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _transactions.take(5).map((t) {
        final amount =
            double.tryParse(t['amount']?.toString() ?? '0') ?? 0;

        final isPlus = (t['type'] ?? 'DEPOSIT') == 'DEPOSIT';
        final date = _formatDateShort(t['createdAt']);

        final title = t['description'] ??
            (isPlus ? 'Komisi Penjemputan' : 'Penarikan Saldo');

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTransactionItem(
            icon: isPlus
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            iconColor: isPlus ? _ecoGreen : Colors.red,
            title: title.toString(),
            date: date,
            amount:
                '${isPlus ? '+' : '-'}Rp ${_formatCurrency(amount)}',
            amountColor: isPlus ? _ecoGreen : Colors.red,
            isWithdrawal: !isPlus,
            transactionData: Map<String, dynamic>.from(
              t is Map ? t : {},
            ),
          ),
        );
      }).toList(),
    );
  }

  // TRANSACTION ITEM
  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
    required bool isWithdrawal,
    Map<String, dynamic>? transactionData,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailTransactionScreen(
                isWithdrawal: isWithdrawal,
                transactionData: transactionData,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
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
                        color: _darkText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      date,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  amount,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
