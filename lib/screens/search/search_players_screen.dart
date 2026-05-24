import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../utils/football_translations.dart';
import '../../models/player.dart';
import '../details/player_details_screen.dart';
import '../../services/local_data_service.dart';
import '../../services/api_service.dart';
import '../../widgets/smart_logo.dart';
import '../../widgets/player_card.dart';

class SearchPlayersScreen extends StatefulWidget {
  const SearchPlayersScreen({Key? key}) : super(key: key);

  @override
  State<SearchPlayersScreen> createState() => _SearchPlayersScreenState();
}

class _SearchPlayersScreenState extends State<SearchPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocalDataService _localDataService = LocalDataService();
  final ApiService _apiService = ApiService();
  final List<String> _searchHistory = [];
  List<Player> _searchResults = [];
  List<Player> _topPlayers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTopPlayers();
  }

  Future<void> _loadTopPlayers() async {
    try {
      final results = await _apiService.getPlayers(limit: 10);
      _topPlayers = results.map((j) => _mapApiPlayer(j)).toList();
      if (mounted) setState(() {});
    } catch (_) {
      try {
        final results = await _localDataService.getTopPlayers(limit: 10);
        _topPlayers = results.map((j) => _mapPlayer(j)).toList();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  int _calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return 0;
    try {
      final dob = DateTime.parse(birthdate);
      final ageStr = (DateTime.now().difference(dob).inDays / 365.25).floor();
      return ageStr;
    } catch (_) {
      return 0;
    }
  }

  Player _mapApiPlayer(Map<String, dynamic> j) {
    final rawNationality = j['nationality'] as String?;
    
    return Player(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Unknown',
      position: translatePosition(j['position'] as String?),
      nationality: translateNationality(rawNationality),
      age: j['age'] as int? ?? _calculateAge(j['birthdate'] as String?),
      photo: j['photo_url']?.toString() ?? '⚽',
      nationalityFlag: getNationalityFlag(rawNationality),
      clubLogo: j['team_logo']?.toString() ?? '',
      club: j['team_name'] as String? ?? 'Team',
      number: j['shirt_number'] as int? ?? 0,
      rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
      dateOfBirth: j['birthdate'] as String?,
      height: j['height_cm']?.toString(),
      weight: j['weight_kg']?.toString(),
      preferredFoot: j['preferred_foot'] as String?,
      teamName: j['team_name'] as String?,
      statistics: PlayerStatistics(
        matchesPlayed: 0,
        goals: 0,
        assists: 0,
        yellowCards: 0,
        redCards: 0,
        minutesPlayed: 0,
        shotsOnTarget: 0,
        passAccuracy: 0,
      ),
      careerHistory: [],
    );
  }

  Player _mapPlayer(Map<String, dynamic> j) {
    // The j map comes from LocalDataService's _buildPlayerIndexTask
    final rawNationality = j['nationality'] as String?;
    
    return Player(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Unknown',
      position: translatePosition(j['position'] as String?),
      nationality: translateNationality(rawNationality),
      age: 0,
      photo: j['photo_url']?.toString() ?? '⚽',
      nationalityFlag: getNationalityFlag(rawNationality),
      clubLogo: '',
      club: j['team_name'] as String? ?? 'Team',
      number: 0,
      rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
      teamName: j['team_name'] as String?,
      statistics: PlayerStatistics(
        matchesPlayed: 0,
        goals: 0,
        assists: 0,
        yellowCards: 0,
        redCards: 0,
        minutesPlayed: 0,
        shotsOnTarget: 0,
        passAccuracy: 0,
      ),
      careerHistory: [],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
      return;
    }

    if (!_searchHistory.contains(query)) {
      if (mounted) {
        setState(() {
          _searchHistory.insert(0, query);
          if (_searchHistory.length > 10) {
            _searchHistory.removeLast();
          }
        });
      }
    }

    if (mounted) setState(() => _isSearching = true);

    try {
      final results = await _apiService.getPlayers(search: query, limit: 20);
      final mapped = results.map((j) => _mapApiPlayer(j)).toList();
      if (mounted) setState(() => _searchResults = mapped);
    } catch (_) {
      try {
        final results = await _localDataService.searchPlayers(query);
        final mapped = results.map((j) => _mapPlayer(j)).toList();
        if (mounted) setState(() => _searchResults = mapped);
      } catch (_) {
        if (mounted) setState(() => _searchResults = []);
      }
    }
  }

  void _clearSearchHistory() {
    if (mounted) setState(() => _searchHistory.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : colorScheme.surface,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
        elevation: 0,
        title: Text(
          AppStrings.t(context, 'search_players'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppStrings.t(context, 'search_players_hint'),
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _performSearch,
            ),
          ),

          // Content
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildTopPlayersAndHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'no_results_found'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return PlayerCard(player: _searchResults[index]);
      },
    );
  }

  Widget _buildTopPlayersAndHistory() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search History
          if (_searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t(context, 'search_history'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearSearchHistory,
                    child: Text(
                      AppStrings.t(context, 'clear'),
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchHistory.map((query) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = query;
                      _performSearch(query);
                    },
                    child: Chip(
                      label: Text(query),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _searchHistory.remove(query);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Top 10 Players
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppStrings.t(context, 'top_players'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _topPlayers.length,
            itemBuilder: (context, index) {
              return PlayerCard(
                player: _topPlayers[index],
                rank: index + 1,
              );
            },
          ),
        ],
      ),
    );
  }}
