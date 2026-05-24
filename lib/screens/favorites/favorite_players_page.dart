import 'package:flutter/material.dart';
import '../../services/favorites_service.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';

class FavoritePlayersPage extends StatefulWidget {
  const FavoritePlayersPage({Key? key}) : super(key: key);

  @override
  State<FavoritePlayersPage> createState() => _FavoritePlayersPageState();
}

class _FavoritePlayersPageState extends State<FavoritePlayersPage> {
  final _favorites = FavoritesService();
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final ok = _favorites.addFavoritePlayer(_input.text);
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
            AppStrings.t(context, 'fav_players'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            hintText: AppStrings.t(context, 'add_player_hint'),
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
            _favorites.favoritePlayers.isEmpty
                ? _empty(AppStrings.t(context, 'no_fav_players'))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _favorites.favoritePlayers
                        .map((p) => _chip(p, () {
                              setState(() => _favorites.removeFavoritePlayer(p));
                            }))
                        .toList(),
                  ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: Chip(
        key: ValueKey(label),
        label: Text(label),
        deleteIcon: const Icon(Icons.close),
        onDeleted: onRemove,
        backgroundColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        deleteIconColor: colorScheme.onPrimaryContainer,
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
              Icons.person_outline,
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
