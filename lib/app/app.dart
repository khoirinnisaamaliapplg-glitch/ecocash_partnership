import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'routes.dart';

class EcoCashApp extends StatelessWidget {
  const EcoCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoCash Indonesia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary2),
        scaffoldBackgroundColor: AppColors.background,
      ),
      routerConfig: AppRoutes.router,
    );
  }
}