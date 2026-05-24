class LeagueStanding {
  final int position;
  final String clubName;
  final String clubLogo;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final String? form; // Recent form like "WWDWL"

  LeagueStanding({
    required this.position,
    required this.clubName,
    required this.clubLogo,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    this.form,
  }) : goalDifference = goalsFor - goalsAgainst;

  // Helper to get position color (Champions League, Europa League, Relegation zones)
  String getPositionZone() {
    if (position <= 4) return 'champions'; // Champions League
    if (position <= 6) return 'europa'; // Europa League
    if (position >= 18) return 'relegation'; // Relegation zone
    return 'safe'; // Safe zone
  }
}
