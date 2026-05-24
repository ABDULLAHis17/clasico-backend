import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/league_standing.dart';
import '../../utils/app_strings.dart';
import '../../widgets/smart_logo.dart';

class StandingsTab extends StatelessWidget {
  final String matchId;
  final String leagueId;

  const StandingsTab({
    Key? key,
    required this.matchId,
    required this.leagueId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final standings = SampleData.getLeagueStandings(leagueId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (standings.isEmpty) {
      return Center(
        child: Text(
          AppStrings.t(context, 'no_standings_available'),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white60 : Colors.grey,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [Colors.grey.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Standings Table
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStandingsTable(
                    context,
                    standings,
                    isDark,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  // Legend at bottom
                  _buildLegend(context, isDark, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            context,
            Colors.green.shade700,
            AppStrings.t(context, 'champions_league'),
            '1-4',
          ),
          _buildLegendItem(
            context,
            Colors.orange.shade700,
            AppStrings.t(context, 'europa_league'),
            '5-6',
          ),
          _buildLegendItem(
            context,
            Colors.red.shade700,
            AppStrings.t(context, 'relegation'),
            '18-20',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, Color color, String label, String positions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              positions,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white60 : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandingsTable(BuildContext context,
      List<LeagueStanding> standings, bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(context, isDark),
          
          // Divider
          Divider(
            height: 1,
            thickness: 2,
            color: isDark ? Colors.white10 : Colors.grey.shade300,
          ),
          
          // Table Rows
          ...standings.map((standing) {
            return _buildTableRow(context, standing, isDark, colorScheme);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('#', 28, context, isDark, isBold: true),
          _buildHeaderCell(
              AppStrings.t(context, 'club_name'), 85, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'mp_short'), 30, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'w_short'), 26, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'd_short'), 26, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'l_short'), 26, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'gf_short'), 30, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'ga_short'), 30, context, isDark),
          _buildHeaderCell(AppStrings.t(context, 'gd_short'), 32, context, isDark),
          _buildHeaderCell(
              AppStrings.t(context, 'pts_short'), 32, context, isDark,
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
      String text, double width, BuildContext context, bool isDark,
      {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, LeagueStanding standing,
      bool isDark, ColorScheme colorScheme) {
    final zone = standing.getPositionZone();
    Color? zoneColor;
    
    if (zone == 'champions') {
      zoneColor = Colors.green.shade700;
    } else if (zone == 'europa') {
      zoneColor = Colors.orange.shade700;
    } else if (zone == 'relegation') {
      zoneColor = Colors.red.shade700;
    }

    final isEven = standing.position % 2 == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isEven
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark
                ? const Color(0xFF0F172A)
                : Colors.grey.shade50),
        border: Border(
          left: BorderSide(
            color: zoneColor ?? Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          // Position
          _buildCell(
            standing.position.toString(),
            28,
            context,
            isDark,
            isBold: true,
            color: zoneColor,
          ),
          
          // Club Name & Logo
          SizedBox(
            width: 85,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SmartLogo(
                    logo: standing.clubLogo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    standing.clubName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Matches Played
          _buildCell(standing.matchesPlayed.toString(), 30, context, isDark),
          
          // Wins
          _buildCell(standing.wins.toString(), 26, context, isDark),
          
          // Draws
          _buildCell(standing.draws.toString(), 26, context, isDark),
          
          // Losses
          _buildCell(standing.losses.toString(), 26, context, isDark),
          
          // Goals For
          _buildCell(standing.goalsFor.toString(), 30, context, isDark,
              color: Colors.green.shade600),
          
          // Goals Against
          _buildCell(standing.goalsAgainst.toString(), 30, context, isDark,
              color: Colors.red.shade600),
          
          // Goal Difference
          _buildCell(
            standing.goalDifference >= 0
                ? '+${standing.goalDifference}'
                : standing.goalDifference.toString(),
            32,
            context,
            isDark,
            color: standing.goalDifference >= 0
                ? Colors.green.shade600
                : Colors.red.shade600,
          ),
          
          // Points
          _buildCell(
            standing.points.toString(),
            32,
            context,
            isDark,
            isBold: true,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    String text,
    double width,
    BuildContext context,
    bool isDark, {
    bool isBold = false,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
