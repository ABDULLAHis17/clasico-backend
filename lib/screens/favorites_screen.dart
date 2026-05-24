import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/api_service.dart';
import '../data/sample_data.dart';
import '../models/league.dart';
import '../models/match.dart';
import '../widgets/smart_logo.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favorites = FavoritesService();
  final _clubCtrl = TextEditingController();
  final _nationCtrl = TextEditingController();
  final _playerCtrl = TextEditingController();
  List<League> _leagues = [];

  @override
  void initState() {
    super.initState();
    _clubCtrl.text = '';
    _nationCtrl.text = '';
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    try {
      final api = ApiService();
      if (await api.isApiAvailable()) {
        final data = await api.getLeagues();
        if (mounted) {
          setState(() {
            _leagues = data
                .map(
                  (j) => League(
                    id: j['id'] as String,
                    name: j['name'] as String,
                    logo: j['logo_url'] as String? ?? '⚽',
                    upcomingMatches: 0,
                  ),
                )
                .toList();
          });
        }
      } else {
        if (mounted) setState(() => _leagues = SampleData.getLeagues());
      }
    } catch (_) {
      if (mounted) setState(() => _leagues = SampleData.getLeagues());
    }
  }

  @override
  void dispose() {
    _clubCtrl.dispose();
    _nationCtrl.dispose();
    _playerCtrl.dispose();
    super.dispose();
  }

  List<Match> _favoriteMatches() {
    final ids = _favorites.favoriteMatchIds.toSet();
    final all = SampleData.getMatches();
    return all.where((m) => ids.contains(m.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final leagues = _leagues;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'fav_hub_title')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Favorite Leagues (multi-select add via dropdown for simplicity)
            _sectionTitle(AppStrings.t(context, 'fav_leagues')),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.cardFlat(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: null,
                    decoration: const InputDecoration(border: InputBorder.none),
                    items: leagues
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SmartLogo(logo: l.logo, size: 20),
                                const SizedBox(width: 8),
                                Text(l.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _favorites.addFavoriteLeague(val));
                      // Removed SnackBar
                    },
                    hint: Text(AppStrings.t(context, 'add_league_hint')),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _favorites.favoriteLeagueIds.map((id) {
                      final l = leagues.firstWhere(
                        (x) => x.id == id,
                        orElse: () => leagues.first,
                      );
                      return Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SmartLogo(logo: l.logo, size: 20),
                            const SizedBox(width: 8),
                            Text(l.name),
                          ],
                        ),
                        onDeleted: () =>
                            setState(() => _favorites.removeFavoriteLeague(id)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Favorite Club
            _sectionTitle(AppStrings.t(context, 'fav_clubs')),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.cardFlat(),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clubCtrl,
                      decoration: InputDecoration(
                        hintText: AppStrings.t(context, 'add_club_hint'),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(
                        () => _favorites.addFavoriteClub(_clubCtrl.text),
                      );
                      _clubCtrl.clear();
                    },
                    style: AppButtonStyles.secondary(context),
                    child: Text(AppStrings.t(context, 'save')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Show selected clubs
            if (_favorites.favoriteClubs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favorites.favoriteClubs
                      .map(
                        (c) => Chip(
                          label: Text(c),
                          onDeleted: () =>
                              setState(() => _favorites.removeFavoriteClub(c)),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Favorite National Team
            _sectionTitle(AppStrings.t(context, 'fav_national')),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.cardFlat(),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nationCtrl,
                      decoration: InputDecoration(
                        hintText: AppStrings.t(context, 'add_national_hint'),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(
                        () => _favorites.addFavoriteNationalTeam(
                          _nationCtrl.text,
                        ),
                      );
                      _nationCtrl.clear();
                    },
                    style: AppButtonStyles.secondary(context),
                    child: Text(AppStrings.t(context, 'save')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Show selected national teams
            if (_favorites.favoriteNationalTeams.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favorites.favoriteNationalTeams
                      .map(
                        (n) => Chip(
                          label: Text(n),
                          onDeleted: () => setState(
                            () => _favorites.removeFavoriteNationalTeam(n),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Favorite Players
            _sectionTitle(AppStrings.t(context, 'fav_players')),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.cardFlat(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playerCtrl,
                          decoration: InputDecoration(
                            hintText: AppStrings.t(context, 'add_player_hint'),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addPlayer(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _addPlayer,
                        style: AppButtonStyles.secondary(context),
                        child: Text(AppStrings.t(context, 'add')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _favorites.favoritePlayers
                        .map(
                          (p) => Chip(
                            label: Text(p),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () => setState(
                              () => _favorites.removeFavoritePlayer(p),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Favorite Matches
            _sectionTitle(AppStrings.t(context, 'fav_matches')),
            _buildFavoriteMatches(),
          ],
        ),
      ),
    );
  }

  void _addPlayer() {
    final name = _playerCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _favorites.addFavoritePlayer(name));
    _playerCtrl.clear();
  }

  Widget _buildFavoriteMatches() {
    final list = _favoriteMatches();
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.cardFlat(),
        child: Column(
          children: [
            const Icon(Icons.favorite_border, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              AppStrings.t(context, 'no_fav_matches'),
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(children: list.map((m) => _matchRow(m)).toList());
  }

  Widget _matchRow(Match m) {
    final isFav = _favorites.isMatchFavorite(m.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardFlat(),
      child: Row(
        children: [
          // Teams
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SmartLogo(logo: m.homeTeamLogo, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      m.homeTeam,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SmartLogo(logo: m.awayTeamLogo, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      m.awayTeam,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _favorites.toggleFavoriteMatch(m));
            },
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.error : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: AppTextStyles.heading3),
    );
  }
}
