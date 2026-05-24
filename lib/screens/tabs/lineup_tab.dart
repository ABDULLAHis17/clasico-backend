import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/lineup.dart';
import '../../models/player.dart';
import '../../utils/app_strings.dart';
import '../details/player_details_screen.dart';
import '../../widgets/player_card.dart';

class LineupTab extends StatefulWidget {
  final String matchId;

  const LineupTab({Key? key, required this.matchId}) : super(key: key);

  @override
  State<LineupTab> createState() => _LineupTabState();
}

class _LineupTabState extends State<LineupTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedTeam = 0; // 0 = Home, 1 = Away

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchTeam(int teamIndex) {
    if (_selectedTeam != teamIndex) {
      _animationController.reset();
      setState(() {
        _selectedTeam = teamIndex;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineup = SampleData.getLineup(widget.matchId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Team Selection Buttons
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                  : [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamButton(
                    context,
                    lineup.homeTeam.teamName,
                    0,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTeamButton(
                    context,
                    lineup.awayTeam.teamName,
                    1,
                    colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Animated Lineup Display
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _selectedTeam == 0
                ? _buildTeamLineup(
                    context,
                    lineup.homeTeam,
                    isHome: true,
                  )
                : _buildTeamLineup(
                    context,
                    lineup.awayTeam,
                    isHome: false,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamButton(BuildContext context, String teamName, int teamIndex, Color color) {
    final isSelected = _selectedTeam == teamIndex;
    
    return GestureDetector(
      onTap: () => _switchTeam(teamIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              )
            : LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
              ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _getPositionCategory(String pos) {
    pos = pos.trim().toUpperCase();
    if (pos == 'GK') return 'GK';
    if (['CB', 'LB', 'RB', 'LWB', 'RWB', 'SW'].contains(pos)) return 'DEF';
    if (['CM', 'CDM', 'CAM', 'RM', 'LM'].contains(pos)) return 'MID';
    if (['ST', 'CF', 'LW', 'RW', 'SS', 'LF', 'RF'].contains(pos)) return 'FWD';
    return 'MID';
  }

  Widget _buildPositionHeader(BuildContext context, String category, bool isDark) {
    String label;
    IconData icon;
    Color color;
    switch (category) {
      case 'GK':
        label = '🧤 حراس المرمى';
        icon = Icons.sports_handball;
        color = Colors.amber;
        break;
      case 'DEF':
        label = '🛡️ المدافعون';
        icon = Icons.shield;
        color = Colors.blue;
        break;
      case 'MID':
        label = '⚙️ لاعبو الوسط';
        icon = Icons.settings;
        color = Colors.green;
        break;
      case 'FWD':
        label = '⚽ المهاجمون';
        icon = Icons.sports_soccer;
        color = Colors.red;
        break;
      default:
        label = '⚽ لاعبون';
        icon = Icons.person;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.25 : 0.12),
            color.withValues(alpha: isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLineup(BuildContext context, TeamLineup teamLineup, {required bool isHome}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Group starting players by position
    final Map<String, List<Player>> grouped = {'GK': [], 'DEF': [], 'MID': [], 'FWD': []};
    for (final p in teamLineup.startingPlayers) {
      final cat = _getPositionCategory(p.position);
      (grouped[cat] ??= []).add(p);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Team Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isHome
                  ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)]
                  : [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.8)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  teamLineup.teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    teamLineup.formation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Starting XI
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, 'starting_xi'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colorScheme.primary : colorScheme.primary,
                  ),
                ),
                for (final category in ['GK', 'DEF', 'MID', 'FWD'])
                  if (grouped[category]!.isNotEmpty) ...[
                    _buildPositionHeader(context, category, isDark),
                    ...grouped[category]!.map((player) => _buildPlayerTile(player, context)),
                  ],
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          
          // Substitutes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, 'substitutes'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colorScheme.primary : colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...teamLineup.substitutes.map((player) => _buildPlayerTile(player, context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Player player, BuildContext context) {
    return PlayerCard(
      player: SampleData.getDetailedPlayer(player.id),
      smallMode: true,
    );
  }
}
