
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_loading.dart';
import 'package:ecocash_partnership/services/api_service.dart';

class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  State<RiwayatLaporanScreen> createState() =>
      _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState
    extends State<RiwayatLaporanScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  List<dynamic> _ticketList = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _navy = Color(0xFF142D4E);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFE8EDF3);

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  // =========================================================
  // FETCH DATA
  // =========================================================

  Future<void> _fetchTickets({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _apiService.getMyTickets();

      if (!mounted) return;

      setState(() {
        if (result['success'] == true) {
          _ticketList = result['data'] is List
              ? result['data']
              : [];
          _errorMessage = null;
        } else {
          _errorMessage = result['message']?.toString() ??
              'Gagal mengambil riwayat laporan.';
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Terjadi kesalahan saat mengambil data. Silakan coba lagi.';
      });
    }
  }

  Future<void> _refreshTickets() async {
    await _fetchTickets(showLoading: false);
  }

  // =========================================================
  // STATISTIK LAPORAN
  // =========================================================

  int get _totalResolved {
    return _ticketList.where((ticket) {
      final status =
          ticket['status']?.toString().toUpperCase() ?? '';

      return status == 'RESOLVED' || status == 'CLOSED';
    }).length;
  }

  int get _totalInProgress {
    return _ticketList.where((ticket) {
      return ticket['status']
              ?.toString()
              .toUpperCase() ==
          'IN_PROGRESS';
    }).length;
  }

  int get _totalWaiting {
    return _ticketList.length -
        _totalResolved -
        _totalInProgress;
  }

  // =========================================================
  // FORMAT TANGGAL
  // =========================================================

  String _formatDate(dynamic date) {
    if (date == null) return '-';

    try {
      final parsedDate = DateTime.parse(date.toString());

      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final year = parsedDate.year.toString();

      return '$day/$month/$year';
    } catch (e) {
      return date.toString().split('T').first;
    }
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge(String status) {
    String label;
    Color background;
    Color foreground;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'CLOSED':
        label = 'Selesai';
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
        break;

      case 'IN_PROGRESS':
        label = 'Sedang Diproses';
        background = const Color(0xFFE0F2FE);
        foreground = const Color(0xFF0284C7);
        icon = Icons.sync_rounded;
        break;

      default:
        label = 'Menunggu';
        background = const Color(0xFFFFF5D6);
        foreground = const Color(0xFFD18A00);
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER DAN STATISTIK
  // =========================================================

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.13),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: _yellow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ECOCASH PARTNERSHIP',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PUSAT BANTUAN',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Riwayat Laporan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Pantau perkembangan dan tanggapan dari setiap laporan kendala Anda.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 19),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.description_rounded,
                  label: 'Total Laporan',
                  value: _ticketList.length.toString(),
                  iconColor: _yellow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Laporan Selesai',
                  value: _totalResolved.toString(),
                  iconColor: const Color(0xFF6EE7B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RINGKASAN STATUS
  // =========================================================

  Widget _buildStatusSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStatus(
              color: const Color(0xFF16A34A),
              value: _totalResolved,
              label: 'Selesai',
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: _border,
          ),
          Expanded(
            child: _buildMiniStatus(
              color: const Color(0xFF0284C7),
              value: _totalInProgress,
              label: 'Diproses',
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: _border,
          ),
          Expanded(
            child: _buildMiniStatus(
              color: const Color(0xFFD18A00),
              value: _totalWaiting,
              label: 'Menunggu',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatus({
    required Color color,
    required int value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: _secondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // JUDUL DAFTAR LAPORAN
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aktivitas Laporan',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Perkembangan laporan yang pernah Anda buat',
                style: TextStyle(
                  color: _secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1F8),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: _navy,
            size: 20,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: _refreshTickets,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFFDC2626),
            ),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryHeader(),
        const SizedBox(height: 45),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1F8),
              borderRadius: BorderRadius.circular(27),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: _navy,
              size: 43,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Belum Ada Laporan',
            style: TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Text(
            'Laporan kendala yang Anda buat nantinya akan muncul dan dapat dipantau melalui halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondary,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TIMELINE TICKET CARD
  // =========================================================

  Widget _buildTicketCard(dynamic ticket, int index) {
    final String subject =
        ticket['subject']?.toString() ?? 'Laporan Masalah';

    final String description =
        ticket['description']?.toString() ?? '';

    final String status =
        ticket['status']?.toString() ?? 'OPEN';

    final String? adminNotes =
        ticket['adminNotes']?.toString();

    final String createdAt =
        _formatDate(ticket['createdAt']);

    final bool isResolved =
        status.toUpperCase() == 'RESOLVED' ||
        status.toUpperCase() == 'CLOSED';

    final Color timelineColor = isResolved
        ? const Color(0xFF16A34A)
        : status.toUpperCase() == 'IN_PROGRESS'
            ? const Color(0xFF0284C7)
            : const Color(0xFFD18A00);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TIMELINE RAIL
          SizedBox(
            width: 27,
            child: Column(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  margin: const EdgeInsets.only(top: 19),
                  decoration: BoxDecoration(
                    color: timelineColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: timelineColor.withOpacity(0.25),
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 5),
                    color: const Color(0xFFDCE4ED),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // TICKET CONTENT
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATE AND STATUS
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: _secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            createdAt,
                            style: const TextStyle(
                              color: _secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // SUBJECT
                  Text(
                    subject,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // DESCRIPTION
                  Text(
                    description.isEmpty
                        ? 'Tidak ada deskripsi laporan.'
                        : description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),

                  // ADMIN NOTES
                  if (adminNotes != null &&
                      adminNotes.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6FB),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(
                            color: Color(0xFF2D7DB5),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.support_agent_rounded,
                            color: Color(0xFF2D7DB5),
                            size: 19,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggapan Admin',
                                  style: TextStyle(
                                    color: _navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  adminNotes,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),

      body: _isLoading
          ? const Center(
              child: AppLoading(
                message: 'Memuat riwayat laporan...',
                size: 76,
              ),
            )
          : RefreshIndicator(
              color: _navy,
              backgroundColor: Colors.white,
              onRefresh: _refreshTickets,
              child: _ticketList.isEmpty
                  ? _errorMessage != null
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildErrorBanner(),
                          ],
                        )
                      : _buildEmptyState()
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        25,
                      ),
                      children: [
                        // HEADER
                        _buildSummaryHeader(),

                        const SizedBox(height: 15),

                        // STATUS SUMMARY
                        _buildStatusSummary(),

                        const SizedBox(height: 25),

                        // SECTION TITLE
                        _buildSectionHeader(),

                        const SizedBox(height: 18),

                        // ERROR WHEN REFRESH FAILS
                        if (_errorMessage != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 12),
                        ],

                        // TIMELINE
                        ...List.generate(
                          _ticketList.length,
                          (index) => _buildTicketCard(
                            _ticketList[index],
                            index,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_double_arrow_down_rounded,
                                size: 15,
                                color: _secondary.withOpacity(0.8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tarik ke bawah untuk memperbarui',
                                style: TextStyle(
                                  color: _secondary.withOpacity(0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
