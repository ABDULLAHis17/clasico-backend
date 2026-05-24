import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/gemini_service_extended.dart';
import '../../models/ai_question_types.dart';

// شاشة اختيار مستوى الصعوبة
class WhosTheOutsiderDifficultyScreen extends StatelessWidget {
  const WhosTheOutsiderDifficultyScreen({Key? key}) : super(key: key);

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
            builder: (context) => WhosTheOutsiderScreen(
              isOnlineMode: false,
              difficulty: difficulty,
            ),
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

class WhosTheOutsiderScreen extends StatefulWidget {
  final bool isOnlineMode;
  final String difficulty;

  const WhosTheOutsiderScreen({
    Key? key,
    this.isOnlineMode = false,
    this.difficulty = 'easy',
  }) : super(key: key);

  @override
  State<WhosTheOutsiderScreen> createState() => _WhosTheOutsiderScreenState();
}

class _WhosTheOutsiderScreenState extends State<WhosTheOutsiderScreen>
    with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  String? selectedPlayer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _correctAnswerAnimationController;
  late Animation<double> _pulseAnimation;
  List<String> shuffledPlayers = [];

  // AI Integration
  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  List<AIMultipleChoiceQuestion> aiQuestions = [];
  bool isLoadingQuestions = false;
  String? errorMessage;
  String? _lastLanguage; // لتتبع آخر لغة تم تحميل الأسئلة بها

  // Timer
  Timer? _timer;
  int _remainingSeconds = 10;
  bool _timeIsUp = false;

  // 10 مراحل من السهل إلى الصعب
  final List<Map<String, dynamic>> questions = [
    // سهل - مستوى 1-3
    {
      'team': 'Barcelona',
      'teamAr': 'برشلونة',
      'teamTr': 'Barcelona',
      'difficulty': 'easy',
      'players': [
        'Lionel Messi',
        'Xavi Hernandez',
        'Andres Iniesta',
        'Cristiano Ronaldo',
      ],
      'outsider': 'Cristiano Ronaldo',
    },
    {
      'team': 'Real Madrid',
      'teamAr': 'ريال مدريد',
      'teamTr': 'Real Madrid',
      'difficulty': 'easy',
      'players': ['Sergio Ramos', 'Karim Benzema', 'Luka Modric', 'Neymar Jr'],
      'outsider': 'Neymar Jr',
    },
    {
      'team': 'Manchester United',
      'teamAr': 'مانشستر يونايتد',
      'teamTr': 'Manchester United',
      'difficulty': 'easy',
      'players': [
        'Wayne Rooney',
        'Rio Ferdinand',
        'Ryan Giggs',
        'Steven Gerrard',
      ],
      'outsider': 'Steven Gerrard',
    },

    // متوسط - مستوى 4-7
    {
      'team': 'Bayern Munich',
      'teamAr': 'بايرن ميونخ',
      'teamTr': 'Bayern Münih',
      'difficulty': 'medium',
      'players': [
        'Thomas Muller',
        'Manuel Neuer',
        'Philipp Lahm',
        'Marco Reus',
      ],
      'outsider': 'Marco Reus',
    },
    {
      'team': 'AC Milan',
      'teamAr': 'إيه سي ميلان',
      'teamTr': 'AC Milan',
      'difficulty': 'medium',
      'players': ['Paolo Maldini', 'Andrea Pirlo', 'Kaka', 'Francesco Totti'],
      'outsider': 'Francesco Totti',
    },
    {
      'team': 'Chelsea',
      'teamAr': 'تشيلسي',
      'teamTr': 'Chelsea',
      'difficulty': 'medium',
      'players': [
        'Frank Lampard',
        'Didier Drogba',
        'John Terry',
        'Thierry Henry',
      ],
      'outsider': 'Thierry Henry',
    },
    {
      'team': 'Juventus',
      'teamAr': 'يوفنتوس',
      'teamTr': 'Juventus',
      'difficulty': 'medium',
      'players': [
        'Alessandro Del Piero',
        'Gianluigi Buffon',
        'Pavel Nedved',
        'Ronaldinho',
      ],
      'outsider': 'Ronaldinho',
    },

    // صعب - مستوى 8-10
    {
      'team': 'Liverpool',
      'teamAr': 'ليفربول',
      'teamTr': 'Liverpool',
      'difficulty': 'hard',
      'players': [
        'Mohamed Salah',
        'Virgil van Dijk',
        'Sadio Mane',
        'Kevin De Bruyne',
      ],
      'outsider': 'Kevin De Bruyne',
    },
    {
      'team': 'Paris Saint-Germain',
      'teamAr': 'باريس سان جيرمان',
      'teamTr': 'Paris Saint-Germain',
      'difficulty': 'hard',
      'players': [
        'Zlatan Ibrahimovic',
        'Thiago Silva',
        'Edinson Cavani',
        'Robert Lewandowski',
      ],
      'outsider': 'Robert Lewandowski',
    },
    {
      'team': 'Manchester City',
      'teamAr': 'مانشستر سيتي',
      'teamTr': 'Manchester City',
      'difficulty': 'hard',
      'players': ['Sergio Aguero', 'David Silva', 'Yaya Toure', 'Gareth Bale'],
      'outsider': 'Gareth Bale',
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

    // أنيميشن للإجابة الصحيحة عند اختيار إجابة خاطئة
    _correctAnswerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _correctAnswerAnimationController,
        curve: Curves.easeInOut,
      ),
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
        selectedPlayer = null;
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

        // طلب أسئلة حسب المستوى المختار فقط
        List<AIMultipleChoiceQuestion> allQuestions = [];

        // الحصول على اللغة الحالية من الإعدادات و من Locale
        String languageFromLocale = 'en'; // default

        // إذا كان context متاحاً، استخدم اللغة من Locale
        if (mounted) {
          final locale = Localizations.localeOf(context);
          languageFromLocale = locale.languageCode;
        }

        // استخدم اللغة من Locale (الأكثر دقة)
        String currentLanguage = languageFromLocale;

        print('🌍 Language from Locale: $languageFromLocale');
        print('🌍 Using language: $currentLanguage');
        print('🎯 Difficulty level: ${widget.difficulty}');

        // 10 أسئلة من نفس المستوى
        print('📥 Requesting 10 ${widget.difficulty} questions...');
        final questions = await _gemini.generateMultipleChoiceQuestions(
          count: 10,
          difficulty: widget.difficulty,
          category: 'wrong_player',
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
                  category: 'wrong_player',
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
            _shufflePlayers();
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
          _shufflePlayers();
        });
      }
    } catch (e) {
      print('❌ Error loading AI questions: $e');
      print('📋 Falling back to static questions');
      setState(() {
        errorMessage = null; // استخدم الأسئلة الثابتة عند الخطأ
        isLoadingQuestions = false;
        _shufflePlayers();
      });
    }
  }

  void _shufflePlayers() {
    if (aiQuestions.isNotEmpty && currentQuestionIndex < aiQuestions.length) {
      shuffledPlayers = List<String>.from(
        aiQuestions[currentQuestionIndex].options,
      );
    } else if (currentQuestionIndex < questions.length) {
      final currentQuestion = questions[currentQuestionIndex];
      shuffledPlayers = List<String>.from(currentQuestion['players']);
    }
    shuffledPlayers.shuffle(Random());
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
        selectedPlayer = null;
        _timeIsUp = false;
        _shufflePlayers();
      });
    } else {
      _showGameOver();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _correctAnswerAnimationController.dispose();
    super.dispose();
  }

  String _getTeamName(BuildContext context, Map<String, dynamic> question) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') return question['teamAr'];
    if (locale == 'tr') return question['teamTr'];
    return question['team'];
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

  void _selectPlayer(String player) {
    if (isAnswered || _timeIsUp) return;

    _timer?.cancel();

    setState(() {
      selectedPlayer = player;
      isAnswered = true;

      String correctAnswer;
      if (aiQuestions.isNotEmpty && currentQuestionIndex < aiQuestions.length) {
        correctAnswer = aiQuestions[currentQuestionIndex].correctAnswer;
      } else {
        correctAnswer = questions[currentQuestionIndex]['outsider'];
      }

      if (player == correctAnswer) {
        score++;
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      } else {
        // إذا كانت الإجابة خاطئة، أظهر الإجابة الصحيحة بأنيميشن لطيف
        _correctAnswerAnimationController.repeat(reverse: true);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // إيقاف أنيميشن الإجابة الصحيحة
      _correctAnswerAnimationController.stop();
      _correctAnswerAnimationController.reset();

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
                          selectedPlayer = null;
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

    if (isLoadingQuestions) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t(context, 'whos_the_outsider'))),
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

    final useAI =
        aiQuestions.isNotEmpty && currentQuestionIndex < aiQuestions.length;
    final currentQuestion = useAI ? null : questions[currentQuestionIndex];
    final teamName = useAI ? '' : _getTeamName(context, currentQuestion!);
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
            AppStrings.t(context, 'whos_the_outsider'),
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
                    selectedPlayer = null;
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
                        teamName,
                        difficultyText,
                        difficultyColor,
                      ),

                const SizedBox(height: 32),

                // Players Grid
                Expanded(
                  child: useAI
                      ? _buildAIPlayersGrid(
                          aiQuestions[currentQuestionIndex],
                          colorScheme,
                          isDark,
                        )
                      : _buildPlayersGrid(
                          currentQuestion!,
                          colorScheme,
                          isDark,
                        ),
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
    String teamName,
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
          Icon(Icons.help_outline, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            AppStrings.t(context, 'find_outsider'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersGrid(
    Map<String, dynamic> currentQuestion,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final outsider = currentQuestion['outsider'];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: shuffledPlayers.length,
      itemBuilder: (context, index) {
        final player = shuffledPlayers[index];
        final isSelected = selectedPlayer == player;
        final showResult = isAnswered || _timeIsUp;
        final isOutsider = player == outsider;
        // إظهار الإجابة الصحيحة فقط عندما يختار المستخدم إجابة خاطئة
        final isWrongAnswer =
            selectedPlayer != null && selectedPlayer != outsider;
        final showCorrectAnswer =
            isAnswered && !isSelected && isOutsider && isWrongAnswer;

        Color cardColor;
        if (showResult) {
          if (_timeIsUp && !isAnswered) {
            cardColor = isOutsider ? Colors.orange : colorScheme.surface;
          } else if (isSelected) {
            cardColor = isOutsider ? Colors.green : Colors.red;
          } else if (isOutsider) {
            cardColor = Colors.green;
          } else {
            cardColor = colorScheme.surface;
          }
        } else {
          cardColor = colorScheme.surface;
        }

        Widget child = InkWell(
          onTap: () => _selectPlayer(player),
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
                        ? (isOutsider ? Icons.check_circle : Icons.cancel)
                        : Icons.person,
                    size: 48,
                    color: showResult ? Colors.white : colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    player,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: showResult ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showResult && isSelected) ...[
                  const SizedBox(height: 8),
                  Text(
                    isOutsider
                        ? AppStrings.t(context, 'correct')
                        : AppStrings.t(context, 'wrong'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (showCorrectAnswer) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.t(context, 'correct'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );

        // تطبيق الأنيميشن
        if (showResult && isOutsider && isSelected) {
          return ScaleTransition(scale: _scaleAnimation, child: child);
        } else if (showCorrectAnswer) {
          return ScaleTransition(scale: _pulseAnimation, child: child);
        } else {
          return child;
        }
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

  Widget _buildAIPlayersGrid(
    AIMultipleChoiceQuestion question,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: shuffledPlayers.length,
      itemBuilder: (context, index) {
        final player = shuffledPlayers[index];
        final isOutsider = player == question.correctAnswer;
        final isSelected = selectedPlayer == player;
        final showResult = isAnswered && isSelected;
        // إظهار الإجابة الصحيحة فقط عندما يختار المستخدم إجابة خاطئة
        final isWrongAnswer =
            selectedPlayer != null && selectedPlayer != question.correctAnswer;
        final showCorrectAnswer =
            isAnswered && !isSelected && isOutsider && isWrongAnswer;

        Color cardColor;
        if (showResult) {
          cardColor = isOutsider ? Colors.green : Colors.red;
        } else if (showCorrectAnswer) {
          cardColor = Colors.green;
        } else {
          cardColor = colorScheme.surface;
        }

        Widget child = InkWell(
          onTap: () => _selectPlayer(player),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: (showResult || showCorrectAnswer)
                  ? cardColor.withValues(alpha: 0.9)
                  : (isDark ? colorScheme.surface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (showResult || showCorrectAnswer)
                    ? cardColor
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: (showResult || showCorrectAnswer) ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (showResult || showCorrectAnswer)
                      ? cardColor.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: (showResult || showCorrectAnswer) ? 20 : 10,
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
                    color: (showResult || showCorrectAnswer)
                        ? Colors.white.withValues(alpha: 0.2)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (showResult || showCorrectAnswer)
                        ? (isOutsider ? Icons.check_circle : Icons.cancel)
                        : Icons.person,
                    size: 48,
                    color: (showResult || showCorrectAnswer)
                        ? Colors.white
                        : colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    player,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (showResult || showCorrectAnswer)
                          ? Colors.white
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showResult) ...[
                  const SizedBox(height: 8),
                  Text(
                    isOutsider
                        ? AppStrings.t(context, 'correct')
                        : AppStrings.t(context, 'wrong'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (showCorrectAnswer) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.t(context, 'correct'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );

        // تطبيق الأنيميشن
        if (showResult && isOutsider) {
          return ScaleTransition(scale: _scaleAnimation, child: child);
        } else if (showCorrectAnswer) {
          return ScaleTransition(scale: _pulseAnimation, child: child);
        } else {
          return child;
        }
      },
    );
  }
}
