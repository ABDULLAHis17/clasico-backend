import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../utils/football_translations.dart';
import '../../services/favorites_service.dart';
import '../../services/local_data_service.dart';
import '../../services/api_service.dart';
import '../../widgets/smart_logo.dart';
import '../../models/player.dart';
import '../../widgets/player_card.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> team;

  const TeamDetailsScreen({Key? key, required this.team}) : super(key: key);

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  late bool _isFavorite;
  final _favoritesService = FavoritesService();
  final _localData = LocalDataService();
  final _apiService = ApiService();

  bool _isLoading = true;
  Map<String, dynamic> _normalizedTeam = {};
  List<Map<String, dynamic>> _trophies = [];
  Map<String, dynamic>? _rawTeam;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesService.favoriteClubs.contains(widget.team['name']);
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() => _isLoading = true);

    final teamName = widget.team['name'] ?? 'Unknown Team';
    _isFavorite = _favoritesService.isClubFavorite(teamName);

    // ── Load team details from LocalDataService (stadium, trophies, etc.) ──
    _rawTeam = await _localData.getTeamDetail(teamName);
    if (_rawTeam != null) {
      _normalizedTeam = _localData.normalizeTeamData(_rawTeam!);
      // Keep the full name from search screen (e.g. "Manchester United")
      // instead of the abbreviated name from team_details.json (e.g. "Manchester U")
      _normalizedTeam['name'] = teamName;
    } else {
      _normalizedTeam = Map<String, dynamic>.from(widget.team);
    }
    _trophies = _localData.extractTrophies(_rawTeam);

    // ── Load players and coach from API (MySQL) — single source of truth ──
    try {
      final apiData = await _apiService.getTeamByName(teamName);
      if (apiData != null) {
        // Override fields from API
        _normalizedTeam['squad_size'] = apiData['squad_size'] ?? 0;
        _normalizedTeam['avg_rating'] = apiData['avg_rating'] ?? 0.0;
        _normalizedTeam['top_rating'] = apiData['top_rating'] ?? 0.0;
        _normalizedTeam['total_trophies'] = apiData['total_trophies'] ?? 0;
        if (apiData['logo_url'] != null) _normalizedTeam['logo_url'] = apiData['logo_url'];
        if (apiData['league_name'] != null) _normalizedTeam['league_name'] = apiData['league_name'];
        if (apiData['league_logo'] != null) _normalizedTeam['league_logo'] = apiData['league_logo'];
        if (apiData['stadium_name'] != null) _normalizedTeam['stadium_name'] = apiData['stadium_name'];
        if (apiData['stadium_capacity'] != null) _normalizedTeam['stadium_capacity'] = apiData['stadium_capacity'];
        if (apiData['stadium_image'] != null) _normalizedTeam['stadium_image'] = apiData['stadium_image'];
        if (apiData['stadium_city'] != null) _normalizedTeam['stadium_city'] = apiData['stadium_city'];

        // Use trophy data from API (complete scraped data) instead of local JSON
        final apiCups = apiData['cups'] as Map<String, dynamic>?;
        final apiCupsDate = apiData['cups_date'] as List<dynamic>?;
        if (apiCups != null || apiCupsDate != null) {
          final apiRawTeam = <String, dynamic>{
            'cups': apiCups ?? {},
            'cups_date': apiCupsDate ?? [],
          };
          _trophies = _localData.getTeamTrophies(apiRawTeam);
        }

        // Coach from API
        final coachData = apiData['coach'] as Map<String, dynamic>?;
        if (coachData != null && coachData['name'] != null) {
          _normalizedTeam['coach_player'] = Player(
            id: coachData['id']?.toString() ?? 'coach_${teamName.hashCode}',
            name: coachData['name']?.toString() ?? 'Unknown Coach',
            position: 'Manager',
            nationality: _getLocalizedCountry(_normalizedTeam['country']?.toString())['name'] ?? '',
            age: 0,
            photo: coachData['photo_url']?.toString() ?? '',
            nationalityFlag: _getLocalizedCountry(_normalizedTeam['country']?.toString())['flag'] ?? '🌍',
            clubLogo: _normalizedTeam['logo_url'] ?? '',
            club: teamName,
            number: 0,
            rating: 0,
            teamName: teamName,
            statistics: PlayerStatistics(
              matchesPlayed: 0, goals: 0, assists: 0, yellowCards: 0,
              redCards: 0, minutesPlayed: 0, shotsOnTarget: 0, passAccuracy: 0
            ),
            careerHistory: [],
          );
        }

        // Players from API (MySQL) — same data as search_players_screen
        final playersList = apiData['players'] as List? ?? [];
        if (playersList.isNotEmpty) {
          final List<Player> playerObjects = playersList
              .where((p) => p is Map<String, dynamic>)
              .map((p) => _mapApiPlayer(p as Map<String, dynamic>, teamName))
              .toList();
          _normalizedTeam['player_objects'] = playerObjects;
          _normalizedTeam['squad_size'] = playerObjects.length;
        }
      }
    } catch (e) {
      debugPrint('[TeamDetails] API failed, falling back to LocalDataService: $e');
      // Fallback: load players from local JSON
      final teamPlayers = await _localData.getPlayersByTeam(teamName);
      if (teamPlayers.isNotEmpty) {
        final List<Player> playerObjects = teamPlayers.map((j) => _mapPlayer(j)).toList();
        final seen = <String>{};
        final uniquePlayers = <Player>[];
        for (final p in playerObjects) {
          if (seen.add(p.id)) uniquePlayers.add(p);
        }
        _normalizedTeam['player_objects'] = uniquePlayers;
        _normalizedTeam['squad_size'] = uniquePlayers.length;
      }

      // Fallback: coach from raw JSON
      if (_rawTeam != null) {
        final coachField = _rawTeam!['coach'] ?? _rawTeam!['المدرب:'] ?? _rawTeam!['مدرب:'] ?? _rawTeam!['Manager:'] ?? _rawTeam!['Coach:'];
        if (coachField != null && !_normalizedTeam.containsKey('coach_player')) {
          String coachName = '';
          String coachPhoto = '';
          if (coachField is Map) {
            coachPhoto = coachField['image']?.toString() ?? '';
            final countryField = coachField['بلد'];
            if (countryField is Map) {
              coachName = countryField['text']?.toString().trim() ?? 'Unknown Coach';
            } else if (coachField['text'] != null) {
              coachName = coachField['text'].toString().trim();
            }
            if (coachPhoto.isEmpty) {
              final link = (countryField is Map ? countryField['link'] : '') ?? '';
              if (link.toString().contains('mid=')) {
                final mid = link.toString().split('mid=').last.split('&').first;
                if (mid.isNotEmpty) coachPhoto = 'https://cdn.soccerwiki.org/images/manager/$mid.png';
              }
            }
          } else {
            coachName = coachField.toString();
          }
          if (coachName.isNotEmpty) {
            _normalizedTeam['coach_player'] = Player(
              id: 'coach_${teamName.hashCode}',
              name: coachName,
              position: 'Manager',
              nationality: _getLocalizedCountry(_normalizedTeam['country']?.toString())['name'] ?? '',
              age: 0,
              photo: coachPhoto,
              nationalityFlag: _getLocalizedCountry(_normalizedTeam['country']?.toString())['flag'] ?? '🌍',
              clubLogo: _normalizedTeam['logo_url'] ?? '',
              club: teamName,
              number: 0,
              rating: 0,
              teamName: teamName,
              statistics: PlayerStatistics(
                matchesPlayed: 0, goals: 0, assists: 0, yellowCards: 0,
                redCards: 0, minutesPlayed: 0, shotsOnTarget: 0, passAccuracy: 0
              ),
              careerHistory: [],
            );
          }
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Player _mapPlayer(Map<String, dynamic> j) {
    final rawNationality = j['nationality'] as String? ?? '';

    return Player(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? j['text']?.toString() ?? 'Unknown',
      position: translatePosition(j['position'] as String?),
      nationality: translateNationality(rawNationality),
      age: 0,
      photo: (j['photo_url'] ?? j['photo'] ?? j['image'])?.toString() ?? '⚽',
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

  Player _mapApiPlayer(Map<String, dynamic> j, String teamName) {
    final rawNationality = j['nationality'] as String?;
    final rating = j['market_value'] as num?;

    return Player(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Unknown',
      position: translatePosition(j['position'] as String?),
      nationality: translateNationality(rawNationality),
      age: j['age'] as int? ?? 0,
      photo: j['photo_url']?.toString() ?? '⚽',
      nationalityFlag: getNationalityFlag(rawNationality),
      clubLogo: _normalizedTeam['logo_url'] ?? '',
      club: teamName,
      number: j['shirt_number'] as int? ?? 0,
      rating: rating?.toDouble() ?? 0.0,
      dateOfBirth: j['birthdate'] as String?,
      height: j['height_cm']?.toString(),
      weight: j['weight_kg']?.toString(),
      preferredFoot: j['preferred_foot'] as String?,
      teamName: teamName,
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

  Map<String, dynamic> get team => _normalizedTeam.isNotEmpty ? _normalizedTeam : widget.team;

  Map<String, String> _getLocalizedCountry(String? country) {
    if (country == null) return {'flag': '🌍', 'name': 'N/A'};
    
    String flag = '🌍';
    String key = '';

    if (country.contains('إسبانيا') || country.contains('اسبانيا')) {
      flag = '🇪🇸';
      key = 'spain';
    } else if (country.contains('إنكلترا') || country.contains('انجلترا')) {
      flag = '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
      key = 'england';
    } else if (country.contains('ألمانيا') || country.contains('المانيا')) {
      flag = '🇩🇪';
      key = 'germany';
    } else if (country.contains('إيطاليا') || country.contains('ايطاليا')) {
      flag = '🇮🇹';
      key = 'italy';
    } else if (country.contains('فرنسا')) {
      flag = '🇫🇷';
      key = 'france';
    } else if (country.contains('البرتغال')) {
      flag = '🇵🇹';
      key = 'portugal';
    } else if (country.contains('هولندا')) {
      flag = '🇳🇱';
      key = 'netherlands';
    } else if (country.contains('البرازيل') || country.contains('برازيل')) {
      flag = '🇧🇷';
      key = 'brazil';
    } else if (country.contains('الأرجنتين') || country.contains('ارجنتين')) {
      flag = '🇦🇷';
      key = 'argentina';
    } else if (country.contains('السعودية')) {
      flag = '🇸🇦';
      key = 'saudi_arabia';
    } else if (country.contains('مصر')) {
      flag = '🇪🇬';
      key = 'egypt';
    } else if (country.contains('المغرب')) {
      flag = '🇲🇦';
      key = 'morocco';
    } else if (country.contains('الجزائر')) {
      flag = '🇩🇿';
      key = 'algeria';
    } else if (country.contains('تونس')) {
      flag = '🇹🇳';
      key = 'tunisia';
    } else if (country.contains('قطر')) {
      flag = '🇶🇦';
      key = 'qatar';
    } else if (country.contains('الإمارات')) {
      flag = '🇦🇪';
      key = 'uae';
    } else if (country.contains('أمريكا') || country.contains('الولايات المتحدة')) {
      flag = '🇺🇸';
      key = 'usa';
    } else if (country.contains('بلجيكا')) {
      flag = '🇧🇪';
      key = 'belgium';
    } else if (country.contains('كرواتيا')) {
      flag = '🇭🇷';
      key = 'croatia';
    } else if (country.contains('الأوروغواي') || country.contains('اوروغواي')) {
      flag = '🇺🇾';
      key = 'uruguay';
    } else if (country.contains('تركيا')) {
      flag = '🇹🇷';
      key = 'turkey';
    } else if (country.contains('المكسيك')) {
      flag = '🇲🇽';
      key = 'mexico';
    } else if (country.contains('اليابان')) {
      flag = '🇯🇵';
      key = 'japan';
    }

    final String name = key.isNotEmpty 
        ? AppStrings.t(context, key) 
        : country;

    return {'flag': flag, 'name': name};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isFavorite) {
                            _favoritesService.removeFavoriteClub(team['name']);
                          } else {
                            _favoritesService.addFavoriteClub(team['name']);
                          }
                          _isFavorite = !_isFavorite;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isFavorite
                                  ? '${team['name']} ${AppStrings.t(context, 'added_to_favorites')}'
                                  : '${team['name']} ${AppStrings.t(context, 'removed_from_favorites')}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Hero(
                              tag: 'team_${team['name']}',
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SmartLogo(
                                    logo: team['logo_url'] ?? team['logo'] ?? '',
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              team['name'] ?? 'Unknown Team',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (team['nickname'] != null && (team['nickname'] as String).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '"${team['nickname']}"',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsSection(context),
                        const SizedBox(height: 16),
                        _buildInfoSection(context),
                        const SizedBox(height: 16),
                        if (team['stadium_name'] != null &&
                            (team['stadium_name'] as String).isNotEmpty) ...[
                          _buildStadiumSection(context),
                          const SizedBox(height: 16),
                        ],
                        if (_trophies.isNotEmpty) ...[
                          _buildTrophiesSection(context),
                          const SizedBox(height: 16),
                        ],
                        if ((team['player_objects'] != null &&
                            (team['player_objects'] as List).isNotEmpty) ||
                            (team['players'] != null &&
                            (team['players'] as List).isNotEmpty))
                          _buildPlayersSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('👥', 'Squad', '${team['squad_size'] ?? 0}'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem('🏆', 'Trophies', '${team['total_trophies'] ?? 0}'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem('📅', 'Founded', '${team['founded_year'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context, 
            _getLocalizedCountry(team['country']?.toString())['flag']!, 
            'Country', 
            _getLocalizedCountry(team['country']?.toString())['name']!,
          ),
          if (team['league_name'] != null && team['league_name'].toString().isNotEmpty)
            _buildInfoRow(
              context, 
              (team['league_logo'] != null && team['league_logo'].toString().isNotEmpty) 
                  ? team['league_logo'].toString() 
                  : '🏆', 
              'League', 
              team['league_name'].toString(),
            ),
          if (team['city'] != null && team['city'].toString().isNotEmpty)
            _buildInfoRow(context, '🏙️', 'City', team['city'].toString()),
          if (team['founded_year'] != null && team['founded_year'].toString().isNotEmpty)
            _buildInfoRow(context, '📅', 'Founded', team['founded_year'].toString()),
          if (team['short_name'] != null && team['short_name'].toString().isNotEmpty)
            _buildInfoRow(context, '📝', 'Short Code', team['short_name'].toString()),
          if (team['nickname'] != null && team['nickname'].toString().isNotEmpty)
            _buildInfoRow(context, '🏷️', 'Nickname', team['nickname'].toString()),
        ],
      ),
    );
  }

  Widget _buildStadiumSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stadium, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Stadium',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, '🏟️', 'Name', team['stadium_name'] ?? 'N/A'),
          if (team['city'] != null && (team['city'] as String).isNotEmpty)
            _buildInfoRow(context, '📍', 'Location', team['city']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, dynamic icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon is String && icon.startsWith('http'))
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: SmartLogo(logo: icon, size: 28),
              ),
            )
          else if (icon is String)
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            )
          else
            const Text('🌍', style: TextStyle(fontSize: 24)),
          
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophiesSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trophy Cabinet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${team['total_trophies'] ?? 0} total titles',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._trophies.map((trophy) => _buildTrophyItem(context, trophy)),
        ],
      ),
    );
  }

  Widget _buildTrophyItem(BuildContext context, Map<String, dynamic> trophy) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final name = trophy['name'] as String;
    final count = trophy['count'] as int;
    final emoji = trophy['emoji'] as String;
    final years = trophy['years'] as List<String>;

    Color accentColor;
    if (name.toLowerCase().contains('champions league')) {
      accentColor = const Color(0xFFFFD700);
    } else if (name.toLowerCase().contains('europa')) {
      accentColor = const Color(0xFFFF8C00);
    } else if (name.toLowerCase().contains('fa cup') || name.toLowerCase().contains('dfb') || name.toLowerCase().contains('copa')) {
      accentColor = const Color(0xFF3B82F6);
    } else if (name.toLowerCase().contains('league cup')) {
      accentColor = const Color(0xFF10B981);
    } else if (name.toLowerCase().contains('world cup')) {
      accentColor = const Color(0xFF8B5CF6);
    } else {
      accentColor = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253348) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'x$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (years.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: years.map((year) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Use pre-built Player objects from the search index
    final List<Player> mappedPlayers = List<Player>.from(
      _normalizedTeam['player_objects'] ?? []
    );

    if (mappedPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Categorize players by position group
    int getPosGroup(String pos) {
      final p = pos.trim();
      // حراس المرمى
      if (['حارس مرمى', 'حارس المرمى', 'حم'].contains(p)) return 0;
      // الدفاع
      if (['قلب دفاع', 'ظهير', 'ظهير أيسر', 'ظهير أيمن', 'ظهير أيسر متقدم', 'ظهير أيمن متقدم', 'مدافع'].contains(p)) return 1;
      // الوسط
      if (['وسط', 'وسط دفاعي', 'وسط هجومي', 'وسط أيسر', 'وسط أيمن'].contains(p)) return 2;
      // الهجوم
      if (['جناح', 'جناح أيسر', 'جناح أيمن', 'مهاجم صريح', 'مهاجم ثاني', 'مهاجم'].contains(p)) return 3;
      return 4;
    }

    // Sort each player by rating within group
    mappedPlayers.sort((a, b) {
      final gA = getPosGroup(a.position);
      final gB = getPosGroup(b.position);
      if (gA != gB) return gA.compareTo(gB);
      return b.rating.compareTo(a.rating);
    });

    // Group players
    final goalkeepers = mappedPlayers.where((p) => getPosGroup(p.position) == 0).toList();
    final defenders = mappedPlayers.where((p) => getPosGroup(p.position) == 1).toList();
    final midfielders = mappedPlayers.where((p) => getPosGroup(p.position) == 2).toList();
    final forwards = mappedPlayers.where((p) => getPosGroup(p.position) == 3).toList();
    final others = mappedPlayers.where((p) => getPosGroup(p.position) == 4).toList();

    final coach = _normalizedTeam['coach_player'] as Player?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Squad',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${mappedPlayers.length} players',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Coach section
          if (coach != null) ...[
            _buildPositionGroupHeader(
              context,
              icon: Icons.sports_soccer,
              title: 'مدرب الفريق',
              count: 1,
              accentColor: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 8),
            _buildCoachCard(context, coach),
            const SizedBox(height: 16),
          ],

          // Goalkeepers
          if (goalkeepers.isNotEmpty) ...[
            _buildPositionGroupHeader(
              context,
              icon: Icons.sports_soccer,
              title: 'حراس المرمى',
              count: goalkeepers.length,
              accentColor: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 8),
            ...goalkeepers.map((p) => PlayerCard(player: p)),
            const SizedBox(height: 16),
          ],

          // Defenders
          if (defenders.isNotEmpty) ...[
            _buildPositionGroupHeader(
              context,
              icon: Icons.shield,
              title: 'الدفاع',
              count: defenders.length,
              accentColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 8),
            ...defenders.map((p) => PlayerCard(player: p)),
            const SizedBox(height: 16),
          ],

          // Midfielders
          if (midfielders.isNotEmpty) ...[
            _buildPositionGroupHeader(
              context,
              icon: Icons.settings,
              title: 'خط الوسط',
              count: midfielders.length,
              accentColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 8),
            ...midfielders.map((p) => PlayerCard(player: p)),
            const SizedBox(height: 16),
          ],

          // Forwards
          if (forwards.isNotEmpty) ...[
            _buildPositionGroupHeader(
              context,
              icon: Icons.flash_on,
              title: 'الهجوم',
              count: forwards.length,
              accentColor: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 8),
            ...forwards.map((p) => PlayerCard(player: p)),
            const SizedBox(height: 16),
          ],

          // Others
          if (others.isNotEmpty) ...[
            _buildPositionGroupHeader(
              context,
              icon: Icons.person,
              title: 'أخرى',
              count: others.length,
              accentColor: colorScheme.outline,
            ),
            const SizedBox(height: 8),
            ...others.map((p) => PlayerCard(player: p)),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionGroupHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
            accentColor.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(BuildContext context, Player coach) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.12 : 0.06),
            const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.06 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Coach photo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  const Color(0xFF7C3AED).withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: SmartLogo(
                  logo: coach.photo,
                  size: 50,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Coach info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'مدرب الفريق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (coach.nationality.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${coach.nationalityFlag} ${coach.nationality}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}
