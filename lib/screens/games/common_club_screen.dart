import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/gemini_service_extended.dart';
import '../../services/settings_service.dart';
import '../../models/ai_question_types.dart';

// شاشة اختيار مستوى الصعوبة
class CommonClubDifficultyScreen extends StatelessWidget {
  const CommonClubDifficultyScreen({Key? key}) : super(key: key);

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
                CommonClubScreen(isOnlineMode: false, difficulty: difficulty),
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

class CommonClubScreen extends StatefulWidget {
  final bool isOnlineMode;
  final String difficulty;

  const CommonClubScreen({
    Key? key,
    this.isOnlineMode = false,
    this.difficulty = 'easy',
  }) : super(key: key);

  @override
  State<CommonClubScreen> createState() => _CommonClubScreenState();
}

class _CommonClubScreenState extends State<CommonClubScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  String? selectedClub;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<String> shuffledClubs = [];

  // AI Integration
  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  final SettingsService _settings = SettingsService();
  List<AIMultipleChoiceQuestion> aiQuestions = [];
  bool isLoadingQuestions = false;
  String? errorMessage;
  String? _lastLanguage; // لتتبع آخر لغة تم تحميل الأسئلة بها

  // Timer
  Timer? _timer;
  int _remainingSeconds = 10;
  bool _timeIsUp = false;

  // 10 مراحل: 1-3 (لاعبان)، 4-8 (ثلاثة لاعبين)، 9-10 (أربعة لاعبين)
  final List<Map<String, dynamic>> questions = [
    // سهل - لاعبان (المستوى 1-3)
    {
      'players': ['Luis Suarez', 'Zlatan Ibrahimovic'],
      'clubs': ['Ajax', 'Barcelona', 'Inter Milan', 'Juventus'],
      'correctClub': 'Ajax',
      'difficulty': 'easy',
    },
    {
      'players': ['Cristiano Ronaldo', 'Casemiro'],
      'clubs': ['Real Madrid', 'Manchester United', 'Juventus', 'Barcelona'],
      'correctClub': 'Real Madrid',
      'difficulty': 'easy',
    },
    {
      'players': ['Xavi Hernandez', 'Andres Iniesta'],
      'clubs': ['Barcelona', 'Real Madrid', 'Bayern Munich', 'Liverpool'],
      'correctClub': 'Barcelona',
      'difficulty': 'easy',
    },

    // متوسط - ثلاثة لاعبين (المستوى 4-8)
    {
      'players': ['Sergio Ramos', 'Iker Casillas', 'Raul Gonzalez'],
      'clubs': ['Real Madrid', 'Barcelona', 'Atletico Madrid', 'Valencia'],
      'correctClub': 'Real Madrid',
      'difficulty': 'medium',
    },
    {
      'players': ['Frank Lampard', 'John Terry', 'Didier Drogba'],
      'clubs': ['Chelsea', 'Arsenal', 'Manchester United', 'Liverpool'],
      'correctClub': 'Chelsea',
      'difficulty': 'medium',
    },
    {
      'players': ['Thierry Henry', 'Patrick Vieira', 'Robert Pires'],
      'clubs': ['Arsenal', 'Chelsea', 'Manchester City', 'Tottenham'],
      'correctClub': 'Arsenal',
      'difficulty': 'medium',
    },
    {
      'players': ['Gianluigi Buffon', 'Andrea Pirlo', 'Alessandro Del Piero'],
      'clubs': ['Juventus', 'AC Milan', 'Inter Milan', 'Roma'],
      'correctClub': 'Juventus',
      'difficulty': 'medium',
    },
    {
      'players': ['Steven Gerrard', 'Jamie Carragher', 'Xabi Alonso'],
      'clubs': ['Liverpool', 'Manchester United', 'Chelsea', 'Arsenal'],
      'correctClub': 'Liverpool',
      'difficulty': 'medium',
    },

    // صعب - أربعة لاعبين (المستوى 9-10)
    {
      'players': [
        'Paolo Maldini',
        'Franco Baresi',
        'Alessandro Costacurta',
        'Clarence Seedorf',
      ],
      'clubs': ['AC Milan', 'Inter Milan', 'Juventus', 'Roma'],
      'correctClub': 'AC Milan',
      'difficulty': 'hard',
    },
    {
      'players': [
        'Arjen Robben',
        'Franck Ribery',
        'Thomas Muller',
        'Bastian Schweinsteiger',
      ],
      'clubs': [
        'Bayern Munich',
        'Borussia Dortmund',
        'Real Madrid',
        'Barcelona',
      ],
      'correctClub': 'Bayern Munich',
      'difficulty': 'hard',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // الحصول على اللغة الحالية
    final currentLocale = Localizations.localeOf(context);
    final currentLanguage = currentLocale.languageCode;

    // إعادة تحميل الأسئلة إذا تغيرت اللغة أو لا توجد أسئلة
    if (_lastLanguage != currentLanguage ||
        (aiQuestions.isEmpty && !isLoadingQuestions)) {
      if (_lastLanguage != currentLanguage) {
        print(
          '🔄 Language changed from $_lastLanguage to $currentLanguage, reloading questions...',
        );
        _gemini.clearUsedQuestions(); // مسح الأسئلة السابقة عند تغيير اللغة
      }
      _lastLanguage = currentLanguage;

      // إعادة تعيين الحالة
      setState(() {
        aiQuestions.clear();
        currentQuestionIndex = 0;
        score = 0;
        isAnswered = false;
        selectedClub = null;
      });

      _loadAIQuestions();
    }
  }

  Future<void> _loadAIQuestions() async {
    setState(() {
      isLoadingQuestions = true;
      errorMessage = null;
    });

    try {
      if (_gemini.isConfigured()) {
        print('✅ Gemini API Key configured, loading AI questions...');

        // طلب أسئلة بصعوبات متنوعة: 3 سهلة + 5 متوسطة + 2 صعبة
        List<AIMultipleChoiceQuestion> allQuestions = [];

        // الحصول على اللغة الحالية من الإعدادات و من Locale
        String languageFromSettings = _settings
            .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
        String languageFromLocale = 'ar'; // default

        // إذا كان context متاحاً، استخدم اللغة من Locale
        if (mounted) {
          final locale = Localizations.localeOf(context);
          languageFromLocale = locale.languageCode;
        }

        // استخدم اللغة من Locale (الأكثر دقة)
        String currentLanguage = languageFromLocale;

        print('🌍 Language from Settings: $languageFromSettings');
        print('🌍 Language from Locale: $languageFromLocale');
        print('🌍 Using language: $currentLanguage');
        print('🎯 Difficulty level: ${widget.difficulty}');

        // طلب أسئلة حسب المستوى المختار فقط
        print('📥 Requesting 10 ${widget.difficulty} questions...');
        final questions = await _gemini.generateMultipleChoiceQuestions(
          count: 10,
          difficulty: widget.difficulty,
          category: 'common_club',
          language: currentLanguage,
        );
        print('✅ Received ${questions.length} ${widget.difficulty} questions');
        allQuestions.addAll(questions);

        // إذا لم نحصل على العدد المطلوب، حاول مرة أخرى للأسئلة الناقصة
        if (allQuestions.length < 10) {
          print(
            '⚠️ Got ${allQuestions.length}/10 questions, requesting more...',
          );
          final remaining = 10 - allQuestions.length;

          try {
            final extraQuestions = await _gemini
                .generateMultipleChoiceQuestions(
                  count: remaining,
                  difficulty: widget.difficulty,
                  category: 'common_club',
                  language: currentLanguage,
                );
            print('✅ Received ${extraQuestions.length} extra questions');
            allQuestions.addAll(extraQuestions);
          } catch (e) {
            print('⚠️ Could not get extra questions: $e');
          }
        }

        // استخدم ما حصلنا عليه طالما لدينا 5 أسئلة على الأقل
        if (allQuestions.length >= 5) {
          print(
            '🎉 Total: ${allQuestions.length} AI questions loaded successfully!',
          );
          setState(() {
            aiQuestions = allQuestions;
            isLoadingQuestions = false;
            _shuffleClubs();
          });
        } else {
          print(
            '⚠️ Not enough questions (${allQuestions.length}/10), using fallback',
          );
          throw Exception('Not enough questions generated');
        }
      } else {
        print('⚠️ Gemini API not configured, using static questions');
        setState(() {
          isLoadingQuestions = false;
          _shuffleClubs();
        });
      }
    } catch (e) {
      print('❌ Error loading AI questions: $e');
      print('📋 Falling back to static questions');
      setState(() {
        errorMessage = null; // استخدم الأسئلة الثابتة عند الخطأ
        isLoadingQuestions = false;
        _shuffleClubs();
      });
    }
  }

  void _shuffleClubs() {
    if (aiQuestions.isNotEmpty && currentQuestionIndex < aiQuestions.length) {
      shuffledClubs = List<String>.from(
        aiQuestions[currentQuestionIndex].options,
      );
    } else if (currentQuestionIndex < questions.length) {
      final currentQuestion = questions[currentQuestionIndex];
      shuffledClubs = List<String>.from(currentQuestion['clubs']);
    }
    shuffledClubs.shuffle();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 10;
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
          if (!isAnswered) {
            _handleTimeUp();
          }
        }
      });
    });
  }

  void _handleTimeUp() {
    if (isAnswered) return;

    setState(() {
      isAnswered = true;
      _timeIsUp = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _moveToNextQuestion();
    });
  }

  void _moveToNextQuestion() {
    final totalQuestions = aiQuestions.isNotEmpty
        ? aiQuestions.length
        : questions.length;
    if (currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        currentQuestionIndex++;
        isAnswered = false;
        selectedClub = null;
        _timeIsUp = false;
        _shuffleClubs();
      });
    } else {
      _showGameOver();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _getDifficultyText(BuildContext context, String difficulty) {
    if (difficulty == 'easy') return AppStrings.t(context, 'easy');
    if (difficulty == 'medium') return AppStrings.t(context, 'medium');
    return AppStrings.t(context, 'hard');
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty == 'easy') return Colors.green;
    if (difficulty == 'medium') return Colors.orange;
    return Colors.red;
  }

  String _getLoadingMessage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'ar':
        return 'جاري تحضير الأسئلة...';
      case 'tr':
        return 'Sorular hazırlanıyor...';
      case 'en':
      default:
        return 'Preparing questions...';
    }
  }

  void _selectClub(String club) {
    if (isAnswered || _timeIsUp) return;

    _timer?.cancel();

    setState(() {
      selectedClub = club;
      isAnswered = true;

      String correctAnswer;
      if (aiQuestions.isNotEmpty && currentQuestionIndex < aiQuestions.length) {
        correctAnswer = aiQuestions[currentQuestionIndex].correctAnswer;
      } else {
        correctAnswer = questions[currentQuestionIndex]['correctClub'];
      }

      // مقارنة صارمة - يجب أن تكون مطابقة تماماً
      final isCorrect =
          club.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

      print('🔍 Selected: "$club" vs Correct: "$correctAnswer"');
      print(isCorrect ? '✅ Correct!' : '❌ Wrong!');

      if (isCorrect) {
        score++;
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _moveToNextQuestion();
    });
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  score >= 7 ? Icons.emoji_events : Icons.sentiment_satisfied,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                score >= 7
                    ? AppStrings.t(context, 'excellent_performance')
                    : AppStrings.t(context, 'game_over'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${AppStrings.t(context, 'your_score')}: $score/10',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppStrings.t(context, 'exit'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
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
                          isAnswered = false;
                          selectedClub = null;
                        });
                        _loadAIQuestions();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppStrings.t(context, 'play_again'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
    final isDark = theme.brightness == Brightness.dark;

    // Show loading state
    if (isLoadingQuestions) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t(context, 'common_club'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                _getLoadingMessage(context),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // Use AI questions if available, otherwise fallback to static questions
    final useAI =
        aiQuestions.isNotEmpty && currentQuestionIndex < aiQuestions.length;
    final currentQuestion = useAI ? null : questions[currentQuestionIndex];
    final difficultyText = useAI
        ? _getDifficultyText(
            context,
            aiQuestions[currentQuestionIndex].difficulty,
          )
        : _getDifficultyText(context, currentQuestion!['difficulty']);
    final difficultyColor = useAI
        ? _getDifficultyColor(aiQuestions[currentQuestionIndex].difficulty)
        : _getDifficultyColor(currentQuestion!['difficulty']);

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
            AppStrings.t(context, 'common_club'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            if (aiQuestions.isNotEmpty)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.refresh, color: colorScheme.primary),
                ),
                tooltip: 'Reload Questions',
                onPressed: () {
                  print('🔄 Manual refresh triggered');
                  _gemini.clearUsedQuestions(); // مسح الأسئلة السابقة
                  setState(() {
                    aiQuestions.clear();
                    currentQuestionIndex = 0;
                    score = 0;
                    isAnswered = false;
                    selectedClub = null;
                  });
                  _loadAIQuestions();
                },
              ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator
                _buildProgressIndicator(colorScheme),

                const SizedBox(height: 24),

                // Question Card
                useAI
                    ? _buildAIQuestionCard(
                        context,
                        theme,
                        colorScheme,
                        aiQuestions[currentQuestionIndex],
                        difficultyText,
                        difficultyColor,
                      )
                    : _buildQuestionCard(
                        context,
                        theme,
                        colorScheme,
                        currentQuestion!,
                        difficultyText,
                        difficultyColor,
                      ),

                const SizedBox(height: 32),

                // Clubs Grid
                Expanded(
                  child: useAI
                      ? _buildAIClubsGrid(
                          aiQuestions[currentQuestionIndex],
                          colorScheme,
                          isDark,
                        )
                      : _buildClubsGrid(currentQuestion!, colorScheme, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.t(context, 'question')} ${currentQuestionIndex + 1}/10',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            // Timer Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds <= 3
                    ? Colors.red.withValues(alpha: 0.9)
                    : colorScheme.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_remainingSeconds <= 3
                                ? Colors.red
                                : colorScheme.primary)
                            .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$_remainingSeconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value:
                (currentQuestionIndex + 1) /
                (aiQuestions.isNotEmpty
                    ? aiQuestions.length
                    : questions.length),
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> question,
    String difficultyText,
    Color difficultyColor,
  ) {
    final players = question['players'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: difficultyColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              difficultyText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Icon(Icons.group, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            AppStrings.t(context, 'find_common_club'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // اللاعبون
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: players.map((player) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  player,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsGrid(
    Map<String, dynamic> currentQuestion,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: shuffledClubs.length,
      itemBuilder: (context, index) {
        final club = shuffledClubs[index];
        final isCorrect = club == currentQuestion['correctClub'];
        final isSelected = selectedClub == club;
        final showResult = isAnswered || _timeIsUp;

        Color cardColor;
        if (showResult) {
          if (_timeIsUp && !isAnswered) {
            cardColor = isCorrect ? Colors.orange : colorScheme.surface;
          } else if (isSelected) {
            cardColor = isCorrect ? Colors.green : Colors.red;
          } else if (isCorrect) {
            cardColor = Colors.green;
          } else {
            cardColor = colorScheme.surface;
          }
        } else {
          cardColor = colorScheme.surface;
        }

        return ScaleTransition(
          scale: (showResult && isCorrect)
              ? _scaleAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: InkWell(
            onTap: () => _selectClub(club),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: showResult
                    ? cardColor.withValues(alpha: 0.9)
                    : (isDark ? colorScheme.surface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: showResult
                      ? cardColor
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: showResult ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: showResult
                        ? cardColor.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: showResult ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: showResult
                          ? Colors.white.withValues(alpha: 0.2)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showResult
                          ? (isCorrect ? Icons.check_circle : Icons.cancel)
                          : Icons.shield,
                      size: 40,
                      color: showResult ? Colors.white : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      club,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: showResult
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (showResult) ...[
                    const SizedBox(height: 8),
                    Text(
                      isCorrect
                          ? AppStrings.t(context, 'correct')
                          : AppStrings.t(context, 'wrong'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIQuestionCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AIMultipleChoiceQuestion question,
    String difficultyText,
    Color difficultyColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  difficultyText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Icon(Icons.auto_awesome, size: 48, color: Colors.purple),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIClubsGrid(
    AIMultipleChoiceQuestion question,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: shuffledClubs.length,
      itemBuilder: (context, index) {
        final club = shuffledClubs[index];
        final isCorrect = club == question.correctAnswer;
        final isSelected = selectedClub == club;
        final showResult = isAnswered && isSelected;

        Color cardColor;
        if (showResult) {
          cardColor = isCorrect ? Colors.green : Colors.red;
        } else {
          cardColor = colorScheme.surface;
        }

        return ScaleTransition(
          scale: (showResult && isCorrect)
              ? _scaleAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: InkWell(
            onTap: () => _selectClub(club),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: showResult
                    ? cardColor.withValues(alpha: 0.9)
                    : (isDark ? colorScheme.surface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: showResult
                      ? cardColor
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: showResult ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: showResult
                        ? cardColor.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: showResult ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: showResult
                          ? Colors.white.withValues(alpha: 0.2)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showResult
                          ? (isCorrect ? Icons.check_circle : Icons.cancel)
                          : Icons.shield,
                      size: 40,
                      color: showResult ? Colors.white : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      club,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: showResult
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (showResult) ...[
                    const SizedBox(height: 8),
                    Text(
                      isCorrect
                          ? AppStrings.t(context, 'correct')
                          : AppStrings.t(context, 'wrong'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
