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
          debugPrint('>>> [API REQUEST] ${options.method} ${options.baseUrl}${options.path}');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('<<< [API RESPONSE SUCCESS] Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('<<< [API RESPONSE ERROR] Status: ${e.response?.statusCode}');
          debugPrint('<<< [API ERROR DETAIL] ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  // ==========================================
  // 1. AUTH, PROFIL & DASHBOARD
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
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }

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
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }

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

  Future<Map<String, dynamic>> resetPinOtp({
    required String phoneNumber,
    required String code,
    required String newPin,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/reset-pin/otp',
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
          'newPin': newPin,
        },
      );
      return {
        'success': true,
        'message': response.data['message'] ?? 'PIN transaksi berhasil direset',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mereset PIN: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/partners/me/password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      return {
        'success': true,
        'message': response.data['message'] ?? 'Kata sandi berhasil diperbarui',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui kata sandi: $e'};
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

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get('/partners/dashboard');
      return {
        'success': true,
        'data': response.data['data'] ?? response.data,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final resFallback = await _dio.get('/partners/me/dashboard');
          return {
            'success': true,
            'data': resFallback.data['data'] ?? resFallback.data,
          };
        } catch (_) {}
      }
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil ringkasan dashboard: $e'};
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
  // 3. BANK & PIN
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
    String? pin,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/me/bank-accounts',
        data: {
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolder': accountHolderName,
          'accountHolderName': accountHolderName,
          if (pin != null && pin.isNotEmpty) 'pin': pin,
        },
      );
      return {'success': true, 'message': response.data['message'] ?? 'Rekening ditambahkan', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menambahkan rekening: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteBankAccount(String bankAccountId) async {
    try {
      final response = await _dio.delete('/partners/me/bank-accounts/$bankAccountId');
      return {
        'success': true,
        'message': response.data['message'] ?? 'Rekening berhasil dihapus',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus rekening: $e'};
    }
  }

  Future<Map<String, dynamic>> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    try {
      final response = await _dio.patch(
        '/partners/me/pin',
        data: {
          'oldPin': oldPin,
          'newPin': newPin,
        },
      );
      return {
        'success': true,
        'message': response.data['message'] ?? 'PIN transaksi berhasil diperbarui',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui PIN: $e'};
    }
  }

  // ==========================================
  // 4. PENARIKAN DANA (WITHDRAWAL)
  // ==========================================

  Future<Map<String, dynamic>> requestWithdrawal({
    required num amount,
    required dynamic bankAccountId,
    String? pin,
  }) async {
    try {
      final response = await _dio.post(
        '/partners/me/withdrawals',
        data: {
          'amount': amount,
          'bankAccountId': bankAccountId.toString(),
          if (pin != null && pin.isNotEmpty) 'pin': pin,
        },
      );
      return {
        'success': true,
        'message': response.data['message'] ?? 'Pengajuan penarikan dikirim',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengajukan penarikan: $e'};
    }
  }

  // ==========================================
  // 5. KENDARAAN (VEHICLE)
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
  // 6. JOBS & MANAJEMEN JARAK SPASIAL POSTGIS
  // ==========================================

  /// Mengambil daftar tugas penjemputan dengan filter radius spasial PostGIS kurir
  Future<Map<String, dynamic>> getAvailableJobs({double? lat, double? lng}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
        queryParams['latitude'] = lat;
        queryParams['longitude'] = lng;
      }

      final response = await _dio.get(
        '/jobs/available',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
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
    List<dynamic>? materials,
    String? notes,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Map<String, dynamic> body = data ?? {
        'materials': materials ?? [
          {'materialId': 1, 'pickupWeight': 20.0}
        ],
        if (notes != null) 'notes': notes,
      };

      final response = await _dio.post(
        '/jobs/$jobId/pickup',
        data: body,
      );
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

  Future<Map<String, dynamic>> getMyJobs({String? status}) async {
    try {
      final response = await _dio.get(
        '/jobs/my-jobs',
        queryParameters: status != null ? {'status': status} : null,
      );
      return {'success': true, 'data': response.data['data'] ?? []};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil pekerjaan saya: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyHandover(
    dynamic jobId, {
    required String qrCode,
    List<Map<String, dynamic>>? materials,
    String? proofImageUrl,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/jobs/$jobId/handover/verify',
        data: {
          'qrCode': qrCode,
          if (materials != null) 'materials': materials,
          if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
          if (notes != null) 'notes': notes,
        },
      );
      return {'success': true, 'message': response.data['message'] ?? 'Handover selesai', 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal verifikasi serah terima: $e'};
    }
  }

  Future<Map<String, dynamic>> completeToMachine(
    dynamic jobId, {
    String? machineCode,
    double? totalWeightKg,
  }) async {
    try {
      final response = await _dio.post(
        '/jobs/$jobId/complete-to-machine',
        data: {
          'machineCode': machineCode ?? 'RVM-001',
          'totalWeightKg': totalWeightKg ?? 15.0,
        },
      );
      return {
        'success': true,
        'message': response.data['message'] ?? 'Berhasil setor ke kontainer',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyelesaikan tugas ke kontainer: $e'};
    }
  }

  // ==========================================
  // 7. WALLET, TOP UP & TRANSAKSI
  // ==========================================

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await _dio.get('/wallets/me');
      return {
        'success': true,
        'data': response.data['data'] ?? response.data,
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil data wallet: $e'};
    }
  }

  Future<Map<String, dynamic>> getWalletTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final response = await _dio.get(
        '/wallets/transactions',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null && type.isNotEmpty && type != 'Semua') 'type': type,
        },
      );
      return {
        'success': true,
        'data': response.data['data'] ?? response.data,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return getWallet();
      }
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil riwayat transaksi: $e'};
    }
  }

  Future<Map<String, dynamic>> createTopUp({required int amount}) async {
    try {
      final response = await _dio.post(
        '/wallets/topup',
        data: {'amount': amount},
      );
      return {
        'success': true,
        'message': response.data['message'] ?? 'Permintaan top up berhasil dibuat',
        'data': response.data['data'] ?? response.data,
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat permintaan top up: $e'};
    }
  }

  Future<Map<String, dynamic>> checkTopUpStatus(dynamic topUpId) async {
    try {
      final response = await _dio.post('/wallets/topup/$topUpId/check-status');
      return {
        'success': true,
        'data': response.data['data'] ?? response.data,
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memeriksa status pembayaran top up: $e'};
    }
  }

  Future<Map<String, dynamic>> mockPayTopUp(dynamic topUpId) async {
    try {
      final response = await _dio.post('/wallets/topup/$topUpId/mock-pay');
      return {
        'success': true,
        'message': response.data['message'] ?? 'Mock payment berhasil',
        'data': response.data['data'] ?? response.data,
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memproses simulasi pembayaran: $e'};
    }
  }

  // ==========================================
  // 8. UPLOAD FILE
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

  // ==========================================
  // 9. ECOCASH ACADEMY
  // ==========================================

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
  // 10. STATISTIK MATERIAL & DAMPAK
  // ==========================================

  Future<Map<String, dynamic>> getMaterialStatistics() async {
    try {
      final response = await _dio.get('/material-statistics/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal memuat statistik',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyImpact() async {
    try {
      final response = await _dio.get('/partners/me/impact');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'] ?? response.data,
        };
      }
      return {'success': false, 'message': 'Gagal memuat data dampak'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  // ==========================================
  // 11. TIKET PENGADUAN & CHAT (KURIR <-> WARGA & CS)
  // ==========================================

  Future<Map<String, dynamic>> createTicket({
    required String category,
    required String subject,
    required String description,
    XFile? attachmentFile,
    String priority = 'MEDIUM',
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'category': category,
        'subject': subject,
        'description': description,
        'priority': priority,
      };

      if (attachmentFile != null) {
        if (kIsWeb) {
          final bytes = await attachmentFile.readAsBytes();
          formMap['attachment'] = MultipartFile.fromBytes(bytes, filename: attachmentFile.name);
        } else {
          formMap['attachment'] = await MultipartFile.fromFile(attachmentFile.path, filename: attachmentFile.name);
        }
      }

      final formData = FormData.fromMap(formMap);
      final response = await _dio.post('/tickets', data: formData);

      return {
        'success': true,
        'message': response.data['message'] ?? 'Tiket berhasil dibuat',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim laporan: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyTickets() async {
    try {
      final response = await _dio.get('/tickets/me');
      return {
        'success': true,
        'data': response.data['data'] ?? [],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil riwayat laporan: $e'};
    }
  }

  /// Room Chat Tugas Penjemputan (Kurir <-> Warga Nasabah)
  Future<Map<String, dynamic>> getJobRoom(dynamic jobId) async {
    try {
      final response = await _dio.get('/chat/job/$jobId');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil chat room penjemputan: $e'};
    }
  }

  /// Room Chat Helpdesk / Bantuan (Kurir <-> Admin CS)
  Future<Map<String, dynamic>> getChatRoom(dynamic partnerId) async {
    try {
      final response = await _dio.get('/chat/room/$partnerId');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil chat room helpdesk: $e'};
    }
  }

  /// Mengambil Riwayat Chat berdasarkan ID Room
  Future<Map<String, dynamic>> getChatHistory(String roomId) async {
    try {
      final response = await _dio.get('/chat/history/$roomId');
      return {'success': true, 'data': response.data['data'] ?? []};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil riwayat chat: $e'};
    }
  }

  /// Mengirim Pesan Chat (Didukung role PARTNER, USER, atau ADMIN)
  Future<Map<String, dynamic>> sendChatMessage({
    required String roomId,
    required int senderId,
    required String message,
    String senderType = 'PARTNER',
    String? attachmentUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/message',
        data: {
          'roomId': roomId,
          'senderId': senderId,
          'message': message,
          'senderType': senderType,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        },
      );
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim pesan chat: $e'};
    }
  }

  // ==========================================
  // 12. PROFIL PARTNER (GET & UPDATE)
  // ==========================================

  Future<Map<String, dynamic>> getPartnerProfile() async {
    try {
      final response = await _dio.get('/partners/me');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'] ?? response.data,
        };
      }
      return {'success': false, 'message': 'Gagal mengambil profil partner'};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePartnerProfile({
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> payload = {};
      if (name != null && name.isNotEmpty) payload['name'] = name;
      if (phoneNumber != null && phoneNumber.isNotEmpty) payload['phoneNumber'] = phoneNumber;
      if (email != null && email.isNotEmpty) payload['email'] = email;
      if (address != null && address.isNotEmpty) payload['address'] = address;
      if (avatarUrl != null && avatarUrl.isNotEmpty) payload['avatarUrl'] = avatarUrl;

      final response = await _dio.patch('/partners/me', data: payload);
      return {
        'success': true,
        'message': response.data['message'] ?? 'Profil berhasil diperbarui',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui profil: $e'};
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['errors'] != null) return data['errors'].toString();
        if (data['message'] != null) return data['message'].toString();
      }
    }
    return 'Terjadi kesalahan jaringan/server (${e.response?.statusCode ?? 'No Connection'})';
  }
}