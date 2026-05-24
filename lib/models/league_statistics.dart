// Top Scorer Model
class TopScorer {
  final String playerId;
  final String playerName;
  final String clubName;
  final String clubLogo;
  final String nationality;
  final int goals;
  final int matches;

  TopScorer({
    required this.playerId,
    required this.playerName,
    required this.clubName,
    required this.clubLogo,
    required this.nationality,
    required this.goals,
    required this.matches,
  });
}

// Top Assist Provider Model
class TopAssist {
  final String playerId;
  final String playerName;
  final String clubName;
  final String clubLogo;
  final String nationality;
  final int assists;
  final int matches;

  TopAssist({
    required this.playerId,
    required this.playerName,
    required this.clubName,
    required this.clubLogo,
    required this.nationality,
    required this.assists,
    required this.matches,
  });
}

// Yellow Cards Model
class YellowCardLeader {
  final String playerId;
  final String playerName;
  final String clubName;
  final String clubLogo;
  final String nationality;
  final int yellowCards;
  final int matches;

  YellowCardLeader({
    required this.playerId,
    required this.playerName,
    required this.clubName,
    required this.clubLogo,
    required this.nationality,
    required this.yellowCards,
    required this.matches,
  });
}

// Red Cards Model
class RedCardLeader {
  final String playerId;
  final String playerName;
  final String clubName;
  final String clubLogo;
  final String nationality;
  final int redCards;
  final int matches;

  RedCardLeader({
    required this.playerId,
    required this.playerName,
    required this.clubName,
    required this.clubLogo,
    required this.nationality,
    required this.redCards,
    required this.matches,
  });
}

// Clean Sheets for Goalkeepers Model
class CleanSheetLeader {
  final String playerId;
  final String playerName;
  final String clubName;
  final String clubLogo;
  final String nationality;
  final int cleanSheets;
  final int matches;

  CleanSheetLeader({
    required this.playerId,
    required this.playerName,
    required this.clubName,
    required this.clubLogo,
    required this.nationality,
    required this.cleanSheets,
    required this.matches,
  });
}

// Historical Champion Model
class HistoricalChampion {
  final String season;
  final String clubName;
  final String clubLogo;
  final int points;
  final int wins;

  HistoricalChampion({
    required this.season,
    required this.clubName,
    required this.clubLogo,
    required this.points,
    required this.wins,
  });
}

// League Statistics Container
class LeagueStatistics {
  final List<TopScorer> topScorers;
  final List<TopAssist> topAssists;
  final List<YellowCardLeader> yellowCards;
  final List<RedCardLeader> redCards;
  final List<CleanSheetLeader> cleanSheets;
  final List<HistoricalChampion> historicalChampions;

  LeagueStatistics({
    required this.topScorers,
    required this.topAssists,
    required this.yellowCards,
    required this.redCards,
    required this.cleanSheets,
    required this.historicalChampions,
  });
}
