import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../models/ai_question_types.dart';
import '../../services/gemini_service_extended.dart';
import '../../services/settings_service.dart';
import '../../services/score_service.dart';
import '../../utils/app_strings.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/game_pause_menu.dart';

// ========== الحالات ==========
enum GameState {
  countdown,
  showQuestion,
  playerAnswer,
  computerAnswer,
  analyzing,
  gameOver,
}

enum Turn { none, player, computer }

enum Chance { first, second }

// ========== الشاشة الرئيسية ==========
class TheBellScreen extends StatefulWidget {
  final bool isOnlineMode;
  final bool isInFullChallenge;
  final int initialPlayerScore;
  final int initialComputerScore;

  const TheBellScreen({
    Key? key,
    this.isOnlineMode = false,
    this.isInFullChallenge = false,
    this.initialPlayerScore = 0,
    this.initialComputerScore = 0,
  }) : super(key: key);

  @override
  State<TheBellScreen> createState() => _TheBellScreenState();
}

class _TheBellScreenState extends State<TheBellScreen>
    with TickerProviderStateMixin {
  // الخدمات
  final GeminiServiceExtended _geminiService = GeminiServiceExtended();
  final SettingsService _settings = SettingsService();
  final ScoreService _scoreService = ScoreService();
  final Set<String> _usedQuestions = {};

  // الأسئلة
  List<AIOpenEndedQuestion> aiQuestions = [];
  int currentQuestionIndex = 0;
  AIOpenEndedQuestion? currentQuestion;

  // النتيجة
  late int playerScore;
  late int computerScore;
  static const int winningScore = 10;

  // الحالة
  GameState currentState = GameState.countdown;
  Turn currentTurn = Turn.none;
  Chance currentChance = Chance.first;

  // العداد
  int countdown = 3;
  Timer? countdownTimer;

  // الجرس والأنيميشن
  AnimationController? bellAnimation;
  Timer? computerReactionTimer;
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;

  // الإجابة
  TextEditingController answerController = TextEditingController();
  String? analysisMessage;
  bool isCorrect = false;
  bool isLoadingQuestions = false;
  String? loadingError;

  // العداد التنازلي للإجابة
  Timer? answerTimer;
  int answerTimeLeft = 10;

  // الصوت
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    playerScore = widget.initialPlayerScore;
    computerScore = widget.initialComputerScore;
    _speech = stt.SpeechToText();
    _loadQuestions();
    _startCountdown();
  }

  @override
  void dispose() {
    bellAnimation?.dispose();
    scaleController.dispose();
    countdownTimer?.cancel();
    computerReactionTimer?.cancel();
    answerTimer?.cancel();
    answerController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ========== دوال التهيئة ==========

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }



  Future<void> _loadQuestions() async {
    setState(() {
      isLoadingQuestions = true;
      loadingError = null;
    });

    try {
      final questions = await _geminiService.generateOpenEndedQuestions(
        count: 10,
        difficulty: 'medium',
        language: _settings
            .getActualLanguageCode(), // ✅ الحصول على اللغة الفعلية
        usedQuestions: _usedQuestions,
      );

      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          loadingError = AppStrings.t(context, 'error_loading_questions');
          isLoadingQuestions = false;
        });
        return;
      }

      final newQuestions = questions
          .where((q) => !_usedQuestions.contains(q.questionText))
          .toList();

      if (newQuestions.isEmpty) {
        _usedQuestions.clear();
        newQuestions.addAll(questions);
      }

      for (var q in newQuestions) {
        _usedQuestions.add(q.questionText);
      }

      setState(() {
        aiQuestions = newQuestions;
        isLoadingQuestions = false;
        currentQuestionIndex = 0;
      });

      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingError = '${AppStrings.t(context, 'error')}: $e';
        isLoadingQuestions = false;
      });
    }
  }

  // ========== دوال اللعب ==========

  void _startCountdown() {
    setState(() {
      currentState = GameState.countdown;
      countdown = 3;
      currentTurn = Turn.none;
      currentChance = Chance.first;
      analysisMessage = null;
      answerController.clear();
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        countdown--;
      });

      if (countdown == 0) {
        timer.cancel();
        _showQuestion();
      }
    });
  }

  void _showQuestion() {
    if (currentQuestionIndex >= aiQuestions.length) {
      _loadQuestions();
      return;
    }

    setState(() {
      currentState = GameState.showQuestion;
      currentQuestion = aiQuestions[currentQuestionIndex];
    });

    _startComputerReaction();
  }

  void _startComputerReaction() {
    final reactionTime = Random().nextInt(2000) + 500;
    computerReactionTimer = Timer(Duration(milliseconds: reactionTime), () {
      if (mounted &&
          currentState == GameState.showQuestion &&
          currentTurn == Turn.none) {
        _onComputerBellPressed();
      }
    });
  }

  void _onPlayerBellPressed() {
    if (currentState != GameState.showQuestion) return;
    if (currentTurn != Turn.none) return;

    computerReactionTimer?.cancel();
    bellAnimation?.forward().then((_) => bellAnimation?.reverse());

    setState(() {
      currentTurn = Turn.player;
      currentState = GameState.playerAnswer;
      answerTimeLeft = 10; // ✅ بدء العداد من 10
    });

    _startAnswerTimer(); // ✅ بدء العداد التنازلي
  }

  void _onComputerBellPressed() {
    if (currentState != GameState.showQuestion) return;
    if (currentTurn != Turn.none) return;

    bellAnimation?.forward().then((_) => bellAnimation?.reverse());

    setState(() {
      currentTurn = Turn.computer;
      currentState = GameState.computerAnswer;
    });

    _computerAnswer();
  }

  // ========== العداد التنازلي ==========

  void _startAnswerTimer() {
    answerTimer?.cancel();
    answerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        answerTimeLeft--;
      });

      if (answerTimeLeft <= 0) {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() async {
    if (!mounted || currentState != GameState.playerAnswer) return;

    if (_isListening) await _stopListening();

    setState(() {
      currentState = GameState.analyzing;
      answerController.clear();
      analysisMessage =
          '⏰ ${AppStrings.t(context, 'time_out')}\n❌ ${AppStrings.t(context, 'didnt_answer_in_time')}';
      isCorrect = false;
    });

    // إعطاء الفرصة للكمبيوتر
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _giveOpponentChance();
    });
  }

  Future<void> _submitAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty) return;

    answerTimer?.cancel(); // ✅ إيقاف العداد
    if (_isListening) await _stopListening();

    setState(() {
      currentState = GameState.analyzing;
    });

    try {
      final validation = await _geminiService.validateAnswer(
        question: currentQuestion!.questionText,
        playerAnswer: answer,
        acceptableAnswers: currentQuestion!.acceptableAnswers,
        language: _settings
            .getActualLanguageCode(), // ✅ الحصول على اللغة الفعلية
      );

      if (!mounted) return;

      final correct = validation['isCorrect'] as bool;

      setState(() {
        isCorrect = correct;
        answerController.clear();
      });

      if (correct) {
        playerScore++;
        analysisMessage = '✅ ${AppStrings.t(context, 'correct_answer')} +1';

        if (playerScore >= winningScore) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _gameOver();
          });
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _nextQuestion();
          });
        }
      } else {
        analysisMessage =
            '❌ ${AppStrings.t(context, 'wrong_answer')}\n${AppStrings.t(context, 'correct_answer_is')}: ${currentQuestion!.acceptableAnswers.first}';

        if (currentChance == Chance.first) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _giveOpponentChance();
          });
        } else {
          analysisMessage = '❌ ${AppStrings.t(context, 'both_failed')}';
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _nextQuestion();
          });
        }
      }
    } catch (e) {
      setState(() {
        analysisMessage = '${AppStrings.t(context, 'error')}: $e';
      });
    }
  }

  Future<void> _computerAnswer() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final willAnswerCorrectly = Random().nextDouble() < 0.6;

    // ✅ اختيار إجابة الكمبيوتر
    String computerAnswerText;
    if (willAnswerCorrectly) {
      // إجابة صحيحة - نختار من القائمة الصحيحة
      computerAnswerText =
          currentQuestion!.acceptableAnswers[Random().nextInt(
            currentQuestion!.acceptableAnswers.length,
          )];
    } else {
      // إجابة خاطئة - نختار إجابة عشوائية مختلفة
      final wrongAnswers = [
        'Barcelona',
        'Real Madrid',
        'Manchester',
        'Bayern',
        'Liverpool',
        'Paris',
        'Juventus',
      ];
      computerAnswerText = wrongAnswers[Random().nextInt(wrongAnswers.length)];
    }

    setState(() {
      isCorrect = willAnswerCorrectly;
      currentState = GameState.analyzing; // ✅ تغيير الحالة لعرض النتيجة
    });

    if (willAnswerCorrectly) {
      computerScore++;
      setState(() {
        analysisMessage =
            '🤖 ${AppStrings.t(context, 'computer_answered')}: "$computerAnswerText"\n✅ ${AppStrings.t(context, 'correct_answer')} +1';
      });

      if (computerScore >= winningScore) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _gameOver();
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _nextQuestion();
        });
      }
    } else {
      setState(() {
        analysisMessage =
            '🤖 ${AppStrings.t(context, 'computer_answered')}: "$computerAnswerText"\n❌ ${AppStrings.t(context, 'wrong_answer')}\n\n${AppStrings.t(context, 'correct_answer_is')}: ${currentQuestion!.acceptableAnswers.first}';
      });

      if (currentChance == Chance.first) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _giveOpponentChance();
        });
      } else {
        setState(() {
          analysisMessage =
              '🤖 ${AppStrings.t(context, 'computer_answered')}: "$computerAnswerText"\n❌ ${AppStrings.t(context, 'both_failed')}';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _nextQuestion();
        });
      }
    }
  }

  void _giveOpponentChance() {
    setState(() {
      currentChance = Chance.second;
      currentTurn = currentTurn == Turn.player ? Turn.computer : Turn.player;
      currentState = currentTurn == Turn.player
          ? GameState.playerAnswer
          : GameState.computerAnswer;
      analysisMessage = currentTurn == Turn.player
          ? '🎯 ${AppStrings.t(context, 'opponent_chance')}'
          : '🤖 ${AppStrings.t(context, 'computer_chance')}';
    });

    if (currentTurn == Turn.computer) {
      _computerAnswer();
    }
  }

  void _nextQuestion() {
    // في Full Challenge: 5 أسئلة فقط
    final maxQuestions = widget.isInFullChallenge ? 5 : aiQuestions.length;
    final questionsCompleted = currentQuestionIndex + 1;

    if (widget.isInFullChallenge && questionsCompleted >= maxQuestions) {
      // انتهت الـ 5 أسئلة في Full Challenge
      _gameOver();
    } else {
      currentQuestionIndex++;
      _startCountdown();
    }
  }

  void _gameOver() {
    // ✅ إلغاء جميع Timers قبل إغلاق الشاشة
    countdownTimer?.cancel();
    computerReactionTimer?.cancel();
    answerTimer?.cancel();

    if (!mounted) return;

    setState(() {
      currentState = GameState.gameOver;
    });

    // حفظ النتيجة
    final isWin = playerScore > computerScore;
    _scoreService.saveGameResult(
      gameName: 'the_bell',
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
              ? '🏆 ${AppStrings.t(context, 'you_won')}'
              : '😞 ${AppStrings.t(context, 'you_lost')}',
        ),
        content: Text(
          '${AppStrings.t(context, 'final_score')}\n\n${AppStrings.t(context, 'you')}: $playerScore\n${AppStrings.t(context, 'computer')}: $computerScore',
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
                    _resetGame();
                  },
                  child: Text(AppStrings.t(context, 'play_again')),
                ),
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
              ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      playerScore = 0;
      computerScore = 0;
      currentQuestionIndex = 0;
    });
    _startCountdown();
  }

  // ========== الصوت ==========

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      await _initializeSpeech();
    }

    setState(() => _isListening = true);

    final actualLang = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
    final localeId = actualLang == 'ar'
        ? 'ar_SA'
        : actualLang == 'en'
        ? 'en_US'
        : 'tr_TR';

    await _speech.listen(
      onResult: (result) {
        setState(() {
          answerController.text = result.recognizedWords;
        });
        if (result.finalResult) _stopListening();
      },
      onSoundLevelChange: (level) {
        setState(() => _soundLevel = level);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
  }

  // ========== الألوان حسب الثيم ==========

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1a1a2e)
        : const Color(0xFFf5f5f5);
  }



  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white;
  }

  void _showPauseMenu() {
    if (_isPaused) return;

    setState(() => _isPaused = true);
    countdownTimer?.cancel();
    answerTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseMenu(
        gameTitle: AppStrings.t(context, 'the_bell'),
        onResume: () {
          setState(() => _isPaused = false);
          _startCountdown();
        },
        onRestart: () {
          Navigator.pop(context); // إغلاق الـ dialog أولاً
          setState(() {
            _isPaused = false;
            currentQuestionIndex = 0;
            playerScore = widget.initialPlayerScore;
            computerScore = widget.initialComputerScore;
          });
          _startCountdown();
        },
        onExit: () {
          Navigator.pop(context); // إغلاق الـ dialog
          Navigator.pop(context); // الخروج من اللعبة نهائياً
        },
      ),
    );
  }

  // ========== الواجهة ==========

  @override
  Widget build(BuildContext context) {
    if (isLoadingQuestions) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).primaryColor,
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
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
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

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.t(context, 'the_bell'),
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
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildGameContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // اللاعب الأول (اليمين)
          _buildPlayerCard(
            name: AppStrings.t(context, 'you'),
            score: playerScore,
            color: Colors.green,
            isPlayer: true,
          ),
          // VS
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    color: _getTextColor(context).withValues(alpha: 0.8),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$winningScore ${AppStrings.t(context, 'points')}',
                  style: TextStyle(
                    color: _getTextColor(context).withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // اللاعب الثاني (اليسار)
          _buildPlayerCard(
            name: AppStrings.t(context, 'computer'),
            score: computerScore,
            color: Colors.red,
            isPlayer: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required int score,
    required Color color,
    required bool isPlayer,
  }) {
    return Column(
      children: [
        // الصورة + العداد
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isPlayer) ...[
              // عداد النقاط على اليسار للكمبيوتر
              _buildScoreBadge(score, color),
              const SizedBox(width: 8),
            ],
            // صورة اللاعب
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                isPlayer ? Icons.person : Icons.computer,
                size: 40,
                color: Colors.white,
              ),
            ),
            if (isPlayer) ...[
              // عداد النقاط على اليمين للاعب
              const SizedBox(width: 8),
              _buildScoreBadge(score, color),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // الاسم
        Text(
          name,
          style: TextStyle(
            color: _getTextColor(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(int score, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    if (currentState == GameState.countdown) {
      return _buildCountdown();
    } else if (currentState == GameState.showQuestion) {
      return _buildQuestionAndBell();
    } else if (currentState == GameState.playerAnswer) {
      return _buildPlayerAnswerSection();
    } else if (currentState == GameState.computerAnswer) {
      return _buildComputerAnswerSection();
    } else if (currentState == GameState.analyzing) {
      return _buildAnalyzingSection();
    }
    return const SizedBox();
  }

  Widget _buildCountdown() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Text(
              countdown == 0 ? AppStrings.t(context, 'ready') : '$countdown',
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: _getTextColor(context).withValues(alpha: value),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionAndBell() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white30
                  : Colors.grey.shade300,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Text(
            currentQuestion?.questionText ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _getTextColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _onPlayerBellPressed,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAnswerSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Text(
              '🎯 ${AppStrings.t(context, 'your_turn')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ✅ العداد التنازلي
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: answerTimeLeft <= 3 ? Colors.red : Colors.orange,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (answerTimeLeft <= 3 ? Colors.red : Colors.orange)
                      .withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$answerTimeLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentQuestion?.questionText ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: _getTextColor(context), fontSize: 20),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: answerController,
                  style: TextStyle(color: _getTextColor(context), fontSize: 18),
                  decoration: InputDecoration(
                    hintText: AppStrings.t(context, 'type_answer'),
                    hintStyle: TextStyle(
                      color: _getTextColor(context).withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: _getCardColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submitAnswer(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [Colors.red.shade400, Colors.red.shade700]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                  onPressed: _toggleListening,
                ),
              ),
            ],
          ),
          if (_isListening) ...[
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: _soundLevel.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.yellow, Colors.red],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: Text(
              AppStrings.t(context, 'submit'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputerAnswerSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Text(
              '🤖 ${AppStrings.t(context, 'computer_thinking')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAnalyzingSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isCorrect
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCorrect ? Colors.green : Colors.red).withValues(alpha: 
                    0.5,
                  ),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              analysisMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
