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
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$minute WIB';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String type = (transactionData?['type'] ?? (isWithdrawal ? 'WITHDRAWAL' : 'DEPOSIT'))
        .toString()
        .toUpperCase();
    final bool isOut = type == 'WITHDRAWAL' || type == 'WITHDRAW' || isWithdrawal;

    final num amount = double.tryParse(transactionData?['amount']?.toString() ?? '0') ?? 0;
    final String formattedAmount = "${isOut ? '-' : '+'}Rp ${_formatCurrency(amount)}";
    final String dateDisplay = _formatDate(transactionData?['createdAt']);
    final String description = transactionData?['description']?.toString() ??
        (isOut ? 'Penarikan Saldo Dompet' : 'Komisi Jasa Penjemputan Sampah');
    final String trxId = transactionData?['id'] != null
        ? 'TRX-ECO-${transactionData!['id']}'
        : 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Ekstraksi data Job ID
    final matchJob = RegExp(r'Job\s*#?(\d+)', caseSensitive: false).firstMatch(description);
    final String? jobId = matchJob != null ? '#${matchJob.group(1)}' : null;

    // Ekstraksi data bobot timbangan
    final matchWeight = RegExp(r'(\d+(?:\.\d+)?)\s*kg', caseSensitive: false).firstMatch(description);
    final double weightKg = matchWeight != null ? (double.tryParse(matchWeight.group(1)!) ?? 0.0) : 0.0;

    // Ekstraksi lokasi kontainer tujuan (format: "disetor ke Smart Container...")
    final matchMachine = RegExp(r'disetor ke\s+([^\n]+?)$', caseSensitive: false).firstMatch(description) ??
        RegExp(r'(?:setor ke|ke)\s+([^(\n]+?)(?:\s+via|\s+Job|\s*\(|$)', caseSensitive: false).firstMatch(description);
    final String? machineDestination = matchMachine != null ? matchMachine.group(1)!.trim() : null;

    final bool isResidentialPickup = description.toLowerCase().contains('warga') ||
        description.toLowerCase().contains('jemput') ||
        description.toLowerCase().contains('penjemputan');

    final bool isContainerToRecycler = description.toLowerCase().contains('pabrik') ||
        description.toLowerCase().contains('daur ulang') ||
        description.toLowerCase().contains('angkut kontainer');

    // Tarif dasar dan insentif dinamis
    final num baseRate = isContainerToRecycler ? 35000 : 20000;
    final num perKgRate = isContainerToRecycler ? 2000 : 1000;
    final num calculatedBonus = (weightKg > 0) ? (weightKg * perKgRate).round() : 0;
    final num weightBonus = (calculatedBonus > 0) ? calculatedBonus : (amount > baseRate ? (amount - baseRate) : 0);

    final num? balBefore = double.tryParse(transactionData?['balanceBefore']?.toString() ?? '');
    final num? balAfter = double.tryParse(transactionData?['balanceAfter']?.toString() ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: const Text('Detail Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOut ? Colors.red.shade50 : Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOut ? Icons.arrow_upward : Icons.check_circle_outline,
                      color: isOut ? Colors.red : Colors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Transaksi Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryCyan)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formattedAmount,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isOut ? Colors.red : const Color(0xFF0F2C59),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dateDisplay, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    'Jenis Transaksi',
                    isOut
                        ? 'Penarikan Saldo'
                        : (isResidentialPickup
                            ? 'Jemput Sampah Warga'
                            : (isContainerToRecycler ? 'Angkut Kontainer ke Pabrik' : 'Setor Smart Container')),
                  ),
                  if (jobId != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow('No. Penugasan', jobId),
                  ],
                  if (weightKg > 0) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow('Total Muatan', '${weightKg.toStringAsFixed(1)} kg'),
                  ],
                  if (machineDestination != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow('Tujuan Setor', machineDestination),
                  ],
                  const SizedBox(height: 10),
                  _buildDetailRow('Keterangan', description),
                  const SizedBox(height: 10),
                  _buildDetailRow('Metode', 'EcoCash Partner Wallet'),
                  const SizedBox(height: 10),
                  _buildDetailRow('ID Transaksi', trxId),

                  if (balBefore != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow('Saldo Sebelum', 'Rp ${_formatCurrency(balBefore)}'),
                  ],
                  if (balAfter != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow('Saldo Sesudah', 'Rp ${_formatCurrency(balAfter)}'),
                  ],
                ],
              ),
            ),

            // Kartu Rincian Skema Komisi
            if (!isOut && (isResidentialPickup || isContainerToRecycler)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.cyan.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calculate_outlined, color: AppColors.primaryCyan, size: 20),
                        SizedBox(width: 8),
                        Text('Rincian Perhitungan Komisi Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2C59))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBreakdownRow(
                      isContainerToRecycler ? 'Tarif Dasar Pengosongan Kontainer' : 'Tarif Dasar Penjemputan Warga',
                      'Rp ${_formatCurrency(baseRate)}',
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      weightKg > 0
                          ? 'Insentif Timbangan (${weightKg.toStringAsFixed(1)} kg × Rp ${_formatCurrency(perKgRate)})'
                          : 'Insentif Bobot Muatan',
                      'Rp ${_formatCurrency(weightBonus)}',
                    ),
                    const Divider(height: 20, color: Color(0xFFEEEEEE)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Komisi Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2C59))),
                        Text(
                          'Rp ${_formatCurrency(amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E88A8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bukti transaksi berhasil diunduh ke perangkat')),
                  );
                },
                icon: const Icon(Icons.download, color: Colors.white, size: 16),
                label: const Text('Unduh Bukti Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88A8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}