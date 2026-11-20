import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:ecocash_partnership/features/dashboard/screens/dashboard_screen.dart';
import 'package:ecocash_partnership/features/jobs/screens/jobs_screen.dart';
import 'package:ecocash_partnership/features/wallet/screens/wallet_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/profile_screen.dart';
import 'package:ecocash_partnership/features/scan/screens/scan_screen.dart';

class MainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainLayout({super.key, this.userData = const {}});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(userData: widget.userData),
          const JobsScreen(),
          _selectedIndex == 2 ? const ScanScreen() : const SizedBox.shrink(),
          const WalletScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.darkNavy,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.grid_view_rounded, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.grid_view_rounded, size: 22),
                ),
                label: 'Beranda',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.assignment_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.assignment_rounded, size: 22),
                ),
                label: 'Tugas',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2 ? AppColors.darkNavy : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedIndex == 2 ? AppColors.darkNavy : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: _selectedIndex == 2 ? Colors.white : AppColors.textMuted,
                  ),
                ),
                label: 'Scan',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.account_balance_wallet_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.account_balance_wallet_rounded, size: 22),
                ),
                label: 'Wallet',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.person_outline_rounded, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.person_rounded, size: 22),
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}