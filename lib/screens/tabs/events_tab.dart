import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/match_event.dart';
import '../../models/match.dart';
import '../../utils/app_strings.dart';

class EventsTab extends StatelessWidget {
  final String matchId;
  final Match match;

  const EventsTab({Key? key, required this.matchId, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final events = SampleData.getMatchEvents(matchId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'no_events'),
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white60 : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event, match, context);
      },
    );
  }

  Widget _buildEventCard(MatchEvent event, Match match, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isHome = event.team == 'home';
    final teamName = isHome ? match.homeTeam : match.awayTeam;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF334155)]
            : [Colors.white, colorScheme.primaryContainer.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Minute Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.minute}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    AppStrings.t(context, 'minute'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Event Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getEventColor(event.type).withValues(alpha: isDark ? 0.3 : 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getEventColor(event.type),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  event.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getEventTitle(event, context),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark 
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      teamName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? colorScheme.primary : colorScheme.primary,
                      ),
                    ),
                  ),
                  if (event.assistPlayerName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 14,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${AppStrings.t(context, 'assist')}: ${event.assistPlayerName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.substitutePlayerName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? const Color(0xFF0F172A)
                          : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.playerName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.substitutePlayerName!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTitle(MatchEvent event, BuildContext context) {
    switch (event.type) {
      case 'goal':
        return '${AppStrings.t(context, 'goal')} - ${event.playerName}';
      case 'yellow_card':
        return '${AppStrings.t(context, 'yellow_card')} - ${event.playerName}';
      case 'red_card':
        return '${AppStrings.t(context, 'red_card')} - ${event.playerName}';
      case 'substitution':
        return AppStrings.t(context, 'substitution');
      default:
        return event.playerName;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
        return Colors.green;
      case 'yellow_card':
        return Colors.yellow;
      case 'red_card':
        return Colors.red;
      case 'substitution':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
