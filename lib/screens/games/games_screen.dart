import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/game.dart';
import '../../models/friend.dart';
import '../../data/games_data.dart';
import '../../data/friends_data.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../widgets/select_game_dialog.dart';
import '../../widgets/select_friend_dialog.dart';
import '../../services/notification_service.dart';
import 'challenge_thirty_screen.dart';
import 'guess_the_player_screen.dart';
import 'football_quiz_screen.dart';
import 'whos_the_outsider_screen.dart';
import 'common_club_screen.dart';
import 'jersey_number_game_screen.dart';
import 'statistics_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool? _selectedMode; // true = online, false = offline, null = not selected

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
          leading: _selectedMode != null
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedMode = null;
                    });
                  },
                )
              : null,
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
                  Icons.sports_esports,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.t(context, 'games'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            // زر الإحصائيات
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: _selectedMode == null ? _buildModeSelection() : _buildGamesList(),
      ),
    );
  }

  Widget _buildModeSelection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.t(context, 'select_game_mode'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Online Mode
              _buildModeCard(
                icon: Icons.wifi,
                title: AppStrings.t(context, 'online_mode'),
                description: AppStrings.t(context, 'play_with_others'),
                color: const Color(0xFF3B82F6),
                onTap: () {
                  setState(() {
                    _selectedMode = true;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Offline Mode
              _buildModeCard(
                icon: Icons.offline_bolt,
                title: AppStrings.t(context, 'offline_mode'),
                description: AppStrings.t(context, 'play_solo'),
                color: const Color(0xFF10B981),
                onTap: () {
                  setState(() {
                    _selectedMode = false;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Play with Friends Mode
              _buildModeCard(
                icon: Icons.people,
                title: AppStrings.t(context, 'play_with_friends'),
                description: AppStrings.t(context, 'challenge_your_friends'),
                color: const Color(0xFFEC4899),
                onTap: _playWithFriends,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playWithFriends() async {
    // اختر اللعبة أولاً
    final selectedGame = await showDialog<Game>(
      context: context,
      builder: (context) => SelectGameDialog(isOnlineMode: true),
    );

    if (selectedGame == null) return;

    // ثم اختر الصديق
    final selectedFriend = await showDialog<Friend>(
      context: context,
      builder: (context) => const SelectFriendDialog(),
    );

    if (selectedFriend == null) return;

    // إضافة إشعار دعوة لعب للصديق
    NotificationService().addGameInviteNotification(
      senderId: 'current_user',
      senderName: 'أنت',
      senderAvatar: '😊',
      gameId: selectedGame.id,
      gameName: AppStrings.t(context, selectedGame.id),
    );

    // ابدأ اللعبة مع الصديق
    _navigateToGame(
      selectedGame,
      withFriend: true,
      friendName: selectedFriend.username,
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 40),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesList() {
    final games = GamesData.getGames()
        .where(
          (game) => _selectedMode == true
              ? game.availableOnline
              : game.availableOffline,
        )
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(game);
      },
    );
  }

  Future<String?> _getOpponentName() async {
    if (_selectedMode != true) return null; // في الوضع الأوفلاين، لا نحتاج اسم

    // في الوضع الأونلاين، اختر صديق عشوائي من الأصدقاء المتاحين
    final friends = FriendsData.getFriends();
    if (friends.isEmpty) return null;

    // اختر صديق عشوائي
    final random = Random();
    final randomFriend = friends[random.nextInt(friends.length)];

    return randomFriend.username;
  }

  Widget _buildGameCard(Game game) {
    final theme = Theme.of(context);
    final color = _getColorFromHex(game.color);

    return InkWell(
      onTap: () async {
        final opponentName = await _getOpponentName();
        _navigateToGame(game, friendName: opponentName);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.7)],
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(game.icon, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.t(context, game.id),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGame(
    Game game, {
    bool withFriend = false,
    String? friendName,
  }) {
    Widget? screen;

    switch (game.id) {
      case 'challenge_thirty':
        screen = ChallengeThirtyScreen(game: game);
        break;
      case 'guess_player':
        screen = GuessThePlayerScreen(
          isOnlineMode: _selectedMode == true || withFriend,
          level: 1,
          opponentName: friendName,
        );
        break;
      case 'football_quiz':
        screen = const FootballQuizScreen();
        break;
      case 'whos_the_outsider':
        screen = const WhosTheOutsiderDifficultyScreen();
        break;
      case 'common_club':
        screen = const CommonClubDifficultyScreen();
        break;
      case 'jersey_number':
        screen = const JerseyNumberGameScreen(difficulty: 'medium');
        break;
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
