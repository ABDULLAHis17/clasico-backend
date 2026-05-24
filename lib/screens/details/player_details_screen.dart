import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../utils/app_strings.dart';
import '../../utils/football_translations.dart';
import '../../services/favorites_service.dart';
import '../../services/api_service.dart';
import '../../services/local_data_service.dart';
import '../../widgets/smart_logo.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailsScreen({Key? key, required this.player}) : super(key: key);

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late bool _isFavorite;
  final _favoritesService = FavoritesService();

  Player? _detailedPlayer;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesService.isPlayerFavorite(widget.player.name);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    // Try API first (data from MySQL)
    try {
      final apiService = ApiService();
      final data = await apiService.getPlayer(widget.player.id);
      if (data != null && mounted) {
          final rawNat = data['nationality'] as String?;
          final rawPos = data['position'] as String?;

          setState(() {
            _detailedPlayer = Player(
              id: data['id']?.toString() ?? widget.player.id,
              name: data['name']?.toString() ?? widget.player.name,
              position: translatePosition(rawPos) ?? widget.player.position,
              nationality: translateNationality(rawNat) ?? widget.player.nationality,
              nationalityFlag: getNationalityFlag(rawNat),
              age: data['age'] as int? ?? widget.player.age,
              photo: data['photo_url']?.toString() ?? widget.player.photo,
              clubLogo: data['team_logo']?.toString() ?? widget.player.clubLogo,
              club: data['team_name'] as String? ?? widget.player.club,
              number: data['shirt_number'] as int? ?? widget.player.number,
              rating: (data['rating'] as num?)?.toDouble() ?? widget.player.rating,
              dateOfBirth: data['birthdate'] as String?,
              height: data['height_cm']?.toString(),
              weight: data['weight_kg']?.toString(),
              preferredFoot: data['preferred_foot'] as String?,
              teamName: data['team_name'] as String?,
              careerHistory: _parseCareerHistory(data['career_history']),
              transfers: [],
              skills: data['skills'] != null
                  ? Map<String, int>.from(data['skills'])
                  : widget.player.skills,
              statistics: PlayerStatistics(
                matchesPlayed: 0, goals: 0, assists: 0,
                yellowCards: 0, redCards: 0, minutesPlayed: 0,
                shotsOnTarget: 0, passAccuracy: 0,
              ),
            );
            _loadingDetails = false;
          });
          return;
        }
    } catch (_) {
      // API failed, fall through to LocalDataService
    }

    // Fallback to LocalDataService
    try {
      final data = await LocalDataService().getPlayerDetail(widget.player.id);
      if (data != null && mounted) {
        final rawNat = data['الأمة:'] is Map ? data['الأمة:']['text'] : null;
        final rawPos = data['player_position'] as String?;
        final ageText = data['العمر:'] is Map ? data['العمر:']['text'] : null;
        
        final heightCm = data['الطول(سم):'] is Map ? int.tryParse(data['الطول(سم):']['text']?.toString() ?? '') : null;
        final weightKg = data['الوزن (كغم):'] is Map ? int.tryParse(data['الوزن (كغم):']['text']?.toString() ?? '') : null;

        final teamObj = data['النادي:'];
        final teamName = teamObj is Map ? teamObj['text'] : null;
        
        final ratingText = data['تقييم:'] is Map ? data['تقييم:']['text'] : null;
        final rating = double.tryParse(ratingText?.toString() ?? '') ?? widget.player.rating;

        final numberText = data['رقم التشكيلة:'] is Map ? data['رقم التشكيلة:']['text'] : null;
        final number = int.tryParse(numberText?.toString() ?? '') ?? widget.player.number;

        final fullNameText = data['الإسم الكامل:'] is Map ? data['الإسم الكامل:']['text'] : null;
        
        final preferredFootText = data['القدم المفضل:'] is Map ? data['القدم المفضل:']['text'] : null;

        // Parse history
        final historyList = data['history'] as List<dynamic>? ?? [];
        List<PlayerTransfer> parsedTransfers = [];
        final seenTransfers = <String>{}; // Deduplicate by club + year

        for (var h in historyList) {
           if (h is Map) {
             final teamList = h['team'] as List<dynamic>? ?? [];
             final tName = teamList.isNotEmpty ? (teamList[0]['text']?.toString() ?? '') : '';
             final tLink = teamList.isNotEmpty ? (teamList[0]['link']?.toString() ?? '') : '';
             final dateStr = h['date']?.toString() ?? '';
             final rStr = h['rating']?.toString() ?? '0';
             
             String tLogo = '';
             if (tLink.contains('clubid=')) {
               final cid = tLink.split('clubid=').last;
               tLogo = 'https://cdn.soccerwiki.org/images/logos/clubs/$cid.png';
             }

             if (tName.isNotEmpty) {
                final yearPart = dateStr.length >= 4 ? dateStr.substring(dateStr.length - 4) : dateStr;
                final dedupKey = '$tName-$yearPart';
                if (!seenTransfers.contains(dedupKey)) {
                   seenTransfers.add(dedupKey);
                   parsedTransfers.add(PlayerTransfer(
                      fromTeamName: tName,
                      toTeamName: tName,
                      fromTeamLogo: tLogo,
                      toTeamLogo: tLogo,
                      fee: rStr, // Hack: store rating here
                      transferDate: dateStr,
                   ));
                }
             }
           }
        }
        
        // Procedural skills generator based on rating and position
        Map<String, int> generatedSkills = {};
        double baseRate = rating > 0 ? rating : 75.0;
        int seed = widget.player.id.hashCode.abs();
        int vary(int base, int spread) => (base + (seed % (spread * 2 + 1)) - spread).clamp(1, 99);
        
        final posL = (rawPos ?? '').toLowerCase();
        int pace = 75, shoot = 75, pass = 75, dribble = 75, def = 75, phy = 75;
        
        if (posL.contains('حارس') || posL.contains('gk')) {
           pace = vary((baseRate * 0.5).toInt(), 10);
           shoot = vary((baseRate * 0.3).toInt(), 10);
           pass = vary((baseRate * 0.8).toInt(), 10);
           dribble = vary((baseRate * 0.4).toInt(), 10);
           def = vary((baseRate * 0.9).toInt(), 5);
           phy = vary((baseRate * 0.85).toInt(), 10);
        } else if (posL.contains('مهاجم') || posL.contains('f(') || posL.contains('هدف') || posL.contains('وينج')) {
           pace = vary((baseRate * 1.05).toInt(), 5);
           shoot = vary((baseRate * 1.05).toInt(), 5);
           pass = vary((baseRate * 0.8).toInt(), 8);
           dribble = vary((baseRate * 1.02).toInt(), 5);
           def = vary((baseRate * 0.4).toInt(), 10);
           phy = vary((baseRate * 0.8).toInt(), 8);
        } else if (posL.contains('وسط') || posL.contains('m(') || posL.contains('صل')) {
           pace = vary((baseRate * 0.85).toInt(), 8);
           shoot = vary((baseRate * 0.85).toInt(), 8);
           pass = vary((baseRate * 1.05).toInt(), 4);
           dribble = vary((baseRate * 1.0).toInt(), 5);
           def = vary((baseRate * 0.85).toInt(), 8);
           phy = vary((baseRate * 0.9).toInt(), 8);
        } else {
           // Defenders
           pace = vary((baseRate * 0.8).toInt(), 8);
           shoot = vary((baseRate * 0.5).toInt(), 10);
           pass = vary((baseRate * 0.8).toInt(), 8);
           dribble = vary((baseRate * 0.7).toInt(), 8);
           def = vary((baseRate * 1.05).toInt(), 4);
           phy = vary((baseRate * 1.05).toInt(), 4);
        }
        
        generatedSkills = {
           'pace': pace, 'shooting': shoot, 'passing': pass,
           'dribbling': dribble, 'defense': def, 'physical': phy,
        };

        setState(() {
          _detailedPlayer = Player(
            id: widget.player.id,
            name: fullNameText ?? widget.player.name,
            position: rawPos ?? widget.player.position,
            nationality: rawNat ?? widget.player.nationality,
            nationalityFlag: getNationalityFlag(rawNat),
            age: _calcAgeFromText(ageText) ?? widget.player.age,
            photo: data['image'] as String? ?? widget.player.photo,
            clubLogo: getNationalityFlag(rawNat),
            club: teamName ?? widget.player.club,
            number: number,
            rating: rating,
            height: heightCm != null ? '${heightCm} cm' : null,
            weight: weightKg != null ? '${weightKg} kg' : null,
            teamName: teamName ?? widget.player.teamName,
            preferredFoot: preferredFootText,
            careerHistory: [],
            transfers: parsedTransfers,
            skills: generatedSkills,
            statistics: PlayerStatistics(
              matchesPlayed: 0, goals: 0, assists: 0,
              yellowCards: 0, redCards: 0, minutesPlayed: 0,
              shotsOnTarget: 0, passAccuracy: 0,
            ),
          );
          _loadingDetails = false;
        });
      } else {
        if (mounted) setState(() => _loadingDetails = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  List<CareerHistory> _parseCareerHistory(dynamic raw) {
    if (raw == null || raw is! List) return [];
    final List<CareerHistory> result = [];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final season = entry['season']?.toString() ?? '';
      final years = entry['years'];
      String startYear = '';
      String? endYear;
      if (years is List && years.isNotEmpty) {
        final sorted = years.map((y) => y.toString()).toList()..sort();
        startYear = sorted.first;
        endYear = sorted.last == startYear ? null : sorted.last;
      } else if (season.isNotEmpty) {
        final parts = season.split('-');
        startYear = parts[0];
        endYear = parts.length > 1 ? parts[1] : null;
      }
      result.add(CareerHistory(
        club: entry['club']?.toString() ?? '',
        clubLogo: entry['club_logo']?.toString() ?? '',
        startYear: startYear,
        endYear: endYear,
        appearances: 0,
        goals: 0,
      ));
    }
    return result;
  }

  int? _calcAgeFromText(String? ageText) {
    if (ageText == null || ageText.isEmpty) return null;
    final parts = ageText.trim().split(' ');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]);
    }
    return null;
  }

  Player get player => _detailedPlayer ?? widget.player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  final newState = _favoritesService.toggleFavoritePlayer(widget.player);
                  setState(() => _isFavorite = newState);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFavorite
                            ? '${widget.player.name} ${AppStrings.t(context, 'added_to_favorites')}'
                            : '${widget.player.name} ${AppStrings.t(context, 'removed_from_favorites')}',
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
                        tag: 'player_${widget.player.id}',
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
                            child: SmartLogo(logo: player.photo, size: 100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: _loadingDetails
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRatingCard(context, player),
                        const SizedBox(height: 16),
                        _buildInfoSection(context, player),
                        const SizedBox(height: 16),
                        _buildStatisticsSection(context, player.statistics ?? PlayerStatistics(
                          matchesPlayed: 0, goals: 0, assists: 0,
                          yellowCards: 0, redCards: 0, minutesPlayed: 0,
                          shotsOnTarget: 0, passAccuracy: 0,
                        )),
                        const SizedBox(height: 16),
                        if (player.skills != null) ...[
                          _buildSkillsSection(context, player.skills!),
                          const SizedBox(height: 16),
                        ],
                        _buildCareerTimelineSection(context, player),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context, Player player) {
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
          _buildRatingItem('⭐', 'Rating', player.rating.toStringAsFixed(0)),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildRatingItem('🎽', 'Number', '#${player.number}'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildRatingItem('📅', 'Age', '${player.age}'),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Player player) {
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
            'Player Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, '⚽', 'Position', player.position),
          _buildInfoRow(context, player.nationalityFlag ?? '🏳️', 'Nationality', player.nationality),
          // Team row with logo
          if (player.teamName != null)
            _buildTeamRow(context, player),
          _buildInfoRow(context, '🎂', 'Date of Birth', player.dateOfBirth ?? 'N/A'),
          _buildInfoRow(context, '📏', 'Height', player.height ?? 'N/A'),
          _buildInfoRow(context, '⚖️', 'Weight', player.weight ?? 'N/A'),
          if (player.preferredFoot != null)
            _buildInfoRow(context, '👟', 'Preferred Foot', player.preferredFoot!),
        ],
      ),
    );
  }

  Widget _buildTeamRow(BuildContext context, Player player) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: SmartLogo(logo: player.teamLogo ?? '', size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Team',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  player.teamName ?? 'Free Agent',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
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

  Widget _buildInfoRow(BuildContext context, String emoji, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
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

  Widget _buildStatisticsSection(BuildContext context, PlayerStatistics stats) {
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
            'Season Statistics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildStatCard(context, '⚽', 'Goals', stats.goals.toString(), const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, '🎯', 'Assists', stats.assists.toString(), const Color(0xFF3B82F6))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildStatCard(context, '🏃', 'Matches', stats.matchesPlayed.toString(), const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, '⏱️', 'Minutes', stats.minutesPlayed.toString(), const Color(0xFFF59E0B))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildStatCard(context, '🟨', 'Yellow', stats.yellowCards.toString(), const Color(0xFFEAB308))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, '🟥', 'Red', stats.redCards.toString(), const Color(0xFFEF4444))),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String emoji, String label, String value, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context, Map<String, int> skills) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final skillLabels = {
      'pace': {'label': 'Pace', 'emoji': '⚡'},
      'shooting': {'label': 'Shooting', 'emoji': '🎯'},
      'passing': {'label': 'Passing', 'emoji': '🎾'},
      'dribbling': {'label': 'Dribbling', 'emoji': '🏃'},
      'defense': {'label': 'Defense', 'emoji': '🛡️'},
      'physical': {'label': 'Physical', 'emoji': '💪'},
    };

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
            'Player Skills',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...skills.entries.map((entry) {
            final info = skillLabels[entry.key];
            if (info == null) return const SizedBox.shrink();
            return _buildSkillBar(
              context,
              info['label']!,
              info['emoji']!,
              entry.value,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSkillBar(BuildContext context, String label, String emoji, int value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color barColor;
    if (value >= 85) {
      barColor = const Color(0xFF10B981);
    } else if (value >= 70) {
      barColor = const Color(0xFF3B82F6);
    } else if (value >= 55) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFFEF4444);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 99.0,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [barColor.withValues(alpha: 0.7), barColor]),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerTimelineSection(BuildContext context, Player player) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Build career entries from careerHistory (API) + current club
    final List<_CareerEntry> entries = [];

    // Add career history entries from API
    if (player.careerHistory != null && player.careerHistory!.isNotEmpty) {
      for (final ch in player.careerHistory!) {
        final dateStr = ch.endYear != null
            ? '${ch.startYear} - ${ch.endYear}'
            : ch.startYear;
        entries.add(_CareerEntry(
          teamName: ch.club,
          teamLogo: ch.clubLogo.isNotEmpty ? ch.clubLogo : null,
          date: dateStr,
          rating: 0,
          isCurrent: false,
        ));
      }
    } else if (player.transfers != null) {
      // Fallback to transfers if no career history
      for (final t in player.transfers!) {
        if (t.fromTeamName != null) {
          int? historyRating = int.tryParse(t.fee ?? '');
          entries.add(_CareerEntry(
            teamName: t.fromTeamName!,
            teamLogo: t.fromTeamLogo,
            date: t.transferDate ?? '',
            rating: historyRating,
            isCurrent: false,
          ));
        }
      }
    }

    // Current club is always the top entry — use clubLogo from API
    entries.add(_CareerEntry(
      teamName: player.teamName ?? 'Free Agent',
      teamLogo: player.clubLogo,
      date: 'Present',
      rating: player.rating.toInt(),
      isCurrent: true,
    ));

    // Reverse so current is at top
    final reversed = entries.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with animated icon
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career Path',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${reversed.length} clubs',
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
          // Animated timeline entries
          ...List.generate(reversed.length, (index) {
            final entry = reversed[index];
            final isLast = index == reversed.length - 1;
            return _AnimatedTimelineEntry(
              key: ValueKey('career_$index'),
              entry: entry,
              isLast: isLast,
              index: index,
              isDark: isDark,
              colorScheme: colorScheme,
              theme: theme,
            );
          }),
        ],
      ),
    );
  }
}

class _CareerEntry {
  final String teamName;
  final String? teamLogo;
  final String date;
  final int? rating;
  final bool isCurrent;

  _CareerEntry({
    required this.teamName,
    this.teamLogo,
    required this.date,
    this.rating,
    this.isCurrent = false,
  });
}

class _AnimatedTimelineEntry extends StatefulWidget {
  final _CareerEntry entry;
  final bool isLast;
  final int index;
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AnimatedTimelineEntry({
    super.key,
    required this.entry,
    required this.isLast,
    required this.index,
    required this.isDark,
    required this.colorScheme,
    required this.theme,
  });

  @override
  State<_AnimatedTimelineEntry> createState() => _AnimatedTimelineEntryState();
}

class _AnimatedTimelineEntryState extends State<_AnimatedTimelineEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Staggered delay based on index
    final delay = Duration(milliseconds: widget.index * 120);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _ratingColors(int rating) {
    if (rating >= 90) return [const Color(0xFF10B981), const Color(0xFF059669)];
    if (rating >= 80) return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    if (rating >= 70) return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = widget.isDark;
    final colorScheme = widget.colorScheme;
    final theme = widget.theme;

    final accentColor = entry.isCurrent
        ? const Color(0xFF10B981)
        : const Color(0xFF6366F1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline bar (left side)
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  // Dot with pulse for current
                  if (entry.isCurrent)
                    _PulsingDot(accentColor: accentColor)
                  else
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  // Vertical line
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: 0.5),
                              accentColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Card content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: entry.isCurrent
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.1),
                            const Color(0xFF059669).withValues(alpha: isDark ? 0.08 : 0.04),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF253348), const Color(0xFF1E293B)]
                              : [Colors.white, const Color(0xFFF1F5F9)],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: entry.isCurrent
                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFE2E8F0)),
                    width: entry.isCurrent ? 1.5 : 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: entry.isCurrent
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: entry.isCurrent ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Club logo with glow for current
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: entry.isCurrent
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: entry.isCurrent
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: SmartLogo(
                            logo: entry.teamLogo ?? '',
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.teamName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (entry.isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'CURRENT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 11, color: colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                entry.date,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Rating Badge
                    if (entry.rating != null && entry.rating! > 0)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _ratingColors(entry.rating!),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _ratingColors(entry.rating!).first.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${entry.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color accentColor;
  const _PulsingDot({required this.accentColor});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.2);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [widget.accentColor, const Color(0xFF059669)],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.star_rounded, size: 11, color: Colors.white),
      ),
    );
  }
}
