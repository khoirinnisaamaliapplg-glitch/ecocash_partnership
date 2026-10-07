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
import 'package:ecocash_partnership/features/profile/screens/security/keamanan_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/pengaturan_notifikasi_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/pusat_bantuan_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/chat_cs_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/laporkan_masalah_screen.dart';

import 'package:ecocash_partnership/features/jobs/screens/jobs_screen.dart';
import 'package:ecocash_partnership/features/jobs/screens/detail_pekerjaan_screen.dart';
import 'package:ecocash_partnership/features/jobs/screens/dalam_perjalanan_screen.dart';
import '../features/dashboard/screens/riwayat_pekerjaan_screen.dart';
import '../features/jobs/screens/detail_pekerjaan_rumah_screen.dart';
import '../features/jobs/screens/dalam_perjalanan_rumah_screen.dart';


import 'package:ecocash_partnership/features/profile/screens/academy/ecocash_academy_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/academy/detail_pelatihan_screen.dart';
import 'package:ecocash_partnership/features/profile/screens/academy/sertifikat_pelatihan_screen.dart';

import 'package:ecocash_partnership/features/profile/screens/riwayat_laporan_screen.dart';

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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final Map<String, dynamic> userData = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return OtpScreen(userData: userData);
        },
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) {
          final Map<String, dynamic> userData = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return MainLayout(userData: userData);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-otp',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return ForgotOtpScreen(extraData: extra);
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return NewPasswordScreen(extraData: extra);
        },
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
          final Map<String, String>? bankData = state.extra is Map
              ? Map<String, String>.from(state.extra as Map)
              : null;
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
        path: '/daftar-pekerjaan',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          final bool fromDashboard = extra['fromDashboard'] == true;
          return JobsScreen(isFromDashboard: fromDashboard);
        },
      ),
      GoRoute(
        path: '/riwayat-pekerjaan',
        builder: (context, state) => const RiwayatPekerjaanScreen(),
      ),
      GoRoute(
        path: '/detail-pekerjaan',
        builder: (context, state) {
          final Map<String, dynamic> jobData = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return DetailPekerjaanScreen(jobData: jobData);
        },
      ),
      GoRoute(
        path: '/dalam-perjalanan',
        builder: (context, state) {
          final Map<String, dynamic> jobData = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return DalamPerjalananScreen(jobData: jobData);
        },
      ),
      GoRoute(
        path: '/detail-pekerjaan-rumah',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return DetailPekerjaanRumahScreen(jobData: extra);
        },
      ),
      GoRoute(
        path: '/dalam-perjalanan-rumah',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return DalamPerjalananRumahScreen(extraData: extra);
        },
      ),
      GoRoute(
        path: '/academy',
        builder: (context, state) => const EcocashAcademyScreen(),
      ),
      GoRoute(
        path: '/academy/detail/:id',
        builder: (context, state) {
          final courseId = state.pathParameters['id'] ?? '';
          return DetailPelatihanScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/academy/sertifikat',
        builder: (context, state) => const SertifikatPelatihanScreen(),
      ),
      GoRoute(
        path: '/riwayat-laporan',
        builder: (context, state) => const RiwayatLaporanScreen(),
      ),
    ],
  );
}
