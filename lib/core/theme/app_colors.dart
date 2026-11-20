import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // 1. BRAND COLOR PALETTE (DESIGN SYSTEM NEW)
  // ==========================================
  
  /// Warna utama identitas brand (Header, kartu sorotan, & aksen penting)
  static const Color primaryYellow = Color(0xFFFFE600);
  
  /// Teks utama & ikon di atas bidang kuning untuk kontras tinggi
  static const Color primaryDark = Color(0xFF1C1C1E);
  
  /// Aksen pelengkap merepresentasikan lingkungan
  static const Color ecoGreen = Color(0xFF00AA13);
  static const Color ecoGreenDark = Color(0xFF059669);
  
  /// Elemen nominal saldo, judul kartu, & tombol aksi utama
  static const Color darkNavy = Color(0xFF0F2C59);
  static const Color slateNavy = Color(0xFF1E293B);
  
  /// Warna dasar kartu saldo, menu aksi, & komponen UI
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Warna latar belakang utama agar kartu putih terlihat menonjol
  static const Color background = Color(0xFFF8F9FA);

  // ==========================================
  // 2. TEXT & BORDER COLORS (DESAIN MODERN)
  // ==========================================
  
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLink = Color(0xFF1E88E5);
  static const Color textLink2 = Color(0xFF63D1F0);
  
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFEBEBEB);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color dotInactive = Color(0xFFD9D9D9);

  // ==========================================
  // 3. SEMANTIC / STATUS COLORS
  // ==========================================
  
  static const Color success = Color(0xFF28A745);
  static const Color successGreen = Color(0xFF047363);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // ==========================================
  // 4. LEGACY ALIASES (AGAR FE TIDAK BREAK)
  // ==========================================
  
  static const Color primaryCyan = Color(0xFF0BCFD1);
  static const Color primaryGreen = Color(0xFF0F7A3E);
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primary2 = Color(0xFF003F7B);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [
      Color(0xFF0F2C59), // Dark Navy
      Color(0xFF1E88E5), // Primary Blue
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}