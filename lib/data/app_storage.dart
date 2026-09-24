import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _riwayatDiprosesKey = 'riwayat_diproses';
  static const String _riwayatDibatalkanKey = 'riwayat_dibatalkan';
  static const String _profileKey = 'user_profile_data';
  static const String _vehiclesKey = 'user_vehicles_data';

  // KEY UNTUK AUTENTIKASI
  static const String _tokenKey = 'jwt_token';
  static const String _userDataKey = 'auth_user_data';

  // --- ONBOARDING ---
  static Future setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // --- MANAJEMEN AUTENTIKASI & TOKEN JWT ---

  static Future saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future isLoggedIn() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future saveUserData(dynamic userData) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(userData);
    await prefs.setString(_userDataKey, encoded);
  }

  static Future getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_userDataKey);
    if (encoded == null) return null;
    return jsonDecode(encoded);
  }

  static Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }

  // --- RIWAYAT PEKERJAAN (DIPROSES & DIBATALKAN) ---
  
  static Future saveDiproses(dynamic list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(list);
    await prefs.setString(_riwayatDiprosesKey, encoded);
  }

  static Future getDiproses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_riwayatDiprosesKey);
    if (encoded == null) return [];
    final List decoded = jsonDecode(encoded);
    return decoded;
  }

  static Future saveDibatalkan(dynamic list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(list);
    await prefs.setString(_riwayatDibatalkanKey, encoded);
  }

  static Future getDibatalkan() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_riwayatDibatalkanKey);
    if (encoded == null) return [];
    final List decoded = jsonDecode(encoded);
    return decoded;
  }

  // --- PROFIL PENGGUNA ---

  static Future saveProfile(dynamic profileData) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(profileData);
    await prefs.setString(_profileKey, encoded);
  }

  static Future getProfile() async {
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
    return jsonDecode(encoded);
  }

  // --- MANAJEMEN KENDARAAN ---

  static Future saveVehicles(dynamic vehiclesList) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(vehiclesList);
    await prefs.setString(_vehiclesKey, encoded);
  }

  static Future getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_vehiclesKey);
    if (encoded == null) return [];
    final List decoded = jsonDecode(encoded);
    return decoded;
  }
}