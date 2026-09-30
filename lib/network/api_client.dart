import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      // Pilih URL sesuai perangkat uji coba Anda:
      // - Android Emulator: 'http://10.0.2.2:3000/api/'
      // - Windows Desktop / Web: 'http://localhost:3000/api/'
      // - Perangkat HP Fisik: 'http://:3000/api/'
      baseUrl: 'http://10.0.2.2:3000/api/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Tempat menyisipkan Token JWT nanti jika sudah ada
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
}