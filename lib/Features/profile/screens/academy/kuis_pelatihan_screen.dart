import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';

class KuisPelatihanScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const KuisPelatihanScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<KuisPelatihanScreen> createState() => _KuisPelatihanScreenState();
}

class _KuisPelatihanScreenState extends State<KuisPelatihanScreen> {
  final PartnerApiService _apiService = PartnerApiService();

  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Apa langkah pertama sebelum memulai pengangkutan material?',
      'options': [
        'Memastikan penggunaan APD lengkap',
        'Langsung membawa muatan ke pabrik',
        'Mengabaikan cek fisik kendaraan',
        'Menghubungi warga tanpa jadwal'
      ],
      'correctIndex': 0,
    },
    {
      'question': 'Berapa batas kapasitas standar muatan armada kendaraan roda tiga?',
      'options': ['100 kg', '350 kg', '1000 kg', '50 kg'],
      'correctIndex': 1,
    },
    {
      'question': 'Apa yang harus dilakukan jika mesin Smart Container mengalami kendala sensor?',
      'options': [
        'Memaksa pintu kontainer',
        'Melaporkan via fitur Laporkan Masalah di aplikasi',
        'Meninggalkan muatan di luar mesin',
        'Membatalkan seluruh akun mitra'
      ],
      'correctIndex': 1,
    },
  ];

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);

    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctIndex']) {
        correctCount++;
      }
    }

    final double score = (correctCount / _questions.length) * 100;
    final bool isPassed = score >= 70;

    if (isPassed) {
      await _apiService.completeAcademyModule(widget.courseId, '1');
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isPassed ? 'Selamat! Anda Lulus 🎉' : 'Kuis Belum Lulus 😞',
          style: TextStyle(color: isPassed ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nilai Anda: ${score.round()}/100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              isPassed
                  ? 'Anda berhasil menyelesaikan evaluasi pelatihan dan berhak mendapatkan sertifikat.'
                  : 'Batas nilai kelulusan adalah 70. Silakan pelajari kembali materi video dan coba kuis lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPassed ? Colors.green : AppColors.primaryCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryCyan,
        elevation: 0,
        title: Text('Kuis: ${widget.courseTitle}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROGRESS KUIS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Soal ${_currentQuestionIndex + 1} dari ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${((_currentQuestionIndex + 1) / _questions.length * 100).round()}%', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryCyan),
            ),
            const SizedBox(height: 24),

            // SOAL KUIS
            Text(currentQ['question'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
            const SizedBox(height: 16),

            // PILIHAN JAWABAN
            Expanded(
              child: ListView.builder(
                itemCount: (currentQ['options'] as List).length,
                itemBuilder: (context, idx) {
                  final optionText = currentQ['options'][idx];
                  final isSelected = _selectedAnswers[_currentQuestionIndex] == idx;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryCyan.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primaryCyan : Colors.grey.shade300, width: 1.5),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedAnswers[_currentQuestionIndex] = idx),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected ? AppColors.primaryCyan : Colors.grey.shade200,
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(optionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),

            // TOMBOL NAVIGASI SOAL
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentQuestionIndex--),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Sebelumnya'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAnswers[_currentQuestionIndex] == null
                        ? null
                        : () {
                            if (_currentQuestionIndex < _questions.length - 1) {
                              setState(() => _currentQuestionIndex++);
                            } else {
                              _submitQuiz();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentQuestionIndex == _questions.length - 1 ? 'Kirim Jawaban' : 'Selanjutnya', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}