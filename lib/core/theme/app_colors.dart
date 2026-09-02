import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryCyan = Color(0xFF0BCFD1);
  // --- Brand Colors (Warna Utama Identitas) ---
  static const Color primaryGreen = Color(0xFF0F7A3E); // Hijau utama (Tombol Masuk, Lanjut, aksen daun di Logo)
  static const Color primaryBlue = Color(0xFF1E88E5);  // Biru utama (Huruf 'e' pada Logo EcoCash, ikon verifikasi)
  
  // --- Background Colors (Warna Latar) ---
  static const Color background = Color(0xFFFFFFFF);   // Putih bersih untuk latar belakang utama aplikasi
  static const Color surface = Color(0xFFF8F9FA);      // Putih abu-abu halus untuk area kartu, panel, atau form
  
  // --- Text Colors (Warna Teks) ---
  static const Color textPrimary = Color(0xFF1A1A1A);  // Hitam pekat untuk judul, heading, dan teks penekanan
  static const Color textSecondary = Color(0xFF6C757D);// Abu-abu untuk teks deskripsi, hint form, dan sub-judul
  static const Color textLink = Color(0xFF1E88E5);     // Biru untuk teks yang bisa diklik (seperti "Lupa Kata Sandi?")
  static const Color textLink2 = Color(0xFF63D1F0);
static const Color primary2 = Color(0xFF003F7B); // biru untuk EcoCash Partner

  // --- UI Elements (Garis & Komponen Pasif) ---
  static const Color border = Color(0xFFEBEBEB);       // Abu-abu terang untuk garis batas luar (border) TextFormField
  static const Color divider = Color(0xFFEEEEEE);      // Abu-abu sangat pudar untuk garis pemisah (divider)
  static const Color dotInactive = Color(0xFFD9D9D9);  // Abu-abu untuk indikator halaman (dot onboarding) yang tidak aktif
  
  // --- Semantic / Status Colors (Warna Validasi) ---
  static const Color success = Color(0xFF28A745);      // Hijau terang untuk status berhasil (seperti centang sukses)
  static const Color successGreen = Color(0xFF047363); //hijau untuk rupiah
  static const Color error = Color(0xFFDC3545);        // Merah untuk peringatan atau teks error (seperti OTP salah)
  static const Color warning = Color(0xFFFFC107);      // Kuning untuk status peringatan, pending, atau menunda
  static const Color info = Color(0xFF17A2B8);         // Biru toska untuk informasi tambahan (opsional)
static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [
      Color(0xFF2B7A98), // Biru Tua (sisi kiri)
      Color(0xFF14A89B), // Toska / Cyan (sisi kanan)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}