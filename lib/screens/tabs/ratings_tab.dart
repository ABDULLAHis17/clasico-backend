import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../details/player_details_screen.dart';

class RatingsTab extends StatefulWidget {
  final String matchId;

  const RatingsTab({Key? key, required this.matchId}) : super(key: key);

  @override
  State<RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends State<RatingsTab> with SingleTickerProviderStateMixin {
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
    final ratings = SampleData.getPlayerRatings(widget.matchId);
    final lineup = SampleData.getLineup(widget.matchId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    
    // Get home and away team player names
    final homePlayerNames = [
      ...lineup.homeTeam.startingPlayers.map((p) => p.name),
      ...lineup.homeTeam.substitutes.map((p) => p.name),
    ].toSet();
    
    final awayPlayerNames = [
      ...lineup.awayTeam.startingPlayers.map((p) => p.name),
      ...lineup.awayTeam.substitutes.map((p) => p.name),
    ].toSet();

    // Filter ratings based on selected team
    Map<String, double> filteredRatings;
    if (_selectedTeam == 0) {
      filteredRatings = Map.fromEntries(
        ratings.entries.where((e) => homePlayerNames.contains(e.key))
      );
    } else {
      filteredRatings = Map.fromEntries(
        ratings.entries.where((e) => awayPlayerNames.contains(e.key))
      );
    }
    
    final sortedRatings = filteredRatings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Team Selection Buttons
        Container(
          margin: const EdgeInsets.all(16),
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
                child: _buildFilterButton(
                  context,
                  lineup.homeTeam.teamName,
                  0,
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  context,
                  lineup.awayTeam.teamName,
                  1,
                  colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        
        // Animated Ratings List
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedRatings.length,
                itemBuilder: (context, index) {
                  final entry = sortedRatings[index];
                  return _buildRatingCard(context, entry.key, entry.value, index + 1);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context, String label, int teamIndex, Color color) {
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
            label,
            style: TextStyle(
              fontSize: 12,
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

  Widget _buildRatingCard(BuildContext context, String playerName, double rating, int rank) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Find player photo from lineup
    final lineup = SampleData.getLineup(widget.matchId);
    final allPlayers = [
      ...lineup.homeTeam.startingPlayers,
      ...lineup.homeTeam.substitutes,
      ...lineup.awayTeam.startingPlayers,
      ...lineup.awayTeam.substitutes,
    ];
    final matchedPlayer = allPlayers.where((p) => p.name == playerName).toList();
    final photoUrl = matchedPlayer.isNotEmpty ? matchedPlayer.first.photo : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
            ? [const Color(0xFF1E293B), const Color(0xFF334155)]
            : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
            ? _getRankColor(rank).withValues(alpha: 0.4)
            : (isDarkMode ? Colors.white12 : Colors.grey.shade200),
          width: rank <= 3 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: rank <= 3
              ? _getRankColor(rank).withValues(alpha: 0.2)
              : (isDarkMode ? Colors.black38 : Colors.black.withAlpha(10)),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (matchedPlayer.isNotEmpty) {
              final detailedPlayer = SampleData.getDetailedPlayer(matchedPlayer.first.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailsScreen(player: detailedPlayer),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rank == 1
                          ? [Colors.amber, Colors.orange]
                          : rank == 2
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : rank == 3
                                  ? [Colors.brown.shade300, Colors.brown.shade400]
                                  : [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank <= 3 ? '🏅${rank}' : '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Player Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: photoUrl != null && photoUrl.startsWith('http')
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Player Name
                Expanded(
                  child: Text(
                    playerName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.5) {
      return Colors.green;
    } else if (rating >= 8.0) {
      return Colors.lightGreen;
    } else if (rating >= 7.5) {
      return Colors.blue;
    } else if (rating >= 7.0) {
      return Colors.orange;
    } else {
      return Colors.deepOrange;
    }
  }
}
