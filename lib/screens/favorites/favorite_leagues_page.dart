import 'package:flutter/material.dart';
import '../../services/favorites_service.dart';
import '../../services/api_service.dart';
import '../../data/sample_data.dart';
import '../../models/league.dart';
import '../../widgets/smart_logo.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';

class FavoriteLeaguesPage extends StatefulWidget {
  const FavoriteLeaguesPage({Key? key}) : super(key: key);

  @override
  State<FavoriteLeaguesPage> createState() => _FavoriteLeaguesPageState();
}

class _FavoriteLeaguesPageState extends State<FavoriteLeaguesPage> {
  final _favorites = FavoritesService();
  List<League> _leagues = [];

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    try {
      final api = ApiService();
      if (await api.isApiAvailable()) {
        final data = await api.getLeagues();
        if (mounted) setState(() {
          _leagues = data.map((j) => League(
            id: j['id'] as String,
            name: j['name'] as String,
            logo: j['logo_url'] as String? ?? '⚽',
            upcomingMatches: 0,
          )).toList();
        });
      } else {
        if (mounted) setState(() => _leagues = SampleData.getLeagues());
      }
    } catch (_) {
      if (mounted) setState(() => _leagues = SampleData.getLeagues());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final leagues = _leagues;
    
    return Container(
      decoration: AppThemes.backgroundGradient(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                        colorScheme.secondary.withValues(alpha: 0.7),
                      ]
                    : [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.9),
                      ],
              ),
            ),
          ),
          title: Text(
            AppStrings.t(context, 'fav_leagues'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: leagues.length,
        itemBuilder: (_, i) {
          final l = leagues[i];
          final selected = _favorites.favoriteLeagueIds.contains(l.id);
          return GestureDetector(
            onTap: () {
              setState(() {
                selected
                    ? _favorites.removeFavoriteLeague(l.id)
                    : _favorites.addFavoriteLeague(l.id);
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // Removed SnackBar
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isDark && selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.2),
                          colorScheme.secondary.withValues(alpha: 0.2),
                        ],
                      )
                    : null,
                color: isDark
                    ? (selected ? null : colorScheme.surface)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmartLogo(logo: l.logo, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          l.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
