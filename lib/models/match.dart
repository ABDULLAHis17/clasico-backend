class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final DateTime matchTime;
  final String leagueId;
  final bool isPlayed; // هل تم لعب المباراة؟
  final int? homeScore; // نتيجة الفريق الأول
  final int? awayScore; // نتيجة الفريق الثاني

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.matchTime,
    required this.leagueId,
    this.isPlayed = false,
    this.homeScore,
    this.awayScore,
  });

  Match copyWith({
    String? id,
    String? homeTeam,
    String? awayTeam,
    String? homeTeamLogo,
    String? awayTeamLogo,
    DateTime? matchTime,
    String? leagueId,
    bool? isPlayed,
    int? homeScore,
    int? awayScore,
  }) {
    return Match(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      matchTime: matchTime ?? this.matchTime,
      leagueId: leagueId ?? this.leagueId,
      isPlayed: isPlayed ?? this.isPlayed,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
    );
  }
}
