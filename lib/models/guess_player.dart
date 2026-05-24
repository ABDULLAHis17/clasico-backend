class GuessPlayer {
  final String name;
  final String nationality;
  final String league;
  final String club;
  final String position;
  final int age;
  final bool isRetired;
  final int level; // 1-4 للمراحل الرئيسية، 5 للمعتزلين

  GuessPlayer({
    required this.name,
    required this.nationality,
    required this.league,
    required this.club,
    required this.position,
    required this.age,
    this.isRetired = false,
    required this.level,
  });
}

class GameQuestion {
  final String question;
  final String askedBy; // 'player' or 'computer'
  final bool answer;
  final DateTime timestamp;

  GameQuestion({
    required this.question,
    required this.askedBy,
    required this.answer,
    required this.timestamp,
  });
}
