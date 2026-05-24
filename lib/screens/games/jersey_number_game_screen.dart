import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/question_manager.dart';
import '../../models/ai_question.dart';

/// شاشة لعبة تحديد اللاعب من رقم القميص
class JerseyNumberGameScreen extends StatefulWidget {
  final String difficulty;

  const JerseyNumberGameScreen({
    Key? key,
    required this.difficulty,
  }) : super(key: key);

  @override
  State<JerseyNumberGameScreen> createState() => _JerseyNumberGameScreenState();
}

class _JerseyNumberGameScreenState extends State<JerseyNumberGameScreen> with TickerProviderStateMixin {
  final QuestionManager _questionManager = QuestionManager();
  
  AIQuestion? currentQuestion;
  List<String> shuffledPlayers = [];
  
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  String? errorMessage;
  
  String? selectedPlayer;
  bool isAnswered = false;
  bool showNextButton = false;
  
  // قائمة الأسئلة الاحتياطية المخلوطة (تُخلط مرة واحدة عند البداية)
  List<AIQuestion>? _shuffledFallbackQuestions;
  
  // Animation controllers
  AnimationController? _scaleController;
  AnimationController? _shakeController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // لا نستدعي _initializeFallbackQuestions هنا لأنها تحتاج context
    _clearCacheAndLoad();
  }
  
  void _initializeFallbackQuestions() {
    // إنشاء وخلط الأسئلة الاحتياطية مرة واحدة فقط
    if (_shuffledFallbackQuestions != null) return; // تم الخلط مسبقاً
    
    _shuffledFallbackQuestions = _getFallbackQuestions();
    _shuffledFallbackQuestions!.shuffle();
    print('🎲 تم خلط ${_shuffledFallbackQuestions!.length} سؤال احتياطي');
  }
  
  Future<void> _clearCacheAndLoad() async {
    // مسح الأسئلة القديمة لضمان الحصول على أسئلة جديدة متنوعة
    print('🗑️ مسح cache الأسئلة القديمة...');
    try {
      await _questionManager.clearCache();
      print('✅ تم مسح الـ cache بنجاح');
    } catch (e) {
      print('⚠️ لم يتم مسح الـ cache: $e');
    }
    _loadQuestion();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController!, curve: Curves.easeInOut),
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _scaleController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isAnswered = false;
      selectedPlayer = null;
      showNextButton = false;
    });

    try {
      // محاولة تحميل السؤال مع timeout
      final question = await _questionManager.getQuestion(
        difficulty: widget.difficulty,
        category: 'jersey_number',
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      
      if (question != null) {
        final newShuffledPlayers = List<String>.from(question.options);
        newShuffledPlayers.shuffle();
        
        setState(() {
          currentQuestion = question;
          shuffledPlayers = newShuffledPlayers;
          isLoading = false;
        });
      } else {
        // استخدام أسئلة افتراضية
        _loadFallbackQuestion();
      }
    } catch (e) {
      // استخدام أسئلة افتراضية في حالة الخطأ
      _loadFallbackQuestion();
    }
  }

  void _loadFallbackQuestion() {
    // استخدام القائمة المخلوطة المحفوظة
    if (_shuffledFallbackQuestions == null || _shuffledFallbackQuestions!.isEmpty) {
      _initializeFallbackQuestions();
    }
    
    final fallbackQuestions = _shuffledFallbackQuestions!;
    
    if (currentQuestionIndex < fallbackQuestions.length) {
      final question = fallbackQuestions[currentQuestionIndex];
      final newShuffledPlayers = List<String>.from(question.options);
      newShuffledPlayers.shuffle();
      
      setState(() {
        currentQuestion = question;
        shuffledPlayers = newShuffledPlayers;
        isLoading = false;
        errorMessage = null;
      });
    } else {
      // إعادة البداية مع خلط جديد للتنويع
      print('🔄 إعادة خلط الأسئلة للجولة الجديدة');
      _shuffledFallbackQuestions!.shuffle();
      currentQuestionIndex = 0;
      
      final question = _shuffledFallbackQuestions![0];
      final newShuffledPlayers = List<String>.from(question.options);
      newShuffledPlayers.shuffle();
      
      setState(() {
        currentQuestion = question;
        shuffledPlayers = newShuffledPlayers;
        isLoading = false;
        errorMessage = null;
      });
    }
  }

  // دالة لترجمة أسماء اللاعبين
  Map<String, Map<String, String>> _getPlayerNames() {
    return {
      'Steven Gerrard': {
        'ar': 'ستيفن جيرارد',
        'en': 'Steven Gerrard',
        'tr': 'Steven Gerrard',
      },
      'Cristiano Ronaldo': {
        'ar': 'كريستيانو رونالدو',
        'en': 'Cristiano Ronaldo',
        'tr': 'Cristiano Ronaldo',
      },
      'David Beckham': {
        'ar': 'ديفيد بيكهام',
        'en': 'David Beckham',
        'tr': 'David Beckham',
      },
      'Raul': {
        'ar': 'راؤول غونزاليس',
        'en': 'Raul Gonzalez',
        'tr': 'Raul Gonzalez',
      },
      'Xavi': {
        'ar': 'تشافي هيرنانديز',
        'en': 'Xavi Hernandez',
        'tr': 'Xavi Hernandez',
      },
      'Benzema': {
        'ar': 'كريم بنزيما',
        'en': 'Karim Benzema',
        'tr': 'Karim Benzema',
      },
      'Lewandowski': {
        'ar': 'روبرت ليفاندوفسكي',
        'en': 'Robert Lewandowski',
        'tr': 'Robert Lewandowski',
      },
      'Cavani': {
        'ar': 'كافاني',
        'en': 'Edinson Cavani',
        'tr': 'Edinson Cavani',
      },
      'Sergio Ramos': {
        'ar': 'سيرجيو راموس',
        'en': 'Sergio Ramos',
        'tr': 'Sergio Ramos',
      },
      'Messi': {
        'ar': 'ليونيل ميسي',
        'en': 'Lionel Messi',
        'tr': 'Lionel Messi',
      },
      'Neymar': {
        'ar': 'نيمار',
        'en': 'Neymar Jr',
        'tr': 'Neymar Jr',
      },
      'Zidane': {
        'ar': 'زين الدين زيدان',
        'en': 'Zinedine Zidane',
        'tr': 'Zinedine Zidane',
      },
      'Iniesta': {
        'ar': 'أندريس إنييستا',
        'en': 'Andres Iniesta',
        'tr': 'Andres Iniesta',
      },
      'Salah': {
        'ar': 'محمد صلاح',
        'en': 'Mohamed Salah',
        'tr': 'Mohamed Salah',
      },
      'Bale': {
        'ar': 'غاريث بيل',
        'en': 'Gareth Bale',
        'tr': 'Gareth Bale',
      },
      'Drogba': {
        'ar': 'ديديه دروجبا',
        'en': 'Didier Drogba',
        'tr': 'Didier Drogba',
      },
      'Lampard': {
        'ar': 'فرانك لامبارد',
        'en': 'Frank Lampard',
        'tr': 'Frank Lampard',
      },
      'Puyol': {
        'ar': 'كارليس بويول',
        'en': 'Carles Puyol',
        'tr': 'Carles Puyol',
      },
      'Cannavaro': {
        'ar': 'فابيو كانافارو',
        'en': 'Fabio Cannavaro',
        'tr': 'Fabio Cannavaro',
      },
      'Busquets': {
        'ar': 'سيرجيو بوسكيتس',
        'en': 'Sergio Busquets',
        'tr': 'Sergio Busquets',
      },
      'Henry': {
        'ar': 'تييري هنري',
        'en': 'Thierry Henry',
        'tr': 'Thierry Henry',
      },
      'Chicharito': {
        'ar': 'خافيير هيرنانديز',
        'en': 'Javier Hernandez',
        'tr': 'Javier Hernandez',
      },
      'Willy': {
        'ar': 'ويلي',
        'en': 'Willy Caballero',
        'tr': 'Willy Caballero',
      },
      'Pirlo': {
        'ar': 'أندريا بيرلو',
        'en': 'Andrea Pirlo',
        'tr': 'Andrea Pirlo',
      },
      'Dybala': {
        'ar': 'باولو ديبالا',
        'en': 'Paulo Dybala',
        'tr': 'Paulo Dybala',
      },
      'Silva': {
        'ar': 'ديفيد سيلفا',
        'en': 'David Silva',
        'tr': 'David Silva',
      },
      'Modric': {
        'ar': 'لوكا مودريتش',
        'en': 'Luka Modric',
        'tr': 'Luka Modric',
      },
      'Pique': {
        'ar': 'جيرارد بيكيه',
        'en': 'Gerard Pique',
        'tr': 'Gerard Pique',
      },
      'Pogba': {
        'ar': 'بول بوجبا',
        'en': 'Paul Pogba',
        'tr': 'Paul Pogba',
      },
      // أساطير (1990-2007)
      'Ronaldo Nazario': {
        'ar': 'رونالدو البرازيلي',
        'en': 'Ronaldo Nazario',
        'tr': 'Ronaldo Nazario',
      },
      'Figo': {
        'ar': 'لويس فيغو',
        'en': 'Luis Figo',
        'tr': 'Luis Figo',
      },
      'Rivaldo': {
        'ar': 'ريفالدو',
        'en': 'Rivaldo',
        'tr': 'Rivaldo',
      },
      'Maldini': {
        'ar': 'باولو مالديني',
        'en': 'Paolo Maldini',
        'tr': 'Paolo Maldini',
      },
      'Totti': {
        'ar': 'فرانشيسكو توتي',
        'en': 'Francesco Totti',
        'tr': 'Francesco Totti',
      },
      'Del Piero': {
        'ar': 'أليساندرو ديل بييرو',
        'en': 'Alessandro Del Piero',
        'tr': 'Alessandro Del Piero',
      },
      // الجيل الذهبي (2008-2019)
      'Robben': {
        'ar': 'أريين روبن',
        'en': 'Arjen Robben',
        'tr': 'Arjen Robben',
      },
      'Ribery': {
        'ar': 'فرانك ريبيري',
        'en': 'Franck Ribery',
        'tr': 'Franck Ribery',
      },
      'Torres': {
        'ar': 'فرناندو توريس',
        'en': 'Fernando Torres',
        'tr': 'Fernando Torres',
      },
      'Falcao': {
        'ar': 'رادامل فالكاو',
        'en': 'Radamel Falcao',
        'tr': 'Radamel Falcao',
      },
      'Sneijder': {
        'ar': 'فيسلي سنايدر',
        'en': 'Wesley Sneijder',
        'tr': 'Wesley Sneijder',
      },
      'Xabi Alonso': {
        'ar': 'تشابي ألونسو',
        'en': 'Xabi Alonso',
        'tr': 'Xabi Alonso',
      },
      'Buffon': {
        'ar': 'جيانلويجي بوفون',
        'en': 'Gianluigi Buffon',
        'tr': 'Gianluigi Buffon',
      },
      'Casillas': {
        'ar': 'إيكر كاسياس',
        'en': 'Iker Casillas',
        'tr': 'Iker Casillas',
      },
    };
  }

  List<AIQuestion> _getFallbackQuestions() {
    // الحصول على اللغة الحالية
    final currentLocale = Localizations.localeOf(context);
    final lang = currentLocale.languageCode;
    final playerNames = _getPlayerNames();
    
    // دالة مساعدة لترجمة اسم اللاعب
    String translate(String key) {
      return playerNames[key]?[lang] ?? playerNames[key]?['en'] ?? key;
    }
    
    // تنوع في الأسئلة من جميع العصور
    return [
      // عصر حديث
      AIQuestion(
        id: 'fallback_1',
        questionText: '7',
        options: [
          translate('Steven Gerrard'), // لم يحمل 7
          translate('Cristiano Ronaldo'),
          translate('David Beckham'),
          translate('Raul'),
        ],
        correctAnswer: translate('Steven Gerrard'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_2',
        questionText: '9',
        options: [
          translate('Xavi'), // لم يحمل 9
          translate('Torres'),
          translate('Falcao'),
          translate('Benzema'),
        ],
        correctAnswer: translate('Xavi'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الأساطير
      AIQuestion(
        id: 'fallback_3',
        questionText: '10',
        options: [
          translate('Maldini'), // لم يحمل 10
          translate('Zidane'),
          translate('Rivaldo'),
          translate('Totti'),
        ],
        correctAnswer: translate('Maldini'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // عصر حديث
      AIQuestion(
        id: 'fallback_4',
        questionText: '11',
        options: [
          translate('Iniesta'), // لم يحمل 11
          translate('Salah'),
          translate('Bale'),
          translate('Drogba'),
        ],
        correctAnswer: translate('Iniesta'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_5',
        questionText: '8',
        options: [
          translate('Benzema'), // لم يحمل 8
          translate('Iniesta'),
          translate('Steven Gerrard'),
          translate('Lampard'),
        ],
        correctAnswer: translate('Benzema'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الأساطير
      AIQuestion(
        id: 'fallback_6',
        questionText: '7',
        options: [
          translate('Maldini'), // لم يحمل 7
          translate('Figo'),
          translate('Raul'),
          translate('David Beckham'),
        ],
        correctAnswer: translate('Maldini'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // عصر حديث
      AIQuestion(
        id: 'fallback_7',
        questionText: '5',
        options: [
          translate('Salah'), // لم يحمل 5
          translate('Sergio Ramos'),
          translate('Puyol'),
          translate('Cannavaro'),
        ],
        correctAnswer: translate('Salah'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_8',
        questionText: '10',
        options: [
          translate('Robben'), // لم يحمل 10
          translate('Sneijder'),
          translate('Ribery'),
          translate('Zidane'),
        ],
        correctAnswer: translate('Robben'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الأساطير
      AIQuestion(
        id: 'fallback_9',
        questionText: '9',
        options: [
          translate('Figo'), // لم يحمل 9
          translate('Ronaldo Nazario'),
          translate('Torres'),
          translate('Falcao'),
        ],
        correctAnswer: translate('Figo'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_10',
        questionText: '21',
        options: [
          translate('Xabi Alonso'), // لم يحمل 21
          translate('Pirlo'),
          translate('Dybala'),
          translate('Silva'),
        ],
        correctAnswer: translate('Xabi Alonso'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // أسئلة إضافية للتنويع
      // الأساطير
      AIQuestion(
        id: 'fallback_11',
        questionText: '3',
        options: [
          translate('Ronaldo Nazario'), // لم يحمل 3
          translate('Maldini'),
          translate('Puyol'),
          translate('Cannavaro'),
        ],
        correctAnswer: translate('Ronaldo Nazario'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // عصر حديث
      AIQuestion(
        id: 'fallback_12',
        questionText: '23',
        options: [
          translate('Iniesta'), // لم يحمل 23
          translate('David Beckham'),
          translate('Xavi'),
          translate('Silva'),
        ],
        correctAnswer: translate('Iniesta'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_13',
        questionText: '14',
        options: [
          translate('Busquets'), // لم يحمل 14
          translate('Henry'),
          translate('Xabi Alonso'),
          translate('Ribery'),
        ],
        correctAnswer: translate('Busquets'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الأساطير
      AIQuestion(
        id: 'fallback_14',
        questionText: '11',
        options: [
          translate('Del Piero'), // لم يحمل 11
          translate('Drogba'),
          translate('Bale'),
          translate('Salah'),
        ],
        correctAnswer: translate('Del Piero'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // عصر حديث
      AIQuestion(
        id: 'fallback_15',
        questionText: '6',
        options: [
          translate('David Beckham'), // لم يحمل 6
          translate('Xavi'),
          translate('Iniesta'),
          translate('Pogba'),
        ],
        correctAnswer: translate('David Beckham'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_16',
        questionText: '7',
        options: [
          translate('Torres'), // لم يحمل 7
          translate('Cristiano Ronaldo'),
          translate('David Beckham'),
          translate('Raul'),
        ],
        correctAnswer: translate('Torres'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الأساطير
      AIQuestion(
        id: 'fallback_17',
        questionText: '1',
        options: [
          translate('Messi'), // لم يحمل 1
          translate('Cannavaro'),
          translate('Buffon'),
          translate('Casillas'),
        ],
        correctAnswer: translate('Messi'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // عصر حديث
      AIQuestion(
        id: 'fallback_18',
        questionText: '4',
        options: [
          translate('Modric'), // لم يحمل 4
          translate('Sergio Ramos'),
          translate('Pique'),
          translate('Cannavaro'),
        ],
        correctAnswer: translate('Modric'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الجيل الذهبي
      AIQuestion(
        id: 'fallback_19',
        questionText: '23',
        options: [
          translate('Falcao'), // لم يحمل 23
          translate('David Beckham'),
          translate('Silva'),
          translate('Lampard'),
        ],
        correctAnswer: translate('Falcao'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
      // الأساطير
      AIQuestion(
        id: 'fallback_20',
        questionText: '8',
        options: [
          translate('Totti'), // لم يحمل 8
          translate('Iniesta'),
          translate('Steven Gerrard'),
          translate('Lampard'),
        ],
        correctAnswer: translate('Totti'),
        difficulty: widget.difficulty,
        category: 'jersey_number',
        createdAt: DateTime.now(),
      ),
    ];
  }

  void _selectPlayer(String player) {
    if (isAnswered || currentQuestion == null) return;
    
    final isCorrect = player.trim().toLowerCase() == currentQuestion!.correctAnswer.trim().toLowerCase();
    
    setState(() {
      selectedPlayer = player;
      isAnswered = true;
      
      if (isCorrect) {
        score++;
        _scaleController?.forward().then((_) => _scaleController?.reverse());
      } else {
        _shakeController?.forward().then((_) => _shakeController?.reverse());
      }
    });

    // إظهار زر Next بعد نصف ثانية
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          showNextButton = true;
        });
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < 9) {
      setState(() {
        currentQuestionIndex++;
      });
      _loadQuestion();
    } else {
      _showGameOver();
    }
  }

  void _showGameOver() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // الحصول على اللغة الحالية
    final currentLocale = Localizations.localeOf(context);
    final currentLanguage = currentLocale.languageCode;
    
    // ترجمة النصوص
    String excellentText;
    String tryAgainText;
    String finalScoreText;
    String homeText;
    String replayText;
    
    switch (currentLanguage) {
      case 'ar':
        excellentText = AppStrings.t(context, 'excellent');
        tryAgainText = AppStrings.t(context, 'continue');
        finalScoreText = AppStrings.t(context, 'final_score');
        homeText = AppStrings.t(context, 'home_title');
        replayText = AppStrings.t(context, 'continue');
        break;
      case 'tr':
        excellentText = 'Mükemmel! 🎉';
        tryAgainText = 'Tekrar Dene';
        finalScoreText = 'Son Skor';
        homeText = 'Ana Sayfa';
        replayText = 'Tekrar Oyna';
        break;
      case 'en':
      default:
        excellentText = 'Excellent! 🎉';
        tryAgainText = 'Try Again';
        finalScoreText = 'Final Score';
        homeText = 'Home';
        replayText = 'Replay';
        break;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                score >= 7 ? Icons.emoji_events : Icons.sports_soccer,
                size: 80,
                color: score >= 7 ? Colors.amber : colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                score >= 7 ? excellentText : tryAgainText,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                finalScoreText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$score / 10',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home),
                      label: Text(homeText),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onPrimaryContainer,
                        side: BorderSide(color: colorScheme.onPrimaryContainer),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          currentQuestionIndex = 0;
                          score = 0;
                          isAnswered = false;
                          selectedPlayer = null;
                          showNextButton = false;
                        });
                        _loadQuestion();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(replayText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Question counter (left)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: colorScheme.onSecondaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${currentQuestionIndex + 1}/10',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Challenge icon (center)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports, color: Colors.white, size: 24),
              ),
              
              // Score counter (right)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(errorMessage!, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadQuestion,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppStrings.t(context, 'next')),
                          ),
                        ],
                      ),
                    )
                  : currentQuestion == null
                      ? Center(child: Text(AppStrings.t(context, 'loading_question')))
                      : _buildQuestionContent(currentQuestion!, theme, colorScheme, isDark),
        ),
      ),
    );
  }

  Widget _buildQuestionContent(AIQuestion question, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildQuestionCard(context, theme, colorScheme, question),
                const SizedBox(height: 32),
                _buildPlayersGrid(question, colorScheme, isDark),
              ],
            ),
          ),
        ),
        
        // Next button at bottom
        if (showNextButton)
          Builder(
            builder: (context) {
              // الحصول على اللغة الحالية
              final currentLocale = Localizations.localeOf(context);
              final currentLanguage = currentLocale.languageCode;
              
              String nextText;
              String resultText;
              
              switch (currentLanguage) {
                case 'ar':
                  nextText = AppStrings.t(context, 'next');
                  resultText = AppStrings.t(context, 'your_score');
                  break;
                case 'tr':
                  nextText = 'Sonraki';
                  resultText = 'Sonuç';
                  break;
                case 'en':
                default:
                  nextText = 'Next';
                  resultText = 'Result';
                  break;
              }
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    currentQuestionIndex < 9 ? nextText : resultText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, AIQuestion question) {
    // الحصول على اللغة الحالية
    final currentLocale = Localizations.localeOf(context);
    final currentLanguage = currentLocale.languageCode;
    
    // ترجمة السؤال حسب اللغة
    String questionTitle;
    switch (currentLanguage) {
      case 'ar':
        questionTitle = 'من لم يحمل هذا الرقم؟';
        break;
      case 'tr':
        questionTitle = 'Bu numarayı kim takmadı?';
        break;
      case 'en':
      default:
        questionTitle = 'Who didn\'t wear this number?';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            questionTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // عرض الرقم مباشرة بدون دائرة
          Text(
            question.questionText.trim(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              fontSize: 120,
              fontFamily: 'monospace',
              shadows: [
                Shadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersGrid(AIQuestion question, ColorScheme colorScheme, bool isDark) {
    if (shuffledPlayers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: shuffledPlayers.length,
      itemBuilder: (context, index) {
        final player = shuffledPlayers[index];
        final isCorrect = player.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();
        final isSelected = selectedPlayer == player;
        final showResult = isAnswered && isSelected;
        final isWrongAnswer = selectedPlayer != null && selectedPlayer!.trim().toLowerCase() != question.correctAnswer.trim().toLowerCase();
        final showCorrectAnswer = isAnswered && !isSelected && isCorrect && isWrongAnswer;
        
        Color cardColor;
        if (showResult) {
          cardColor = isCorrect ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
        } else if (showCorrectAnswer) {
          cardColor = const Color(0xFF27AE60);
        } else {
          cardColor = colorScheme.surface;
        }
        
        Widget cardChild = Container(
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
                      ? (isCorrect ? Icons.check_circle : Icons.cancel)
                      : Icons.person,
                  size: 40,
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
              if (showCorrectAnswer) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓ الإجابة الصحيحة',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
        
        // Apply animations
        if (showResult && isCorrect && _scaleAnimation != null) {
          cardChild = AnimatedBuilder(
            animation: _scaleAnimation!,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation!.value,
              child: child,
            ),
            child: cardChild,
          );
        } else if (showResult && !isCorrect && _shakeAnimation != null) {
          cardChild = AnimatedBuilder(
            animation: _shakeAnimation!,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnimation!.value * (index % 2 == 0 ? 1 : -1), 0),
              child: child,
            ),
            child: cardChild,
          );
        }
        
        return InkWell(
          onTap: () => _selectPlayer(player),
          borderRadius: BorderRadius.circular(20),
          child: cardChild,
        );
      },
    );
  }
}
