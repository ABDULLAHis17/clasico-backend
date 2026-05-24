import 'package:flutter/material.dart';
import '../models/player.dart';
import '../screens/details/player_details_screen.dart';
import 'smart_logo.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final int? rank;
  final String? alternativeTeamName;
  final bool smallMode;

  const PlayerCard({
    super.key,
    required this.player,
    this.rank,
    this.alternativeTeamName,
    this.smallMode = false,
  });

  int _getPositionSortValue(String pos) {
    pos = pos.trim().toUpperCase();
    if (pos == 'MANAGER' || pos == 'COACH' || pos == 'المدرب') return 0;
    if (['GK', 'GOALKEEPER', 'حارس', 'حارس مرمى'].contains(pos)) return 1;
    if (['CB', 'RB', 'LB', 'RWB', 'LWB', 'DF', 'D', 'DEFENDER', 'مدافع', 'قلب دفاع', 'ظهير', 'ظهير أيمن', 'ظهير أيسر', 'ظهير أيمن متقدم', 'ظهير أيسر متقدم'].contains(pos)) return 2;
    if (['CM', 'CDM', 'CAM', 'RM', 'LM', 'MF', 'MIDFIELDER', 'وسط', 'وسط دفاعي', 'وسط هجومي', 'وسط أيمن', 'وسط أيسر'].contains(pos)) return 3;
    if (['ST', 'CF', 'RW', 'LW', 'FW', 'F', 'FORWARD', 'مهاجم', 'مهاجم صريح', 'مهاجم ثاني', 'جناح', 'جناح أيمن', 'جناح أيسر'].contains(pos)) return 4;
    return 5;
  }

  Color _getPositionColor(String pos, ColorScheme colorScheme) {
    pos = pos.trim().toUpperCase();
    if (pos == 'MANAGER' || pos == 'COACH' || pos == 'المدرب') return Colors.white;
    if (['GK', 'GOALKEEPER', 'حارس', 'حارس مرمى'].contains(pos)) return Colors.blue;
    if (['CB', 'RB', 'LB', 'RWB', 'LWB', 'DF', 'D', 'DEFENDER', 'مدافع', 'قلب دفاع', 'ظهير', 'ظهير أيمن', 'ظهير أيسر', 'ظهير أيمن متقدم', 'ظهير أيسر متقدم'].contains(pos)) return Colors.green;
    if (['CM', 'CDM', 'CAM', 'RM', 'LM', 'MF', 'MIDFIELDER', 'وسط', 'وسط دفاعي', 'وسط هجومي', 'وسط أيمن', 'وسط أيسر'].contains(pos)) return Colors.yellow;
    if (['ST', 'CF', 'RW', 'LW', 'FW', 'F', 'FORWARD', 'مهاجم', 'مهاجم صريح', 'مهاجم ثاني', 'جناح', 'جناح أيمن', 'جناح أيسر'].contains(pos)) return Colors.red;
    return colorScheme.primary.withValues(alpha: 0.2);
  }

  List<Color> _getRatingGradients(double rating) {
    if (rating >= 90) return [const Color(0xFFFFD700), const Color(0xFFFDB931)];
    if (rating >= 80) return [const Color(0xFFC0C0C0), const Color(0xFFA6A6A6)];
    if (rating >= 70) return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
    return [Colors.blueGrey.shade400, Colors.blueGrey.shade700];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool isManager = _getPositionSortValue(player.position) == 0;
    final Color positionBorderColor = _getPositionColor(player.position, colorScheme);

    return Container(
      margin: EdgeInsets.only(bottom: smallMode ? 8 : 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailsScreen(player: player),
              ),
            );
          },
          borderRadius: BorderRadius.circular(smallMode ? 12 : 16),
          child: Container(
            padding: EdgeInsets.all(smallMode ? 8 : 12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface.withValues(alpha: 0.3) : colorScheme.surface,
              borderRadius: BorderRadius.circular(smallMode ? 12 : 16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Player Photo / Rank
                Stack(
                  children: [
                    Container(
                      width: smallMode ? 50 : 80,
                      height: smallMode ? 50 : 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(smallMode ? 10 : 16),
                        border: Border.all(
                          color: positionBorderColor,
                          width: smallMode ? 1.5 : 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(smallMode ? 9 : 14),
                        child: SmartLogo(
                          logo: player.photo,
                          size: smallMode ? 40 : 70,
                        ),
                      ),
                    ),
                    if (rank != null)
                      Positioned(
                        top: smallMode ? -2 : -5,
                        left: smallMode ? -2 : -5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: smallMode ? 6 : 8,
                            vertical: smallMode ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(smallMode ? 8 : 10),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: smallMode ? 10 : 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: smallMode ? 10 : 16),

                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            player.position,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (player.club != null || alternativeTeamName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colorScheme.outline.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                player.club ?? alternativeTeamName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Nationality
                      Row(
                        children: [
                          if (player.nationalityFlag != null) ...[
                            Text(player.nationalityFlag!, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              player.nationality,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rating Badge (hide if Manager)
                if (!isManager)
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _getRatingGradients(player.rating),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getRatingGradients(player.rating)[0].withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.rating.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'OVR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
