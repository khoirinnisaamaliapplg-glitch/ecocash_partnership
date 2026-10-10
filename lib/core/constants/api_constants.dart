import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Ubah ke true untuk server live, ubah ke false jika ingin kembali ke lokal
  static const bool isProduction = false; 
  static const String _port = '3000';

  static String get baseUrl {
    if (isProduction) {
      return 'https://api.ecocash.id/api/v1';
    }

    if (kIsWeb) {
      return 'http://localhost:$_port/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_port/api/v1';
    } else {
      return 'http://127.0.0.1:$_port/api/v1';
    }
  }
}