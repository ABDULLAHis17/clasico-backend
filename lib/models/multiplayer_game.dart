import 'game.dart';
import 'friend.dart';

class MultiplayerGame {
  final Game game;
  final Friend opponent;
  final DateTime startedAt;

  MultiplayerGame({
    required this.game,
    required this.opponent,
    required this.startedAt,
  });
}
