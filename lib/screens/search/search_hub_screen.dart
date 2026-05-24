import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import 'search_players_screen.dart';
import 'search_teams_screen.dart';
import 'search_leagues_screen.dart';
import 'search_coaches_screen.dart';
import 'search_national_teams_screen.dart';
import 'search_stadiums_screen.dart';

class SearchHubScreen extends StatelessWidget {
  const SearchHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : colorScheme.surface,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
        elevation: 0,
        title: Text(
          AppStrings.t(context, 'search_hub_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          _buildSearchCard(
            context,
            Icons.person_rounded,
            AppStrings.t(context, 'search_players'),
            const SearchPlayersScreen(),
            const Color(0xFF8B5CF6),
          ),
          _buildSearchCard(
            context,
            Icons.shield_rounded,
            AppStrings.t(context, 'search_teams'),
            const SearchTeamsScreen(),
            const Color(0xFFEF4444),
          ),
          _buildSearchCard(
            context,
            Icons.emoji_events_rounded,
            AppStrings.t(context, 'search_leagues'),
            const SearchLeaguesScreen(),
            const Color(0xFF3B82F6),
          ),
          _buildSearchCard(
            context,
            Icons.sports_rounded,
            AppStrings.t(context, 'search_coaches'),
            const SearchCoachesScreen(),
            const Color(0xFFF59E0B),
          ),
          _buildSearchCard(
            context,
            Icons.flag_rounded,
            AppStrings.t(context, 'search_national_teams'),
            const SearchNationalTeamsScreen(),
            const Color(0xFF10B981),
          ),
          _buildSearchCard(
            context,
            Icons.stadium_rounded,
            AppStrings.t(context, 'search_stadiums'),
            const SearchStadiumsScreen(),
            const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface.withValues(alpha: 0.95),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, colorScheme.surface],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
