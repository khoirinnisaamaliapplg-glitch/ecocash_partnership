import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:idn_finlogos/idn_finlogos.dart';

import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';
import '../../../core/widgets/app_loading.dart';

class AkunBankScreen extends StatefulWidget {
  const AkunBankScreen({super.key});

  @override
  State<AkunBankScreen> createState() => _AkunBankScreenState();
}

class _AkunBankScreenState extends State<AkunBankScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  List<dynamic> _bankList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _apiService.getBankAccounts();

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (result['success'] == true) {
          _bankList = result['data'] is List ? result['data'] : [];
        } else {
          _errorMessage = result['message'] ?? 'Gagal mengambil data rekening.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan koneksi ke server.';
      });
    }
  }

  String _maskAccountNumber(String raw) {
    if (raw.isEmpty) return 'Nomor rekening tidak tersedia';
    if (raw.length <= 4) return raw;

    return '•••• •••• ${raw.substring(raw.length - 4)}';
  }

  // LOGO BANK DINAMIS

  Widget _buildBankLogo(String bankName) {
    final normalizedName = bankName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    // Pemetaan nama bank ke slug logo.
    final Map<String, String> bankSlugs = {
      'bca': 'bca',
      'bankcentralasia': 'bca',
      'bri': 'bri',
      'bankrakyatindonesia': 'bri',
      'bni': 'bni',
      'banknegaraindonesia': 'bni',
      'mandiri': 'mandiri',
      'bankmandiri': 'mandiri',
      'bsi': 'bsi',
      'banksyariahindonesia': 'bsi',
      'btn': 'btn',
      'banktabungannegara': 'btn',
      'cimbniaga': 'cimb-niaga',
      'cimb': 'cimb-niaga',
      'danamon': 'danamon',
      'bankdanamon': 'danamon',
      'permata': 'permata',
      'bankpermata': 'permata',
      'bankmega': 'bank-mega',
      'mega': 'bank-mega',
      'bankjago': 'bank-jago',
      'jago': 'bank-jago',
      'seabank': 'seabank',
      'bankseabank': 'seabank',
      'ocbc': 'ocbc',
      'bankocbc': 'ocbc',
      'maybank': 'maybank',
      'bankmaybank': 'maybank',
      'panin': 'panin',
      'bankpanin': 'panin',
      'uob': 'uob',
      'bankuob': 'uob',
      'dbs': 'dbs',
      'bankdbs': 'dbs',
      'hsbc': 'hsbc',
      'bankhsbc': 'hsbc',
      'blu': 'blu',
    };

    String? matchedSlug;

    // Cocokkan nama bank dari API dengan daftar slug.
    for (final entry in bankSlugs.entries) {
      if (normalizedName == entry.key || normalizedName.contains(entry.key)) {
        matchedSlug = entry.value;
        break;
      }
    }

    // Cari logo berdasarkan slug terlebih dahulu.
    dynamic matchedLogo;

    if (matchedSlug != null) {
      matchedLogo = IdnFinLogos.get(matchedSlug);
    }

    // Jika belum ditemukan, gunakan pencarian nama bank.
    if (matchedLogo == null) {
      final searchResults = IdnFinLogos.search(bankName);

      for (final logo in searchResults) {
        if (logo.category == 'bank-logo') {
          matchedLogo = logo;
          break;
        }
      }
    }

    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: matchedLogo != null
          ? SvgPicture.asset(
              matchedLogo.assetPath,
              fit: BoxFit.contain,
              semanticsLabel: matchedLogo.name,
              placeholderBuilder: (context) => const Icon(
                Icons.account_balance_rounded,
                color: AppColors.darkNavy,
                size: 20,
              ),
            )
          : const Icon(
              Icons.account_balance_rounded,
              color: AppColors.darkNavy,
              size: 20,
            ),
    );
  }

  Future<void> _openAddAccount() async {
    final refreshNeeded = await context.push<bool>('/tambah-rekening');

    if (!mounted) return;

    if (refreshNeeded == true) {
      _fetchBankAccounts();
    }
  }

  Future<void> _openAccountDetail(Map<String, dynamic> item) async {
    final refreshNeeded = await context.push<bool>(
      '/detail-rekening',
      extra: {
        'id': item['id'].toString(),
        'bankName': item['bankName'] ?? 'Bank',
        'accountNumber': item['accountNumber'] ?? '',
        'accountName': item['accountHolderName'] ?? item['accountName'] ?? '',
      },
    );

    if (!mounted) return;

    if (refreshNeeded == true) {
      _fetchBankAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 54,
        leadingWidth: 54,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: AppColors.darkNavy,
          ),
        ),
        title: const Text(
          'Rekening Bank',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? AppLoading(message: 'Menyiapkan rekening bank kamu...', size: 76)
          : RefreshIndicator(
              color: AppColors.darkNavy,
              onRefresh: _fetchBankAccounts,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _buildPageHeading(),
                  const SizedBox(height: 25),
                  _buildSectionHeader(),
                  const SizedBox(height: 12),

                  if (_errorMessage != null)
                    _buildErrorState()
                  else if (_bankList.isEmpty)
                    _buildEmptyState()
                  else
                    ..._bankList.map((item) {
                      final bank = Map<String, dynamic>.from(item);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildBankCard(bank),
                      );
                    }),

                  const SizedBox(height: 15),
                  _buildAddButton(),
                  const SizedBox(height: 20),
                  _buildSecurityNote(),
                ],
              ),
            ),
    );
  }

  // HEADER

  Widget _buildPageHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PENGATURAN PEMBAYARAN',
          style: TextStyle(
            color: AppColors.primaryCyan,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Kelola rekeningmu.',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Rekening ini digunakan untuk menerima pencairan penghasilan EcoCash.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // SECTION HEADER

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Rekening tersimpan',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${_bankList.length} rekening',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // BANK CARD

  Widget _buildBankCard(Map<String, dynamic> item) {
    final String bankName = item['bankName'] ?? 'Bank';
    final String accountNumber = item['accountNumber'] ?? '';
    final String accountHolderName =
        item['accountHolderName'] ?? item['accountName'] ?? '';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => _openAccountDetail(item),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBankLogo(bankName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.darkNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          accountHolderName.isEmpty
                              ? 'Nama pemilik tidak tersedia'
                              : accountHolderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 150),
                    iconSize: 19,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    onSelected: (value) {
                      if (value == 'detail') {
                        _openAccountDetail(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'detail',
                        height: 42,
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: AppColors.darkNavy,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Detail rekening',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(height: 1, color: AppColors.cardBorder),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NOMOR REKENING',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _maskAccountNumber(accountNumber),
                          style: const TextStyle(
                            color: AppColors.darkNavy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 10,
                          color: AppColors.successGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tersimpan',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 27,
            color: AppColors.textMuted.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 11),
          const Text(
            'Belum ada rekening bank',
            style: TextStyle(
              color: AppColors.darkNavy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tambahkan rekening untuk menerima penghasilanmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 25,
            color: AppColors.error,
          ),
          const SizedBox(height: 9),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          TextButton(
            onPressed: _fetchBankAccounts,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ADD ACCOUNT BUTTON

  Widget _buildAddButton() {
    return Material(
      color: AppColors.darkNavy,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _openAddAccount,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: AppColors.primaryYellow),
              SizedBox(width: 7),
              Text(
                'Tambah rekening bank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECURITY NOTE

  Widget _buildSecurityNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Jaga kerahasiaan informasi rekening dan pastikan nama pemilik sesuai dengan data akunmu.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
