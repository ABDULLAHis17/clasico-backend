class Player {
  final String id;
  final String name;
  final int number;
  final String position;
  final String nationality;
  final String? nationalityFlag;
  final int age;
  final String photo;
  final double rating;
  final PlayerStatistics? statistics;
  final String? club;
  final String? clubLogo;
  final String? dateOfBirth;
  final String? height;
  final String? weight;
  final String? preferredFoot;
  final List<CareerHistory>? careerHistory;
  final String? teamName;
  final String? teamLogo;
  final List<PlayerTransfer>? transfers;
  final Map<String, int>? skills;

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.nationality,
    required this.age,
    required this.photo,
    this.nationalityFlag,
    this.rating = 0.0,
    this.statistics,
    this.club,
    this.clubLogo,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.preferredFoot,
    this.careerHistory,
    this.teamName,
    this.teamLogo,
    this.transfers,
    this.skills,
  });
}

class PlayerStatistics {
  final int matchesPlayed;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int minutesPlayed;
  final int shotsOnTarget;
  final int passAccuracy;

  PlayerStatistics({
    required this.matchesPlayed,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.minutesPlayed,
    required this.shotsOnTarget,
    required this.passAccuracy,
  });
}

class CareerHistory {
  final String club;
  final String clubLogo;
  final String startYear;
  final String? endYear;
  final int appearances;
  final int goals;

  CareerHistory({
    required this.club,
    required this.clubLogo,
    required this.startYear,
    this.endYear,
    required this.appearances,
    required this.goals,
  });
}

class PlayerTransfer {
  final String? fromTeamName;
  final String? fromTeamLogo;
  final String? toTeamName;
  final String? toTeamLogo;
  final double? feeAmount;
  final String? feeCurrency;
  final String? fee;
  final String? transferType;
  final String? transferDate;

  PlayerTransfer({
    this.fromTeamName,
    this.fromTeamLogo,
    this.toTeamName,
    this.toTeamLogo,
    this.feeAmount,
    this.feeCurrency,
    this.fee,
    this.transferType,
    this.transferDate,
  });
}
