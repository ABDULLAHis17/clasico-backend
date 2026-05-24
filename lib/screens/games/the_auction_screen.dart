import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../models/question.dart';
import '../../data/game_questions_data.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/gemini_service_extended.dart';
import '../../services/settings_service.dart';
import '../../services/score_service.dart';
import '../../widgets/game_pause_menu.dart';

class TheAuctionScreen extends StatefulWidget {
  final bool isOnlineMode;
  final bool isInFullChallenge;
  final int initialPlayerScore;
  final int initialComputerScore;

  const TheAuctionScreen({
    Key? key,
    this.isOnlineMode = false,
    this.isInFullChallenge = false,
    this.initialPlayerScore = 0,
    this.initialComputerScore = 0,
  }) : super(key: key);

  @override
  State<TheAuctionScreen> createState() => _TheAuctionScreenState();
}

class _TheAuctionScreenState extends State<TheAuctionScreen>
    with TickerProviderStateMixin {
  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  final SettingsService _settings = SettingsService();
  final ScoreService _scoreService = ScoreService();
  List<AuctionQuestion> questions = [];
  int currentQuestionIndex = 0;
  late int playerScore;
  late int computerScore;
  int playerHearts = 3;
  int computerHearts = 3;
  int currentBid = 0;
  bool isPlayerBidding = true;
  bool auctionActive = true;
  bool answeringPhase = false;
  bool anyBidMade = false;
  bool isLoadingQuestions = true;
  Timer? timer;
  Timer? bidTimer;
  int timeLeft = 30;
  int bidTimeLeft = 5;
  bool showInitialCountdown = false;
  int initialCountdown = 3;
  TextEditingController answerController = TextEditingController();
  int playerAnswerCount = 0;
  List<String> playerAnswers = [];
  List<String> computerAnswers = [];
  bool isComputerAnswering = false;
  bool? lastAnswerCorrect;
  bool isEvaluating = false;
  String evaluationResult = '';
  bool isComputerTurn = false; // هل الدور كان للكمبيوتر؟

  // Animation Controllers
  late AnimationController _countdownController;
  late Animation<double> _scaleAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultScale;
  late Animation<double> _resultOpacity;
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulse;

  int consecutivePlayerPasses = 0;

  // Voice input
  late stt.SpeechToText _speech;
  String _voiceText = '';
  bool _isListening = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    playerScore = widget.initialPlayerScore;
    computerScore = widget.initialComputerScore;
    _loadQuestions();
    _speech = stt.SpeechToText();

    // Countdown Animation
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.elasticOut),
    );

    // Result Animation (Success/Failure)
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
    _resultOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _resultController, curve: Curves.easeIn));

    // Timer Pulse Animation (for urgency)
    _timerPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _timerPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _timerPulseController, curve: Curves.easeInOut),
    );

    _loadQuestionsFromGemini();
  }

  void _loadQuestions() {
    // Initialize empty - will be loaded from Gemini
    questions = [];
  }

  Future<void> _loadQuestionsFromGemini() async {
    setState(() => isLoadingQuestions = true);

    try {
      final language = _settings
          .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      print(
        '🎪 Loading NEW auction questions in $language (seed: $timestamp)...',
      );

      final geminiQuestions = await _gemini.generateAuctionQuestions(
        count: 20, // 20 سؤال متنوع
        language: language,
        difficulty: 'mixed', // مزيج من الصعوبات
        seed: timestamp, // seed مختلف في كل مرة = أسئلة مختلفة
      );

      if (geminiQuestions.isNotEmpty && mounted) {
        setState(() {
          questions = geminiQuestions
              .map(
                (q) => AuctionQuestion(
                  id: q['id'],
                  question: q['question'],
                  correctAnswer: q['correctAnswer'],
                  difficulty: q['difficulty'],
                ),
              )
              .toList();
          isLoadingQuestions = false;
        });
        print('✅ Loaded ${questions.length} NEW auction questions');
        _startInitialCountdown();
      } else {
        // Fallback to local data
        if (mounted) {
          setState(() {
            questions = GameQuestionsData.getAuctionQuestions();
            isLoadingQuestions = false;
          });
          _startInitialCountdown();
        }
      }
    } catch (e) {
      print('❌ Error loading questions from Gemini: $e');
      // Fallback to local data
      if (mounted) {
        setState(() {
          questions = GameQuestionsData.getAuctionQuestions();
          isLoadingQuestions = false;
        });
        _startInitialCountdown();
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    bidTimer?.cancel();
    _countdownController.dispose();
    _resultController.dispose();
    _timerPulseController.dispose();
    answerController.dispose();
    super.dispose();
  }

  void _startInitialCountdown() {
    setState(() {
      showInitialCountdown = true;
      initialCountdown = 3;
      auctionActive = false;
      answeringPhase = false;
      // ✅ مسح الإجابات من السؤال السابق
      playerAnswers.clear();
      computerAnswers.clear();
      playerAnswerCount = 0;
      evaluationResult = '';
      lastAnswerCorrect = null;
      isComputerTurn = false;
      isComputerAnswering = false;
    });

    _runInitialCountdown();
  }

  void _runInitialCountdown() {
    if (initialCountdown > 0) {
      _countdownController.reset();
      _countdownController.forward();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            initialCountdown--;
          });
          _runInitialCountdown();
        }
      });
    } else {
      setState(() {
        showInitialCountdown = false;
      });
      _startAuction();
    }
  }

  void _startAuction() {
    setState(() {
      auctionActive = true;
      answeringPhase = false;
      currentBid = 0;
      isPlayerBidding = true;
      lastAnswerCorrect = null;
      isComputerTurn = false;
      anyBidMade = false; // إعادة تعيين عند سؤال جديد
      consecutivePlayerPasses = 0; // إعادة تعيين عداد التمرير
      // ✅ مسح الإجابات من السؤال السابق
      playerAnswers.clear();
      computerAnswers.clear();
      playerAnswerCount = 0;
      isComputerAnswering = false;
    });
    _startBidTimer();
  }

  void _startBidTimer() {
    bidTimer?.cancel();
    setState(() => bidTimeLeft = 5);

    bidTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && isPlayerBidding && auctionActive) {
        setState(() {
          if (bidTimeLeft > 0) {
            bidTimeLeft--;
          } else {
            // انتهى الوقت - اللاعب اختار "0" (عدم المزايدة)
            bidTimer?.cancel();
            _playerPass(); // تمرير الدور بدون مزايدة
          }
        });
      } else {
        t.cancel();
      }
    });
  }

  void _playerBid(int amount) {
    print('👤 اللاعب يزايد بـ: $amount (السابقة: $currentBid)');

    bidTimer?.cancel();
    setState(() {
      currentBid = amount;
      isPlayerBidding = false;
      anyBidMade = true;
      consecutivePlayerPasses = 0; // إعادة تعيين العداد عند المزايدة
    });

    print('✅ تم تحديث currentBid إلى: $currentBid');

    _computerDecision();
  }

  Future<void> _computerDecision() async {
    await Future.delayed(Duration(seconds: Random().nextInt(2) + 1));

    if (!mounted) return;

    final currentQuestion = questions[currentQuestionIndex];
    final random = Random();

    // تنويع استراتيجية الكمبيوتر
    final strategies = [0.7, 0.75, 0.8, 0.85, 0.9]; // 70%-90%
    final maxSafeBid =
        (currentQuestion.correctAnswer *
                strategies[random.nextInt(strategies.length)])
            .round();

    // ✅ التأكد من أن الكمبيوتر لا يزايد بأكثر من العدد الصحيح
    final absoluteMaxBid = currentQuestion.correctAnswer;
    final safeBid = maxSafeBid > absoluteMaxBid ? absoluteMaxBid : maxSafeBid;

    // تنويع احتمال الاستسلام (20%-40%)
    final giveUpChance = 0.2 + random.nextDouble() * 0.2;

    // إذا كانت المزايدة = 0 (لم يبدأ أحد)، الكمبيوتر يبدأ أو يستسلم
    if (currentBid == 0) {
      if (random.nextDouble() < giveUpChance) {
        // الكمبيوتر يستسلم - لا أحد يريد المزايدة (0 مقابل 0)
        bidTimer?.cancel();
        setState(() {
          auctionActive = false;
          evaluationResult = 'لا مزايدة - انتقال للسؤال التالي';
        });
        // لا نقاط لأحد - انتقل للسؤال التالي
        Future.delayed(const Duration(seconds: 2), _nextQuestion);
      } else {
        // الكمبيوتر يبدأ المزايدة
        final bidIncrease = [1, 2, 3][random.nextInt(3)]; // يبدأ بـ 1-3

        print('🤖 الكمبيوتر يبدأ المزايدة بـ: $bidIncrease');

        if (mounted) {
          setState(() {
            currentBid = bidIncrease;
            isPlayerBidding = false; // أولاً يظهر "الكمبيوتر يقرر"
            anyBidMade = true;
            consecutivePlayerPasses = 0; // إعادة تعيين العداد - الكمبيوتر زايد
          });

          print('✅ تم تحديث currentBid إلى: $currentBid');

          // انتظر قليلاً قبل إعطاء الدور للاعب
          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            print('👤 الآن دور اللاعب - currentBid: $currentBid');
            setState(() {
              isPlayerBidding = true;
            });
            _startBidTimer();
          }
        }
      }
    } else if (currentBid >= safeBid || random.nextDouble() < giveUpChance) {
      // الكمبيوتر يستسلم - المزايدة عالية جداً
      bidTimer?.cancel();
      setState(() {
        auctionActive = false;
      });
      _startAnsweringPhase(true, computerGaveUp: true);
    } else {
      // الكمبيوتر يزيد المزايدة
      final bidIncrease = [1, 1, 2, 2, 3, 3, 4, 5][random.nextInt(8)];
      var newBid = currentBid + bidIncrease;

      // ✅ التأكد من عدم تجاوز العدد الصحيح
      if (newBid > absoluteMaxBid) {
        newBid = absoluteMaxBid;
      }

      print('🤖 الكمبيوتر يزيد: من $currentBid إلى $newBid (+$bidIncrease)');

      if (mounted) {
        setState(() {
          currentBid = newBid;
          isPlayerBidding = false; // أولاً يظهر "الكمبيوتر يقرر"
          anyBidMade = true;
          consecutivePlayerPasses = 0; // إعادة تعيين العداد - الكمبيوتر زايد
        });

        print('✅ تم تحديث currentBid إلى: $currentBid');

        // انتظر قليلاً قبل إعطاء الدور للاعب
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          print('👤 الآن دور اللاعب - currentBid: $currentBid');
          setState(() {
            isPlayerBidding = true;
          });
          _startBidTimer();
        }
      }
    }
  }

  void _playerPass() {
    bidTimer?.cancel();

    // زيادة عداد التمريرات المتتالية
    consecutivePlayerPasses++;

    print('⏭️ اللاعب مرر الدور (المرة $consecutivePlayerPasses)');

    // إذا مرّر مرتين متتاليتين → استسلام
    if (consecutivePlayerPasses >= 2) {
      print('🏳️ اللاعب استسلم بعد تمريرتين متتاليتين');
      setState(() {
        auctionActive = false;
      });
      _startAnsweringPhase(false, playerGaveUp: true);
      return;
    }

    // Removed SnackBar

    setState(() {
      isPlayerBidding = false;
    });
    _computerDecision();
  }

  void _playerGiveUp() {
    bidTimer?.cancel();
    setState(() {
      auctionActive = false;
    });
    _startAnsweringPhase(false, playerGaveUp: true);
  }

  void _startAnsweringPhase(
    bool playerWonAuction, {
    bool playerGaveUp = false,
    bool computerGaveUp = false,
  }) {
    // إذا استسلم الطرفان (لم تحدث أي مزايدة)
    if (!anyBidMade && playerGaveUp) {
      // لا أحد يحصل على نقطة - الانتقال للسؤال التالي مباشرة
      setState(() {
        evaluationResult = 'لا مزايدة - انتقال للسؤال التالي';
      });
      Future.delayed(const Duration(seconds: 2), _nextQuestion);
      return;
    }

    setState(() {
      answeringPhase = true;
      playerAnswerCount = 0;
      playerAnswers.clear();
      evaluationResult = '';
      lastAnswerCorrect = null;
      isComputerTurn = false;
      timeLeft = 30;
      isComputerAnswering = !playerWonAuction; // ✅ تحديد من يجاوب
    });

    if (playerWonAuction) {
      _startTimer();
    } else {
      _computerAnswers();
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            _evaluatePlayerAnswers();
          }
        });
      }
    });
  }

  void _submitAnswer() {
    final answer = answerController.text.trim();
    if (answer.isNotEmpty && !playerAnswers.contains(answer)) {
      setState(() {
        playerAnswers.add(answer);
        playerAnswerCount = playerAnswers.length;
        answerController.clear();
      });
    }
  }

  Future<void> _startVoiceInput() async {
    // طلب صلاحية الميكروفون
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      // Removed SnackBar
      return;
    }

    if (_isListening) {
      // إيقاف التسجيل
      await _speech.stop();
      setState(() => _isListening = false);

      // معالجة النص المسجل
      if (_voiceText.isNotEmpty) {
        await _processVoiceText(_voiceText);
      }
      return;
    }

    // بدء التسجيل
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted && _isListening) {
            setState(() => _isListening = false);
            if (_voiceText.isNotEmpty) {
              _processVoiceText(_voiceText);
            }
          }
        }
      },
      onError: (error) {
        print('❌ Speech error: $error');
        if (mounted) {
          setState(() => _isListening = false);
          // Removed SnackBar
        }
      },
    );

    if (!available) {
      // Removed SnackBar
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = '';
    });

    // بدء الاستماع
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: _settings.getActualLanguageCode() == 'ar'
          ? 'ar_SA'
          : 'en_US', // ✅ الحصول على اللغة الفعلية
    );
  }

  Future<void> _processVoiceText(String text) async {
    if (text.trim().isEmpty) return;

    // ✅ عرض Dialog بدلاً من حجب الواجهة
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppStrings.t(context, 'extracting_names'),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final currentQuestion = questions[currentQuestionIndex];
      final language = _settings
          .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

      // استخراج الأسماء من النص بواسطة Gemini
      print('🎤 استخراج الأسماء من: $text');

      final extractedNames = await _gemini.extractPlayerNamesFromVoice(
        voiceText: text,
        question: currentQuestion.question,
        language: language,
      );

      if (!mounted) return;

      // إغلاق Dialog
      Navigator.of(context).pop();
      setState(() {
        _voiceText = '';
      });

      if (extractedNames.isEmpty) {
        // Removed SnackBar
        return;
      }

      // إضافة الأسماء المستخرجة
      print('✅ تم استخراج ${extractedNames.length} أسماء: $extractedNames');
      setState(() {
        for (final name in extractedNames) {
          if (!playerAnswers.contains(name)) {
            playerAnswers.add(name);
          }
        }
        playerAnswerCount = playerAnswers.length;
      });

      // Removed SnackBar
    } catch (e) {
      print('❌ Error processing voice: $e');
      if (mounted) {
        // إغلاق Dialog في حالة الخطأ
        Navigator.of(context).pop();

        setState(() {
          _voiceText = '';
        });
        // Removed SnackBar
      }
    }
  }

  Future<void> _evaluatePlayerAnswers() async {
    timer?.cancel();
    setState(() {
      isEvaluating = true;
      evaluationResult = AppStrings.t(context, 'analyzing');
      lastAnswerCorrect = null; // ← إعادة تعيين لمنع عرض الأنيميشن القديم
      isComputerTurn = false;
    });

    try {
      final currentQuestion = questions[currentQuestionIndex];
      final language = _settings
          .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

      // تحليل الإجابات باستخدام Gemini
      final analysis = await _gemini.analyzeAuctionAnswers(
        question: currentQuestion.question,
        playerAnswers: playerAnswers,
        requiredCount: currentBid,
        correctCount: currentQuestion.correctAnswer,
        language: language,
      );

      if (!mounted) return;

      final correctAnswersCount = analysis['correctCount'] ?? 0;
      final isSuccess = correctAnswersCount >= currentBid;

      setState(() {
        isEvaluating = false;
        isComputerTurn = false; // دور اللاعب
        if (isSuccess) {
          evaluationResult =
              '✅ نجحت! ($correctAnswersCount/$currentBid إجابات صحيحة)';
          playerScore++;
          if (computerHearts > 0) computerHearts--;
          lastAnswerCorrect = true; // نجح اللاعب
        } else {
          evaluationResult =
              '❌ فشلت! ($correctAnswersCount/$currentBid إجابات صحيحة)';
          computerScore++;
          if (playerHearts > 0) playerHearts--;
          lastAnswerCorrect = false; // فشل اللاعب
        }
      });

      // تشغيل أنيميشن النتيجة
      _resultController.reset();
      _resultController.forward();

      // عرض النتيجة لمدة 3 ثواني
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      print('❌ Error evaluating answers: $e');
      // Fallback: التحقق من العدد فقط
      setState(() {
        isEvaluating = false;
        isComputerTurn = false; // دور اللاعب
        if (playerAnswerCount >= currentBid) {
          evaluationResult = '✅ نجحت!';
          playerScore++;
          if (computerHearts > 0) computerHearts--;
          lastAnswerCorrect = true; // نجح اللاعب
        } else {
          evaluationResult = '❌ فشلت!';
          computerScore++;
          if (playerHearts > 0) playerHearts--;
          lastAnswerCorrect = false; // فشل اللاعب
        }
      });

      // تشغيل أنيميشن النتيجة
      _resultController.reset();
      _resultController.forward();

      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      _nextQuestion();
    }
  }

  Future<void> _computerAnswers() async {
    setState(() {
      answeringPhase = true;
      timeLeft = 30;
      computerAnswers.clear();
      isEvaluating = false;
    });

    try {
      final currentQuestion = questions[currentQuestionIndex];
      final language = _settings
          .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

      // طلب إجابات من Gemini
      print('🤖 الكمبيوتر يطلب $currentBid إجابات...');

      final generatedAnswers = await _gemini.generateAuctionAnswersForComputer(
        question: currentQuestion.question,
        requiredCount: currentBid,
        language: language,
      );

      if (!mounted) return;

      print('🤖 الكمبيوتر أجاب بـ: $generatedAnswers');

      // بدء العداد 30 ثانية
      _startTimer();

      // إضافة الإجابات تدريجياً (واحدة كل 2-4 ثواني)
      final answersToAdd = generatedAnswers.take(currentBid).toList();
      for (int i = 0; i < answersToAdd.length && mounted; i++) {
        // انتظار عشوائي بين 2-4 ثواني
        final waitTime = 2 + Random().nextInt(3);
        await Future.delayed(Duration(seconds: waitTime));

        if (mounted && answeringPhase) {
          setState(() {
            computerAnswers.add(answersToAdd[i]);
          });
          print(
            '🤖 الكمبيوتر أضاف: ${answersToAdd[i]} (${computerAnswers.length}/$currentBid)',
          );
        }
      }

      // انتظار بقية الوقت أو حتى ينتهي العداد
      if (mounted && timeLeft > 0) {
        await Future.delayed(Duration(seconds: timeLeft));
      }

      timer?.cancel();

      if (!mounted) return;

      setState(() {
        answeringPhase = false;
      });

      // تقييم إجابات الكمبيوتر
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        isEvaluating = true;
        evaluationResult = AppStrings.t(context, 'evaluating_computer_answers');
      });

      final analysis = await _gemini.analyzeAuctionAnswers(
        question: currentQuestion.question,
        playerAnswers: computerAnswers,
        requiredCount: currentBid,
        correctCount: currentQuestion.correctAnswer,
        language: language,
      );

      if (!mounted) return;

      final correctAnswersCount = analysis['correctCount'] ?? 0;
      final isSuccess = correctAnswersCount >= currentBid;

      setState(() {
        isEvaluating = false;
        isComputerTurn = true; // دور الكمبيوتر
        if (isSuccess) {
          evaluationResult =
              '✅ الكمبيوتر نجح! ($correctAnswersCount/$currentBid إجابات صحيحة)';
          computerScore++;
          if (playerHearts > 0) playerHearts--;
          lastAnswerCorrect = true; // الكمبيوتر نجح (الأنيميشن خضراء)
        } else {
          evaluationResult =
              '❌ الكمبيوتر فشل! ($correctAnswersCount/$currentBid إجابات صحيحة)';
          playerScore++;
          if (computerHearts > 0) computerHearts--;
          lastAnswerCorrect = false; // الكمبيوتر فشل (الأنيميشن حمراء)
        }
      });

      // تشغيل أنيميشن النتيجة
      _resultController.reset();
      _resultController.forward();

      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      print('❌ Error in computer answers: $e');
      // Fallback: نجاح عشوائي
      final willSucceed = Random().nextDouble() < 0.7;
      setState(() {
        isEvaluating = false;
        isComputerTurn = true; // دور الكمبيوتر
        if (willSucceed) {
          evaluationResult = '✅ الكمبيوتر نجح!';
          computerScore++;
          if (playerHearts > 0) playerHearts--;
          lastAnswerCorrect = true; // الكمبيوتر نجح (الأنيميشن خضراء)
        } else {
          evaluationResult = '❌ الكمبيوتر فشل!';
          playerScore++;
          if (computerHearts > 0) computerHearts--;
          lastAnswerCorrect = false; // الكمبيوتر فشل (الأنيميشن حمراء)
        }
      });

      // تشغيل أنيميشن النتيجة
      _resultController.reset();
      _resultController.forward();

      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      _nextQuestion();
    }
  }

  void _nextQuestion() {
    // في Full Challenge: 5 أسئلة فقط
    final maxQuestions = widget.isInFullChallenge ? 5 : questions.length;
    final questionsCompleted = currentQuestionIndex + 1;

    if (widget.isInFullChallenge && questionsCompleted >= maxQuestions) {
      // انتهت الـ 5 أسئلة في Full Challenge
      _showGameOver();
    } else if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        // ✅ مسح الإجابات من السؤال السابق
        playerAnswers.clear();
        computerAnswers.clear();
        playerAnswerCount = 0;
        evaluationResult = '';
        lastAnswerCorrect = null;
        isComputerTurn = false;
        isComputerAnswering = false;
      });
      _startInitialCountdown();
    } else {
      _showGameOver();
    }
  }

  void _showGameOver() {
    // ✅ إلغاء جميع Timers قبل إغلاق الشاشة
    timer?.cancel();
    bidTimer?.cancel();

    if (!mounted) return;

    // حفظ النتيجة
    final isWin = playerScore > computerScore;
    _scoreService.saveGameResult(
      gameName: 'the_auction',
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
              ? AppStrings.t(context, 'you_win')
              : AppStrings.t(context, 'you_lose'),
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
                    setState(() {
                      currentQuestionIndex = 0;
                      playerScore = 0;
                      computerScore = 0;
                      playerHearts = 3;
                      computerHearts = 3;
                    });
                    _startInitialCountdown();
                  },
                  child: Text(AppStrings.t(context, 'play_again')),
                ),
              ],
      ),
    );
  }

  void _showPauseMenu() {
    if (_isPaused) return;

    setState(() => _isPaused = true);
    timer?.cancel();
    bidTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseMenu(
        gameTitle: AppStrings.t(context, 'the_auction'),
        onResume: () {
          setState(() => _isPaused = false);
          _startInitialCountdown();
        },
        onRestart: () {
          Navigator.pop(context); // إغلاق الـ dialog أولاً
          setState(() {
            _isPaused = false;
            currentQuestionIndex = 0;
            playerScore = widget.initialPlayerScore;
            computerScore = widget.initialComputerScore;
            playerHearts = 3;
            computerHearts = 3;
          });
          _startInitialCountdown();
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
            AppStrings.t(context, 'the_auction'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
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
                child: const Icon(
                  Icons.pause_rounded,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              onPressed: _showPauseMenu,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: isLoadingQuestions
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.t(context, 'loading_questions'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Section: Players and Auction Icon
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 600;
                        final iconSize = isSmallScreen ? 48.0 : 64.0;
                        final spacing = isSmallScreen ? 8.0 : 32.0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Player 2 (Computer) - Left
                            Flexible(
                              child: _buildTopPlayerScore(
                                'Computer',
                                computerScore,
                                computerHearts,
                                false,
                                colorScheme,
                                iconSize,
                              ),
                            ),
                            SizedBox(width: spacing),
                            // Auction Icon - Center
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEC4899,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.gavel,
                                color: Colors.white,
                                size: iconSize * 0.56,
                              ),
                            ),
                            SizedBox(width: spacing),
                            // Player 1 (You) - Right
                            Flexible(
                              child: _buildTopPlayerScore(
                                'You',
                                playerScore,
                                playerHearts,
                                true,
                                colorScheme,
                                iconSize,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Main Content Area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // Question Card
                            if (questions.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEC4899),
                                      Color(0xFFF59E0B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFEC4899,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.gavel,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      questions[currentQuestionIndex].question,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    // عرض العدد الإجمالي المتاح
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.format_list_numbered,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${AppStrings.t(context, 'total_available_count')}: ${questions[currentQuestionIndex].correctAnswer}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Initial Countdown / Auction / Answer Phase
                            if (showInitialCountdown)
                              _buildInitialCountdown(colorScheme, theme)
                            else if (auctionActive)
                              _buildAuctionPhase(colorScheme, theme)
                            else
                              _buildAnswerPhase(colorScheme, theme),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInitialCountdown(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 0.1,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEC4899).withValues(alpha: 0.9),
                      const Color(0xFFF59E0B).withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 60,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, textValue, child) {
                      return Opacity(
                        opacity: textValue,
                        child: Text(
                          initialCountdown > 0
                              ? initialCountdown.toString()
                              : 'GO!',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: initialCountdown > 0 ? 80 : 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: initialCountdown > 0 ? 0 : 4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuctionPhase(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Current Bid Display
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                AppStrings.t(context, 'current_bid'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentBid.toString(),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        if (isPlayerBidding) ...[
          // Bid Timer with Pulse Animation
          ScaleTransition(
            scale: bidTimeLeft <= 2 ? _timerPulse : AlwaysStoppedAnimation(1.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: bidTimeLeft <= 2
                            ? [Colors.red.shade400, Colors.red.shade700]
                            : [
                                const Color(0xFFEC4899),
                                const Color(0xFFF59E0B),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (bidTimeLeft <= 2
                                      ? Colors.red
                                      : const Color(0xFFEC4899))
                                  .withValues(alpha: 0.6),
                          blurRadius: bidTimeLeft <= 2 ? 30 : 20,
                          spreadRadius: bidTimeLeft <= 2 ? 8 : 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        bidTimeLeft.toString(),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 40,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            AppStrings.t(context, 'your_turn_to_bid'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: bidTimeLeft <= 2 ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final maxBid = questions[currentQuestionIndex].correctAnswer;
              final bid1 = currentBid + 1;
              final bid2 = currentBid + 2;
              final bid3 = currentBid + 5;

              print(
                '🎯 عرض أزرار المزايدة - currentBid: $currentBid, maxBid: $maxBid',
              );
              print(
                '   الأزرار المتاحة: ${bid1 <= maxBid ? bid1 : '-'}, ${bid2 <= maxBid ? bid2 : '-'}, ${bid3 <= maxBid ? bid3 : '-'}',
              );

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (bid1 <= maxBid) _buildBidButton(bid1),
                  if (bid2 <= maxBid) _buildBidButton(bid2),
                  if (bid3 <= maxBid) _buildBidButton(bid3),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _playerGiveUp,
            icon: const Icon(Icons.cancel),
            label: Text(AppStrings.t(context, 'give_up')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  AppStrings.t(context, 'computer_deciding'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerPhase(ColorScheme colorScheme, ThemeData theme) {
    // عرض نتيجة التحليل
    if (isEvaluating || evaluationResult.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isEvaluating)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  evaluationResult,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else if (evaluationResult.contains('لا مزايدة'))
            // عرض رسالة "لا مزايدة"
            Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  evaluationResult,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else if (lastAnswerCorrect != null)
            Column(
              children: [
                // أنميشن النجاح أو الفشل المحسّن
                ScaleTransition(
                  scale: _resultScale,
                  child: FadeTransition(
                    opacity: _resultOpacity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, rotationValue, child) {
                        return Transform.rotate(
                          angle:
                              rotationValue *
                              0.2 *
                              (lastAnswerCorrect == true ? 1 : -1),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: lastAnswerCorrect == true
                                    ? [
                                        const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.3),
                                        const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.1),
                                      ]
                                    : [
                                        Colors.red.withValues(alpha: 0.3),
                                        Colors.red.withValues(alpha: 0.1),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: lastAnswerCorrect == true
                                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                      : Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              lastAnswerCorrect == true
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 90,
                              color: lastAnswerCorrect == true
                                  ? const Color(0xFF10B981)
                                  : Colors.red,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  evaluationResult,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: lastAnswerCorrect == true
                        ? const Color(0xFF10B981)
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                // توضيح إضافي
                if (isComputerTurn) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: lastAnswerCorrect == true
                          ? Colors.red.withValues(alpha: 0.1)
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: lastAnswerCorrect == true
                            ? Colors.red.withValues(alpha: 0.3)
                            : const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      lastAnswerCorrect == true
                          ? '😞 خسرت هذه الجولة'
                          : '🎉 فزت في هذه الجولة!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: lastAnswerCorrect == true
                            ? Colors.red.shade700
                            : const Color(0xFF10B981),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                // عرض إجابات الكمبيوتر
                if (computerAnswers.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    '🤖 إجابات الكمبيوتر:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: computerAnswers
                          .map(
                            (answer) => Chip(
                              label: Text(answer),
                              backgroundColor: Colors.red.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
        ],
      );
    }

    if (answeringPhase && timeLeft > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isComputerAnswering
                ? '🤖 ${AppStrings.t(context, 'computer_thinking')}'
                : '${AppStrings.t(context, 'you_need_answers')}: $currentBid',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isComputerAnswering
                ? '${AppStrings.t(context, 'answers_given')}: ${computerAnswers.length}'
                : '${AppStrings.t(context, 'answers_given')}: $playerAnswerCount',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isComputerAnswering
                  ? (computerAnswers.length >= currentBid
                        ? const Color(0xFF10B981)
                        : Colors.red)
                  : (playerAnswerCount >= currentBid
                        ? const Color(0xFF10B981)
                        : Colors.red),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // عرض قائمة الإجابات المدخلة
          if (isComputerAnswering && computerAnswers.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: computerAnswers
                    .map(
                      (answer) => Chip(
                        label: Text(answer),
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          else if (!isComputerAnswering && playerAnswers.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: playerAnswers
                    .map(
                      (answer) => Chip(
                        label: Text(answer),
                        backgroundColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
          CircularProgressIndicator(value: timeLeft / 30, strokeWidth: 8),
          const SizedBox(height: 12),
          Text(
            '$timeLeft ${AppStrings.t(context, 'seconds')}',
            style: theme.textTheme.headlineSmall,
          ),
          if (_isListening) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.t(context, 'recording_mention_players'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_voiceText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _voiceText,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
          const SizedBox(height: 32),
          if (!isComputerAnswering)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Input Field - Expanded
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: answerController,
                            onSubmitted: (_) => _submitAnswer(),
                            decoration: InputDecoration(
                              hintText: AppStrings.t(context, 'type_answer'),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Color(0xFF10B981),
                                ),
                                onPressed: _submitAnswer,
                              ),
                            ),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Microphone Button - Fixed Size
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.red, Colors.red[700]!]
                                : [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? Colors.red
                                          : const Color(0xFF10B981))
                                      .withValues(alpha: 0.3),
                              blurRadius: _isListening ? 15 : 10,
                              spreadRadius: _isListening ? 3 : 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _startVoiceInput,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // زر "انتهيت من الإجابة"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: playerAnswerCount >= currentBid
                          ? _evaluatePlayerAnswers
                          : null,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: Text(
                        AppStrings.t(context, 'finish_answering'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: playerAnswerCount >= currentBid ? 4 : 0,
                      ),
                    ),
                  ),
                  if (playerAnswerCount < currentBid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ ${AppStrings.t(context, 'need_more_answers')}: ${currentBid - playerAnswerCount}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lastAnswerCorrect == true ? Icons.check_circle : Icons.cancel,
              size: 100,
              color: lastAnswerCorrect == true
                  ? const Color(0xFF10B981)
                  : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              lastAnswerCorrect == true
                  ? AppStrings.t(context, 'correct_answer')
                  : AppStrings.t(context, 'wrong_answer'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBidButton(int bid) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: () => _playerBid(bid),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        bid.toString(),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTopPlayerScore(
    String name,
    int score,
    int hearts,
    bool isPlayer,
    ColorScheme colorScheme,
    double iconSize,
  ) {
    final theme = Theme.of(context);
    final color = isPlayer ? const Color(0xFF10B981) : Colors.red;
    final innerSpacing = iconSize * 0.25;

    return Row(
      mainAxisAlignment: isPlayer
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isPlayer) ...[
          // Computer Profile (left side)
          Column(
            children: [
              // Profile Picture
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: iconSize * 0.047),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: iconSize * 0.156,
                      spreadRadius: iconSize * 0.031,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  radius: iconSize * 0.469,
                  child: Icon(
                    Icons.smart_toy,
                    color: color,
                    size: iconSize * 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(width: innerSpacing),
          // Score
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(iconSize * 0.25),
              border: Border.all(color: color, width: iconSize * 0.047),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                score.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
            ),
          ),
        ] else ...[
          // Score for Player (right side)
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(iconSize * 0.25),
              border: Border.all(color: color, width: iconSize * 0.047),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                score.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
            ),
          ),
          SizedBox(width: innerSpacing),
          // Player Profile
          Column(
            children: [
              // Profile Picture
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: iconSize * 0.047),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: iconSize * 0.156,
                      spreadRadius: iconSize * 0.031,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  radius: iconSize * 0.469,
                  child: Icon(Icons.person, color: color, size: iconSize * 0.5),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
