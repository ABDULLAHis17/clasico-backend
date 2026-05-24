class UserProfile {
  final String uid;
  final String email;
  String? displayName;
  String? username;
  String? phoneNumber;
  String? favoritePlayer;
  String? favoriteTeam;
  String? nationalTeam;
  String? preferredLeague;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.username,
    this.phoneNumber,
    this.favoritePlayer,
    this.favoriteTeam,
    this.nationalTeam,
    this.preferredLeague,
  });
}
