
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class DetailRekeningScreen extends StatelessWidget {
  final Map<String, String>? bankData;
  final PartnerApiService _apiService = PartnerApiService();

  DetailRekeningScreen({super.key, this.bankData});

  static const Color _navy = Color(0xFF0F2C59);
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _border = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    final String bankName = bankData?['bankName'] ?? 'Bank BCA';
    final String accountNumber =
        bankData?['accountNumber'] ?? '1234567890';
    final String accountName =
        bankData?['accountName'] ?? 'BUDI SANTOSO';
    final String cabang = bankData?['cabang'] ?? 'KCP Utama';
    final String tipe = bankData?['tipe'] ?? 'Tabungan';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _navy,
            size: 19,
          ),
        ),
        title: const Text(
          'Detail Rekening',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(bankName),
              const SizedBox(height: 20),

              _buildAccountCard(
                context,
                accountNumber: accountNumber,
                accountName: accountName,
              ),
              const SizedBox(height: 19),

              

              const SizedBox(height: 20),
              _buildSecurityNote(),
              const SizedBox(height: 27),

              _buildDeleteButton(context),
              const SizedBox(height: 11),

              Text(
                'Pastikan rekening yang digunakan masih aktif sebelum melakukan penarikan saldo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(String bankName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF194477),
            Color(0xFF0F2C59),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -17,
            child: Icon(
              Icons.account_balance_rounded,
              size: 115,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REKENING TERSIMPAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Informasi rekening pembayaran mitra EcoCash.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACCOUNT CARD
  // =========================================================

  Widget _buildAccountCard(
    BuildContext context, {
    required String accountNumber,
    required String accountName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Status rekening',
                  style: TextStyle(
                    color: Color(0xFF78818D),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF21845B),
                      size: 12,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Terverifikasi',
                      style: TextStyle(
                        color: Color(0xFF21845B),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'NOMOR REKENING',
            style: TextStyle(
              color: Color(0xFF8993A0),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: SelectableText(
                  accountNumber,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Material(
                color: const Color(0xFFEAF2FC),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: accountNumber),
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Nomor rekening berhasil disalin.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.copy_rounded,
                      color: _navy,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 15),

          const Text(
            'NAMA PEMILIK REKENING',
            style: TextStyle(
              color: Color(0xFF8993A0),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _navy,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  accountName,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget _buildInformationCard({
    required String bankName,
    required String cabang,
    required String tipe,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Nama Bank',
            value: bankName,
          ),
          const Divider(height: 1, color: _border),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Cabang',
            value: cabang,
          ),
          const Divider(height: 1, color: _border),
          _buildInfoRow(
            icon: Icons.wallet_outlined,
            label: 'Tipe Akun',
            value: tipe,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF60758F),
              size: 17,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF78818D),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY NOTE
  // =========================================================

  Widget _buildSecurityNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.shield_outlined,
          color: Color(0xFF21845B),
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Informasi rekening ini digunakan untuk kebutuhan transaksi dan pencairan saldo mitra EcoCash. Jaga kerahasiaan informasi akun Anda.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DELETE ACCOUNT
  // =========================================================

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showDeleteConfirmation(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD94B4B),
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: Color(0xFFF0DADA),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(
          Icons.delete_outline_rounded,
          size: 18,
        ),
        label: const Text(
          'Hapus Rekening',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            10,
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            0,
          ),
          title: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD94B4B),
                  size: 25,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hapus rekening?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus rekening ini? Rekening yang dihapus tidak dapat digunakan lagi untuk pencairan saldo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF78818D),
              fontSize: 11,
              height: 1.6,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            15,
            16,
            16,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      final String? bankAccountId = bankData?['id'];

                      if (bankAccountId == null ||
                          bankAccountId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ID Rekening tidak ditemukan!',
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      try {
                        final result = await _apiService
                            .deleteBankAccount(bankAccountId);

                        if (!context.mounted) return;

                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    'Rekening berhasil dihapus.',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          context.pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    'Gagal menghapus rekening.',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Terjadi kesalahan saat menghapus rekening.',
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        debugPrint('Delete bank account error: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD94B4B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Ya, Hapus',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
