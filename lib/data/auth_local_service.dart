import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalService {
  static const String _usersKey = 'registered_users_key';
  static String? _currentResetIdentifier; // Menyimpan identitas user yang sedang reset password

  // Data default awal jika penyimpanan masih kosong
  static const List<Map<String, String>> _defaultUsers = [
    {
      'name': 'Mitra EcoCash',
      'username': 'mitra_ecocash',
      'phone': '081234567890',
      'email': 'mitra@ecocash.com',
      'password': 'password123',
    }
  ];

  // 1. Ambil semua data pengguna dari SharedPreferences
  static Future<List<Map<String, String>>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString(_usersKey);
    
    if (usersString == null) {
      // Jika belum ada, simpan data default
      await saveUsers(_defaultUsers);
      return _defaultUsers;
    }

    List<dynamic> decoded = jsonDecode(usersString);
    return decoded.map((item) => Map<String, String>.from(item)).toList();
  }

  // 2. Simpan daftar pengguna ke SharedPreferences
  static Future<void> saveUsers(List<Map<String, String>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  // 3. Fungsi Register (Menyimpan data baru secara lokal)
  static Future<bool> register({
    required String name,
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    List<Map<String, String>> users = await getUsers();

    // Cek apakah email atau nomor ponsel sudah terdaftar
    bool isExist = users.any((user) => user['email'] == email || user['phone'] == phone);
    if (isExist) {
      return false; // Gagal karena sudah ada
    }

    // Tambah user baru
    users.add({
      'name': name,
      'username': username,
      'phone': phone,
      'email': email,
      'password': password,
    });

    // Simpan kembali ke penyimpanan lokal
    await saveUsers(users);
    return true;
  }

  // 4. Fungsi Login (Validasi dengan data lokal)
  static Future<bool> login({required String identifier, required String password}) async {
    List<Map<String, String>> users = await getUsers();
    try {
      users.firstWhere(
        (u) => 
          (u['phone'] == identifier || u['email'] == identifier || u['username'] == identifier) && 
          u['password'] == password,
      );
      return true; // Cocok
    } catch (e) {
      return false; // Tidak ditemukan
    }
  }

  // 5. Simulasi Masuk dengan Google (Menyimpan jika belum ada)
  static Future<bool> googleSignIn({required String email, required String name}) async {
    List<Map<String, String>> users = await getUsers();
    bool exists = users.any((u) => u['email'] == email);
    
    if (!exists) {
      users.add({
        'name': name,
        'username': email.split('@').first,
        'phone': '081299998888',
        'email': email,
        'password': 'google_signed_in',
      });
      await saveUsers(users);
    }
    return true;
  }

  // 6. Simulasi Cari Password untuk Lupa Kata Sandi
  static Future<String?> resetPassword(String identifier) async {
    List<Map<String, String>> users = await getUsers();
    try {
      final user = users.firstWhere(
        (u) => u['phone'] == identifier || u['email'] == identifier || u['username'] == identifier,
      );
      _currentResetIdentifier = identifier; // Catat siapa yang sedang melakukan pemulihan sandi
      return user['password']; // Mengembalikan password asli
    } catch (e) {
      return null; // Tidak ditemukan
    }
  }

  // 7. Fungsi untuk Memperbarui Sandi Baru ke SharedPreferences
  static Future<bool> updatePassword(String newPassword) async {
    if (_currentResetIdentifier == null) return false;

    List<Map<String, String>> users = await getUsers();
    bool updated = false;

    for (var user in users) {
      if (user['phone'] == _currentResetIdentifier || 
          user['email'] == _currentResetIdentifier || 
          user['username'] == _currentResetIdentifier) {
        user['password'] = newPassword; // Timpa dengan password baru
        updated = true;
        break;
      }
    }

    if (updated) {
      await saveUsers(users); // Simpan perubahan ke SharedPreferences secara permanen
      _currentResetIdentifier = null; // Reset kembali variabel pelacak
      return true;
    }
    return false;
  }

  // 8. Getter untuk melihat seluruh akun terdaftar (Debug)
  static Future<List<Map<String, String>>> get allUsers async {
    return await getUsers();
  }
}