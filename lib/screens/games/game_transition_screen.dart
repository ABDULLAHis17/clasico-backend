import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';

class GameTransitionScreen extends StatefulWidget {
  final String currentGameName;
  final String currentGameIcon;
  final String nextGameName;
  final String nextGameIcon;
  final int playerScore;
  final int computerScore;
  final int currentGameNumber;
  final int totalGames;

  const GameTransitionScreen({
    Key? key,
    required this.currentGameName,
    required this.currentGameIcon,
    required this.nextGameName,
    required this.nextGameIcon,
    required this.playerScore,
    required this.computerScore,
    required this.currentGameNumber,
    required this.totalGames,
  }) : super(key: key);

  @override
  State<GameTransitionScreen> createState() => _GameTransitionScreenState();
}

class _GameTransitionScreenState extends State<GameTransitionScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scoreController;
  late AnimationController _nextGameController;
  late AnimationController _particleController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scoreOpacity;
  late Animation<double> _scoreBounce;
  late Animation<Offset> _nextGameSlide;
  late Animation<double> _nextGameFade;

  @override
  void initState() {
    super.initState();
    
    // Slide animation للعبة الحالية
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInBack,
    ));
    
    // Score animation
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _scoreOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    
    _scoreBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticInOut),
      ),
    );
    
    // Next game animation
    _nextGameController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _nextGameSlide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _nextGameController,
      curve: Curves.easeOutBack,
    ));
    
    _nextGameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _nextGameController,
        curve: Curves.easeIn,
      ),
    );
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // انتظر قليلاً ثم ابدأ
    await Future.delayed(const Duration(milliseconds: 300));
    
    // تحريك اللعبة الحالية للخارج
    await _slideController.forward();
    
    // إظهار النقاط
    _scoreController.forward();
    
    // انتظر قليلاً
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // إظهار اللعبة القادمة
    await _nextGameController.forward();
    
    // انتظر قليلاً ثم أغلق الشاشة
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scoreController.dispose();
    _nextGameController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppThemes.backgroundGradient(context),
        child: Stack(
          children: [
            // Particles في الخلفية
            _buildParticles(),
            
            // المحتوى الرئيسي
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Progress indicator
                  _buildProgressBar(),
                  
                  const Spacer(),
                  
                  // اللعبة الحالية (تخرج)
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildCurrentGameCard(),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // النقاط
                  AnimatedBuilder(
                    animation: _scoreController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _scoreOpacity.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value * _scoreBounce.value,
                          child: _buildScoreDisplay(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // اللعبة القادمة (تدخل)
                  SlideTransition(
                    position: _nextGameSlide,
                    child: FadeTransition(
                      opacity: _nextGameFade,
                      child: _buildNextGameCard(),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(_particleController.value),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            children: List.generate(widget.totalGames, (index) {
              final isCompleted = index < widget.currentGameNumber;
              final isCurrent = index == widget.currentGameNumber - 1;
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: isCompleted || isCurrent
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ],
                          )
                        : null,
                    color: isCompleted || isCurrent
                        ? null
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Game ${widget.currentGameNumber} of ${widget.totalGames}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGameCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.8),
            const Color(0xFF7C3AED).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.currentGameIcon,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            widget.currentGameName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '✓ Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    final isWinning = widget.playerScore > widget.computerScore;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWinning
              ? [
                  const Color(0xFF10B981).withValues(alpha: 0.9),
                  const Color(0xFF059669).withValues(alpha: 0.7),
                ]
              : [
                  const Color(0xFFEF4444).withValues(alpha: 0.9),
                  const Color(0xFFDC2626).withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (isWinning ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                .withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.t(context, 'current_score'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScorePill(AppStrings.t(context, 'you'), widget.playerScore, Colors.white),
              const SizedBox(width: 20),
              const Text(
                '-',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              _buildScorePill(AppStrings.t(context, 'ai'), widget.computerScore, Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorePill(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextGameCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha: 0.8),
            const Color(0xFFDB2777).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⚡ ${AppStrings.t(context, 'next_game')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.nextGameName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Starting...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Particle painter للخلفية
class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // رسم جزيئات متحركة
    for (int i = 0; i < 20; i++) {
      final x = (i * 50.0 + animationValue * 200) % size.width;
      final y = (i * 30.0 + animationValue * 100) % size.height;
      final opacity = (0.1 + (i % 3) * 0.1);
      
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 3),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
