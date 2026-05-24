import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_strings.dart';
import 'package:confetti/confetti.dart';

class FinalResultsScreen extends StatefulWidget {
  final int playerScore;
  final int computerScore;
  final List<Map<String, dynamic>> games;

  const FinalResultsScreen({
    Key? key,
    required this.playerScore,
    required this.computerScore,
    required this.games,
  }) : super(key: key);

  @override
  State<FinalResultsScreen> createState() => _FinalResultsScreenState();
}

class _FinalResultsScreenState extends State<FinalResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scoreController;
  late AnimationController _trophyController;
  late AnimationController _fireworksController;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _scoreScale;
  late Animation<double> _scoreCounter;
  late Animation<double> _trophyRotate;
  late Animation<double> _trophyBounce;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Main animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideUp = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Score animation
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scoreScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _scoreCounter = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Trophy animation
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _trophyRotate = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.easeInOut),
    );

    _trophyBounce = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.elasticInOut),
    );

    // Fireworks animation
    _fireworksController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _scoreController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _trophyController.repeat(reverse: true);

    // إذا فاز اللاعب، أطلق الاحتفالات
    if (widget.playerScore > widget.computerScore) {
      await Future.delayed(const Duration(milliseconds: 1200));
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scoreController.dispose();
    _trophyController.dispose();
    _fireworksController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.playerScore > widget.computerScore;
    final isDraw = widget.playerScore == widget.computerScore;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isWin
                ? [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                    const Color(0xFF047857),
                  ]
                : isDraw
                ? [
                    const Color(0xFF6366F1),
                    const Color(0xFF4F46E5),
                    const Color(0xFF4338CA),
                  ]
                : [
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
                    const Color(0xFFB91C1C),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Fireworks في الخلفية
            if (isWin) _buildFireworks(),

            // Confetti
            if (isWin)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 30,
                  maxBlastForce: 20,
                  minBlastForce: 10,
                  emissionFrequency: 0.05,
                  colors: const [
                    Colors.white,
                    Color(0xFFFBBF24),
                    Color(0xFFF59E0B),
                    Color(0xFF10B981),
                    Color(0xFF3B82F6),
                  ],
                ),
              ),

            // المحتوى الرئيسي
            SafeArea(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Trophy / Result Icon
                    AnimatedBuilder(
                      animation: _trophyController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _trophyRotate.value,
                          child: Transform.scale(
                            scale: _trophyBounce.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isWin
                                      ? '🏆'
                                      : isDraw
                                      ? '🤝'
                                      : '😔',
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Result Title
                    Text(
                      isWin
                          ? '🎉 ${AppStrings.t(context, 'you_won')}'
                          : isDraw
                          ? '🤝 ${AppStrings.t(context, 'its_a_tie')}'
                          : '💪 ${AppStrings.t(context, 'you_lost')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
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

                    const SizedBox(height: 16),

                    Text(
                      '🎯 ${AppStrings.t(context, 'challenge_completed')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Final Score
                    AnimatedBuilder(
                      animation: _scoreController,
                      builder: (context, child) {
                        final playerAnimatedScore =
                            (widget.playerScore * _scoreCounter.value).round();
                        final computerAnimatedScore =
                            (widget.computerScore * _scoreCounter.value)
                                .round();

                        return Transform.scale(
                          scale: _scoreScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildFinalScorePill(
                                  AppStrings.t(context, 'you'),
                                  playerAnimatedScore,
                                  true,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    'VS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildFinalScorePill(
                                  AppStrings.t(context, 'ai'),
                                  computerAnimatedScore,
                                  false,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Games Summary
                    _buildGamesSummary(),

                    const Spacer(),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.home_rounded),
                              label: Text(AppStrings.t(context, 'exit')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
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
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  true,
                                ); // Signal to play again
                              },
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(AppStrings.t(context, 'play_again')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: isWin
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalScorePill(String label, int score, bool isPlayer) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          ),
          child: Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamesSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            '4 Games Completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: widget.games.map((game) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(game['icon'], style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFireworks() {
    return AnimatedBuilder(
      animation: _fireworksController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: FireworksPainter(_fireworksController.value),
        );
      },
    );
  }
}

// Fireworks Painter
class FireworksPainter extends CustomPainter {
  final double animationValue;

  FireworksPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // رسم ألعاب نارية
    for (int i = 0; i < 5; i++) {
      final centerX = (i + 1) * size.width / 6;
      final centerY = size.height * 0.3;
      final progress = (animationValue + i * 0.2) % 1.0;

      for (int j = 0; j < 12; j++) {
        final angle = (j * math.pi * 2 / 12);
        final distance = progress * 100;
        final x = centerX + math.cos(angle) * distance;
        final y = centerY + math.sin(angle) * distance;

        paint.color = Colors.white.withValues(alpha: 1.0 - progress);
        canvas.drawCircle(Offset(x, y), 3 * (1.0 - progress), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
