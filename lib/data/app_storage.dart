import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _riwayatDiprosesKey = 'riwayat_diproses';
  static const String _riwayatDibatalkanKey = 'riwayat_dibatalkan';
  static const String _profileKey = 'user_profile_data';
  static const String _vehiclesKey = 'user_vehicles_data'; // <-- Key baru untuk kendaraan

  // --- ONBOARDING ---
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // --- RIWAYAT PEKERJAAN (DIPROSES & DIBATALKAN) ---
  
  static Future<void> saveDiproses(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(list);
    await prefs.setString(_riwayatDiprosesKey, encoded);
  }

  static Future<List<Map<String, dynamic>>> getDiproses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_riwayatDiprosesKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> saveDibatalkan(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(list);
    await prefs.setString(_riwayatDibatalkanKey, encoded);
  }

  static Future<List<Map<String, dynamic>>> getDibatalkan() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_riwayatDibatalkanKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // --- PROFIL PENGGUNA ---

  static Future<void> saveProfile(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(profileData);
    await prefs.setString(_profileKey, encoded);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_profileKey);
    if (encoded == null) {
      return {
        'name': 'Budi Santoso',
        'phone': '+62 812-3456-7890',
        'email': 'budi.s@email.com',
        'address': 'Jl. Merdeka Raya No. 45, Kebayoran Baru,\nJakarta Selatan, 12110',
        'imageBytes': null,
      };
    }
    return Map<String, dynamic>.from(jsonDecode(encoded));
  }

  // --- MANAJEMEN KENDARAAN --- (Baru ditambahkan)

  // Simpan list kendaraan
  static Future<void> saveVehicles(List<Map<String, dynamic>> vehiclesList) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(vehiclesList);
    await prefs.setString(_vehiclesKey, encoded);
  }

  // Ambil list kendaraan
  static Future<List<Map<String, dynamic>>> getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_vehiclesKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}