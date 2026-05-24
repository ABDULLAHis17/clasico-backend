class Transfer {
  final String id;
  final String playerName;
  final String playerPhoto;
  final String nationality;
  final String nationalityFlag;
  final int age;
  final String position;
  final String oldClub;
  final String oldClubLogo;
  final String newClub;
  final String newClubLogo;
  final String transferFee;
  final String contractLength;
  final DateTime transferDate;
  final String officialStatement;
  final String sourceUrl;

  Transfer({
    required this.id,
    required this.playerName,
    required this.playerPhoto,
    required this.nationality,
    required this.nationalityFlag,
    required this.age,
    required this.position,
    required this.oldClub,
    required this.oldClubLogo,
    required this.newClub,
    required this.newClubLogo,
    required this.transferFee,
    required this.contractLength,
    required this.transferDate,
    required this.officialStatement,
    required this.sourceUrl,
  });
}
