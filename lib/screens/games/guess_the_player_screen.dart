import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../models/guess_player.dart';
import '../../data/guess_players_data.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/gemini_service_extended.dart';

class GuessThePlayerScreen extends StatefulWidget {
  final bool isOnlineMode;
  final int level;
  final String? opponentName; // اسم الصديق عند اللعب مع الأصدقاء

  const GuessThePlayerScreen({
    Key? key,
    this.isOnlineMode = false,
    this.level = 1,
    this.opponentName,
  }) : super(key: key);

  @override
  State<GuessThePlayerScreen> createState() => _GuessThePlayerScreenState();
}

class _GuessThePlayerScreenState extends State<GuessThePlayerScreen> {
  late GuessPlayer playerPlayer; // لاعب المستخدم
  late GuessPlayer computerPlayer; // لاعب الكمبيوتر

  int playerScore = 0;
  int computerScore = 0;

  bool isPlayerTurn = true;
  Timer? timer;
  int timeLeft = 30;

  TextEditingController questionController = TextEditingController();
  TextEditingController guessController = TextEditingController();
  List<GameQuestion> askedQuestions = [];

  String? lastQuestion;
  bool? lastAnswer;
  bool showResult = false;
  bool gameEnded = false;

  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  bool isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    questionController.dispose();
    guessController.dispose();
    super.dispose();
  }

  void _initializePlayers() {
    // احصل على مزيج من اللاعبين من جميع المستويات والمراكز
    final players = GuessPlayersData.getMixedPlayers();

    if (players.length >= 2) {
      playerPlayer = players[0];
      computerPlayer = players[1];

      print('🎮 NEW GAME:');
      print(
        '   👤 Player\'s target: ${playerPlayer.name} (${playerPlayer.position}, ${playerPlayer.nationality})',
      );
      print(
        '   🤖 Computer\'s target: ${computerPlayer.name} (${computerPlayer.position}, ${computerPlayer.nationality})',
      );
    }
  }

  void _startTimer() {
    timeLeft = 30;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            _handleTimeout();
          }
        });
      }
    });
  }

  void _handleTimeout() {
    timer?.cancel();
    setState(() {
      if (isPlayerTurn) {
        // فقط تبديل الدور دون خسارة قلوب
        isPlayerTurn = false;
        _startTimer();
        _computerAskQuestion();
      }
    });
  }

  Future<void> _submitQuestion() async {
    final question = questionController.text.trim();
    if (question.isEmpty) return;

    // تحقق من عدم تكرار السؤال
    bool isDuplicate = askedQuestions.any(
      (q) => q.question.toLowerCase() == question.toLowerCase(),
    );

    if (isDuplicate) {
      // Removed SnackBar
      return;
    }

    timer?.cancel();

    setState(() {
      isVerifying = true;
    });

    try {
      // الذكاء الاصطناعي يجيب على السؤال بناءً على معلومات اللاعب
      final answer = await _gemini.verifyQuestionAnswer(
        question: question,
        playerInfo: {
          'name': computerPlayer.name,
          'nationality': computerPlayer.nationality,
          'position': computerPlayer.position,
          'league': computerPlayer.league,
          'age': computerPlayer.age,
          'club': computerPlayer.club,
          'isRetired': computerPlayer.isRetired,
        },
      );

      setState(() {
        isVerifying = false;
        askedQuestions.add(
          GameQuestion(
            question: question,
            askedBy: 'player',
            answer: answer,
            timestamp: DateTime.now(),
          ),
        );
        lastQuestion = question;
        lastAnswer = answer;
        showResult = true;
      });

      questionController.clear();

      // بعد ثانيتين، دور الكمبيوتر
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showResult = false;
            isPlayerTurn = false;
          });
          _startTimer();
          _computerAskQuestion();
        }
      });
    } catch (e) {
      setState(() {
        isVerifying = false;
      });

      if (!mounted) return;
      // Removed SnackBar
    }
  }

  void _computerAskQuestion() {
    // الكمبيوتر يطرح سؤالاً بعد 3 ثواني
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted && !isPlayerTurn) {
        // حساب عدد الأسئلة التي طرحها الكمبيوتر
        final computerQuestionsCount = askedQuestions
            .where((q) => q.askedBy == 'computer')
            .length;

        // احتمالية ذكية للتخمين (مثل لاعب حقيقي يحلل)
        final random = Random();
        double guessChance = 0.0;

        // حساب جودة المعلومات المجمعة
        final yesAnswers = askedQuestions
            .where((q) => q.askedBy == 'computer' && q.answer == true)
            .length;

        if (computerQuestionsCount >= 4 && yesAnswers >= 2) {
          // بعد 4 أسئلة + إجابتين نعم: 10% فرصة
          guessChance = 0.10;
        }
        if (computerQuestionsCount >= 6 && yesAnswers >= 3) {
          // بعد 6 أسئلة + 3 إجابات نعم: 25% فرصة
          guessChance = 0.25;
        }
        if (computerQuestionsCount >= 8 && yesAnswers >= 4) {
          // بعد 8 أسئلة + 4 إجابات نعم: 45% فرصة
          guessChance = 0.45;
        }
        if (computerQuestionsCount >= 10 && yesAnswers >= 5) {
          // بعد 10 أسئلة + 5 إجابات نعم: 65% فرصة
          guessChance = 0.65;
        }
        if (computerQuestionsCount >= 12) {
          // بعد 12 سؤال: 85% فرصة (كثير جداً)
          guessChance = 0.85;
        }

        // قرار عشوائي للتخمين بناءً على التحليل
        final shouldTryToGuess = random.nextDouble() < guessChance;

        if (shouldTryToGuess && mounted) {
          print('🎲 Computer decided to guess!');
          print('   📊 Questions: $computerQuestionsCount');
          print('   ✅ YES answers: $yesAnswers');
          print(
            '   🎯 Guess chance: ${(guessChance * 100).toStringAsFixed(0)}%',
          );
          await _computerMakeGuess();
          return;
        }

        // الكمبيوتر يطرح سؤال آخر
        setState(() {
          isVerifying = true;
          lastQuestion = AppStrings.t(context, 'thinking');
          showResult = true;
        });

        // توليد سؤال ذكي باستخدام الذكاء الاصطناعي
        final question = await _generateSmartComputerQuestion();

        if (question != null && mounted) {
          setState(() {
            lastQuestion = question;
          });

          // الذكاء الاصطناعي يجيب تلقائياً
          await _answerComputerQuestion(false);
        } else if (mounted) {
          // في حالة فشل توليد السؤال، استخدم سؤال افتراضي
          setState(() {
            lastQuestion = _generateComputerQuestion();
          });
          await _answerComputerQuestion(false);
        }
      }
    });
  }

  Future<void> _computerMakeGuess() async {
    setState(() {
      isVerifying = true;
      lastQuestion = 'الكمبيوتر يحاول التخمين...';
      showResult = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    try {
      // جمع المعلومات من الأسئلة السابقة
      final computerQuestions = askedQuestions
          .where((q) => q.askedBy == 'computer')
          .map((q) => {'question': q.question, 'answer': q.answer})
          .toList();

      // الذكاء الاصطناعي يخمن اسم اللاعب
      final guessedName = await _gemini.guessPlayerName(
        previousQuestions: computerQuestions,
      );

      if (guessedName != null && mounted) {
        // التحقق من التخمين
        final isCorrect = await _gemini.verifyPlayerGuess(
          guessedName: guessedName,
          correctName: playerPlayer.name,
          playerInfo: {
            'nationality': playerPlayer.nationality,
            'position': playerPlayer.position,
            'league': playerPlayer.league,
          },
        );

        setState(() {
          isVerifying = false;
        });

        if (isCorrect) {
          // الكمبيوتر فاز!
          _endRound(false);
        } else {
          // خطأ في التخمين - استمر في اللعب
          if (!mounted) return;

          // Removed SnackBar

          // عودة لدور اللاعب
          setState(() {
            showResult = false;
            isPlayerTurn = true;
          });
          _startTimer();
        }
      } else {
        // فشل التخمين، استمر في طرح الأسئلة
        setState(() {
          isVerifying = false;
          showResult = false;
          isPlayerTurn = true;
        });
        _startTimer();
      }
    } catch (e) {
      print('❌ Error in computer guess: $e');
      setState(() {
        isVerifying = false;
        showResult = false;
        isPlayerTurn = true;
      });
      _startTimer();
    }
  }

  Future<String?> _generateSmartComputerQuestion() async {
    try {
      // جمع الأسئلة السابقة التي طرحها الكمبيوتر
      final computerQuestions = askedQuestions
          .where((q) => q.askedBy == 'computer')
          .map((q) => {'question': q.question, 'answer': q.answer})
          .toList();

      // الحصول على اللغة الحالية
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;

      // الكمبيوتر يولد سؤال بدون معرفة اللاعب (عادل!)
      final question = await _gemini.generateBlindQuestion(
        previousQuestions: computerQuestions,
        language: language,
      );

      return question;
    } catch (e) {
      print('❌ Error generating smart question: $e');
      return null;
    }
  }

  String _generateComputerQuestion() {
    final questions = [
      'هل اللاعب من أوروبا؟',
      'هل اللاعب مهاجم؟',
      'هل اللاعب يلعب في الدوري الإنجليزي؟',
      'هل عمر اللاعب أكثر من 30 سنة؟',
      'هل اللاعب من أمريكا الجنوبية؟',
      'هل اللاعب لاعب وسط؟',
      'هل اللاعب يلعب في الدوري السعودي؟',
      'هل اللاعب من إسبانيا؟',
      'هل اللاعب فاز بدوري الأبطال؟',
      'هل اللاعب معتزل؟',
    ];

    // اختيار سؤال لم يُسأل من قبل
    final availableQuestions = questions
        .where((q) => !askedQuestions.any((aq) => aq.question == q))
        .toList();

    if (availableQuestions.isEmpty) {
      return 'هل اللاعب مشهور عالمياً؟';
    }

    availableQuestions.shuffle();
    return availableQuestions.first;
  }

  Future<void> _answerComputerQuestion(bool userAnswer) async {
    timer?.cancel();

    setState(() {
      isVerifying = true;
    });

    try {
      // الذكاء الاصطناعي يتحقق من الإجابة الحقيقية
      final correctAnswer = await _gemini.verifyQuestionAnswer(
        question: lastQuestion!,
        playerInfo: {
          'name': playerPlayer.name,
          'nationality': playerPlayer.nationality,
          'position': playerPlayer.position,
          'league': playerPlayer.league,
          'age': playerPlayer.age,
          'club': playerPlayer.club,
          'isRetired': playerPlayer.isRetired,
        },
      );

      setState(() {
        isVerifying = false;
        askedQuestions.add(
          GameQuestion(
            question: lastQuestion!,
            askedBy: 'computer',
            answer: correctAnswer,
            timestamp: DateTime.now(),
          ),
        );
        lastAnswer = correctAnswer;
      });

      // بعد ثانيتين، دور اللاعب
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showResult = false;
            isPlayerTurn = true;
          });
          _startTimer();
        }
      });
    } catch (e) {
      setState(() {
        isVerifying = false;
      });

      if (!mounted) return;
      // Removed SnackBar
    }
  }

  void _makeGuess(bool isPlayer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isPlayer
              ? AppStrings.t(context, 'guess_player_name')
              : AppStrings.t(context, 'computer_guessing'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPlayer
                  ? AppStrings.t(context, 'enter_player_name')
                  : AppStrings.t(context, 'computer_is_thinking'),
            ),
            if (isPlayer) ...[
              const SizedBox(height: 16),
              TextField(
                controller: guessController,
                decoration: InputDecoration(
                  hintText: AppStrings.t(context, 'player_name'),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              guessController.clear();
            },
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          if (isPlayer)
            ElevatedButton(
              onPressed: () => _verifyGuess(),
              child: Text(AppStrings.t(context, 'submit')),
            ),
        ],
      ),
    );
  }

  Future<void> _verifyGuess() async {
    final guess = guessController.text.trim();
    if (guess.isEmpty) return;

    Navigator.pop(context);

    setState(() {
      isVerifying = true;
    });

    try {
      // التحقق من التخمين باستخدام Gemini
      final isCorrect = await _gemini.verifyPlayerGuess(
        guessedName: guess,
        correctName: computerPlayer.name,
        playerInfo: {
          'nationality': computerPlayer.nationality,
          'position': computerPlayer.position,
          'league': computerPlayer.league,
        },
      );

      setState(() {
        isVerifying = false;
      });

      if (isCorrect) {
        _endRound(true);
      } else {
        // خطأ في التخمين - لكن اللعبة تستمر
        if (!mounted) return;
        // Removed SnackBar
      }

      guessController.clear();
    } catch (e) {
      setState(() {
        isVerifying = false;
      });

      if (!mounted) return;
      // Removed SnackBar
    }
  }

  void _endRound(bool playerWon) {
    timer?.cancel();
    setState(() {
      gameEnded = true;
      if (playerWon) {
        playerScore++;
      } else {
        computerScore++;
      }
    });

    _showGameOverDialog(playerWon);
  }

  void _showGameOverDialog(bool playerWon) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _GameOverScreen(
            playerWon: playerWon,
            playerScore: playerScore,
            computerScore: computerScore,
            playerName: playerPlayer.name,
            computerName: computerPlayer.name,
            onPlayAgain: () {
              Navigator.pop(context);
              setState(() {
                _initializePlayers();
                askedQuestions.clear();
                gameEnded = false;
                showResult = false;
                isPlayerTurn = true;
              });
              _startTimer();
            },
            onExit: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
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
          title: Text(
            AppStrings.t(context, 'guess_the_player'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Scores Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Player 2 (Computer/Friend) Score - Left
                    _buildScoreCard(
                      widget.opponentName ?? 'Computer',
                      computerScore,
                      const Color(0xFFEF4444),
                      widget.opponentName != null
                          ? Icons.person
                          : Icons.computer,
                      isDark,
                    ),

                    // Timer في الوسط
                    _buildTimer(isDark),

                    // Player 1 Score - Right
                    _buildScoreCard(
                      'You',
                      playerScore,
                      const Color(0xFF10B981),
                      Icons.person,
                      isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Player Name Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                          : [const Color(0xFF60A5FA), const Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.t(context, 'your_player_is'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        playerPlayer.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Question/Answer Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // عرض النتيجة الأخيرة
                        if (showResult && lastQuestion != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (lastAnswer ?? false)
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (lastAnswer ?? false)
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      (lastAnswer ?? false)
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: (lastAnswer ?? false)
                                          ? Colors.green
                                          : Colors.red,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        lastQuestion!,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (lastAnswer ?? false)
                                      ? AppStrings.t(context, 'answer_yes')
                                      : AppStrings.t(context, 'answer_no'),
                                  style: TextStyle(
                                    color: (lastAnswer ?? false)
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // عرض الأسئلة السابقة
                        if (askedQuestions.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(context, 'asked_questions'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...askedQuestions.reversed
                                    .take(5)
                                    .map(
                                      (q) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              q.askedBy == 'player'
                                                  ? Icons.person
                                                  : Icons.computer,
                                              size: 16,
                                              color: q.askedBy == 'player'
                                                  ? const Color(0xFF10B981)
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                q.question,
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ),
                                            Icon(
                                              q.answer
                                                  ? Icons.check
                                                  : Icons.close,
                                              size: 16,
                                              color: q.answer
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Input Area - سؤال أو أزرار الإجابة
                if (!showResult)
                  isPlayerTurn
                      ? _buildQuestionInput(theme, colorScheme)
                      : _buildAnswerButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    String name,
    int score,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)]
              : [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // صورة دائرية مع تأثيرات
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.9), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // النتيجة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // الاسم
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(bool isDark) {
    final timerColor = timeLeft <= 5 ? Colors.red : const Color(0xFFFBBF24);

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: timeLeft <= 5
              ? [Colors.red, const Color(0xFFDC2626)]
              : isDark
              ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
              : [const Color(0xFFFCD34D), const Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: timerColor.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: timeLeft <= 5
                ? [const Color(0xFFDC2626), Colors.red]
                : [timerColor.withValues(alpha: 0.9), timerColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                timeLeft <= 5 ? Icons.warning_rounded : Icons.timer_outlined,
                color: Colors.white,
                size: 26,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$timeLeft',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // زر "خمن اللاعب"
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            onPressed: isVerifying ? null : () => _makeGuess(true),
            icon: isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sports_soccer, size: 24),
            label: Text(
              isVerifying
                  ? AppStrings.t(context, 'verifying')
                  : AppStrings.t(context, 'guess_player_name'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),

        // حقل إدخال السؤال
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: questionController,
                  enabled: !isVerifying,
                  onSubmitted: (_) => _submitQuestion(),
                  decoration: InputDecoration(
                    hintText: isVerifying
                        ? AppStrings.t(context, 'verifying')
                        : AppStrings.t(context, 'ask_question'),
                    border: InputBorder.none,
                    suffixIcon: isVerifying
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF3B82F6),
                            ),
                            onPressed: _submitQuestion,
                          ),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerButtons(ThemeData theme) {

    return Column(
      children: [
        // عرض سؤال الكمبيوتر
        if (lastQuestion != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.computer, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.t(context, 'computer_asking'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lastQuestion!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // مؤشر تحميل أثناء التحقق
                if (isVerifying)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.t(context, 'ai_thinking'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

        // لا توجد أزرار - الذكاء الاصطناعي يجيب تلقائياً
      ],
    );
  }
}

// شاشة النتيجة مع أنيميشن
class _GameOverScreen extends StatefulWidget {
  final bool playerWon;
  final int playerScore;
  final int computerScore;
  final String playerName;
  final String computerName;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _GameOverScreen({
    required this.playerWon,
    required this.playerScore,
    required this.computerScore,
    required this.playerName,
    required this.computerName,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<_GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<_GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotateAnimation = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ألوان حسب النتيجة
    final primaryColor = widget.playerWon
        ? const Color(0xFF10B981) // أخضر للفوز
        : const Color(0xFFEF4444); // أحمر للخسارة

    final secondaryColor = widget.playerWon
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);

    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: Stack(
        children: [
          // خلفية متحركة
          ...List.generate(20, (index) {
            return AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                final progress =
                    (_confettiController.value + index * 0.05) % 1.0;
                final xPos = (index * 50) % size.width;
                final yPos = progress * size.height;

                return Positioned(
                  left: xPos,
                  top: yPos,
                  child: Transform.rotate(
                    angle: progress * 6.28 * 3,
                    child: Icon(
                      index % 3 == 0
                          ? Icons.sports_soccer
                          : index % 3 == 1
                          ? Icons.star
                          : Icons.favorite,
                      color: primaryColor.withValues(alpha: 0.3),
                      size: 20 + (index % 3) * 10,
                    ),
                  ),
                );
              },
            );
          }),

          // المحتوى الرئيسي
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.9),
                        secondaryColor.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة النتيجة
                      AnimatedBuilder(
                        animation: _rotateAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.playerWon
                                    ? Icons.emoji_events
                                    : Icons.sentiment_dissatisfied,
                                size: 70,
                                color: primaryColor,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // النص الرئيسي
                      Text(
                        widget.playerWon
                            ? AppStrings.t(context, 'you_win')
                            : AppStrings.t(context, 'computer_wins'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // النتيجة النهائية
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${widget.playerScore} - ${widget.computerScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // أسماء اللاعبين
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.t(context, 'your_player'),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        widget.playerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.computer,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.t(
                                          context,
                                          'computer_player',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        widget.computerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // الأزرار
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onExit,
                              icon: const Icon(Icons.exit_to_app),
                              label: Text(
                                AppStrings.t(context, 'exit'),
                                style: const TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onPlayAgain,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                AppStrings.t(context, 'play_again'),
                                style: const TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 5,
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
        ],
      ),
    );
  }
}
