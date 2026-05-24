import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/match.dart';
import '../screens/tabs/lineup_tab.dart';
import '../screens/tabs/events_tab.dart';
import '../screens/tabs/players_tab.dart';
import '../screens/tabs/injuries_tab.dart';
import '../screens/tabs/statistics_tab.dart';
import '../screens/tabs/ratings_tab.dart';
import '../screens/tabs/standings_tab.dart';
import '../screens/comments_screen.dart';
import '../utils/app_strings.dart';
import '../widgets/smart_logo.dart'; // Added import

class MatchDetailsScreen extends StatelessWidget {
  final Match match;

  const MatchDetailsScreen({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMatchPlayed = match.isPlayed;
    final locale = Localizations.localeOf(context).languageCode;
    
    // Initialize date formatting for the current locale
    initializeDateFormatting(locale, null);
    
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppStrings.t(context, 'match_details'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {},
              tooltip: AppStrings.t(context, 'add_to_favorites'),
            ),
            IconButton(
              icon: const Icon(Icons.comment, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(matchId: match.id),
                  ),
                );
              },
              tooltip: AppStrings.t(context, 'comments'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Refactored Premium Match Header
            _buildMatchHeader(context, isDark, colorScheme, locale),
            
            if (!isMatchPlayed)
              // No Data Available Message for unplayed matches
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.t(context, 'no_data_available'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.t(context, 'match_data_not_available'),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              // Tab Bar for played matches
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [Colors.white, colorScheme.primaryContainer.withValues(alpha: 0.05)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  isScrollable: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: [
                    _buildTab(Icons.sports_soccer, AppStrings.t(context, 'lineup')),
                    _buildTab(Icons.event_note, AppStrings.t(context, 'events')),
                    _buildTab(Icons.people, AppStrings.t(context, 'players')),
                    _buildTab(Icons.medical_services, AppStrings.t(context, 'injuries')),
                    _buildTab(Icons.bar_chart, AppStrings.t(context, 'statistics')),
                    _buildTab(Icons.star, AppStrings.t(context, 'ratings')),
                    _buildTab(Icons.emoji_events, AppStrings.t(context, 'standings')),
                  ],
                ),
              ),
              
              // Tab Views for played matches
              Expanded(
                child: TabBarView(
                  children: [
                    LineupTab(matchId: match.id),
                    EventsTab(matchId: match.id, match: match),
                    PlayersTab(matchId: match.id),
                    InjuriesTab(matchId: match.id),
                    StatisticsTab(matchId: match.id, match: match),
                    RatingsTab(matchId: match.id),
                    StandingsTab(matchId: match.id, leagueId: match.leagueId),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeader(BuildContext context, bool isDark, ColorScheme colorScheme, String locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
            ? [
                const Color(0xFF1E293B),
                colorScheme.primary.withValues(alpha: 0.8),
              ]
            : [
                colorScheme.primary,
                colorScheme.secondary,
              ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Match Date & Time
          Text(
            DateFormat('EEEE, MMMM d, yyyy', locale).format(match.matchTime),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 15),
          
          // Teams & Score/VS
          Row(
            children: [
              // Home Team
              Expanded(child: _buildTeamItem(match.homeTeam, match.homeTeamLogo, false)),
              
              // Score or VS
              _buildScoreArea(context, colorScheme),
              
              // Away Team
              Expanded(child: _buildTeamItem(match.awayTeam, match.awayTeamLogo, true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem(String name, String logo, bool isAway) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium Circular Logo Badge
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SmartLogo(logo: logo, size: 50),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildScoreArea(BuildContext context, ColorScheme colorScheme) {
    if (match.isPlayed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${match.homeScore ?? 0}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "-",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "${match.awayScore ?? 0}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          Text(
            DateFormat('HH:mm').format(match.matchTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppStrings.t(context, 'vs'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

