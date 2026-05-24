class Game {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final bool availableOnline;
  final bool availableOffline;
  final List<SubGame>? subGames;

  Game({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.availableOnline = true,
    this.availableOffline = true,
    this.subGames,
  });
}

class SubGame {
  final String id;
  final String title;
  final String description;
  final String icon;

  SubGame({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
