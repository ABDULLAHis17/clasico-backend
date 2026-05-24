import 'player.dart';

class Lineup {
  final String matchId;
  final TeamLineup homeTeam;
  final TeamLineup awayTeam;

  Lineup({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
  });
}

class TeamLineup {
  final String teamName;
  final String formation;
  final List<Player> startingPlayers;
  final List<Player> substitutes;

  TeamLineup({
    required this.teamName,
    required this.formation,
    required this.startingPlayers,
    required this.substitutes,
  });
}
