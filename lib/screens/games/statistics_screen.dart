import 'package:flutter/material.dart';
import '../../services/score_service.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ScoreService _scoreService = ScoreService();
  Map<String, int> _totalStats = {};
  Map<String, Map<String, int>> _gameStats = {};
  bool _isLoading = true;

  // قائمة الألعاب المتاحة
  final List<Map<String, dynamic>> _games = [
    {'key': 'football_quiz', 'name': 'football_quiz', 'icon': Icons.quiz},
    {
      'key': 'what_do_you_know',
      'name': 'what_do_you_know',
      'icon': Icons.lightbulb,
    },
    {'key': 'the_auction', 'name': 'the_auction', 'icon': Icons.gavel},
    {'key': 'the_bell', 'name': 'the_bell', 'icon': Icons.notifications_active},
    {
      'key': 'guess_transfers',
      'name': 'guess_the_player_from_transfers',
      'icon': Icons.swap_horiz,
    },
    {
      'key': 'thirty_challenge',
      'name': 'thirty_challenge',
      'icon': Icons.timer,
    },
    {
      'key': 'guess_the_player',
      'name': 'guess_the_player',
      'icon': Icons.person_search,
    },
    {
      'key': 'whos_the_outsider',
      'name': 'whos_the_outsider',
      'icon': Icons.group_remove,
    },
    {'key': 'common_club', 'name': 'common_club', 'icon': Icons.sports_soccer},
    {'key': 'jersey_number', 'name': 'jersey_number', 'icon': Icons.looks_one},
  ];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // تحميل الإحصائيات العامة
      final totalStats = await _scoreService.getTotalStats();

      // تحميل إحصائيات كل لعبة
      final gameStats = <String, Map<String, int>>{};
      for (final game in _games) {
        final stats = await _scoreService.getGameStats(game['key']);
        if (stats['totalGames'] != null && stats['totalGames']! > 0) {
          gameStats[game['key']] = stats;
        }
      }

      setState(() {
        _totalStats = totalStats;
        _gameStats = gameStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() => _isLoading = false);
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.t(context, 'stats_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            // زر مسح الإحصائيات
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              onPressed: _showClearConfirmDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الإحصائيات العامة
                      _buildTotalStatsCard(),
                      const SizedBox(height: 24),

                      // عنوان إحصائيات الألعاب
                      Text(
                        AppStrings.t(context, 'game_statistics'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // إحصائيات كل لعبة
                      if (_gameStats.isEmpty)
                        _buildEmptyStatsCard()
                      else
                        ..._gameStats.entries.map(
                          (entry) =>
                              _buildGameStatsCard(entry.key, entry.value),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTotalStatsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [Colors.white, colorScheme.primaryContainer.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                AppStrings.t(context, 'overall_statistics'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // صف الإحصائيات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                AppStrings.t(context, 'total_games'),
                _totalStats['totalGames'] ?? 0,
                Icons.gamepad,
                colorScheme.primary,
              ),
              _buildStatItem(
                AppStrings.t(context, 'total_wins'),
                _totalStats['totalWins'] ?? 0,
                Icons.star,
                Colors.amber,
              ),
              _buildStatItem(
                AppStrings.t(context, 'total_score'),
                _totalStats['totalScore'] ?? 0,
                Icons.score,
                Colors.green,
              ),
            ],
          ),

          // معدل الفوز
          if ((_totalStats['totalGames'] ?? 0) > 0) ...[
            const SizedBox(height: 20),
            _buildWinRateBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWinRateBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalGames = _totalStats['totalGames'] ?? 1;
    final totalWins = _totalStats['totalWins'] ?? 0;
    final winRate = (totalWins / totalGames) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.t(context, 'win_rate'),
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              '${winRate.toStringAsFixed(1)}%',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: winRate / 100,
            minHeight: 12,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              winRate >= 70
                  ? Colors.green
                  : winRate >= 40
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameStatsCard(String gameKey, Map<String, int> stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final game = _games.firstWhere((g) => g['key'] == gameKey);
    final bestScore = stats['bestScore'] ?? 0;
    final totalGames = stats['totalGames'] ?? 0;
    final avgScore = totalGames > 0
        ? (stats['totalScore'] ?? 0) / totalGames
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // أيقونة اللعبة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              game['icon'] as IconData,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // معلومات اللعبة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, game['name']),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.t(context, 'played')}: $totalGames | ${AppStrings.t(context, 'best')}: $bestScore',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${AppStrings.t(context, 'average')}: ${avgScore.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // أفضل نتيجة
          Column(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              Text(
                '$bestScore',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.sports_esports,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'no_games_played_yet'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearConfirmDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t(context, 'clear_statistics')),
        content: Text(AppStrings.t(context, 'clear_statistics_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.t(context, 'clear')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _scoreService.clearAllStats();
      await _loadStatistics();
    }
  }
}
