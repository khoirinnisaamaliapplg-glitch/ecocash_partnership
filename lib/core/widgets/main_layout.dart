import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:ecocash_partnership/features/dashboard/screens/dashboard_screen.dart'; // <-- TAMBAHKAN IMPORT INI
import 'package:ecocash_partnership/features/jobs/screens/jobs_screen.dart';
import 'package:ecocash_partnership/features/wallet/screens/wallet_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/profile_screen.dart';
import 'package:ecocash_partnership/features/scan/screens/scan_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Daftar halaman untuk masing-masing tab
final List<Widget> _screens = [
  const DashboardScreen(),
  const JobsScreen(),
  const ScanScreen(), // <-- Hubungkan ke ScanScreen
  const WalletScreen(),
  const ProfileScreen(),
];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary2,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}