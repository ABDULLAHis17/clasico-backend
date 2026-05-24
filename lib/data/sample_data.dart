import '../models/league.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
import '../models/injury.dart';
import '../models/match_statistics.dart';
import '../models/news.dart';
import '../models/league_standing.dart';
import '../models/league_statistics.dart';
import 'mock_match_data.dart';

class SampleData {
  static List<League> getLeagues() {
    return [];
  }

  static List<Match> getMatches() {
    return MockMatchDataService.matches;
  }

  static Player getDetailedPlayer(String id) {
    return Player(
      id: id,
      name: 'Unknown Player',
      number: 0,
      position: 'Unknown',
      nationality: 'Unknown',
      age: 0,
      photo: '⚽',
    );
  }

  static List<MatchEvent> getMatchEvents(String matchId) {
    return MockMatchDataService.getMatchEvents(matchId);
  }

  static List<Injury> getInjuries(String matchId) {
    return MockMatchDataService.getInjuries(matchId);
  }

  static MatchStatistics getMatchStatistics(String matchId) {
    return MockMatchDataService.getMatchStatistics(matchId);
  }

  static Lineup getLineup(String matchId) {
    return MockMatchDataService.getLineup(matchId);
  }

  static List<Player> getTopPlayers() {
    return [];
  }

  static List<News> getNews() {
    return [];
  }

  static Map<String, double> getPlayerRatings(String matchId) {
    return MockMatchDataService.getPlayerRatings(matchId);
  }

  static List<LeagueStanding> getLeagueStandings(String leagueId) {
    return MockMatchDataService.getLeagueStandings(leagueId);
  }

  static LeagueStatistics getLeagueStatistics(String leagueId) {
    return LeagueStatistics(
      topScorers: [],
      topAssists: [],
      yellowCards: [],
      redCards: [],
      cleanSheets: [],
      historicalChampions: [],
    );
  }
}
