import 'package:flutter/material.dart';
import '../services/local_data_service.dart';
import '../screens/details/team_details_screen.dart';
import 'smart_logo.dart';

class TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final int? rank;

  const TeamCard({
    super.key,
    required this.team,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final localData = LocalDataService();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            // Enrich team map with league logo before navigation if missing
            final leagueName = team['league']?.toString() ?? team['league_name']?.toString() ?? '';
            final enrichedTeam = {
              ...team,
              if (leagueName.isNotEmpty && (team['league_logo'] == null || team['league_logo'] == '')) 
                'league_logo': localData.getLeagueLogoByName(leagueName),
            };
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamDetailsScreen(team: enrichedTeam),
              ),
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: SmartLogo(
                      logo: team['logo'] as String? ?? team['logo_url'] as String? ?? '⚽',
                      size: 40,
                    ),
                  ),
                ),
              ),
              if (rank != null)
                Positioned(
                  top: -8,
                  left: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            team['name'] ?? 'Unknown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          team['country'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      // League Logo helper
                      Builder(
                        builder: (context) {
                          final leagueName = team['league']?.toString() ?? team['league_name']?.toString() ?? '';
                          final logoUrl = team['league_logo']?.toString() ?? localData.getLeagueLogoByName(leagueName);
                          
                          if (logoUrl.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SmartLogo(logo: logoUrl, size: 16),
                            );
                          }
                          return Icon(Icons.emoji_events_outlined, size: 14, color: colorScheme.secondary);
                        },
                      ),
                      Flexible(
                        child: Text(
                          team['league'] ?? team['league_name'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          trailing: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
