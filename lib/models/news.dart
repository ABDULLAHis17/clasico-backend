class News {
  final String id;
  final String title;
  final String summary;
  final String fullArticle;
  final String imageUrl;
  final String leagueId;
  final String leagueName;
  final DateTime publishedDate;
  final String author;
  final List<String> tags;

  News({
    required this.id,
    required this.title,
    required this.summary,
    required this.fullArticle,
    required this.imageUrl,
    required this.leagueId,
    required this.leagueName,
    required this.publishedDate,
    required this.author,
    required this.tags,
  });
}
