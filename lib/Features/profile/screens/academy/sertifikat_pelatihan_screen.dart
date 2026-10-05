import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';

class SertifikatPelatihanScreen extends StatefulWidget {
  const SertifikatPelatihanScreen({super.key});

  @override
  State<SertifikatPelatihanScreen> createState() => _SertifikatPelatihanScreenState();
}

class _SertifikatPelatihanScreenState extends State<SertifikatPelatihanScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  static const Color _navyColor = Color(0xFF0F2C59);

  bool _isLoading = true;
  List<dynamic> _certificates = [];

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAcademyCertificates();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] is List) {
          _certificates = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('EcoCash Academy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PENCAPAIAN ANDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  const Text('Sertifikat Pelatihan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navyColor)),
                  const SizedBox(height: 6),
                  const Text('Sertifikat digital resmi atas keberhasilan menyelesaikan modul pelatihan Mitra EcoCash.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 20),

                  if (_certificates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Belum Ada Sertifikat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                          SizedBox(height: 4),
                          Text('Selesaikan 100% modul pada salah satu pelatihan untuk mendapatkan sertifikat digital.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ..._certificates.map((cert) => Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildCertificateCard(cert),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    final String certNumber = cert['certificateNumber'] ?? 'ECA-2026-UNKNOWN';
    final String courseTitle = cert['course']?['title'] ?? 'Program Pelatihan Mitra';
    final String issueDate = cert['createdAt'] != null ? cert['createdAt'].toString().split('T')[0] : '2026';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primaryCyan.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.eco, size: 20, color: _navyColor),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EcoCash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _navyColor, height: 1.0)),
                  Text('ACADEMY PARTNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Colors.green, letterSpacing: 1.2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Atas keberhasilannya menyelesaikan program pelatihan wajib:', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(courseTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navyColor, height: 1.3)),
          const SizedBox(height: 24),
          const Text('Tanggal Penerbitan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          Text(issueDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(6)),
            child: Text('ID Sertifikat: $certNumber', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}