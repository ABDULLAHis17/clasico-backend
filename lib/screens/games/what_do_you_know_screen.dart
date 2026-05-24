import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../models/question.dart';
import '../../data/game_questions_data.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/gemini_service_extended.dart';
import '../../services/settings_service.dart';
import '../../services/score_service.dart';
import '../../widgets/game_question_result_dialog.dart';
import '../../widgets/game_pause_menu.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class WhatDoYouKnowScreen extends StatefulWidget {
  final bool isOnlineMode;
  final bool isInFullChallenge;
  final int initialPlayerScore;
  final int initialComputerScore;

  const WhatDoYouKnowScreen({
    Key? key,
    this.isOnlineMode = false,
    this.isInFullChallenge = false,
    this.initialPlayerScore = 0,
    this.initialComputerScore = 0,
  }) : super(key: key);

  @override
  State<WhatDoYouKnowScreen> createState() => _WhatDoYouKnowScreenState();
}

class _WhatDoYouKnowScreenState extends State<WhatDoYouKnowScreen> {
  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  final SettingsService _settings = SettingsService();
  final ScoreService _scoreService = ScoreService();
  stt.SpeechToText _speech = stt.SpeechToText(); // ✅ تهيئة مباشرة

  List<GameQuestion> questions = [];
  int currentQuestionIndex = 0;
  late int playerScore;
  late int computerScore;
  int playerHearts = 3;
  int computerHearts = 3;
  bool isPlayerTurn = true;
  Timer? timer;
  int timeLeft = 18;
  TextEditingController answerController = TextEditingController();
  List<String> usedAnswers = [];
  bool isWaitingForComputer = false;
  String? lastComputerAnswer;
  String? lastPlayerAnswer;
  bool isLoadingQuestions = true;

  // Voice Recognition
  bool _isListening = false;
  bool _speechAvailable = false;
  String _voiceAnswer = '';

  // Answer feedback
  bool _showAnswerFeedback = false;
  bool _isAnswerCorrect = false;
  String _feedbackMessage = '';
  bool _canChallenge = false;
  String _lastVoiceAnswer = '';
  bool _isShowingAnimation = false;
  bool _isAnalyzing = false;
  bool _isPaused = false;

  // 🎤 Enhanced Speech Config
  List<stt.LocaleName> _locales = [];
  String? _selectedLocaleId;
  // ignore: unused_field
  double _soundLevel = 0.0; // for potential UI feedback
  int _restartsLeft = 0; // auto-restart guard

  @override
  void initState() {
    super.initState();
    playerScore = widget.initialPlayerScore;
    computerScore = widget.initialComputerScore;
    _loadQuestions();
    _initSpeech();
    _loadQuestionsFromGemini();
  }

  Future<void> _initSpeech() async {
    try {
      // التحقق من حالة الصلاحية الحالية
      final currentStatus = await Permission.microphone.status;
      print('🎤 Current microphone permission status: $currentStatus');

      if (currentStatus.isDenied || currentStatus.isRestricted) {
        // طلب الصلاحية
        final status = await Permission.microphone.request();
        print('🎤 Requested microphone permission, result: $status');

        if (status.isPermanentlyDenied) {
          // المستخدم رفض الصلاحية بشكل دائم - اعرض رسالة لفتح الإعدادات
          if (mounted) {
            // Removed SnackBar
          }
          return;
        }

        if (!status.isGranted) {
          print('❌ Microphone permission not granted');
          return;
        }
      }

      // تهيئة خدمة التعرف على الصوت
      print('🎤 Initializing speech recognition...');
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          print('❌ Speech error: $error');
          if (mounted) {
            // Removed SnackBar
          }
        },
        onStatus: (status) {
          print('🎤 Speech status: $status');
          _handleSpeechStatus(status);
        },
        debugLogging: false,
      );

      print('✅ Speech recognition available: $_speechAvailable');

      // تحميل اللغات المتاحة واختيار الأنسب
      try {
        _locales = await _speech.locales();
      } catch (e) {
        print('⚠️ Could not load speech locales: $e');
        _locales = [];
      }
      final language = _settings
          .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
      _selectedLocaleId = _pickBestLocaleForLanguage(language, _locales);
      print(
        '🌐 Selected speech locale: ${_selectedLocaleId ?? 'default'} (lang=$language)',
      );

      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error initializing speech: $e');
      if (mounted) {
        // Removed SnackBar
      }
    }
  }

  Future<void> _startListening() async {
    if (_isAnalyzing || _isPaused) return;
    if (timeLeft <= 0) return;

    if (!_speechAvailable) {
      // حاول إعادة التهيئة السريعة
      await _initSpeech();
      if (!_speechAvailable) {
        // Removed SnackBar
        return;
      }
    }

    setState(() {
      _isListening = true;
      _voiceAnswer = '';
      _restartsLeft = 3; // السماح بثلاث محاولات إعادة تشغيل تلقائية
    });

    final language = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
    final fallbackLocale = language == 'ar'
        ? 'ar_SA'
        : language == 'tr'
        ? 'tr_TR'
        : 'en_US';
    final localeId = _selectedLocaleId ?? fallbackLocale;

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceAnswer = result.recognizedWords;
          });

          if (result.finalResult) {
            _stopListening();
            // ✅ أرسل الإجابة تلقائياً بعد اكتمال التعرف
            Future.microtask(() {
              if (mounted &&
                  answerController.text.trim().isNotEmpty &&
                  !_isAnalyzing) {
                _submitAnswer();
              }
            });
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30), // ⬆️ وقت أطول للاستماع
        pauseFor: const Duration(seconds: 4), // ⬆️ وقت السكون قبل الإيقاف
        partialResults: true, // ✅ نتائج جزئية لتحسين الاستجابة
        onSoundLevelChange: _onSoundLevelChange, // ✅ مراقبة حساسية الصوت
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation, // ✅ وضع الإملاء للأداء الأفضل
        onDevice: true, // ✅ التعرّف على الجهاز إن أمكن
      );
    } catch (e) {
      print('❌ Error starting listening: $e');
      // Removed SnackBar
    }
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (_) {}
    setState(() => _isListening = false);

    // وضع النص المسموع في حقل الإدخال للتعديل
    if (_voiceAnswer.isNotEmpty) {
      final lang = _settings
          .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية
      final normalized = lang == 'ar'
          ? _normalizeText(_voiceAnswer)
          : _voiceAnswer.trim();
      answerController.text = normalized;
      setState(() => _voiceAnswer = '');
    }
  }

  // =====================
  // 🔊 Helpers
  // =====================
  void _onSoundLevelChange(double level) {
    // غالباً يكون بين 0-1 أو أعلى بقليل حسب المنصة
    setState(() {
      _soundLevel = level;
    });
  }

  void _handleSpeechStatus(String status) {
    // إعادة التشغيل التلقائي إذا توقف بشكل غير متوقع أثناء الاستماع
    if (status == 'notListening' &&
        _isListening &&
        !_isAnalyzing &&
        !_isPaused &&
        timeLeft > 0) {
      _restartListeningIfNeeded();
    }
  }

  Future<void> _restartListeningIfNeeded() async {
    if (_restartsLeft <= 0) return;
    _restartsLeft--;
    // مهلة قصيرة قبل إعادة التشغيل
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted &&
        _isListening &&
        !_isAnalyzing &&
        !_isPaused &&
        timeLeft > 0) {
      print('🔁 Restarting speech listening ($_restartsLeft left)');
      try {
        await _speech.stop();
      } catch (_) {}
      // إعادة التشغيل مع نفس الإعدادات
      _startListening();
    }
  }

  String? _pickBestLocaleForLanguage(
    String language,
    List<stt.LocaleName> locales,
  ) {
    if (locales.isEmpty) return null;
    // محاولات مطابقة دقيقة ثم عامة
    final candidates = <String>[
      if (language == 'ar') ...['ar_SA', 'ar_EG', 'ar_AE', 'ar'],
      if (language == 'tr') ...['tr_TR', 'tr'],
      if (language == 'en') ...['en_US', 'en_GB', 'en'],
    ];
    for (final c in candidates) {
      final match = locales.firstWhere(
        (l) => l.localeId.toLowerCase() == c.toLowerCase(),
        orElse: () => stt.LocaleName(c, c),
      );
      if (locales.any((l) => l.localeId.toLowerCase() == c.toLowerCase())) {
        return match.localeId;
      }
    }
    // fallback: أول لغة متاحة على الجهاز
    return locales.first.localeId;
  }

  // 🧠 Normalize Arabic text to improve AI analysis matching
  String _normalizeText(String input) {
    var t = input;
    // إزالة التشكيل
    t = t.replaceAll(RegExp('[\u064B-\u0652]'), '');
    // توحيد الألفات والياءات والتاءات
    t = t
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه');
    // إزالة مسافات زائدة
    t = t.replaceAll(RegExp('\n+'), ' ').replaceAll(RegExp('\s+'), ' ').trim();
    return t;
  }

  void _challengeDecision() {
    // اللاعب يطعن في القرار - نعيد القلب ونقبل الإجابة
    setState(() {
      playerHearts++;
      _canChallenge = false;
      _showAnswerFeedback = true;
      _isAnswerCorrect = true;
      _feedbackMessage = '✅ ${AppStrings.t(context, 'challenge_accepted')}!';
    });

    usedAnswers.add(_lastVoiceAnswer);
    lastPlayerAnswer = _lastVoiceAnswer;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showAnswerFeedback = false;
          isPlayerTurn = false;
          _isAnalyzing = false;
        });
        _computerTurn();
      }
    });
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

      // تحميل أسئلة من مستويات صعوبة مختلفة للتنويع
      print('🔄 Loading varied difficulty questions...');

      final List<GameQuestion> allQuestions = [];

      // 40% أسئلة سهلة
      final easyQuestions = await _gemini.generateWhatDoYouKnowQuestions(
        count: 12,
        language: language,
        difficulty: 'easy',
      );
      allQuestions.addAll(
        easyQuestions.map(
          (q) => GameQuestion(
            id: q['id'],
            question: q['question'],
            category: q['category'],
            possibleAnswers: List<String>.from(q['possibleAnswers']),
          ),
        ),
      );

      // 40% أسئلة متوسطة
      final mediumQuestions = await _gemini.generateWhatDoYouKnowQuestions(
        count: 12,
        language: language,
        difficulty: 'medium',
      );
      allQuestions.addAll(
        mediumQuestions.map(
          (q) => GameQuestion(
            id: q['id'],
            question: q['question'],
            category: q['category'],
            possibleAnswers: List<String>.from(q['possibleAnswers']),
          ),
        ),
      );

      // 20% أسئلة صعبة
      final hardQuestions = await _gemini.generateWhatDoYouKnowQuestions(
        count: 6,
        language: language,
        difficulty: 'hard',
      );
      allQuestions.addAll(
        hardQuestions.map(
          (q) => GameQuestion(
            id: q['id'],
            question: q['question'],
            category: q['category'],
            possibleAnswers: List<String>.from(q['possibleAnswers']),
          ),
        ),
      );

      // خلط الأسئلة بشكل عشوائي
      allQuestions.shuffle();

      if (allQuestions.isNotEmpty && mounted) {
        setState(() {
          questions = allQuestions;
          isLoadingQuestions = false;
        });
        print(
          '✅ Loaded ${allQuestions.length} questions (Easy: ${easyQuestions.length}, Medium: ${mediumQuestions.length}, Hard: ${hardQuestions.length})',
        );
        _startTimer();
      } else {
        // Fallback to local data
        if (mounted) {
          setState(() {
            questions = GameQuestionsData.getWhatDoYouKnowQuestions();
            isLoadingQuestions = false;
          });
          _startTimer();
        }
      }
    } catch (e) {
      print('❌ Error loading questions from Gemini: $e');
      // Fallback to local data
      if (mounted) {
        setState(() {
          questions = GameQuestionsData.getWhatDoYouKnowQuestions();
          isLoadingQuestions = false;
        });
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    answerController.dispose();
    _speech.stop(); // ✅ إيقاف التعرف على الصوت
    super.dispose();
  }

  void _startTimer() {
    timeLeft = 18;
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
    if (isPlayerTurn) {
      setState(() {
        playerHearts--;
      });

      if (playerHearts == 0) {
        setState(() {
          computerScore++;
        });
        _resetRound(
          showAnimation: true,
          playerWon: false,
        ); // اللاعب خسر - أنيميشن خسارة
      } else {
        setState(() {
          isPlayerTurn = false;
        });
        _computerTurn();
      }
    }
  }

  Future<void> _submitAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    answerController.clear();

    final currentQuestion = questions[currentQuestionIndex];
    timer?.cancel();

    // عرض نافذة التحليل فقط (بدون عرض صح/خطأ)
    setState(() {
      _showAnswerFeedback = true;
      _isAnswerCorrect = false; // لا نعرض أي لون حتى الآن
      _feedbackMessage =
          '${AppStrings.t(context, 'answer_analyzing')}\n\n"$answer"';
    });

    final language = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

    print('📝 Analyzing answer: "$answer"');
    print('📋 Possible answers: ${currentQuestion.possibleAnswers}');
    print('📝 Used answers: $usedAnswers');

    final analysis = await _gemini.analyzeAnswerWithDuplicateCheck(
      playerAnswer: answer,
      correctAnswers: currentQuestion.possibleAnswers,
      usedAnswers: usedAnswers,
      question: currentQuestion.question,
      language: language,
    );

    if (!mounted) {
      setState(() => _isAnalyzing = false);
      return;
    }

    final isCorrect = analysis['isCorrect'] == true;
    final isDuplicate = analysis['isDuplicate'] == true;
    final matchedAnswer = analysis['matchedAnswer'] ?? answer;
    final reason = analysis['reason'] ?? '';
    final confidence = analysis['confidence'] ?? 0;

    print(
      '🎯 AI Result: Correct=$isCorrect, Duplicate=$isDuplicate, Confidence=${confidence}%',
    );
    print('📝 Input: "$answer"');
    print('✅ Matched: "${matchedAnswer}"');
    print('💡 Reason: $reason');

    // إذا كانت الإجابة مكررة
    if (isDuplicate) {
      setState(() {
        playerHearts--;
        _showAnswerFeedback = true;
        _isAnswerCorrect = false;
        _feedbackMessage =
            '❌ ${AppStrings.t(context, 'already_used')}\n💡 $reason';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showAnswerFeedback = false;
            _isAnalyzing = false;
          });
          if (playerHearts == 0) {
            computerScore++;
            _resetRound(
              showAnimation: true,
              playerWon: false,
            ); // اللاعب خسر - أنيميشن خسارة
          } else {
            isPlayerTurn = false;
            _computerTurn();
          }
        }
      });
      return;
    }

    if (isCorrect) {
      usedAnswers.add(matchedAnswer);
      setState(() {
        lastPlayerAnswer = matchedAnswer;
        _showAnswerFeedback = true;
        _isAnswerCorrect = true;
        _feedbackMessage = '✅ ${AppStrings.t(context, 'correct')}!';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showAnswerFeedback = false;
            isPlayerTurn = false;
            _isAnalyzing = false;
          });
          _computerTurn();
        }
      });
    } else {
      setState(() {
        playerHearts--;
        _showAnswerFeedback = true;
        _isAnswerCorrect = false;
        _canChallenge = true;
        _lastVoiceAnswer = answer;
        if (reason.isNotEmpty && confidence > 70) {
          _feedbackMessage =
              '❌ ${AppStrings.t(context, 'wrong_answer')}\n💡 $reason';
        } else {
          _feedbackMessage = '❌ ${AppStrings.t(context, 'wrong_answer')}';
        }
      });

      final delayDuration = (reason.isNotEmpty && confidence > 70)
          ? const Duration(seconds: 5)
          : const Duration(seconds: 3);

      Future.delayed(delayDuration, () {
        if (mounted && _canChallenge) {
          setState(() {
            _showAnswerFeedback = false;
            _canChallenge = false;
            _isAnalyzing = false;
          });
          if (playerHearts == 0) {
            computerScore++;
            _resetRound(
              showAnimation: true,
              playerWon: false,
            ); // اللاعب خسر - أنيميشن خسارة
          } else {
            isPlayerTurn = false;
            _computerTurn();
          }
        }
      });
    }
  }

  Future<void> _computerTurn() async {
    if (!mounted) return;

    setState(() {
      isWaitingForComputer = true;
      lastComputerAnswer = null;
    });

    await Future.delayed(Duration(seconds: Random().nextInt(3) + 2));

    if (!mounted) return;

    final currentQuestion = questions[currentQuestionIndex];
    final language = _settings
        .getActualLanguageCode(); // ✅ الحصول على اللغة الفعلية

    print('🤖 Computer is generating answer...');
    print('📝 Question: ${currentQuestion.question}');
    print('📝 Used answers: $usedAnswers');

    // استخدام AI لتوليد إجابة صحيحة للكمبيوتر
    final computerAnswerData = await _gemini.generateComputerAnswer(
      question: currentQuestion.question,
      usedAnswers: usedAnswers,
      language: language,
    );

    if (!mounted) return;

    final success = computerAnswerData['success'] == true;
    final computerAnswer = computerAnswerData['answer'] ?? '';

    print(
      '🎯 Computer answer result: success=$success, answer="$computerAnswer"',
    );

    if (!success || computerAnswer.isEmpty || Random().nextDouble() < 0.15) {
      // Computer fails (15% chance or AI couldn't generate)
      print('❌ Computer failed to answer');
      setState(() {
        computerHearts--;
        isWaitingForComputer = false;
        lastComputerAnswer = null;
      });

      if (computerHearts == 0) {
        setState(() {
          playerScore++;
        });
        _resetRound(
          showAnimation: true,
          playerWon: true,
        ); // اللاعب فاز - أنيميشن!
      } else {
        setState(() {
          isPlayerTurn = true;
        });
        _startTimer();
      }
    } else {
      // التحقق من صحة إجابة الكمبيوتر باستخدام AI
      print('🔍 Verifying computer answer: "$computerAnswer"');

      final verification = await _gemini.analyzeAnswerWithDuplicateCheck(
        playerAnswer: computerAnswer,
        correctAnswers: currentQuestion.possibleAnswers,
        usedAnswers: usedAnswers,
        question: currentQuestion.question,
        language: language,
      );

      if (!mounted) return;

      final isCorrect = verification['isCorrect'] == true;
      final isDuplicate = verification['isDuplicate'] == true;
      final reason = verification['reason'] ?? '';

      print('🎯 Verification: Correct=$isCorrect, Duplicate=$isDuplicate');
      print('💡 Reason: $reason');

      if (!isCorrect || isDuplicate) {
        // إجابة الكمبيوتر خاطئة أو مكررة
        print('❌ Computer answer is wrong or duplicate!');
        setState(() {
          computerHearts--;
          isWaitingForComputer = false;
          lastComputerAnswer = null;
        });

        if (computerHearts == 0) {
          setState(() {
            playerScore++;
          });
          _resetRound(showAnimation: true, playerWon: true);
        } else {
          setState(() {
            isPlayerTurn = true;
          });
          _startTimer();
        }
      } else {
        // إجابة الكمبيوتر صحيحة
        usedAnswers.add(computerAnswer);
        print('✅ Computer answered correctly: $computerAnswer');
        setState(() {
          lastComputerAnswer = computerAnswer;
          isWaitingForComputer = false;
          isPlayerTurn = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startTimer();
        }
      }
    }
  }

  Future<void> _resetRound({
    bool showAnimation = true,
    bool playerWon = true,
  }) async {
    if (!mounted) return;

    // أنيميشن نهاية السؤال (فوز أو خسارة)
    if (showAnimation) {
      try {
        await _showRoundEndAnimation(playerWon: playerWon);
      } catch (e) {
        print('⚠️ Error showing animation: $e');
      }
    }

    if (!mounted) return;

    usedAnswers.clear();
    playerHearts = 3;
    computerHearts = 3;
    lastPlayerAnswer = null;
    lastComputerAnswer = null;
    timer?.cancel();

    // في Full Challenge: 5 أسئلة فقط
    final maxQuestions = widget.isInFullChallenge ? 5 : questions.length;
    final questionsCompleted = currentQuestionIndex + 1;

    if (playerScore >= 5 || computerScore >= 5) {
      if (mounted) {
        _showGameOver();
      }
    } else if (widget.isInFullChallenge && questionsCompleted >= maxQuestions) {
      // انتهت الـ 5 أسئلة في Full Challenge
      if (mounted) {
        _showGameOver();
      }
    } else {
      if (currentQuestionIndex < questions.length - 1) {
        if (mounted) {
          setState(() {
            currentQuestionIndex++;
            isPlayerTurn = true;
          });
          _startTimer();
        }
      } else {
        if (mounted) {
          _showGameOver();
        }
      }
    }
  }

  Future<void> _showRoundEndAnimation({required bool playerWon}) async {
    if (!mounted || _isShowingAnimation) {
      return;
    }

    setState(() {
      _isShowingAnimation = true;
    });

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameQuestionResultDialog(
          gameTitle: AppStrings.t(context, 'what_do_you_know'),
          playerScore: playerScore,
          computerScore: computerScore,
          playerHearts: playerHearts,
          computerHearts: computerHearts,
          isWin: playerWon,
          onContinue: () {
            // Dialog will be closed automatically
          },
        ),
      );
    } catch (e) {
      print('⚠️ Error in dialog: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isShowingAnimation = false;
        });
      }
    }
  }

  void _showPauseMenu() {
    if (_isPaused) return;

    setState(() => _isPaused = true);
    timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseMenu(
        gameTitle: AppStrings.t(context, 'what_do_you_know'),
        onResume: () {
          setState(() => _isPaused = false);
          if (isPlayerTurn) {
            _startTimer();
          }
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
            usedAnswers.clear();
            isPlayerTurn = true;
          });
          _startTimer();
        },
        onExit: () {
          Navigator.pop(context); // إغلاق الـ dialog
          Navigator.pop(context); // الخروج من اللعبة نهائياً
        },
      ),
    );
  }

  void _showGameOver() {
    timer?.cancel();

    if (!mounted) return;

    // حفظ النتيجة
    final isWin = playerScore > computerScore;
    _scoreService.saveGameResult(
      gameName: 'what_do_you_know',
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
                // في مود Full Challenge - زر واحد فقط للمتابعة
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, {
                      'playerScore': playerScore,
                      'computerScore': computerScore,
                    }); // Return with results to continue
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
                // في المود العادي - خيارين
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, {
                      'playerScore': playerScore,
                      'computerScore': computerScore,
                    }); // Return to previous screen with results
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
                      usedAnswers.clear();
                      isPlayerTurn = true;
                    });
                    _startTimer();
                  },
                  child: Text(AppStrings.t(context, 'play_again')),
                ),
              ],
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
            AppStrings.t(context, 'what_do_you_know'),
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
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.t(context, 'loading'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🤖 ${AppStrings.t(context, 'ai_thinking')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            : questions.isEmpty
            ? Center(
                child: Text(
                  AppStrings.t(context, 'no_questions'),
                  style: theme.textTheme.titleMedium,
                ),
              )
            : Builder(
                builder: (context) {
                  final currentQuestion = questions[currentQuestionIndex];

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Top Section: Players and Challenge Icon
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
                                // Challenge Icon - Center
                                Container(
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF8B5CF6),
                                        const Color(
                                          0xFF8B5CF6,
                                        ).withValues(alpha: 0.7),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.psychology,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),

                                  // Player's Last Answer (at the top) - Compact
                                  if (lastPlayerAnswer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF059669),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              lastPlayerAnswer!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (lastPlayerAnswer != null)
                                    const SizedBox(height: 12),

                                  // Computer Answer Display - Compact
                                  if (lastComputerAnswer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.red,
                                            Color(0xFFDC2626),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.smart_toy,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              lastComputerAnswer!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (lastComputerAnswer != null)
                                    const SizedBox(height: 12),

                                  // Question Card (Blue Box)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.question_mark_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          currentQuestion.question,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        // Timer
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  value: timeLeft / 15,
                                                  strokeWidth: 3,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$timeLeft s',
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
                                  ),

                                  const SizedBox(height: 24),

                                  // Answer Feedback - Beautiful Small Notification
                                  if (_showAnswerFeedback)
                                    TweenAnimationBuilder(
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.elasticOut,
                                      builder: (context, double value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: _isAnalyzing
                                                    ? [
                                                        const Color(0xFF8B5CF6),
                                                        const Color(0xFF7C3AED),
                                                      ] // أرجواني أثناء التحليل
                                                    : (_isAnswerCorrect
                                                          ? [
                                                              const Color(
                                                                0xFF10B981,
                                                              ),
                                                              const Color(
                                                                0xFF059669,
                                                              ),
                                                            ] // أخضر للصحيح
                                                          : [
                                                              const Color(
                                                                0xFFEF4444,
                                                              ),
                                                              const Color(
                                                                0xFFDC2626,
                                                              ),
                                                            ]), // أحمر للخطأ
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      (_isAnalyzing
                                                              ? const Color(
                                                                  0xFF8B5CF6,
                                                                )
                                                              : (_isAnswerCorrect
                                                                    ? const Color(
                                                                        0xFF10B981,
                                                                      )
                                                                    : const Color(
                                                                        0xFFEF4444,
                                                                      )))
                                                          .withValues(alpha: 0.4),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      _isAnalyzing
                                                          ? Icons
                                                                .hourglass_bottom
                                                          : (_isAnswerCorrect
                                                                ? Icons
                                                                      .check_circle
                                                                : Icons.cancel),
                                                      color: Colors.white,
                                                      size: 32,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Flexible(
                                                      child: Text(
                                                        _feedbackMessage,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // زر الطعن في القرار
                                                if (!_isAnswerCorrect &&
                                                    _canChallenge) ...[
                                                  const SizedBox(height: 12),
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        _challengeDecision,
                                                    icon: const Icon(
                                                      Icons.gavel,
                                                      size: 20,
                                                    ),
                                                    label: Text(
                                                      AppStrings.t(
                                                        context,
                                                        'challenge_decision',
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.white,
                                                      foregroundColor:
                                                          const Color(
                                                            0xFFEF4444,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                  // Voice Recognition Status
                                  if (_isListening)
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFDC2626),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                AppStrings.t(
                                                  context,
                                                  'listening',
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_voiceAnswer.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _voiceAnswer,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                  // Answer Input with Microphone
                                  if (isPlayerTurn && !isWaitingForComputer)
                                    Row(
                                      children: [
                                        // Input Field - Expanded
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF3B82F6,
                                                ).withValues(alpha: 0.3),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ).withValues(alpha: 0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              controller: answerController,
                                              enabled: !_isAnalyzing,
                                              onSubmitted: (_) => !_isAnalyzing
                                                  ? _submitAnswer()
                                                  : null,
                                              decoration: InputDecoration(
                                                hintText: AppStrings.t(
                                                  context,
                                                  'type_answer',
                                                ),
                                                border: InputBorder.none,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    Icons.send,
                                                    color: _isAnalyzing
                                                        ? Colors.grey
                                                              .withValues(alpha: 0.3)
                                                        : const Color(
                                                            0xFF3B82F6,
                                                          ),
                                                  ),
                                                  onPressed: _isAnalyzing
                                                      ? null
                                                      : _submitAnswer,
                                                ),
                                              ),
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Microphone Button - Fixed Size
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _isListening
                                                  ? [
                                                      const Color(0xFFEF4444),
                                                      const Color(0xFFDC2626),
                                                    ]
                                                  : [
                                                      const Color(0xFF3B82F6),
                                                      const Color(0xFF2563EB),
                                                    ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (_isListening
                                                            ? Colors.red
                                                            : const Color(
                                                                0xFF3B82F6,
                                                              ))
                                                        .withValues(alpha: 0.4),
                                                blurRadius: _isListening
                                                    ? 20
                                                    : 10,
                                                spreadRadius: _isListening
                                                    ? 4
                                                    : 2,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              _isListening
                                                  ? Icons.mic
                                                  : Icons.mic_none,
                                              color: _isAnalyzing
                                                  ? Colors.white.withValues(alpha: 
                                                      0.3,
                                                    )
                                                  : Colors.white,
                                              size: 28,
                                            ),
                                            onPressed: _isAnalyzing
                                                ? null
                                                : (_isListening
                                                      ? _stopListening
                                                      : _startListening),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (isWaitingForComputer)
                                    Column(
                                      children: [
                                        const SizedBox(height: 24),
                                        const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.red,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppStrings.t(
                                            context,
                                            'computer_thinking',
                                          ),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(color: Colors.red),
                                        ),
                                      ],
                                    ),

                                  // مؤشر تحليل الذكاء الاصطناعي
                                  if (_isAnalyzing && !_showAnswerFeedback)
                                    Column(
                                      children: [
                                        const SizedBox(height: 24),
                                        const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF3B82F6),
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '🤖 ${AppStrings.t(context, 'ai_thinking')}...',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: const Color(0xFF3B82F6),
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
              const SizedBox(height: 4),
              // Hearts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      index < hearts ? Icons.favorite : Icons.favorite_border,
                      color: index < hearts
                          ? color
                          : Colors.grey.withValues(alpha: 0.3),
                      size: 18,
                    ),
                  ),
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
              const SizedBox(height: 4),
              // Hearts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      index < hearts ? Icons.favorite : Icons.favorite_border,
                      color: index < hearts
                          ? color
                          : Colors.grey.withValues(alpha: 0.3),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ========== أنيميشن نهاية الجولة ==========
class RoundEndAnimation extends StatefulWidget {
  final bool playerWon;

  const RoundEndAnimation({Key? key, required this.playerWon})
    : super(key: key);

  @override
  State<RoundEndAnimation> createState() => _RoundEndAnimationState();
}

class _RoundEndAnimationState extends State<RoundEndAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade in ثم Fade out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Scale خفيف جداً
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 45,
                    vertical: 35,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.playerWon
                          ? [
                              const Color(0xFF10B981).withValues(alpha: 0.95),
                              const Color(0xFF059669).withValues(alpha: 0.95),
                            ]
                          : [
                              const Color(0xFFEF4444).withValues(alpha: 0.95),
                              const Color(0xFFDC2626).withValues(alpha: 0.95),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.playerWon
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.playerWon ? '⚽' : '💔',
                        style: const TextStyle(fontSize: 65),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.playerWon ? 'WIN' : 'Strike',
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.playerWon ? '+1 POINT' : 'OPPONENT +1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
