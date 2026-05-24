import 'package:flutter/material.dart';
import '../../services/favorites_service.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';

class FavoriteClubsPage extends StatefulWidget {
  const FavoriteClubsPage({Key? key}) : super(key: key);

  @override
  State<FavoriteClubsPage> createState() => _FavoriteClubsPageState();
}

class _FavoriteClubsPageState extends State<FavoriteClubsPage> with SingleTickerProviderStateMixin {
  final _favorites = FavoritesService();
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final ok = _favorites.addFavoriteClub(_input.text);
    if (ok) {
      setState(() {});
      _input.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
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
            AppStrings.t(context, 'fav_clubs'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: InputDecoration(
                          hintText: AppStrings.t(context, 'add_club_hint'),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _add,
                      child: Text(AppStrings.t(context, 'add')),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _favorites.favoriteClubs.isEmpty
                  ? _empty(AppStrings.t(context, 'no_fav_clubs'))
                  : ListView(
                      children: _favorites.favoriteClubs
                          .map((c) => _tile(c, () {
                                setState(() => _favorites.removeFavoriteClub(c));
                              }))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _tile(String label, VoidCallback onRemove) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dismissible(
      key: ValueKey(label),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      child: Card(
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
              Icon(Icons.shield_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              color: colorScheme.outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
