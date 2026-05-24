class League {
  final String id;
  final String name;
  final String logo;
  final String? country;
  final int upcomingMatches;

  League({
    required this.id,
    required this.name,
    required this.logo,
    this.country,
    required this.upcomingMatches,
  });

  League copyWith({
    String? id,
    String? name,
    String? logo,
    String? country,
    int? upcomingMatches,
  }) {
    return League(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      country: country ?? this.country,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
    );
  }
}
