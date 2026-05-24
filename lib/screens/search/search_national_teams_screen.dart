import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../services/api_service.dart';
import '../../widgets/team_card.dart';
import '../../widgets/smart_logo.dart';

class SearchNationalTeamsScreen extends StatefulWidget {
  const SearchNationalTeamsScreen({Key? key}) : super(key: key);

  @override
  State<SearchNationalTeamsScreen> createState() => _SearchNationalTeamsScreenState();
}

class _SearchNationalTeamsScreenState extends State<SearchNationalTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<String> _searchHistory = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _topNationalTeams = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await _apiService.getTeams(teamType: 'national', limit: 50);
      if (mounted) setState(() => _topNationalTeams = results);
    } catch (_) {}
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) _searchHistory.removeLast();
      });
    }

    setState(() => _isSearching = true);

    try {
      final results = await _apiService.getTeams(search: query, teamType: 'national', limit: 20);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    }
  }

  Widget _buildTopNationalTeams() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    onPressed: () => setState(() => _searchHistory.clear()),
                    child: Text(AppStrings.t(context, 'clear')),
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
                      onDeleted: () => setState(() => _searchHistory.remove(query)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppStrings.t(context, 'top_national_teams'),
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
            itemCount: _topNationalTeams.length,
            itemBuilder: (context, index) => TeamCard(team: _topNationalTeams[index]),
          ),
        ],
      ),
    );
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
          AppStrings.t(context, 'search_national_teams'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppStrings.t(context, 'search_national_teams_hint'),
                hintStyle: const TextStyle(color: Colors.white70),
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
              ),
              onChanged: _performSearch,
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildTopNationalTeams(),
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
            Icon(Icons.search_off_rounded, size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'no_results_found'),
              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => TeamCard(team: _searchResults[index]),
    );
  }
}
