class GameQuestion {
  final String id;
  final String question;
  final String category;
  final List<String> possibleAnswers;
  final int difficulty;

  GameQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.possibleAnswers,
    this.difficulty = 1,
  });
}

class PlayerTransferHistory {
  final String playerId;
  final String playerName;
  final List<String> clubs;
  final List<String> clubLogos;
  final int difficulty;

  PlayerTransferHistory({
    required this.playerId,
    required this.playerName,
    required this.clubs,
    required this.clubLogos,
    this.difficulty = 1,
  });
}

class AuctionQuestion {
  final String id;
  final String question;
  final int correctAnswer;
  final int difficulty;

  AuctionQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    this.difficulty = 1,
  });
}
