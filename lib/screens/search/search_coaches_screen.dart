import 'package:flutter/material.dart';

import '../../utils/app_strings.dart';

import '../../services/local_data_service.dart';

import '../../widgets/smart_logo.dart';

import '../details/coach_details_screen.dart';



class SearchCoachesScreen extends StatefulWidget {

  const SearchCoachesScreen({Key? key}) : super(key: key);



  @override

  State<SearchCoachesScreen> createState() => _SearchCoachesScreenState();

}



class _SearchCoachesScreenState extends State<SearchCoachesScreen> {

  final TextEditingController _searchController = TextEditingController();

  final List<String> _searchHistory = [];

  List<Map<String, dynamic>> _searchResults = [];

  List<Map<String, dynamic>> _topCoaches = [];

  bool _isSearching = false;



  @override

  void initState() {

    super.initState();

    _loadInitialData();

  }



  Future<void> _loadInitialData() async {

    final localData = LocalDataService();

    await localData.init();

    setState(() {

      _topCoaches = localData.searchCoaches('');

    });

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  void _performSearch(String query) {

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



    final localData = LocalDataService();

    setState(() {

      _isSearching = true;

      _searchResults = localData.searchCoaches(query);

    });

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

          AppStrings.t(context, 'search_coaches'),

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

                hintText: AppStrings.t(context, 'search_coaches_hint'),

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

            child: _isSearching ? _buildSearchResults() : _buildTopCoaches(),

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

      padding: const EdgeInsets.all(16),

      itemCount: _searchResults.length,

      itemBuilder: (context, index) => _buildCoachCard(_searchResults[index]),

    );

  }



  Widget _buildTopCoaches() {

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

              AppStrings.t(context, 'top_coaches'),

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

            itemCount: _topCoaches.length,

            itemBuilder: (context, index) => _buildCoachCard(_topCoaches[index], rank: index + 1),

          ),

        ],

      ),

    );

  }



  Widget _buildCoachCard(Map<String, dynamic> coach, {int? rank}) {

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final colorScheme = theme.colorScheme;



    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(16),

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

            blurRadius: 10,

            offset: const Offset(0, 4),

          ),

        ],

        border: Border.all(

          color: isDark ? Colors.white10 : Colors.black12,

        ),

      ),

      child: ListTile(

        onTap: () => Navigator.push(

          context,

          MaterialPageRoute(

            builder: (context) => CoachDetailsScreen(coach: coach),

          ),

        ),

        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: ClipRRect(

          borderRadius: BorderRadius.circular(12),

          child: Container(

            width: 50,

            height: 50,

            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,

            child: SmartLogo(logo: coach['image'] ?? coach['logo'] ?? '⚽', size: 40),

          ),

        ),

        title: Text(

          coach['name'] ?? 'Unknown',

          style: theme.textTheme.titleMedium?.copyWith(

            fontWeight: FontWeight.bold,

            color: colorScheme.onSurface,

          ),

        ),

        subtitle: Text(

          coach['team'] ?? coach['nationality'] ?? 'Coach',

          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),

        ),

        trailing: Icon(Icons.chevron_right, color: colorScheme.primary),

      ),

    );

  }

}

