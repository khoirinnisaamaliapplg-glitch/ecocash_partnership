import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../core/widgets/app_loading.dart';

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

  // EcoCash Brand Colors
  static const Color _primaryYellow = Color(0xFFFFE600);
  static const Color _darkText = Color(0xFF1C1C1E);
  static const Color _ecoGreen = Color(0xFF00AA13);
  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkNavy = Color(0xFF0F2C59);
  static const Color _slate = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8F9FA);
  static const Color _secondaryText = Color(0xFF64748B);

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
        'Menghubungi warga tanpa jadwal',
      ],
      'correctIndex': 0,
    },
    {
      'question':
          'Berapa batas kapasitas standar muatan armada kendaraan roda tiga?',
      'options': ['100 kg', '350 kg', '1000 kg', '50 kg'],
      'correctIndex': 1,
    },
    {
      'question':
          'Apa yang harus dilakukan jika mesin Smart Container mengalami kendala sensor?',
      'options': [
        'Memaksa pintu kontainer',
        'Melaporkan via fitur Laporkan Masalah di aplikasi',
        'Meninggalkan muatan di luar mesin',
        'Membatalkan seluruh akun mitra',
      ],
      'correctIndex': 1,
    },
  ];

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AppLoading(message: 'Mengirim hasil kuis kamu...', size: 64),
        ),
      ),
    );

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

    Navigator.of(context, rootNavigator: true).pop();

    setState(() => _isSubmitting = false);

    _showResultDialog(score: score, isPassed: isPassed);
  }

  // RESULT DIALOG
  void _showResultDialog({required double score, required bool isPassed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFFE8F7EB)
                        : const Color(0xFFFFF5D6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPassed
                        ? Icons.emoji_events_rounded
                        : Icons.menu_book_rounded,
                    color: isPassed ? _ecoGreen : _darkNavy,
                    size: 39,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  isPassed ? 'Selamat! Anda Lulus' : 'Kuis Belum Lulus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPassed ? _ecoGreen : _darkNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Hasil evaluasi pelatihan Anda',
                  style: TextStyle(color: _secondaryText, fontSize: 11),
                ),

                const SizedBox(height: 19),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${score.round()}',
                        style: TextStyle(
                          color: isPassed ? _ecoGreen : _darkNavy,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'NILAI ANDA',
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  isPassed
                      ? 'Anda berhasil menyelesaikan evaluasi pelatihan dan berhak mendapatkan sertifikat.'
                      : 'Batas nilai kelulusan adalah 70. Silakan pelajari kembali materi video dan coba kuis lagi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPassed ? _ecoGreen : _darkNavy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentQuestionIndex];

    final double progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QUIZ HEADER
              _buildQuizHeader(),

              const SizedBox(height: 22),

              // QUESTION CARD
              _buildQuestionCard(
                question: currentQ['question'].toString(),
                progress: progress,
              ),

              const SizedBox(height: 20),

              // ANSWER LABEL
              const Text(
                'Pilih Jawaban Anda',
                style: TextStyle(
                  color: _darkNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              // ANSWER OPTIONS
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: (currentQ['options'] as List).length,
                  itemBuilder: (context, index) {
                    final optionText = currentQ['options'][index].toString();

                    final bool isSelected =
                        _selectedAnswers[_currentQuestionIndex] == index;

                    return _buildAnswerOption(
                      index: index,
                      text: optionText,
                      isSelected: isSelected,
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // QUESTION NAVIGATION
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _darkNavy,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 19,
        ),
      ),
      title: const Text(
        'Evaluasi Pelatihan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.assignment_rounded, color: _primaryYellow, size: 15),
              SizedBox(width: 5),
              Text(
                'KUIS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // QUIZ HEADER
  Widget _buildQuizHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9CC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.school_rounded, color: _darkNavy, size: 24),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kuis Pelatihan',
                  style: TextStyle(
                    color: _darkNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.courseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, fontSize: 10),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_questions.length} Soal',
              style: const TextStyle(
                color: _darkNavy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // QUESTION CARD
  Widget _buildQuestionCard({
    required String question,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: _darkNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkNavy.withValues(alpha: 0.12),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SOAL ${_currentQuestionIndex + 1}',
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _primaryYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation(_ecoGreen),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Pertanyaan',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Pilih satu jawaban yang paling tepat.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ANSWER OPTION
  Widget _buildAnswerOption({
    required int index,
    required String text,
    required bool isSelected,
  }) {
    final String letter = String.fromCharCode(65 + index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFCE5) : _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? _darkNavy : const Color(0xFFE3E9EF),
          width: isSelected ? 1.7 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            setState(() {
              _selectedAnswers[_currentQuestionIndex] = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryYellow
                        : const Color(0xFFEAF0F8),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        color: _darkNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: _darkText,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected ? _ecoGreen : const Color(0xFFCBD5E1),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NAVIGATION BUTTONS
  Widget _buildNavigationButtons() {
    final bool isFirstQuestion = _currentQuestionIndex == 0;
    final bool isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    final bool hasSelectedAnswer =
        _selectedAnswers[_currentQuestionIndex] != null;

    return Row(
      children: [
        if (!isFirstQuestion) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkNavy,
                side: const BorderSide(color: _darkNavy, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Sebelumnya',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 11),
        ],

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: !hasSelectedAnswer || _isSubmitting
                ? null
                : () {
                    if (!isLastQuestion) {
                      setState(() {
                        _currentQuestionIndex++;
                      });
                    } else {
                      _submitQuiz();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkNavy,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastQuestion ? 'Kirim Jawaban' : 'Selanjutnya',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        isLastQuestion
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded,
                        color: _primaryYellow,
                        size: 17,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
