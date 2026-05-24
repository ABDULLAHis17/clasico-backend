class MatchStatistics {
  final String matchId;
  final TeamStatistics homeTeam;
  final TeamStatistics awayTeam;

  MatchStatistics({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
  });
}

class TeamStatistics {
  final int possession;
  final int shots;
  final int shotsOnTarget;
  final int corners;
  final int fouls;
  final int yellowCards;
  final int redCards;
  final int offsides;
  final int passes;
  final int passAccuracy;

  TeamStatistics({
    required this.possession,
    required this.shots,
    required this.shotsOnTarget,
    required this.corners,
    required this.fouls,
    required this.yellowCards,
    required this.redCards,
    required this.offsides,
    required this.passes,
    required this.passAccuracy,
  });
}
