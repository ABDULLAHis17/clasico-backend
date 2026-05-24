class Injury {
  final String id;
  final String playerName;
  final String injuryType;
  final String severity; // 'minor', 'moderate', 'severe'
  final DateTime injuryDate;
  final DateTime? expectedReturn;
  final String team;

  Injury({
    required this.id,
    required this.playerName,
    required this.injuryType,
    required this.severity,
    required this.injuryDate,
    this.expectedReturn,
    required this.team,
  });
}
