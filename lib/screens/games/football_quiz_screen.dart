import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/gemini_service_extended.dart';
import '../../services/settings_service.dart';

// صفحة اختيار نوع السؤال
class FootballQuizScreen extends StatelessWidget {
  const FootballQuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: AppThemes.backgroundGradient(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppStrings.t(context, 'football_quiz'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.quiz, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.t(context, 'choose_quiz_type'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // أزرار اختيار النوع
                Expanded(
                  child: ListView(
                    children: [
                      _buildTypeCard(
                        context,
                        icon: Icons.person,
                        title: AppStrings.t(context, 'player'),
                        subtitle: AppStrings.t(context, 'guess_player_name'),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DifficultySelectionScreen(type: 'player'),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTypeCard(
                        context,
                        icon: Icons.sports,
                        title: AppStrings.t(context, 'coach'),
                        subtitle: AppStrings.t(context, 'guess_coach_name'),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DifficultySelectionScreen(type: 'coach'),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTypeCard(
                        context,
                        icon: Icons.shield,
                        title: AppStrings.t(context, 'club'),
                        subtitle: AppStrings.t(context, 'guess_club_name'),
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DifficultySelectionScreen(type: 'club'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// صفحة اختيار مستوى الصعوبة
class DifficultySelectionScreen extends StatelessWidget {
  final String type;

  const DifficultySelectionScreen({Key? key, required this.type})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: AppThemes.backgroundGradient(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppStrings.t(context, 'level'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_score,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.t(context, 'select_difficulty'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // أزرار المستويات
                Expanded(
                  child: ListView(
                    children: [
                      _buildDifficultyCard(
                        context,
                        difficulty: 'easy',
                        icon: Icons.sentiment_satisfied,
                        title: AppStrings.t(context, 'easy'),
                        subtitle: AppStrings.t(context, 'very_famous'),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildDifficultyCard(
                        context,
                        difficulty: 'medium',
                        icon: Icons.sentiment_neutral,
                        title: AppStrings.t(context, 'medium'),
                        subtitle: AppStrings.t(context, 'well_known'),
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildDifficultyCard(
                        context,
                        difficulty: 'hard',
                        icon: Icons.sentiment_very_dissatisfied,
                        title: AppStrings.t(context, 'hard'),
                        subtitle: AppStrings.t(context, 'very_difficult'),
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context, {
    required String difficulty,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizGameScreen(type: type, difficulty: difficulty),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة اللعبة
class QuizGameScreen extends StatefulWidget {
  final String type;
  final String difficulty;

  const QuizGameScreen({Key? key, required this.type, required this.difficulty})
    : super(key: key);

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  final SettingsService _settings = SettingsService();

  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  String userAnswer = '';
  List<String> availableLetters = [];
  List<bool> letterUsed = []; // لتتبع الحروف المستخدمة
  bool isLoading = true;
  bool isAnswered = false;

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _timeIsUp = false;

  // للأنيميشن
  bool _showResultAnimation = false;
  bool _isCorrectAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => isLoading = true);

    final language = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

    try {
      final loadedQuestions = await _gemini.generateHintQuestions(
        count: 10,
        type: widget.type,
        difficulty: widget.difficulty,
        language: language,
      );

      if (loadedQuestions.isNotEmpty) {
        setState(() {
          questions = loadedQuestions;
          isLoading = false;
          _loadCurrentQuestion();
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _loadCurrentQuestion() {
    if (currentQuestionIndex >= questions.length) return;

    final currentAnswer = questions[currentQuestionIndex]['answer'] as String;
    _generateAvailableLetters(currentAnswer);
    _startTimer();

    setState(() {
      userAnswer = '';
      isAnswered = false;
      _timeIsUp = false;
    });
  }

  void _generateAvailableLetters(String answer) {
    final answerWithoutSpaces = answer.replaceAll(' ', '');

    // حساب عدد تكرار كل حرف في الإجابة
    final Map<String, int> letterCount = {};
    for (var char in answerWithoutSpaces.split('')) {
      letterCount[char] = (letterCount[char] ?? 0) + 1;
    }

    // إضافة الحروف بعدد تكرارها
    final List<String> answerLetters = [];
    letterCount.forEach((letter, count) {
      for (int i = 0; i < count; i++) {
        answerLetters.add(letter);
      }
    });

    // اختيار الأحرف حسب اللغة
    final String allLettersString;
    final language = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

    if (language == 'ar') {
      // الأحرف العربية
      allLettersString = 'ابتثجحخدذرزسشصضطظعغفقكلمنهويءآأإؤئةى';
    } else if (language == 'tr') {
      // الأحرف التركية
      allLettersString = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';
    } else {
      // الأحرف الإنجليزية
      allLettersString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    }

    final allLetters = allLettersString.split('');
    final random = Random();

    // إضافة حروف عشوائية للوصول إلى 18 حرف
    final additionalLetters = <String>[];
    final usedInAnswer = letterCount.keys.toSet();

    while (answerLetters.length + additionalLetters.length < 18) {
      final randomLetter = allLetters[random.nextInt(allLetters.length)];
      if (!usedInAnswer.contains(randomLetter)) {
        additionalLetters.add(randomLetter);
      }
    }

    availableLetters = [...answerLetters, ...additionalLetters];
    availableLetters.shuffle();

    // تهيئة قائمة الحروف المستخدمة
    letterUsed = List.filled(availableLetters.length, false);
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 60;
    _timeIsUp = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timeIsUp = true;
          timer.cancel();
          _handleTimeUp();
        }
      });
    });
  }

  void _handleTimeUp() {
    if (isAnswered) return;

    setState(() {
      isAnswered = true;
      _timeIsUp = true;
      _showResultAnimation = true;
      _isCorrectAnswer = false; // خطأ لأن الوقت انتهى
    });

    // إخفاء الأنيميشن والانتقال للسؤال التالي
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showResultAnimation = false;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _moveToNextQuestion();
      });
    });
  }

  void _addLetter(String letter, int letterIndex) {
    if (isAnswered || _timeIsUp || letterUsed[letterIndex]) return;

    final currentAnswer = questions[currentQuestionIndex]['answer'] as String;
    final answerWithoutSpaces = currentAnswer.replaceAll(' ', '');

    if (userAnswer.length < answerWithoutSpaces.length) {
      setState(() {
        userAnswer += letter;
        letterUsed[letterIndex] = true; // تحديد الحرف كمستخدم
      });

      if (userAnswer.length == answerWithoutSpaces.length) {
        _checkAnswer();
      }
    }
  }

  void _removeLetterAtIndex(int answerIndex) {
    if (isAnswered || _timeIsUp || answerIndex >= userAnswer.length) return;

    // الحصول على الحرف في هذا الموقع
    final letterToRemove = userAnswer[answerIndex];

    // إزالة الحرف من الإجابة
    String newAnswer = '';
    for (int i = 0; i < userAnswer.length; i++) {
      if (i != answerIndex) {
        newAnswer += userAnswer[i];
      }
    }

    // البحث عن الحرف في لوحة المفاتيح وإعادته
    for (int i = availableLetters.length - 1; i >= 0; i--) {
      if (availableLetters[i] == letterToRemove && letterUsed[i]) {
        setState(() {
          userAnswer = newAnswer;
          letterUsed[i] = false;
        });
        break;
      }
    }
  }

  void _checkAnswer() {
    if (isAnswered) return;

    _timer?.cancel();

    final currentAnswer = questions[currentQuestionIndex]['answer'] as String;
    final isCorrect =
        userAnswer.replaceAll(' ', '') == currentAnswer.replaceAll(' ', '');

    setState(() {
      isAnswered = true;
      if (isCorrect) score++;
      _showResultAnimation = true;
      _isCorrectAnswer = isCorrect;
    });

    // إخفاء الأنيميشن والانتقال للسؤال التالي
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showResultAnimation = false;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _moveToNextQuestion();
      });
    });
  }

  void _moveToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _loadCurrentQuestion();
      });
    } else {
      _showGameOver();
    }
  }

  void _showGameOver() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                score >= 7 ? Icons.emoji_events : Icons.sentiment_satisfied,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                score >= 7
                    ? AppStrings.t(context, 'excellent_performance')
                    : AppStrings.t(context, 'game_over'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$score/${questions.length}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(AppStrings.t(context, 'exit')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          currentQuestionIndex = 0;
                          score = 0;
                          _loadQuestions();
                        });
                      },
                      child: Text(AppStrings.t(context, 'play_again')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Container(
        decoration: AppThemes.backgroundGradient(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  AppStrings.t(context, 'loading_questions'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Container(
        decoration: AppThemes.backgroundGradient(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 20),
                Text(AppStrings.t(context, 'error_loading_questions')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.t(context, 'go_back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final currentAnswer = currentQuestion['answer'] as String;

    return Container(
      decoration: AppThemes.backgroundGradient(context),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Icon(Icons.quiz, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.t(context, 'football_quiz'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Progress & Timer
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.quiz,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${currentQuestionIndex + 1}/${questions.length}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _remainingSeconds <= 10
                                    ? Colors.red.withValues(alpha: 0.9)
                                    : colorScheme.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_remainingSeconds',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Hint
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.1),
                                colorScheme.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentQuestion['hint'] as String,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Answer boxes
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(currentAnswer.length, (
                            index,
                          ) {
                            final letter = currentAnswer[index];
                            if (letter == ' ') return const SizedBox(width: 16);

                            final currentIndex =
                                currentAnswer
                                    .substring(0, index + 1)
                                    .replaceAll(' ', '')
                                    .length -
                                1;
                            final displayLetter =
                                currentIndex >= 0 &&
                                    currentIndex < userAnswer.length
                                ? userAnswer[currentIndex]
                                : '';

                            return InkWell(
                              onTap: displayLetter.isNotEmpty
                                  ? () => _removeLetterAtIndex(currentIndex)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 45,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: displayLetter.isNotEmpty
                                      ? colorScheme.primary.withValues(alpha: 0.2)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: displayLetter.isNotEmpty
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    displayLetter,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Keyboard (18 letters)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(availableLetters.length, (index) {
                      final letter = availableLetters[index];
                      final isUsed = letterUsed[index];

                      return InkWell(
                        onTap: !isUsed ? () => _addLetter(letter, index) : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Opacity(
                          opacity: isUsed ? 0.3 : 1.0,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isUsed
                                    ? [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ]
                                    : [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isUsed
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 
                                          0.3,
                                        ),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isUsed
                                      ? Colors.grey.shade300
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // أنيميشن الربح/الخسارة الخرافي
          if (_showResultAnimation)
            AnimatedOpacity(
              opacity: _showResultAnimation ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(_isCorrectAnswer),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: (1 - value) * 0.5,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.85,
                                  maxHeight: constraints.maxHeight * 0.8,
                                ),
                                padding: const EdgeInsets.all(24),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isCorrectAnswer
                                        ? [
                                            Colors.green.shade400,
                                            Colors.green.shade700,
                                          ]
                                        : [
                                            Colors.red.shade400,
                                            Colors.red.shade700,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isCorrectAnswer
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withValues(alpha: 0.6),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color:
                                          (_isCorrectAnswer
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 60,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // الأيقونة مع أنيميشن دوران
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        builder: (context, iconValue, child) {
                                          return Transform.rotate(
                                            angle: iconValue * 6.28,
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 
                                                  0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _isCorrectAnswer
                                                    ? Icons.check_circle_rounded
                                                    : Icons.cancel_rounded,
                                                size: 60,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 16),

                                      // النص الرئيسي
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: DefaultTextStyle(
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 10,
                                                color: Colors.black26,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _isCorrectAnswer
                                                ? AppStrings.t(
                                                    context,
                                                    'correct',
                                                  )
                                                : AppStrings.t(
                                                    context,
                                                    'wrong',
                                                  ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.clip,
                                          ),
                                        ),
                                      ),

                                      // عرض الإجابة الصحيحة عند الخطأ
                                      if (!_isCorrectAnswer) ...[
                                        const SizedBox(height: 16),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 
                                                  0.3,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: DefaultTextStyle(
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                    child: Text(
                                                      '${AppStrings.t(context, 'correct_answer')}:',
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.clip,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: DefaultTextStyle(
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 8,
                                                          color: Colors.black26,
                                                          offset: Offset(1, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      questions[currentQuestionIndex]['answer']
                                                          as String,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
