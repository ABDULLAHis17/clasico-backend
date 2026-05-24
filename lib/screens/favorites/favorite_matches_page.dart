import 'package:flutter/material.dart';
import '../../services/favorites_service.dart';
import '../../services/api_service.dart';
import '../../data/sample_data.dart';
import '../../models/match.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';

class FavoriteMatchesPage extends StatefulWidget {
  const FavoriteMatchesPage({Key? key}) : super(key: key);

  @override
  State<FavoriteMatchesPage> createState() => _FavoriteMatchesPageState();
}

class _FavoriteMatchesPageState extends State<FavoriteMatchesPage> {
  final _favorites = FavoritesService();
  List<Match> _allMatches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final api = ApiService();
      if (await api.isApiAvailable()) {
        // Even if API is available, we force use local test data for matches right now
      } 
      if (mounted) setState(() => _allMatches = SampleData.getMatches());
    } catch (_) {
      if (mounted) setState(() => _allMatches = SampleData.getMatches());
    }
  }

  List<Match> _favoriteMatches() {
    final ids = _favorites.favoriteMatchIds.toSet();
    return _allMatches.where((m) => ids.contains(m.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final list = _favoriteMatches();
    
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
            AppStrings.t(context, 'fav_matches'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: list.isEmpty
            ? _empty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _row(list[i]),
              ),
      ),
    );
  }

  Widget _row(Match m) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.homeTeamLogo}  ${m.homeTeam}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${m.awayTeamLogo}  ${m.awayTeam}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _favorites.toggleFavoriteMatch(m));
            },
            icon: const Icon(Icons.favorite, color: Colors.red),
          ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border,
                  color: colorScheme.outline,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.t(context, 'no_fav_matches'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
