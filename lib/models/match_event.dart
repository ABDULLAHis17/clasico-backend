class MatchEvent {
  final String id;
  final String matchId;
  final int minute;
  final String type; // 'goal', 'yellow_card', 'red_card', 'substitution'
  final String team; // 'home' or 'away'
  final String playerName;
  final String? assistPlayerName;
  final String? substitutePlayerName; // For substitutions

  MatchEvent({
    required this.id,
    required this.matchId,
    required this.minute,
    required this.type,
    required this.team,
    required this.playerName,
    this.assistPlayerName,
    this.substitutePlayerName,
  });

  String get icon {
    switch (type) {
      case 'goal':
        return '⚽';
      case 'yellow_card':
        return '🟨';
      case 'red_card':
        return '🟥';
      case 'substitution':
        return '🔄';
      default:
        return '📌';
    }
  }
}
