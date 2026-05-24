import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  final ScoreService _scoreService = ScoreService();
  late TabController _tabController;
  
  Map<String, int>? totalStats;
  Map<String, int>? bestScores;
  DateTime? lastPlayed;
  double? winRate;
  double? averageScore;
  bool isLoading = true;

  // Game names for detailed stats
  final List<Map<String, dynamic>> games = [
    {'name': 'what_do_you_know', 'title': 'What Do You Know', 'icon': '🧠', 'color': Color(0xFF8B5CF6)},
    {'name': 'the_auction', 'title': 'The Auction', 'icon': '💰', 'color': Color(0xFFEC4899)},
    {'name': 'the_bell', 'title': 'The Bell', 'icon': '🔔', 'color': Color(0xFFF59E0B)},
    {'name': 'guess_transfers', 'title': 'Guess Transfers', 'icon': '🔄', 'color': Color(0xFF10B981)},
    {'name': 'jersey_number', 'title': 'Jersey Number', 'icon': '🎽', 'color': Color(0xFF3B82F6)},
    {'name': 'common_club', 'title': 'Common Club', 'icon': '🏟️', 'color': Color(0xFFEF4444)},
    {'name': 'wrong_player', 'title': 'Wrong Player', 'icon': '❌', 'color': Color(0xFF6366F1)},
    {'name': 'quiz', 'title': 'Quiz', 'icon': '❓', 'color': Color(0xFF14B8A6)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    
    totalStats = await _scoreService.getTotalStats();
    bestScores = await _scoreService.getBestScores();
    lastPlayed = await _scoreService.getLastPlayedDate();
    winRate = await _scoreService.getWinRate();
    averageScore = await _scoreService.getAverageScore();
    
    setState(() => isLoading = false);
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
            '📊 ${AppStrings.t(context, 'stats_title')}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.refresh, color: colorScheme.onSurface),
              ),
              onPressed: _loadStats,
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            tabs: const [
              Tab(text: '📈 Overview', icon: Icon(Icons.dashboard_rounded)),
              Tab(text: '🎮 Games', icon: Icon(Icons.sports_esports_rounded)),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildGamesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Games Played',
                  value: '${totalStats!['gamesPlayed']}',
                  icon: Icons.sports_esports_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Wins',
                  value: '${totalStats!['wins']}',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Win Rate',
                  value: '${winRate!.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Score',
                  value: averageScore!.toStringAsFixed(1),
                  icon: Icons.stars_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Best Scores Section
          _buildSectionTitle('🏆 Best Scores'),
          const SizedBox(height: 12),
          _buildBestScoresCard(),

          const SizedBox(height: 24),

          // Achievements
          _buildSectionTitle('🎖️ Achievements'),
          const SizedBox(height: 12),
          _buildAchievementsCard(),

          const SizedBox(height: 24),

          // Last Played
          if (lastPlayed != null) ...[
            _buildSectionTitle('⏰ Last Played'),
            const SizedBox(height: 12),
            _buildLastPlayedCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildGamesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return FutureBuilder<Map<String, int>>(
          future: _scoreService.getGameStats(game['name']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }
            
            final stats = snapshot.data!;
            if (stats['played'] == 0) {
              return const SizedBox();
            }

            return _buildGameStatsCard(
              gameName: game['title'],
              icon: game['icon'],
              color: game['color'],
              stats: stats,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBestScoresCard() {
    if (bestScores == null || bestScores!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(AppStrings.t(context, 'no_best_scores')),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
            const Color(0xFFEF4444).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: bestScores!.entries.map((entry) {
          final game = games.firstWhere(
            (g) => g['name'] == entry.key,
            orElse: () => {'title': entry.key, 'icon': '🎮', 'color': Colors.grey},
          );
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(game['icon'], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    game['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.value} pts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    final totalGames = totalStats!['gamesPlayed']!;
    final wins = totalStats!['wins']!;
    final thirtyCompleted = totalStats!['thirtyChallengeCompleted']!;

    final achievements = [
      if (totalGames >= 1) {'icon': '🎮', 'title': 'First Game', 'desc': 'Played your first game'},
      if (totalGames >= 10) {'icon': '🔥', 'title': 'Getting Hot', 'desc': 'Played 10 games'},
      if (totalGames >= 50) {'icon': '💯', 'title': 'Half Century', 'desc': 'Played 50 games'},
      if (wins >= 1) {'icon': '🥇', 'title': 'First Victory', 'desc': 'Won your first game'},
      if (wins >= 10) {'icon': '👑', 'title': 'Champion', 'desc': 'Won 10 games'},
      if (winRate! >= 50) {'icon': '⚡', 'title': 'Winner', 'desc': '50%+ win rate'},
      if (thirtyCompleted >= 1) {'icon': '🏆', 'title': '30 Challenge', 'desc': 'Completed the challenge'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            const Color(0xFF6366F1).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: achievements.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Play games to unlock achievements!'),
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: achievements.map((achievement) {
                return Tooltip(
                  message: achievement['desc']!,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(achievement['icon']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          achievement['title']!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLastPlayedCard() {
    final formatter = DateFormat('MMM dd, yyyy - HH:mm');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF10B981),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(lastPlayed!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatsCard({
    required String gameName,
    required String icon,
    required Color color,
    required Map<String, int> stats,
  }) {
    final played = stats['played']!;
    final wins = stats['wins']!;
    final losses = stats['losses']!;
    final gameWinRate = played > 0 ? (wins / played * 100).toStringAsFixed(1) : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  gameName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$gameWinRate%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGameStat('Played', '$played', Icons.sports_esports_rounded),
              _buildGameStat('Wins', '$wins', Icons.check_circle_rounded),
              _buildGameStat('Losses', '$losses', Icons.cancel_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
