import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/score_service.dart';
import 'what_do_you_know_screen.dart';
import 'the_auction_screen.dart';
import 'the_bell_screen.dart';
import 'guess_transfers_screen.dart';
import 'game_transition_screen.dart';
import 'final_results_screen.dart';

class FullThirtyChallengeScreen extends StatefulWidget {
  final bool isOnlineMode;

  const FullThirtyChallengeScreen({Key? key, this.isOnlineMode = false})
    : super(key: key);

  @override
  State<FullThirtyChallengeScreen> createState() =>
      _FullThirtyChallengeScreenState();
}

class _FullThirtyChallengeScreenState extends State<FullThirtyChallengeScreen> {
  final ScoreService _scoreService = ScoreService();
  int currentGameIndex = 0;
  int playerTotalScore = 0;
  int computerTotalScore = 0;

  final List<Map<String, dynamic>> games = [
    {'name': 'What Do You Know?', 'icon': '🧠', 'color': Color(0xFF8B5CF6)},
    {'name': 'The Auction', 'icon': '💰', 'color': Color(0xFFEC4899)},
    {'name': 'The Bell', 'icon': '🔔', 'color': Color(0xFFF59E0B)},
    {'name': 'Guess the Player', 'icon': '🔄', 'color': Color(0xFF10B981)},
  ];

  void _onGameCompleted(int playerScore, int computerScore) async {
    setState(() {
      playerTotalScore = playerScore;
      computerTotalScore = computerScore;
    });

    if (currentGameIndex < 3) {
      // عرض شاشة الانتقال الخرافية
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameTransitionScreen(
            currentGameName: games[currentGameIndex]['name'],
            currentGameIcon: games[currentGameIndex]['icon'],
            nextGameName: games[currentGameIndex + 1]['name'],
            nextGameIcon: games[currentGameIndex + 1]['icon'],
            playerScore: playerTotalScore,
            computerScore: computerTotalScore,
            currentGameNumber: currentGameIndex + 1,
            totalGames: 4,
          ),
        ),
      );

      setState(() {
        currentGameIndex++;
      });
      _navigateToGame();
    } else {
      _showFinalResults();
    }
  }

  void _navigateToGame() async {
    Widget screen;
    switch (currentGameIndex) {
      case 0:
        screen = WhatDoYouKnowScreen(
          isOnlineMode: false,
          isInFullChallenge: true,
          initialPlayerScore: playerTotalScore,
          initialComputerScore: computerTotalScore,
        );
        break;
      case 1:
        screen = TheAuctionScreen(
          isOnlineMode: false,
          isInFullChallenge: true,
          initialPlayerScore: playerTotalScore,
          initialComputerScore: computerTotalScore,
        );
        break;
      case 2:
        screen = TheBellScreen(
          isOnlineMode: false,
          isInFullChallenge: true,
          initialPlayerScore: playerTotalScore,
          initialComputerScore: computerTotalScore,
        );
        break;
      case 3:
        screen = GuessTransfersScreen(
          isOnlineMode: false,
          isInFullChallenge: true,
          initialPlayerScore: playerTotalScore,
          initialComputerScore: computerTotalScore,
        );
        break;
      default:
        return;
    }

    // الانتقال إلى اللعبة وانتظار النتيجة
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // التحقق من النتيجة
    if (result != null && result is Map<String, int>) {
      final playerScore = result['playerScore'] ?? 0;
      final computerScore = result['computerScore'] ?? 0;
      _onGameCompleted(playerScore, computerScore);
    } else {
      // إذا لم يتم إرجاع نتيجة، افترض نتيجة افتراضية أو ألغِ
      print('⚠️ No result returned from game');
      // يمكن هنا إضافة معالجة الإلغاء
    }
  }

  void _showFinalResults() async {
    // حفظ إنجاز تحدي الثلاثين
    final isWin = playerTotalScore > computerTotalScore;
    _scoreService.saveThirtyChallengeCompletion(
      playerTotalScore: playerTotalScore,
      computerTotalScore: computerTotalScore,
      isWin: isWin,
    );

    // عرض شاشة النتائج الخرافية
    final playAgain = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalResultsScreen(
          playerScore: playerTotalScore,
          computerScore: computerTotalScore,
          games: games,
        ),
      ),
    );

    // إذا اختار اللاعب اللعب مرة أخرى
    if (playAgain == true) {
      setState(() {
        currentGameIndex = 0;
        playerTotalScore = 0;
        computerTotalScore = 0;
      });
      _navigateToGame();
    }
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t(context, 'thirty_challenge'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${games[currentGameIndex]['name']} (${currentGameIndex + 1}/4)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                  child: Text(
                    '$playerTotalScore - $computerTotalScore',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            // Main Game Area
            Expanded(
              flex: 7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            games[currentGameIndex]['color'],
                            games[currentGameIndex]['color'].withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: games[currentGameIndex]['color'].withValues(alpha: 
                              0.4,
                            ),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        games[currentGameIndex]['icon'],
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      games[currentGameIndex]['name'],
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _navigateToGame,
                      icon: const Icon(Icons.play_arrow, size: 32),
                      label: Text(
                        AppStrings.t(context, 'start_game'),
                        style: const TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: games[currentGameIndex]['color'],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Side - Progress Panel
            Container(
              width: 120,
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildGameProgress(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameProgress(int gameIndex) {
    final isCompleted = gameIndex < currentGameIndex;
    final isCurrent = gameIndex == currentGameIndex;

    Color color;
    if (isCompleted) {
      color = const Color(0xFF10B981);
    } else if (isCurrent) {
      color = games[gameIndex]['color'];
    } else {
      color = Colors.grey.withValues(alpha: 0.3);
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isCurrent ? 4 : 2),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Text(
            games[gameIndex]['icon'],
            style: TextStyle(fontSize: isCurrent ? 32 : 24),
          ),
        ),
        if (isCompleted)
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
      ],
    );
  }
}
