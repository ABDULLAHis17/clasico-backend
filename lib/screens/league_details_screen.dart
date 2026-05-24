import 'package:flutter/material.dart';
import '../data/mock_match_data.dart';
import '../models/league_standing.dart';
import '../services/api_service.dart';
import '../services/local_data_service.dart';
import '../widgets/smart_logo.dart';
import '../utils/app_strings.dart';
import '../widgets/team_card.dart';
import 'details/team_details_screen.dart';

class LeagueDetailsScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  const LeagueDetailsScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _leagueDetail;
  List<Map<String, dynamic>> _leagueTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeagueData();
  }

  Future<void> _loadLeagueData() async {
    // Try API first (data from MySQL)
    final apiService = ApiService();

    try {
      final leagueData = await apiService.getLeague(widget.leagueId);
      final teamsData = await apiService.getLeagueTeams(widget.leagueId);

      if (leagueData != null && mounted) {
        setState(() {
          _leagueDetail = {
            'name': leagueData['name'] ?? widget.leagueName,
            'image': leagueData['logo_url'] ?? '',
            'country': leagueData['country'] ?? '',
            'teams': teamsData.length,
          };
          _leagueTeams = teamsData;
          _leagueTeams.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback to LocalDataService
    final localData = LocalDataService();
    await localData.init();

    Map<String, dynamic>? detail;
    detail = localData.getLeagueDetailByName(widget.leagueName);
    if (detail == null && int.tryParse(widget.leagueId) != null) {
       detail = localData.getLeagueDetail(int.parse(widget.leagueId));
    }

    if (detail != null) {
      final normalized = localData.normalizeLeagueData(detail);
      final teamsList = localData.getTeamsForLeague(normalized['league_index']);

      setState(() {
        _leagueDetail = normalized;
        _leagueTeams =
            teamsList.map((t) => localData.normalizeTeamData(t)).toList();
        _leagueTeams.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(title: Text(widget.leagueName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_leagueDetail == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(title: Text(widget.leagueName)),
        body: Center(
          child: Text(
            AppStrings.t(context, 'no_data_available'),
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(_leagueDetail!, colorScheme, isDark),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: AppStrings.t(context, 'teams')),
                Tab(text: AppStrings.t(context, 'standings')),
                Tab(text: AppStrings.t(context, 'league_info')),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeamsTab(isDark, colorScheme),
                _buildStandingsTab(isDark, colorScheme),
                _buildInfoTab(isDark, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      Map<String, dynamic> league, ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            isDark ? const Color(0xFF1E293B) : colorScheme.primary.withAlpha(200),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16, bottom: 48),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: SmartLogo(
                  logo: league['image'],
                  size: 60,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.leagueName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.public, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          league['country']?.isNotEmpty == true
                              ? league['country']
                              : AppStrings.t(context, 'unknown'),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsTab(bool isDark, ColorScheme colorScheme) {
    if (_leagueTeams.isEmpty) {
      return Center(
        child: Text(
          AppStrings.t(context, 'no_data_available'),
          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leagueTeams.length,
      itemBuilder: (context, index) {
        final team = _leagueTeams[index];
        return TeamCard(team: team);
      },
    );
  }

  Widget _buildStandingsTab(bool isDark, ColorScheme colorScheme) {
    final standings = MockMatchDataService.getLeagueStandings(widget.leagueId);

    if (standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'no_standings_available'),
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white60 : Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      _standingsHeaderCell('#', 28, isDark, isBold: true),
                      _standingsHeaderCell(AppStrings.t(context, 'club_name'), 95, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'mp_short'), 30, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'w_short'), 26, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'd_short'), 26, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'l_short'), 26, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'gf_short'), 30, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'ga_short'), 30, isDark),
                      _standingsHeaderCell('+/-', 32, isDark),
                      _standingsHeaderCell(AppStrings.t(context, 'pts_short'), 32, isDark, isBold: true),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 2, color: isDark ? Colors.white10 : Colors.grey.shade300),
                ...standings.map((s) => _buildStandingRow(s, isDark, colorScheme)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem(Colors.green.shade700, AppStrings.t(context, 'champions_league'), '1-4', isDark),
                _legendItem(Colors.orange.shade700, AppStrings.t(context, 'europa_league'), '5-6', isDark),
                _legendItem(Colors.red.shade700, AppStrings.t(context, 'relegation'), '18-20', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _standingsHeaderCell(String text, double width, bool isDark, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStandingRow(LeagueStanding standing, bool isDark, ColorScheme colorScheme) {
    final zone = standing.getPositionZone();
    Color? zoneColor;
    if (zone == 'champions') zoneColor = Colors.green.shade700;
    else if (zone == 'europa') zoneColor = Colors.orange.shade700;
    else if (zone == 'relegation') zoneColor = Colors.red.shade700;

    final isEven = standing.position % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isEven
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade50),
        border: Border(
          left: BorderSide(color: zoneColor ?? Colors.transparent, width: 4),
        ),
      ),
      child: Row(
        children: [
          _standingsCell(standing.position.toString(), 28, isDark, isBold: true, color: zoneColor),
          SizedBox(
            width: 95,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SmartLogo(logo: standing.clubLogo, size: 24),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    standing.clubName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _standingsCell(standing.matchesPlayed.toString(), 30, isDark),
          _standingsCell(standing.wins.toString(), 26, isDark),
          _standingsCell(standing.draws.toString(), 26, isDark),
          _standingsCell(standing.losses.toString(), 26, isDark),
          _standingsCell(standing.goalsFor.toString(), 30, isDark, color: Colors.green.shade600),
          _standingsCell(standing.goalsAgainst.toString(), 30, isDark, color: Colors.red.shade600),
          _standingsCell(
            standing.goalDifference >= 0 ? '+${standing.goalDifference}' : standing.goalDifference.toString(),
            32, isDark,
            color: standing.goalDifference >= 0 ? Colors.green.shade600 : Colors.red.shade600,
          ),
          _standingsCell(standing.points.toString(), 32, isDark, isBold: true, color: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _standingsCell(String text, double width, bool isDark, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, String positions, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            Text(positions, style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTab(bool isDark, ColorScheme colorScheme) {
    final league = _leagueDetail!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: AppStrings.t(context, 'league_info'),
          icon: Icons.info_outline,
          isDark: isDark,
          colorScheme: colorScheme,
          items: [
            _buildInfoRow(AppStrings.t(context, 'founded'),
                league['founded_year'], isDark),
            _buildInfoRow(AppStrings.t(context, 'country'), league['country'], isDark),
            _buildInfoRow(AppStrings.t(context, 'teams'),
                '${league['team_count']} ${AppStrings.t(context, 'teams')}', isDark),
            if (league['sponsor']?.toString().isNotEmpty == true &&
                league['sponsor'].toString() != AppStrings.t(context, 'unknown'))
              _buildInfoRow(AppStrings.t(context, 'sponsor'), league['sponsor'], isDark),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: AppStrings.t(context, 'champions'),
          icon: Icons.emoji_events,
          isDark: isDark,
          colorScheme: colorScheme,
          items: [
            _buildChampionRow(
                AppStrings.t(context, 'reigning_champion'), league['reigning_champion'], isDark, colorScheme),
            const SizedBox(height: 12),
            _buildChampionRow(
                AppStrings.t(context, 'record_champion'), league['record_champion'], isDark, colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, bool isDark) {
    if (value == null || value.isEmpty || value == AppStrings.t(context, 'unknown') || value == 'مجهول' || value == '0') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionRow(
      String label, Map<String, String?>? championInfo, bool isDark, ColorScheme colorScheme) {
    if (championInfo == null || (championInfo['text']?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  championInfo['text'] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (championInfo['link'] != null && championInfo['text'] != null)
                Icon(Icons.chevron_right, color: colorScheme.primary, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
