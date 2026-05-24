import '../models/match.dart';
import '../models/player.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  // Favorites state (in-memory)
  final Set<String> _favoriteMatchIds = {};

  // Multi-select preferences
  final Set<String> favoriteLeagueIds = {}; // store league IDs
  final Set<String> favoriteClubs = {}; // store club names
  final Set<String> favoriteNationalTeams = {}; // store national team names
  final Set<String> favoritePlayers = {}; // store player names

  // ===== Matches =====
  bool isMatchFavorite(String matchId) => _favoriteMatchIds.contains(matchId);

  bool toggleFavoriteMatch(Match match) {
    final added = !_favoriteMatchIds.remove(match.id);
    if (added) _favoriteMatchIds.add(match.id);
    return added; // true if added, false if removed
  }

  List<String> get favoriteMatchIds => List.unmodifiable(_favoriteMatchIds);

  // ===== Leagues =====
  bool addFavoriteLeague(String leagueId) => favoriteLeagueIds.add(leagueId);
  bool removeFavoriteLeague(String leagueId) => favoriteLeagueIds.remove(leagueId);

  // ===== Clubs =====
  bool addFavoriteClub(String name) {
    final n = name.trim();
    if (n.isEmpty) return false;
    return favoriteClubs.add(n);
  }

  bool removeFavoriteClub(String name) => favoriteClubs.remove(name);
  
  bool isClubFavorite(String name) {
    if (name.trim().isEmpty) return false;
    return favoriteClubs.contains(name.trim());
  }

  // ===== National Teams =====
  bool addFavoriteNationalTeam(String name) {
    final n = name.trim();
    if (n.isEmpty) return false;
    return favoriteNationalTeams.add(n);
  }

  bool removeFavoriteNationalTeam(String name) => favoriteNationalTeams.remove(name);

  // ===== Players =====
  bool addFavoritePlayer(String name) {
    final n = name.trim();
    if (n.isEmpty) return false;
    return favoritePlayers.add(n);
  }

  bool removeFavoritePlayer(String name) => favoritePlayers.remove(name);

  bool isPlayerFavorite(String playerName) {
    if (playerName.trim().isEmpty) return false;
    return favoritePlayers.contains(playerName.trim());
  }

  bool toggleFavoritePlayer(Player player) {
    final playerName = player.name.trim();
    if (playerName.isEmpty) return false;
    final wasRemoved = favoritePlayers.remove(playerName);
    if (!wasRemoved) {
      favoritePlayers.add(playerName);
      return true;
    }
    return false;
  }

  List<String> get favoritePlayerIds => List.unmodifiable(favoritePlayers);
}
