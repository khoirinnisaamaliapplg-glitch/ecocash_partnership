import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/main_layout.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart'; 
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/forgot_otp_screen.dart';
import '../features/auth/screens/new_password_screen.dart';
import 'package:ecocash_partnership/features/dashboard/screens/detail_penghasilan_screen.dart';
import 'package:ecocash_partnership/features/dashboard/screens/statistik_material_screen.dart';
import 'package:ecocash_partnership/features/dashboard/screens/skor_partner_screen.dart';
import 'package:ecocash_partnership/features/dashboard/screens/harga_material_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/edit_profile_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/dampak_saya_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/akun_bank_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/tambah_rekening_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/detail_rekening_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/pengaturan_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/keamanan_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/pengaturan_notifikasi_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/pusat_bantuan_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/chat_cs_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/laporkan_masalah_screen.dart';
import '../features/dashboard/screens/riwayat_pekerjaan_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // 2. Tambahkan route OTP di sini
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainLayout(),
      ),
      // Tambahkan di dalam routes list GoRouter:
GoRoute(
  path: '/forgot-password',
  builder: (context, state) => const ForgotPasswordScreen(),
),
GoRoute(
  path: '/forgot-otp',
  builder: (context, state) => const ForgotOtpScreen(),
),
GoRoute(
  path: '/new-password',
  builder: (context, state) => const NewPasswordScreen(),
),

GoRoute(
  path: '/detail-penghasilan',
  builder: (context, state) => const DetailPenghasilanScreen(),
),

GoRoute(
  path: '/statistik-material',
  builder: (context, state) => const StatistikMaterialScreen(),
),
GoRoute(
  path: '/skor-partner',
  builder: (context, state) => const SkorPartnerScreen(),
),
GoRoute(
  path: '/harga-material',
  builder: (context, state) => const HargaMaterialScreen(),
),
GoRoute(
  path: '/edit-profile',
  builder: (context, state) => const EditProfileScreen(),
),
GoRoute(
  path: '/dampak-saya',
  builder: (context, state) => const DampakSayaScreen(),
),
GoRoute(
  path: '/akun-bank',
  builder: (context, state) => const AkunBankScreen(),
),
GoRoute(
  path: '/tambah-rekening',
  builder: (context, state) => const TambahRekeningScreen(),
),
GoRoute(
  path: '/detail-rekening',
  builder: (context, state) {
    final bankData = state.extra as Map<String, String>?;
    return DetailRekeningScreen(bankData: bankData);
  },
),
GoRoute(
  path: '/pengaturan',
  builder: (context, state) => const PengaturanScreen(),
),
GoRoute(
  path: '/keamanan',
  builder: (context, state) => const KeamananScreen(),
),
GoRoute(
  path: '/pengaturan-notifikasi',
  builder: (context, state) => const PengaturanNotifikasiScreen(),
),
GoRoute(
  path: '/pusat-bantuan',
  builder: (context, state) => const PusatBantuanScreen(),
),
GoRoute(
  path: '/chat-cs',
  builder: (context, state) => const ChatCsScreen(),
),
GoRoute(
  path: '/laporkan-masalah',
  builder: (context, state) => const LaporkanMasalahScreen(),
),
GoRoute(
  path: '/riwayat-pekerjaan',
  builder: (context, state) => const RiwayatPekerjaanScreen(),
),

    ],
  );
}