import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/app_storage.dart';

class AuthApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Fungsi Login
  Future> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login', // Sesuaikan endpoint backend (misal /auth/login atau /auth/partner/login)
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Simpan token JWT ke local storage jika respons mengembalikan token
        final String? token = data['token'] ?? data['data']?['token'];
        if (token != null) {
          await AppStorage.saveToken(token);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal melakukan login',
      };
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan jaringan';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  /// Fungsi Register
  Future> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register', // Sesuaikan endpoint backend
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Registrasi berhasil',
          'data': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal melakukan registrasi',
      };
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan jaringan';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }
}