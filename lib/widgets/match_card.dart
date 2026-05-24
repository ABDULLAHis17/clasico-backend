import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../screens/match_details_screen.dart';
import '../screens/details/team_details_screen.dart';
import '../utils/page_transitions.dart';
import '../utils/app_strings.dart';
import 'smart_logo.dart';

class MatchCard extends StatefulWidget {
  final Match match;
  final bool showLeagueName;
  final String leagueName;
  final String leagueLogo;

  const MatchCard({
    Key? key,
    required this.match,
    this.showLeagueName = false,
    this.leagueName = '',
    this.leagueLogo = '',
  }) : super(key: key);

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Hero(
        tag: 'match_${widget.match.id}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: MatchDetailsScreen(match: widget.match),
                    direction: AxisDirection.left,
                  ),
                );
              },
              child: Stack(
                children: [
                   // Subtle corner accent for played matches
                  if (widget.match.isPlayed)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(40),
                          ),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  
                  // Main content
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Home Team
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailsScreen(
                                    team: {
                                      'name': widget.match.homeTeam,
                                      'logo': widget.match.homeTeamLogo,
                                      'country': '',
                                      'league': widget.leagueName,
                                      'stadium': '',
                                      'founded': '',
                                      'coach': '',
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                SmartLogo(
                                  logo: widget.match.homeTeamLogo,
                                  size: 44,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.match.homeTeam,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Status area
                        Container(
                          width: 100,
                          child: Column(
                            children: [
                              if (widget.match.isPlayed) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${widget.match.homeScore}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        ':',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${widget.match.awayScore}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppStrings.t(context, 'finished'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat('HH:mm').format(widget.match.matchTime),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('MMM d').format(widget.match.matchTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Away Team
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailsScreen(
                                    team: {
                                      'name': widget.match.awayTeam,
                                      'logo': widget.match.awayTeamLogo,
                                      'country': '',
                                      'league': widget.leagueName,
                                      'stadium': '',
                                      'founded': '',
                                      'coach': '',
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                SmartLogo(
                                  logo: widget.match.awayTeamLogo,
                                  size: 44,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.match.awayTeam,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ),
    );
  }
}
