import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import 'what_do_you_know_screen.dart';
import 'the_auction_screen.dart';
import 'the_bell_screen.dart';
import 'guess_transfers_screen.dart';
import 'full_thirty_challenge_screen.dart';

class ChallengeThirtyScreen extends StatelessWidget {
  final Game game;

  const ChallengeThirtyScreen({Key? key, required this.game}) : super(key: key);

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
            AppStrings.t(context, 'challenge_thirty'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Play Full Game Button
              _buildMainOption(context, theme, colorScheme),

              const SizedBox(height: 24),

              // Section Title
              Text(
                AppStrings.t(context, 'select_sub_game'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // Sub-games List
              Expanded(
                child: ListView.builder(
                  itemCount: game.subGames?.length ?? 0,
                  itemBuilder: (context, index) {
                    final subGame = game.subGames![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSubGameCard(context, subGame, index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainOption(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return _buildOptionCard(
      context: context,
      icon: Icons.emoji_events,
      title: AppStrings.t(context, 'play_full_thirty_challenge'),
      description: AppStrings.t(context, 'play_all_games_compete'),
      gradientColors: isDark
          ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
          : [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const FullThirtyChallengeScreen(isOnlineMode: false),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubGameCard(BuildContext context, SubGame subGame, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // ألوان جميلة وجذابة للألعاب الفرعية
    final gradients = [
      // ماذا تعرف - بنفسجي/أرجواني
      isDark
          ? [const Color(0xFF9D50BB), const Color(0xFF6E48AA)]
          : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      // المزاد - وردي/فوشيا
      isDark
          ? [const Color(0xFFFF6B9D), const Color(0xFFC94B7D)]
          : [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      // الجرس - ذهبي/برتقالي
      isDark
          ? [const Color(0xFFFFA94D), const Color(0xFFFF8C42)]
          : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
      // خمن الانتقالات - أخضر فيروزي
      isDark
          ? [const Color(0xFF20E3B2), const Color(0xFF29CBA2)]
          : [const Color(0xFF10B981), const Color(0xFF059669)],
    ];
    final gradient = gradients[index % gradients.length];

    return InkWell(
      onTap: () {
        Widget? screen;
        switch (subGame.id) {
          case 'what_do_you_know':
            screen = const WhatDoYouKnowScreen(isOnlineMode: false);
            break;
          case 'the_auction':
            screen = const TheAuctionScreen(isOnlineMode: false);
            break;
          case 'the_bell':
            screen = const TheBellScreen(isOnlineMode: false);
            break;
          case 'guess_transfers':
            screen = const GuessTransfersScreen(isOnlineMode: false);
            break;
        }
        if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen!),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withValues(alpha: isDark ? 0.15 : 0.08),
              gradient[1].withValues(alpha: isDark ? 0.08 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient[0].withValues(alpha: isDark ? 0.3 : 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(subGame.icon, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, subGame.id),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isDark ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.t(context, '${subGame.id}_desc'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : colorScheme.outline,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
