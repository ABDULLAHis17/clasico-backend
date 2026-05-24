import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/match.dart';
import '../../utils/app_strings.dart';

class StatisticsTab extends StatelessWidget {
  final String matchId;
  final Match match;

  const StatisticsTab({Key? key, required this.matchId, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = SampleData.getMatchStatistics(matchId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatRow(context, AppStrings.t(context, 'possession'), stats.homeTeam.possession, stats.awayTeam.possession, isPercentage: true),
          _buildStatRow(context, AppStrings.t(context, 'shots'), stats.homeTeam.shots, stats.awayTeam.shots),
          _buildStatRow(context, AppStrings.t(context, 'shots_on_target'), stats.homeTeam.shotsOnTarget, stats.awayTeam.shotsOnTarget),
          _buildStatRow(context, AppStrings.t(context, 'passes'), stats.homeTeam.passes, stats.awayTeam.passes),
          _buildStatRow(context, AppStrings.t(context, 'pass_accuracy'), stats.homeTeam.passAccuracy, stats.awayTeam.passAccuracy, isPercentage: true),
          _buildStatRow(context, AppStrings.t(context, 'corners'), stats.homeTeam.corners, stats.awayTeam.corners),
          _buildStatRow(context, AppStrings.t(context, 'fouls'), stats.homeTeam.fouls, stats.awayTeam.fouls),
          _buildStatRow(context, '${AppStrings.t(context, 'yellow_card')}s', stats.homeTeam.yellowCards, stats.awayTeam.yellowCards),
          _buildStatRow(context, '${AppStrings.t(context, 'red_card')}s', stats.homeTeam.redCards, stats.awayTeam.redCards),
          _buildStatRow(context, AppStrings.t(context, 'offsides'), stats.homeTeam.offsides, stats.awayTeam.offsides),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int homeValue, int awayValue, {bool isPercentage = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? (homeValue / total) : 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF334155)]
            : [Colors.white, colorScheme.primaryContainer.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colorScheme.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 16),
            
            // Values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark 
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPercentage ? '$homeValue%' : '$homeValue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark 
                      ? colorScheme.secondary.withValues(alpha: 0.2)
                      : colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPercentage ? '$awayValue%' : '$awayValue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark 
                        ? Colors.white12
                        : colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: homePercentage,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
