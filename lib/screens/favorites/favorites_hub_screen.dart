import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import 'favorite_leagues_page.dart';
import 'favorite_clubs_page.dart';
import 'favorite_national_teams_page.dart';
import 'favorite_players_page.dart';
import 'favorite_matches_page.dart';

class FavoritesHubScreen extends StatelessWidget {
  const FavoritesHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.t(context, 'fav_hub_title'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _card(context, Icons.emoji_events_rounded, AppStrings.t(context, 'fav_leagues'), const FavoriteLeaguesPage(), const Color(0xFF3B82F6)),
          _card(context, Icons.shield_rounded, AppStrings.t(context, 'fav_clubs'), const FavoriteClubsPage(), const Color(0xFFEF4444)),
          _card(context, Icons.flag_rounded, AppStrings.t(context, 'fav_national'), const FavoriteNationalTeamsPage(), const Color(0xFFF59E0B)),
          _card(context, Icons.person_rounded, AppStrings.t(context, 'fav_players'), const FavoritePlayersPage(), const Color(0xFF8B5CF6)),
          _card(context, Icons.favorite_rounded, AppStrings.t(context, 'fav_matches'), const FavoriteMatchesPage(), const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, Widget page, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: AppThemes.cardGradient(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
