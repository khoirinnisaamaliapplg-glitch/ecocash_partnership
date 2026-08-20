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
    ],
  );
}