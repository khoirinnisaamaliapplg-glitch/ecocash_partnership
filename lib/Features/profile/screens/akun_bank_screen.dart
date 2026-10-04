import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class AkunBankScreen extends StatefulWidget {
  const AkunBankScreen({super.key});

  @override
  State<AkunBankScreen> createState() => _AkunBankScreenState();
}

class _AkunBankScreenState extends State<AkunBankScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  List<dynamic> _bankList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getBankAccounts();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _bankList = result['data'] is List ? result['data'] : [];
        }
      });
    }
  }

  String _maskAccountNumber(String raw) {
    if (raw.length <= 4) return raw;
    return '* * * *     ${raw.substring(raw.length - 4)}';
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
          'Akun Bank',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelola rekening bank Anda untuk menerima penarikan hasil penjualan material. Pastikan nama pemilik rekening sesuai dengan nama akun Anda.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Rekening Tersimpan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  _bankList.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada rekening tersimpan.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _bankList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _bankList[index];
                            return _buildBankCard(item: item);
                          },
                        ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () async {
                      final refreshNeeded = await context.push<bool>('/tambah-rekening');
                      if (refreshNeeded == true) {
                        _fetchBankAccounts();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryCyan,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: AppColors.primaryCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tambah Rekening Baru',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBankCard({required Map<String, dynamic> item}) {
    final String bankName = item['bankName'] ?? 'Bank';
    final String accountNumber = item['accountNumber'] ?? '';
    final String accountHolderName = item['accountHolderName'] ?? item['accountName'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Icon(Icons.account_balance, color: AppColors.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(accountHolderName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _maskAccountNumber(accountNumber),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary, letterSpacing: 1.2),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 12, color: AppColors.primaryCyan),
                          SizedBox(width: 4),
                          Text('Terverifikasi', style: TextStyle(fontSize: 10, color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'detail') {
                context.push('/detail-rekening', extra: {
                  'bankName': bankName,
                  'accountNumber': accountNumber,
                  'accountName': accountHolderName,
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'detail',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 10),
                    Text('Detail Rekening', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}