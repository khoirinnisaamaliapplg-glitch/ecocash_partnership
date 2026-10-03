import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/app_storage.dart';

class PartnerApiService {
  late final Dio _dio;

  PartnerApiService() {
    _dio = Dio(
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

    // Interceptor untuk otomatis menyisipkan Token JWT dari AppStorage
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  /// 1. Login Khusus Partner (POST /partners/login)
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final String? token = responseData['data']?['token'];
        final dynamic userData = responseData['data']?['user'];

        if (token != null) {
          await AppStorage.saveToken(token);
        }
        if (userData != null) {
          await AppStorage.saveUserData(userData);
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login berhasil',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal melakukan login',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  /// 2. Register Partner Baru (POST /partners/register)
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    String? companyName,
    String type = 'WASTE_COLLECTOR',
  }) async {
    try {
      final response = await _dio.post(
        '/partners/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'companyName': companyName,
          'type': type,
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
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  /// 3. Minta Kode OTP via WhatsApp / Email (POST /partners/otp/send)
  Future<Map<String, dynamic>> sendOtp({
    String? phoneNumber,
    String? email,
    String channel = 'EMAIL', // Definisikan channel 'EMAIL' atau 'WHATSAPP'
    String purpose = 'REGISTRATION',
  }) async {
    try {
      final Map<String, dynamic> body = {
        'channel': channel,
        'purpose': purpose,
      };

      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }

      final response = await _dio.post(
        '/partners/otp/send',
        data: body,
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Kode OTP berhasil dikirim',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim OTP: $e'};
    }
  }

  /// Verifikasi Kode OTP (Mendukung WHATSAPP dan EMAIL)
  Future<Map<String, dynamic>> verifyOtp({
    String? phoneNumber,
    String? email,
    required String code,
    String purpose = 'REGISTRATION',
  }) async {
    try {
      final Map<String, dynamic> body = {
        'code': code,
        'purpose': purpose,
      };

      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }

      final response = await _dio.post(
        '/partners/otp/verify',
        data: body,
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Verifikasi OTP berhasil',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal verifikasi OTP: $e'};
    }
  }

  /// 5. Reset Password Menggunakan OTP (POST /partners/reset-password/otp)
  Future<Map<String, dynamic>> resetPasswordOtp({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/reset-password/otp',
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
          'newPassword': newPassword,
        },
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Kata sandi berhasil diperbarui',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mereset kata sandi: $e'};
    }
  }

  /// 6. Ambil Profil Partner yang Sedang Login (GET /partners/me)
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/partners/me');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Gagal mengambil data profil partner'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  /// 7. Logout (POST /auth/logout)
  Future<Map<String, dynamic>> logout() async {
    try {
      await _dio.post('/auth/logout');
      // Hapus token penyimpanan (ganti clearAll jika tidak ada)
      await AppStorage.saveToken('');

      return {
        'success': true,
        'message': 'Logout berhasil',
      };
    } on DioException catch (e) {
      await AppStorage.saveToken('');
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal logout: $e'};
    }
  }

  /// Helper untuk merapikan pesan error dari Express Validator / AppError
  String _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data['errors'] != null) {
        return data['errors'].toString();
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return 'Terjadi kesalahan jaringan/server (${e.response?.statusCode ?? 'No Connection'})';
  }
}