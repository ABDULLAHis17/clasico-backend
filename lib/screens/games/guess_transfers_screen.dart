import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../models/ai_question_types.dart';
import '../../services/gemini_service_extended.dart';
import '../../services/settings_service.dart';
import '../../services/score_service.dart';
import '../../utils/app_strings.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../widgets/game_pause_menu.dart';

class GuessTransfersScreen extends StatefulWidget {
  final bool isOnlineMode;
  final bool isInFullChallenge;
  final int initialPlayerScore;
  final int initialComputerScore;

  const GuessTransfersScreen({
    Key? key,
    this.isOnlineMode = false,
    this.isInFullChallenge = false,
    this.initialPlayerScore = 0,
    this.initialComputerScore = 0,
  }) : super(key: key);

  @override
  State<GuessTransfersScreen> createState() => _GuessTransfersScreenState();
}

class _GuessTransfersScreenState extends State<GuessTransfersScreen> {
  final GeminiServiceExtended _geminiService = GeminiServiceExtended();
  final SettingsService _settings = SettingsService();
  final ScoreService _scoreService = ScoreService();

  List<AITransferQuestion> questions = [];
  int currentQuestionIndex = 0;
  late int playerScore;
  late int computerScore;
  bool showTransfers = false;
  int countdown = 3;
  bool playerAnswered = false;
  bool computerAnswered = false;
  TextEditingController answerController = TextEditingController();
  Timer? computerTimer;
  Timer? countdownTimer;
  bool? lastAnswerCorrect;
  String? computerAnswer; // ✅ إجابة الكمبيوتر
  bool? computerAnswerCorrect; // ✅ هل إجابة الكمبيوتر صحيحة
  bool isLoading = true;
  String? loadingError;

  // Speech to Text
  stt.SpeechToText? _speech; // ✅ جعله nullable
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    playerScore = widget.initialPlayerScore;
    computerScore = widget.initialComputerScore;
    _loadQuestions();
  }

  @override
  void dispose() {
    computerTimer?.cancel();
    countdownTimer?.cancel();
    answerController.dispose();
    _speech?.stop(); // ✅ استخدام safe navigation
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      isLoading = true;
      loadingError = null;
    });

    try {
      print('🔄 Loading transfer questions...');
      final loadedQuestions = await _geminiService.generateTransferQuestions(
        count: widget.isInFullChallenge ? 5 : 10, // ✅ 5 أسئلة في Full Challenge
        difficulty: 'medium',
        language: _settings
            .getActualLanguageCode(), // ✅ الحصول على اللغة الفعلية
      );

      if (!mounted) return;

      if (loadedQuestions.isEmpty) {
        // ✅ إذا فشلت حتى الأسئلة الاحتياطية، أظهر رسالة خطأ
        setState(() {
          loadingError = AppStrings.t(context, 'error_loading_questions');
          isLoading = false;
        });
        return;
      }

      setState(() {
        questions = loadedQuestions;
        isLoading = false;
        currentQuestionIndex = 0;
      });

      _startQuestion();
    } catch (e) {
      print('❌ Error loading questions: $e');
      if (!mounted) return;

      // ✅ رسالة خطأ واضحة
      setState(() {
        loadingError = AppStrings.t(context, 'error_loading_questions');
        isLoading = false;
      });
    }
  }

  void _startQuestion() {
    setState(() {
      showTransfers = false;
      countdown = 3;
      playerAnswered = false;
      computerAnswered = false;
      lastAnswerCorrect = null;
      computerAnswer = null; // ✅ مسح إجابة الكمبيوتر
      computerAnswerCorrect = null; // ✅ مسح حالة إجابة الكمبيوتر
      answerController.clear();
    });
    _startCountdown();
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          showTransfers = true;
        });
        _startComputerTimer();
      }
    });
  }

  void _startComputerTimer() {
    computerTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !playerAnswered) {
        _computerGuess();
      }
    });
  }

  Future<void> _submitPlayerAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty) return;

    // ✅ التحقق من صحة الفهرس
    if (currentQuestionIndex >= questions.length) return;

    // Stop listening if microphone is active
    if (_isListening) {
      await _stopListening();
    }

    computerTimer?.cancel();

    // Show loading indicator
    setState(() {
      playerAnswered = true;
      lastAnswerCorrect = null; // Loading state
    });

    try {
      final currentQuestion = questions[currentQuestionIndex];

      // Use AI to validate the answer
      print(
        '🤖 Validating answer with AI: "$answer" vs "${currentQuestion.playerName}"',
      );
      final isCorrect = await _geminiService.validatePlayerName(
        playerAnswer: answer,
        correctPlayerName: currentQuestion.playerName,
        language: _settings
            .getActualLanguageCode(), // ✅ الحصول على اللغة الفعلية
      );

      if (!mounted) return;

      setState(() {
        lastAnswerCorrect = isCorrect;
        if (isCorrect) {
          playerScore++;
        }
      });

      if (!isCorrect) {
        // ✨ عرض رسالة تمرير السؤال
        if (mounted) {
          // Removed SnackBar
        }

        // تأخير قبل أن يبدأ الكمبيوتر
        await Future.delayed(const Duration(milliseconds: 1500));
        await _computerGuess();
      } else {
        _nextQuestion();
      }
    } catch (e) {
      print('❌ Error in _submitPlayerAnswer: $e');
      // ✅ Fallback: في حالة الخطأ، اعتبرها إجابة خاطئة
      if (!mounted) return;
      setState(() {
        lastAnswerCorrect = false;
      });
      await _computerGuess();
    }
  }

  Future<void> _computerGuess() async {
    if (computerAnswered) return;

    // ✅ التحقق من صحة الفهرس
    if (currentQuestionIndex >= questions.length) return;

    setState(() {
      computerAnswered = true;
      // ✨ مسح الإجابة الخاطئة للاعب
      answerController.clear();
    });

    // تأخير تفكير الكمبيوتر (أطول قليلاً للواقعية)
    await Future.delayed(Duration(seconds: Random().nextInt(2) + 2));

    if (!mounted) return;

    final successChance = 0.5;
    final willGuessCorrectly = Random().nextDouble() < successChance;
    final currentQuestion = questions[currentQuestionIndex];

    setState(() {
      if (willGuessCorrectly) {
        // ✅ الكمبيوتر أجاب بشكل صحيح
        computerScore++;
        computerAnswerCorrect = true;
        lastAnswerCorrect = false; // اللاعب أخفق
      } else {
        // الكمبيوتر أجاب بشكل خاطئ - أسماء لاعبين خاطئة
        final actualLang = _settings
            .getActualLanguageCode(); // الحصول على اللغة الفعلية
        final wrongAnswers = actualLang == 'ar'
            ? [
                'كريستيانو رونالدو',
                'ليونيل ميسي',
                'نيمار جونيور',
                'كيليان مبابي',
                'إرلينغ هالاند',
                'فيرجيل فان دايك',
              ]
            : actualLang == 'en'
            ? [
                'Cristiano Ronaldo',
                'Lionel Messi',
                'Neymar Jr',
                'Kylian Mbappé',
                'Erling Haaland',
                'Virgil Van Dijk',
              ]
            : [
                'كريستيانو رونالدو',
                'ليونيل ميسي',
                'نيمار جونيور',
                'كيليان مبابي',
                'كيفن دي بروين',
                'إرلينغ هالاند',
                'فيرجيل فان دايك',
                'Mohamed Salah',
                'Arda Turan',
                'Hakan Çalhanoğlu',
                'Cengiz Ünder',
                'Merih Demiral',
                'Ozan Kabak',
              ];

        // إزالة الإجابة الصحيحة من القائمة (إن وجدت)
        wrongAnswers.removeWhere(
          (name) =>
              name.toLowerCase() == currentQuestion.playerName.toLowerCase(),
        );

        // اختيار إجابة خاطئة عشوائية
        if (wrongAnswers.isNotEmpty) {
          computerAnswer = wrongAnswers[Random().nextInt(wrongAnswers.length)];
        } else {
          computerAnswer = _settings.languageCode == 'ar'
              ? 'لاعب مجهول'
              : 'Unknown Player';
        }
        computerAnswerCorrect = false;
      }
    });

    // ✅ إظهار الإجابة لمدة 3 ثواني قبل الانتقال للسؤال التالي
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    _nextQuestion();
  }

  void _nextQuestion() {
    // ✅ مسح إجابة الكمبيوتر عند الانتقال للسؤال الجديد
    computerAnswer = null;
    computerAnswerCorrect = null;

    Future.delayed(const Duration(seconds: 2), () {
      // في Full Challenge: 5 أسئلة فقط
      final maxQuestions = widget.isInFullChallenge ? 5 : questions.length;
      final questionsCompleted = currentQuestionIndex + 1;

      if (widget.isInFullChallenge && questionsCompleted >= maxQuestions) {
        // انتهت الـ 5 أسئلة في Full Challenge
        _showGameOver();
      } else if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
        _startQuestion();
      } else {
        _showGameOver();
      }
    });
  }

  void _showGameOver() {
    // ✅ إلغاء جميع Timers قبل إغلاق الشاشة
    computerTimer?.cancel();
    countdownTimer?.cancel();

    if (!mounted) return;

    // حفظ النتيجة
    final isWin = playerScore > computerScore;
    _scoreService.saveGameResult(
      gameName: 'guess_transfers',
      playerScore: playerScore,
      computerScore: computerScore,
      isWin: isWin,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          playerScore > computerScore
              ? AppStrings.t(context, 'you_won')
              : AppStrings.t(context, 'you_lost'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${AppStrings.t(context, 'final_score')}: $playerScore - $computerScore',
        ),
        actions: widget.isInFullChallenge
            ? [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, {
                      'playerScore': playerScore,
                      'computerScore': computerScore,
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(AppStrings.t(context, 'continue')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, {
                      'playerScore': playerScore,
                      'computerScore': computerScore,
                    });
                  },
                  child: Text(AppStrings.t(context, 'exit')),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadQuestions();
                  },
                  child: Text(AppStrings.t(context, 'play_again')),
                ),
              ],
      ),
    );
  }

  // ========== Speech to Text Functions ==========



  Future<void> _startListening() async {
    if (!_speechAvailable) {
      // Removed SnackBar
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    setState(() => _isListening = true);

    String localeId;
    final actualLang = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
    switch (actualLang) {
      case 'ar':
        localeId = 'ar-SA';
        break;
      case 'tr':
        localeId = 'tr-TR';
        break;
      default:
        localeId = 'en-US';
    }

    await _speech!.listen(
      onResult: (result) {
        setState(() {
          answerController.text = result.recognizedWords;
        });

        if (result.finalResult) {
          _stopListening();
          // Auto-submit after getting final result
          Future.delayed(const Duration(milliseconds: 500), () {
            if (answerController.text.isNotEmpty) {
              _submitPlayerAnswer();
            }
          });
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> _stopListening() async {
    if (_isListening && _speech != null) {
      await _speech!.stop();
      setState(() => _isListening = false);
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1a1a2e)
        : const Color(0xFFf5f5f5);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  void _showPauseMenu() {
    if (_isPaused) return;

    setState(() => _isPaused = true);
    computerTimer?.cancel();
    countdownTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseMenu(
        gameTitle: AppStrings.t(context, 'guess_transfers'),
        onResume: () {
          setState(() => _isPaused = false);
          _loadQuestions();
        },
        onRestart: () {
          Navigator.pop(context); // إغلاق الـ dialog أولاً
          setState(() {
            _isPaused = false;
            currentQuestionIndex = 0;
            playerScore = widget.initialPlayerScore;
            computerScore = widget.initialComputerScore;
          });
          _loadQuestions();
        },
        onExit: () {
          Navigator.pop(context); // إغلاق الـ dialog
          Navigator.pop(context); // الخروج من اللعبة نهائياً
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF10B981)),
              const SizedBox(height: 24),
              Text(
                AppStrings.t(context, 'ai_loading_questions'),
                style: TextStyle(fontSize: 18, color: _getTextColor(context)),
              ),
            ],
          ),
        ),
      );
    }

    if (loadingError != null) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                loadingError!,
                style: TextStyle(color: _getTextColor(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: Text(AppStrings.t(context, 'retry')),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ التحقق من أن الأسئلة موجودة والفهرس صحيح
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                AppStrings.t(context, 'error_loading_questions'),
                style: TextStyle(color: _getTextColor(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: Text(AppStrings.t(context, 'retry')),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.t(context, 'guess_transfers'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getTextColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
              ),
              child: const Icon(Icons.pause_rounded, color: Color(0xFF8B5CF6)),
            ),
            onPressed: _showPauseMenu,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Scores
            _buildHeader(),
            const SizedBox(height: 24),

            // Main Content
            Expanded(
              child: !showTransfers
                  ? _buildCountdown()
                  : _buildTransfersView(currentQuestion),
            ),

            // Answer Display
            if (lastAnswerCorrect != null && playerAnswered)
              _buildAnswerResult(currentQuestion),

            // ✨ عرض من دوره الآن
            if ((playerAnswered &&
                    lastAnswerCorrect == false &&
                    computerAnswered &&
                    computerAnswer == null) ||
                (!playerAnswered && !computerAnswered))
              _buildTurnIndicator(
                isComputerTurn:
                    playerAnswered &&
                    lastAnswerCorrect == false &&
                    computerAnswered &&
                    computerAnswer == null,
              ),

            // ✅ عرض إجابة الكمبيوتر
            if (computerAnswer != null && !playerAnswered)
              _buildComputerAnswerResult(currentQuestion),

            const SizedBox(height: 16),

            // Input Field
            if (!playerAnswered && !computerAnswered && showTransfers)
              _buildAnswerInput(),

            if (computerAnswered && !playerAnswered && computerAnswer == null)
              _buildComputerThinking(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(
          AppStrings.t(context, 'computer'),
          computerScore,
          Colors.red,
          false,
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.swap_horiz, color: Colors.white),
        ),
        _buildPlayerCard(
          AppStrings.t(context, 'you'),
          playerScore,
          const Color(0xFF10B981),
          true,
        ),
      ],
    );
  }

  Widget _buildPlayerCard(String name, int score, Color color, bool isPlayer) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(
              isPlayer ? Icons.person : Icons.smart_toy,
              color: color,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getTextColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.t(context, 'ready'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                countdown > 0 ? countdown.toString() : 'GO!',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransfersView(AITransferQuestion question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.t(context, 'guess_player_name'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getTextColor(context),
          ),
        ),
        const SizedBox(height: 24),
        // عرض الأندية عمودياً في صفحة واحدة
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(question.clubs.length * 2 - 1, (index) {
                if (index.isOdd) {
                  // السهم
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Icon(
                              Icons.arrow_downward,
                              size: 32 * value,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // النادي
                  final clubIndex = index ~/ 2;
                  return _buildClubCard(question.clubs[clubIndex], clubIndex);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubCard(String clubName, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Transform.scale(
            scale: 0.5 + (0.5 * value),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        clubName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerResult(AITransferQuestion question) {
    // Show loading state while AI is validating
    if (lastAnswerCorrect == null && playerAnswered) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '🤖 ${AppStrings.t(context, 'ai_checking_answer')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lastAnswerCorrect == true
            ? const Color(0xFF10B981).withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lastAnswerCorrect == true
              ? const Color(0xFF10B981)
              : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            lastAnswerCorrect == true ? Icons.check_circle : Icons.cancel,
            color: lastAnswerCorrect == true
                ? const Color(0xFF10B981)
                : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              question.playerName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: lastAnswerCorrect == true
                    ? const Color(0xFF10B981)
                    : Colors.red,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputerAnswerResult(AITransferQuestion question) {
    // ✅ عرض إجابة الكمبيوتر
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: computerAnswerCorrect == true
            ? Colors.red.withValues(alpha: 0.2) // أحمر للصحيح (الكمبيوتر فاز)
            : const Color(
                0xFF10B981,
              ).withValues(alpha: 0.2), // أخضر للخطأ (اللاعب فاز)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: computerAnswerCorrect == true
              ? Colors.red
              : const Color(0xFF10B981),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_toy,
                color: computerAnswerCorrect == true
                    ? Colors.red
                    : const Color(0xFF10B981),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                computerAnswerCorrect == true
                    ? '🤖 ${AppStrings.t(context, 'computer_answered_correctly')}'
                    : '🤖 ${AppStrings.t(context, 'computer_answered_wrong')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: computerAnswerCorrect == true
                      ? Colors.red
                      : const Color(0xFF10B981),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  computerAnswerCorrect == true
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: computerAnswerCorrect == true
                      ? Colors.red
                      : const Color(0xFF10B981),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    computerAnswer ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(context),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (computerAnswerCorrect == false) ...[
            const SizedBox(height: 8),
            Text(
              '✅ ${AppStrings.t(context, 'correct_answer_is')}: ${question.playerName}', // ✅ اسم اللاعب الصحيح
              style: TextStyle(
                color: _getTextColor(context).withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: answerController,
              onSubmitted: (_) => _submitPlayerAnswer(),
              style: TextStyle(color: _getTextColor(context)),
              decoration: InputDecoration(
                hintText: AppStrings.t(context, 'player_name'),
                hintStyle: TextStyle(
                  color: _getTextColor(context).withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF10B981)),
                  onPressed: _submitPlayerAnswer,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Microphone Button
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isListening
                  ? [Colors.red, Colors.redAccent]
                  : [const Color(0xFF10B981), const Color(0xFF059669)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isListening ? Colors.red : const Color(0xFF10B981))
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _startListening,
          ),
        ),
      ],
    );
  }

  Widget _buildComputerThinking() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.red),
        const SizedBox(width: 16),
        Text(
          AppStrings.t(context, 'computer_thinking'),
          style: TextStyle(color: _getTextColor(context)),
        ),
      ],
    );
  }

  Widget _buildTurnIndicator({required bool isComputerTurn}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComputerTurn
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComputerTurn ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComputerTurn ? Icons.computer : Icons.person,
            color: isComputerTurn ? Colors.red : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            isComputerTurn
                ? AppStrings.t(context, 'computer_turn')
                : AppStrings.t(context, 'your_turn'),
            style: TextStyle(
              color: isComputerTurn ? Colors.red : Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
