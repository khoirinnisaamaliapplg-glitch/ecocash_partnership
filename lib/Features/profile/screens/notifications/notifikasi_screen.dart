
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  static const Color _navy = Color(0xFF0F2C59);
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _border = Color(0xFFE9EDF2);

  final List<Map<String, dynamic>> _todayNotifications = [
    {
      'icon': Icons.work_outline_rounded,
      'title': 'Pekerjaan baru tersedia',
      'subtitle': 'EcoCash Valen #BGD-021 (2,3 km)',
      'time': '10 mnt yang lalu',
      'unread': true,
      'color': Color(0xFF3766A5),
    },
    {
      'icon': Icons.account_balance_wallet_outlined,
      'title': 'Pembayaran berhasil',
      'subtitle': 'Rp82.000 masuk ke Wallet',
      'time': '1 jam yang lalu',
      'unread': true,
      'color': Color(0xFF21845B),
    },
    {
      'icon': Icons.verified_outlined,
      'title': 'Verifikasi berhasil',
      'subtitle': 'Material PET terverifikasi.',
      'time': '3 jam yang lalu',
      'unread': false,
      'color': Color(0xFF21845B),
    },
    {
      'icon': Icons.school_outlined,
      'title': 'Pelatihan hampir selesai',
      'subtitle': 'Modul Digital Literacy sudah 75%.',
      'time': '5 jam yang lalu',
      'unread': false,
      'color': Color(0xFF8A62C2),
      'progress': 0.75,
    },
  ];

  final List<Map<String, dynamic>> _previousNotifications = [
    {
      'icon': Icons.local_shipping_outlined,
      'title': 'Tugas selesai',
      'subtitle': 'Pengambilan di Kios Pak Budi berhasil diselesaikan.',
      'time': 'Kemarin, 14:30',
      'unread': false,
      'color': Color(0xFF3766A5),
    },
    {
      'icon': Icons.campaign_outlined,
      'title': 'Info Sistem',
      'subtitle': 'Pembaruan aplikasi versi 3.1 tersedia. Silakan update.',
      'time': '2 Hari yang lalu',
      'unread': false,
      'color': Color(0xFFD59A32),
    },
  ];

  int get _unreadCount {
    return [
      ..._todayNotifications,
      ..._previousNotifications,
    ].where((item) => item['unread'] == true).length;
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _todayNotifications) {
        item['unread'] = false;
      }

      for (final item in _previousNotifications) {
        item['unread'] = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua notifikasi sudah dibaca.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF21845B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _markAsRead(Map<String, dynamic> notification) {
    if (notification['unread'] != true) return;

    setState(() {
      notification['unread'] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 58,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _navy,
            size: 19,
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Baca semua',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 23),

              Row(
                children: [
                  const Text(
                    'Hari Ini',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_unreadCount BELUM DIBACA',
                        style: const TextStyle(
                          color: Color(0xFF3766A5),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              ..._todayNotifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _buildNotificationCard(notification),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Sebelumnya',
                style: TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              ..._previousNotifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _buildNotificationCard(notification),
                ),
              ),

              const SizedBox(height: 10),

              _buildFooterNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF153C70),
            Color(0xFF0F2C59),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -16,
            child: Icon(
              Icons.notifications_active_rounded,
              size: 110,
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
                  'PUSAT INFORMASI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Pemberitahuan Anda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _unreadCount > 0
                    ? 'Anda memiliki $_unreadCount notifikasi yang belum dibaca.'
                    : 'Semua notifikasi sudah Anda baca.',
                style: const TextStyle(
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isUnread = notification['unread'] == true;
    final double? progress = notification['progress'] as double?;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFD9E8F8)
                  : _border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  notification['icon'] as IconData,
                  color: notification['color'] as Color,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] as String,
                            style: TextStyle(
                              color: _navy,
                              fontSize: 12,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      notification['subtitle'] as String,
                      style: const TextStyle(
                        color: Color(0xFF78818D),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),

                    if (progress != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0xFFE8ECEF),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryCyan,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Color(0xFF9AA3AE),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification['time'] as String,
                          style: const TextStyle(
                            color: Color(0xFF9AA3AE),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFD9E8F8),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF3766A5),
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ketuk notifikasi untuk menandainya sebagai sudah dibaca.',
              style: TextStyle(
                color: Color(0xFF385675),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
