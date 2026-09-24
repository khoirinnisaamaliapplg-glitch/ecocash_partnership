import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/app_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI INTEGRASI REGISTER PARTNER KE BACKEND DOCKER ---
  Future _prosesRegisterBackend() async {
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (name.isEmpty || username.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio(
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

      // Endpoint Khusus Register Partner: /partners/register
      final response = await dio.post(
        '/partners/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'phoneNumber': phone,
          'type': 'WASTE_COLLECTOR', // Default tipe mitra pengumpul sampah
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        final String? token = responseData['token'] ?? responseData['data']?['token'];
        final dynamic userData = responseData['data']?['user'] ?? responseData['user'];

        if (token != null) {
          await AppStorage.saveToken(token);
        }
        if (userData != null) {
          await AppStorage.saveUserData(userData);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Pendaftaran Partner berhasil dikirim.'),
            backgroundColor: Colors.green,
          ),
        );

        // Pindah ke halaman OTP / Verifikasi
        context.go('/otp', extra: {
          'name': name,
          'email': email,
          'phone': phone,
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Registrasi gagal!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Registrasi Partner gagal. Silakan periksa kembali data Anda.';
      
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response?.data;
        if (responseData['errors'] != null) {
          errorMessage = responseData['errors'].toString();
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isLoading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'EcoCash ',
                            style: TextStyle(color: AppColors.primary2),
                          ),
                          TextSpan(
                            text: 'Partner',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Daftar Mitra Partner',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Nama', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Nama Lengkap',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Username', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Nomor Ponsel', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 08123456789',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Contoh: mitra@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryButtonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _prosesRegisterBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Daftar Sebagai Partner',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '→',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Atau masuk dengan',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () {},
                          icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                          label: const Text('Google', style: TextStyle(color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () {},
                          icon: const Icon(Icons.apple, color: Colors.black, size: 24),
                          label: const Text('Apple', style: TextStyle(color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}