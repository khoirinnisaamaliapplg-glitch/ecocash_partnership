import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppStorage.getToken();
          print('>>> [API REQUEST] ${options.method} ${options.baseUrl}${options.path}');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('<<< [API RESPONSE SUCCESS] Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('<<< [API RESPONSE ERROR] Status: ${e.response?.statusCode}');
          print('<<< [API ERROR DETAIL] ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  // ==========================================
  // 1. AUTH & PROFIL
  // ==========================================

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/login',
        data: {'identifier': identifier, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final String? token = responseData['data']?['token'] ?? responseData['token'];
        final dynamic userData = responseData['data']?['user'] ?? responseData['user'] ?? responseData['data'];

        if (token != null) await AppStorage.saveToken(token);
        if (userData != null) await AppStorage.saveUserData(userData);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login berhasil',
          'data': responseData['data'] ?? responseData,
        };
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal login'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

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
        return {'success': true, 'message': response.data['message'] ?? 'Registrasi berhasil', 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal registrasi'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> sendOtp({
    String? phoneNumber,
    String? email,
    String channel = 'EMAIL',
    String purpose = 'REGISTRATION',
  }) async {
    try {
      final Map<String, dynamic> body = {'channel': channel, 'purpose': purpose};
      if (email != null && email.isNotEmpty) body['email'] = email;
      else if (phoneNumber != null && phoneNumber.isNotEmpty) body['phoneNumber'] = phoneNumber;

      final response = await _dio.post('/partners/otp/send', data: body);
      return {'success': true, 'message': response.data['message'] ?? 'Kode OTP dikirim', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim OTP: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    String? phoneNumber,
    String? email,
    required String code,
    String purpose = 'REGISTRATION',
  }) async {
    try {
      final Map<String, dynamic> body = {'code': code, 'purpose': purpose};
      if (email != null && email.isNotEmpty) body['email'] = email;
      else if (phoneNumber != null && phoneNumber.isNotEmpty) body['phoneNumber'] = phoneNumber;

      final response = await _dio.post('/partners/otp/verify', data: body);
      return {'success': true, 'message': response.data['message'] ?? 'Verifikasi OTP berhasil', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal verifikasi OTP: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordOtp({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/reset-password/otp',
        data: {'phoneNumber': phoneNumber, 'code': code, 'newPassword': newPassword},
      );
      return {'success': true, 'message': response.data['message'] ?? 'Kata sandi diperbarui'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal reset kata sandi: $e'};
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/partners/me');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': 'Gagal mengambil profil'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? ktpImageUrl,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final userData = await AppStorage.getUserData();
      final String existingName = name ??
          userData?['name'] ??
          userData?['user']?['name'] ??
          userData?['username'] ??
          'Mitra EcoCash';

      final Map<String, dynamic> payload = {'name': existingName};
      if (ktpImageUrl != null) {
        payload['ktpImageUrl'] = ktpImageUrl;
        payload['ktpUrl'] = ktpImageUrl;
      }
      if (phoneNumber != null) payload['phoneNumber'] = phoneNumber;

      final response = await _dio.patch('/users/me', data: payload);
      return {'success': true, 'message': response.data['message'] ?? 'Profil diperbarui', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui profil: $e'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await _dio.post('/auth/logout');
      await AppStorage.saveToken('');
      return {'success': true, 'message': 'Logout berhasil'};
    } on DioException catch (e) {
      await AppStorage.saveToken('');
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal logout: $e'};
    }
  }

  // ==========================================
  // 2. DOKUMEN & KYC
  // ==========================================

  Future<Map<String, dynamic>> uploadPartnerDocument({
    required String documentType,
    required String fileUrl,
    String? documentNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/me/documents',
        data: {
          'documentType': documentType,
          if (documentNumber != null && documentNumber.isNotEmpty) 'documentNumber': documentNumber,
          'fileUrl': fileUrl,
        },
      );
      return {'success': true, 'message': response.data['message'] ?? 'Dokumen diunggah', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengunggah dokumen: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyDocuments() async {
    try {
      final response = await _dio.get('/partners/me/documents');
      return {'success': true, 'data': response.data['data'] ?? []};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil dokumen: $e'};
    }
  }

  // ==========================================
  // 3. BANK & WITHDRAWAL
  // ==========================================

  Future<Map<String, dynamic>> getBankAccounts() async {
    try {
      final response = await _dio.get('/partners/me/bank-accounts');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil data rekening: $e'};
    }
  }

  Future<Map<String, dynamic>> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/me/bank-accounts',
        data: {
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolder': accountHolderName,
          'accountHolderName': accountHolderName,
        },
      );
      return {'success': true, 'message': response.data['message'] ?? 'Rekening ditambahkan', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menambahkan rekening: $e'};
    }
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/me/withdrawals',
        data: {'amount': amount, 'bankAccountId': bankAccountId},
      );
      return {'success': true, 'message': response.data['message'] ?? 'Pengajuan penarikan dikirim', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengajukan penarikan: $e'};
    }
  }

  // ==========================================
  // 4. KENDARAAN (VEHICLE)
  // ==========================================

  Future<Map<String, dynamic>> getMyVehicle() async {
    try {
      final response = await _dio.get('/partners/me/vehicle');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data'] ?? response.data};
      }
      return {'success': false, 'message': 'Gagal mengambil data kendaraan'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': true, 'data': null};
      }
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> registerOrUpdateVehicle({
    required String type,
    String? plateNumber,
    String? stnkPhotoUrl,
    String? vehiclePhotoUrl,
  }) async {
    try {
      final response = await _dio.put(
        '/partners/me/vehicle',
        data: {
          'type': type,
          'plateNumber': type != 'CART' ? plateNumber?.trim().toUpperCase() : null,
          'stnkPhotoUrl': type != 'CART' ? stnkPhotoUrl : null,
          'vehiclePhotoUrl': vehiclePhotoUrl,
        },
      );
      return {'success': true, 'message': response.data['message'] ?? 'Data kendaraan disimpan', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui data kendaraan: $e'};
    }
  }

  Future<Map<String, dynamic>> updateVehicle({
    required String type,
    String? plateNumber,
    String? imageUrl,
  }) async {
    return registerOrUpdateVehicle(
      type: type,
      plateNumber: plateNumber,
      stnkPhotoUrl: imageUrl,
      vehiclePhotoUrl: imageUrl,
    );
  }

  // ==========================================
  // 5. JOBS OPERASIONAL
  // ==========================================

  Future<Map<String, dynamic>> getAvailableJobs() async {
    try {
      final response = await _dio.get('/jobs/available');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil daftar pekerjaan: $e'};
    }
  }

  Future<Map<String, dynamic>> getJobDetail(dynamic jobId) async {
    try {
      final response = await _dio.get('/jobs/$jobId');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil detail pekerjaan: $e'};
    }
  }

  Future<Map<String, dynamic>> acceptJob(dynamic jobId) async {
    try {
      final response = await _dio.post('/jobs/$jobId/accept');
      return {'success': true, 'message': response.data['message'] ?? 'Pekerjaan diambil', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil pekerjaan: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelJob(dynamic jobId, {String? reason}) async {
    try {
      final response = await _dio.post('/jobs/$jobId/cancel', data: reason != null ? {'reason': reason} : {});
      return {'success': true, 'message': response.data['message'] ?? 'Pekerjaan dibatalkan'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membatalkan pekerjaan: $e'};
    }
  }

  Future<Map<String, dynamic>> startRoute(dynamic jobId) async {
    try {
      final response = await _dio.patch('/jobs/$jobId/start-route');
      return {'success': true, 'message': response.data['message'] ?? 'Perjalanan dimulai', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memulai rute: $e'};
    }
  }

  Future<Map<String, dynamic>> checkIn(
    dynamic jobId, {
    String? qrCode,
    String? manualCode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/jobs/$jobId/checkin',
        data: {
          if (qrCode != null) 'qrCode': qrCode,
          if (manualCode != null) 'manualCode': manualCode,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      return {'success': true, 'message': response.data['message'] ?? 'Check-in berhasil', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal check-in: $e'};
    }
  }

  Future<Map<String, dynamic>> submitPickup(
    dynamic jobId, {
    required List<Map<String, dynamic>> materials,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/jobs/$jobId/pickup', data: {'materials': materials, if (notes != null) 'notes': notes});
      return {'success': true, 'message': response.data['message'] ?? 'Timbangan disimpan', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyimpan data timbangan: $e'};
    }
  }

  Future<Map<String, dynamic>> generateHandoverQr(dynamic jobId) async {
    try {
      final response = await _dio.post('/jobs/$jobId/handover/generate-qr');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat QR Handover: $e'};
    }
  }

  // ==========================================
  // 6. UPLOAD FILE
  // ==========================================

  Future<Map<String, dynamic>> uploadSingleFile(
    String filePath, {
    XFile? xFile,
    String category = 'document',
  }) async {
    try {
      final MultipartFile multipartFile;
      if (kIsWeb && xFile != null) {
        final bytes = await xFile.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: xFile.name);
      } else {
        final fileName = filePath.split('/').last;
        multipartFile = await MultipartFile.fromFile(filePath, filename: fileName);
      }

      final formData = FormData.fromMap({'category': category, 'file': multipartFile});
      final response = await _dio.post('/upload/single', data: formData);
      final responseData = response.data;
      final String? fileUrl = responseData['data']?['url'] ?? responseData['url'];

      return {'success': true, 'url': fileUrl, 'data': responseData};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengunggah berkas: $e'};
    }
  }

  // --- ECOCASH ACADEMY API ---
  Future<Map<String, dynamic>> getAcademyCourses() async {
    try {
      final response = await _dio.get('/academy/courses');
      return {'success': true, 'data': response.data['data'] ?? []};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String, dynamic>> getAcademyCourseById(String courseId) async {
    try {
      final response = await _dio.get('/academy/courses/$courseId');
      return {'success': true, 'data': response.data['data']};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String, dynamic>> completeAcademyModule(String courseId, String moduleId) async {
    try {
      final response = await _dio.post('/academy/courses/$courseId/modules/$moduleId/complete');
      return {'success': true, 'message': response.data['message'], 'data': response.data['data']};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String, dynamic>> getAcademyCertificates() async {
    try {
      final response = await _dio.get('/academy/certificates');
      return {'success': true, 'data': response.data['data'] ?? []};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // ==========================================
  // HELPER
  // ==========================================

  String _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data['errors'] != null) return data['errors'].toString();
      if (data['message'] != null) return data['message'].toString();
    }
    return 'Terjadi kesalahan jaringan/server (${e.response?.statusCode ?? 'No Connection'})';
  }
}