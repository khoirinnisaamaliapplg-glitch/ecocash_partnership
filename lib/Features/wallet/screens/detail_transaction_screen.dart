
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DetailTransactionScreen extends StatelessWidget {
  final bool isWithdrawal;
  final Map<String, dynamic>? transactionData;

  const DetailTransactionScreen({
    super.key,
    this.isWithdrawal = false,
    this.transactionData,
  });

  String _formatCurrency(num number) {
    final str = number.toStringAsFixed(0);
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'Tercatat di sistem';

    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();

      const months = [
        'Januari', 'Februari', 'Maret', 'April',
        'Mei', 'Juni', 'Juli', 'Agustus',
        'September', 'Oktober', 'November', 'Desember'
      ];

      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');

      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$minute';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Map<String, dynamic> _getStatusInfo(String status, bool isOut) {
    if (!isOut) {
      return {
        'label': 'Transaksi Berhasil',
        'description': 'Transaksi berhasil tercatat di dompet EcoCash.',
        'color': const Color(0xFF16865B),
        'background': const Color(0xFFE4F6ED),
        'icon': Icons.check_circle_outline_rounded,
      };
    }

    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'WAITING':
      case 'WAITING_APPROVAL':
        return {
          'label': 'Menunggu Validasi',
          'description':
              'Permintaan penarikan sedang menunggu pemeriksaan dan persetujuan admin.',
          'color': const Color(0xFFB78110),
          'background': const Color(0xFFFFF5D9),
          'icon': Icons.access_time_rounded,
        };

      case 'APPROVED':
        return {
          'label': 'Disetujui Admin',
          'description':
              'Permintaan penarikan telah disetujui oleh admin.',
          'color': const Color(0xFF16865B),
          'background': const Color(0xFFE4F6ED),
          'icon': Icons.check_circle_outline_rounded,
        };

      case 'COMPLETED':
      case 'SUCCESS':
        return {
          'label': 'Penarikan Selesai',
          'description':
              'Proses penarikan telah diselesaikan.',
          'color': const Color(0xFF16865B),
          'background': const Color(0xFFE4F6ED),
          'icon': Icons.check_circle_outline_rounded,
        };

      case 'REJECTED':
      case 'FAILED':
        return {
          'label': 'Penarikan Ditolak',
          'description':
              'Permintaan penarikan tidak disetujui oleh admin.',
          'color': const Color(0xFFD94848),
          'background': const Color(0xFFFFEEEE),
          'icon': Icons.cancel_outlined,
        };

      default:
        return {
          'label': 'Status Penarikan',
          'description':
              'Silakan periksa kembali status penarikan pada riwayat transaksi.',
          'color': AppColors.textSecondary,
          'background': const Color(0xFFF1F3F5),
          'icon': Icons.info_outline_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = transactionData ?? {};

    final String type = (data['type'] ??
            (isWithdrawal ? 'WITHDRAWAL' : 'DEPOSIT'))
        .toString()
        .toUpperCase();

    final bool isOut =
        type == 'WITHDRAWAL' || type == 'WITHDRAW' || isWithdrawal;

    final num amount =
        double.tryParse(data['amount']?.toString() ?? '0') ?? 0;

    final String formattedAmount =
        '${isOut ? '-' : '+'}Rp ${_formatCurrency(amount)}';

    final String dateDisplay = _formatDate(data['createdAt']);

    final String description = data['description']?.toString() ??
        (isOut
            ? 'Penarikan Saldo Dompet'
            : 'Komisi Jasa Penjemputan Sampah');

    final String trxId = data['id'] != null
        ? 'TRX-ECO-${data['id']}'
        : 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final String statusValue =
        (data['status'] ?? data['withdrawalStatus'] ?? '')
            .toString();

    final status = _getStatusInfo(statusValue, isOut);

    // Ekstraksi Job ID
    final matchJob = RegExp(
      r'Job\s*#?(\d+)',
      caseSensitive: false,
    ).firstMatch(description);

    final String? jobId =
        matchJob != null ? '#${matchJob.group(1)}' : null;

    // Ekstraksi bobot timbangan
    final matchWeight = RegExp(
      r'(\d+(?:\.\d+)?)\s*kg',
      caseSensitive: false,
    ).firstMatch(description);

    final double weightKg = matchWeight != null
        ? (double.tryParse(matchWeight.group(1)!) ?? 0.0)
        : 0.0;

    // Ekstraksi lokasi kontainer
    final matchMachine = RegExp(
          r'disetor ke\s+([^\n]+?)$',
          caseSensitive: false,
        ).firstMatch(description) ??
        RegExp(
          r'(?:setor ke|ke)\s+([^(\n]+?)(?:\s+via|\s+Job|\s*\(|$)',
          caseSensitive: false,
        ).firstMatch(description);

    final String? machineDestination =
        matchMachine != null ? matchMachine.group(1)!.trim() : null;

    final String lowerDescription = description.toLowerCase();

    final bool isResidentialPickup =
        lowerDescription.contains('warga') ||
        lowerDescription.contains('jemput') ||
        lowerDescription.contains('penjemputan');

    final bool isContainerToRecycler =
        lowerDescription.contains('pabrik') ||
        lowerDescription.contains('daur ulang') ||
        lowerDescription.contains('angkut kontainer');

    // Tarif dasar dan insentif
    final num baseRate = isContainerToRecycler ? 35000 : 20000;
    final num perKgRate = isContainerToRecycler ? 2000 : 1000;

    final num calculatedBonus =
        weightKg > 0 ? (weightKg * perKgRate).round() : 0;

    final num weightBonus = calculatedBonus > 0
        ? calculatedBonus
        : (amount > baseRate ? amount - baseRate : 0);

    final num? balBefore =
        double.tryParse(data['balanceBefore']?.toString() ?? '');

    final num? balAfter =
        double.tryParse(data['balanceAfter']?.toString() ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Transaksi',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // KARTU UTAMA TRANSAKSI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: status['background'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOut
                            ? status['icon'] as IconData
                            : Icons.south_west_rounded,
                        color: status['color'] as Color,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      status['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      status['description'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      formattedAmount,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isOut
                            ? const Color(0xFFD94848)
                            : const Color(0xFF16865B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      dateDisplay,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 17),

                    // INFORMASI TRANSAKSI
                    _buildDetailRow(
                      'Jenis Transaksi',
                      isOut
                          ? 'Penarikan Saldo'
                          : (isResidentialPickup
                              ? 'Jemput Sampah Warga'
                              : (isContainerToRecycler
                                  ? 'Angkut Kontainer ke Pabrik'
                                  : 'Setor Smart Container')),
                    ),

                    if (jobId != null) ...[
                      const SizedBox(height: 14),
                      _buildDetailRow('No. Penugasan', jobId),
                    ],

                    if (weightKg > 0) ...[
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        'Total Muatan',
                        '${weightKg.toStringAsFixed(1)} kg',
                      ),
                    ],

                    if (machineDestination != null) ...[
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        'Tujuan Setor',
                        machineDestination,
                      ),
                    ],

                    const SizedBox(height: 14),
                    _buildDetailRow('Keterangan', description),

                    const SizedBox(height: 14),
                    _buildDetailRow(
                      'Metode',
                      'EcoCash Partner Wallet',
                    ),

                    const SizedBox(height: 14),
                    _buildDetailRow('ID Transaksi', trxId),

                    if (balBefore != null) ...[
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        'Saldo Sebelum',
                        'Rp ${_formatCurrency(balBefore)}',
                      ),
                    ],

                    if (balAfter != null) ...[
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        'Saldo Sesudah',
                        'Rp ${_formatCurrency(balAfter)}',
                      ),
                    ],
                  ],
                ),
              ),

              // RINCIAN KOMISI
              if (!isOut &&
                  (isResidentialPickup || isContainerToRecycler)) ...[
                const SizedBox(height: 17),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.025),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            color: AppColors.primaryCyan,
                            size: 21,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Rincian Perhitungan Komisi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 19),

                      _buildBreakdownRow(
                        isContainerToRecycler
                            ? 'Tarif Dasar Pengosongan Kontainer'
                            : 'Tarif Dasar Penjemputan Warga',
                        'Rp ${_formatCurrency(baseRate)}',
                      ),

                      const SizedBox(height: 13),

                      _buildBreakdownRow(
                        weightKg > 0
                            ? 'Insentif Timbangan (${weightKg.toStringAsFixed(1)} kg × Rp ${_formatCurrency(perKgRate)})'
                            : 'Insentif Bobot Muatan',
                        'Rp ${_formatCurrency(weightBonus)}',
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Divider(
                          color: Color(0xFFEEEEEE),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Komisi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // TOMBOL KEMBALI
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Riwayat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
