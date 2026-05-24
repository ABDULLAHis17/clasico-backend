import 'package:flutter/material.dart';
import '../screens/league_details_screen.dart';
import '../utils/app_strings.dart';
import 'smart_logo.dart';

class LeagueCard extends StatelessWidget {
  final dynamic league;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const LeagueCard({
    super.key,
    required this.league,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? (isSelected 
                  ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)]
                  : [const Color(0xFF1E293B), const Color(0xFF0F172A)])
              : (isSelected
                  ? [colorScheme.primary.withValues(alpha: 0.1), colorScheme.primary.withValues(alpha: 0.05)]
                  : [Colors.white, const Color(0xFFF1F5F9)]),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap ?? () {
            if (league == null) return;
            
            final String id = league is Map 
                ? (league['leagueid']?.toString() ?? league['id']?.toString() ?? league['index']?.toString() ?? '')
                : (league.id.toString());
            final String name = league is Map 
                ? (league['name'] ?? 'League')
                : (league.name);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeagueDetailsScreen(
                  leagueId: id,
                  leagueName: name,
                ),
              ),
            );
          },
          onLongPress: onLongPress,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
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
                  logo: league == null 
                      ? '🏆' 
                      : (league is Map ? (league['logo_url'] ?? league['image'] ?? '🏆') : league.logo),
                  size: 40,
                ),
              ),
            ),
          ),
          title: Text(
            league == null 
                ? AppStrings.t(context, 'all_leagues') 
                : (league is Map ? (league['name'] ?? 'Unknown') : league.name),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected && !isDark ? Colors.white : colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: league == null ? null : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.public, 
                  size: 14, 
                  color: isSelected && !isDark ? Colors.white70 : colorScheme.primary
                ),
                const SizedBox(width: 4),
                Text(
                  league is Map ? (league['country'] ?? 'International') : 'League',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected && !isDark ? Colors.white70 : colorScheme.outline
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
