import 'dart:math';
import '../models/match.dart';
import '../models/player.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
import '../models/injury.dart';
import '../models/match_statistics.dart';
import '../models/league_standing.dart';
import '../models/league.dart';
import '../services/local_data_service.dart';

class MockMatchDataService {
  static List<Match> matches = [];
  static Map<String, List<LeagueStanding>> standings = {};
  static bool initialized = false;
  static final Random _random = Random();

  static final List<String> _firstNames = [
    'Marco', 'Luis', 'Andres', 'Paulo', 'Sergio', 'Kevin', 'Thomas', 'Lucas',
    'David', 'James', 'Carlos', 'Antonio', 'Daniel', 'Jose', 'Angel', 'Rafael',
    'Diego', 'Miguel', 'Alejandro', 'Manuel', 'Pedro', 'Jorge', 'Eduardo',
    'Francisco', 'Juan', 'Pablo', 'Victor', 'Hugo', 'Martin', 'Santiago',
    'Olivier', 'Liam', 'Noah', 'Ethan', 'Mason', 'Luca', 'Matteo', 'Leonardo',
    'Riccardo', 'Francesco', 'Lorenzo', 'Simone', 'Federico', 'Alessandro',
    'Yusuf', 'Mehmet', 'Ali', 'Ahmed', 'Mohamed', 'Hassan',
    'Mats', 'Lars', 'Erik', 'Jonas', 'Sven', 'Jan', 'Max', 'Felix',
  ];

  static final List<String> _lastNames = [
    'Silva', 'Santos', 'Lopez', 'Martinez', 'Rodriguez', 'Garcia',
    'Gonzalez', 'Fernandez', 'Perez', 'Sanchez', 'Ramirez', 'Torres',
    'Rivera', 'Morales', 'Ortiz', 'Cruz', 'Reyes', 'Gutierrez',
    'Molina', 'Diaz', 'Moreno', 'Alvarez', 'Romero', 'Navarro',
    'Russo', 'Ferrari', 'Bianchi', 'Romano', 'Gallo', 'Costa',
    'Fontana', 'Conti', 'Esposito', 'Ricci', 'Bruno', 'Barbieri',
    'Marchetti', 'Rinaldi', 'Caruso', 'Amato', 'Moretti', 'Gatti',
    'Berg', 'Andersen', 'Johansson', 'Lindberg', 'Nilsson', 'Eriksson',
    'Karlsson', 'Gustavsson', 'Lundqvist', 'Wallin',
    'Petersen', 'Christensen', 'Jensen', 'Sorensen', 'Rasmussen',
    'Muller', 'Schmidt', 'Weber', 'Wagner', 'Becker', 'Hoffman',
  ];

  static final List<String> _injuryNames = [
    'Hamstring Strain', 'Ankle Sprain', 'ACL Tear', 'Groin Pull',
    'Calf Strain', 'Knee Injury', 'Shoulder Dislocation', 'Concussion',
    'Thigh Strain', 'Back Spasm', 'Hip Flexor', 'Quad Strain',
    'Meniscus Tear', 'Achilles Tendonitis', 'Rib Fracture',
  ];

  static final List<String> _formations = [
    '4-3-3', '4-4-2', '4-2-3-1', '3-5-2', '3-4-3', '4-1-4-1',
  ];

  static const List<String> _positionsBase = [
    'GK', 'CB', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CM', 'LW', 'RW', 'ST',
  ];

  static Future<void> initialize(LocalDataService localData) async {
    if (initialized) return;

    final rawLeagues = localData.getLeagues();

    for (int leagueIdx = 0; leagueIdx < rawLeagues.length; leagueIdx++) {
      final league = rawLeagues[leagueIdx];
      final leagueId = league['leagueid'] as String? ?? '$leagueIdx';

      final teams = localData.getTeamsForLeague(leagueIdx);
      if (teams.length < 2) continue;

      final teamData = teams.map((t) {
        final n = localData.normalizeTeamData(t);
        return {
          'name': n['name'] as String? ?? 'Unknown',
          'logo': n['logo_url'] as String? ?? '',
          'idx': teams.indexOf(t),
        };
      }).toList();

      _generateRoundRobinMatches(leagueId, teamData);
      _generateStandings(leagueId, teamData);
    }

    initialized = true;
  }

  /// Generates 5 rounds of matches using the circle method (round-robin).
  /// Each team plays exactly once per round, max 1 match per day.
  /// Match dates start from TODAY (day 0) through day 4.
  static void _generateRoundRobinMatches(String leagueId, List<Map<String, dynamic>> teamData) {
    final teamList = List<Map<String, dynamic>>.from(teamData);
    final n = teamList.length;
    final isOdd = n % 2 == 1;
    final total = isOdd ? n + 1 : n;
    final today = DateTime.now();

    // First 4 rounds are played, 5th is upcoming
    for (int round = 0; round < 5; round++) {
      final matchDate = DateTime(today.year, today.month, today.day).add(Duration(days: round));

      for (int i = 0; i < total ~/ 2; i++) {
        final homeIdx = i;
        final awayIdx = total - 1 - i;

        // Skip BYE matches (the last index when odd)
        if (isOdd && (homeIdx == n || awayIdx == n)) continue;

        final home = teamList[homeIdx];
        final away = teamList[awayIdx];

        final isPlayed = round < 4;
        int? homeScore, awayScore;
        if (isPlayed) {
          homeScore = _random.nextInt(5);
          awayScore = _random.nextInt(5);
        }

        final matchTime = matchDate.add(Duration(
          hours: 12 + _random.nextInt(10),
          minutes: _random.nextBool() ? 0 : 30,
        ));

        final matchId = 'mock_${leagueId}_r${round}_h${home['idx']}_a${away['idx']}';

        matches.add(Match(
          id: matchId,
          homeTeam: home['name'] as String,
          awayTeam: away['name'] as String,
          homeTeamLogo: home['logo'] as String,
          awayTeamLogo: away['logo'] as String,
          matchTime: matchTime,
          leagueId: leagueId,
          isPlayed: isPlayed,
          homeScore: homeScore,
          awayScore: awayScore,
        ));
      }

      // Circle method rotation: keep first fixed, rotate the rest clockwise
      if (total >= 3) {
        final first = teamList[0];
        final rotating = teamList.sublist(1);
        final last = rotating.removeLast();
        teamList
          ..clear()
          ..add(first)
          ..add(last)
          ..addAll(rotating);
      }
    }
  }

  static void _generateStandings(String leagueId, List<Map<String, dynamic>> teamData) {
    final list = <LeagueStanding>[];
    final rng = Random(leagueId.hashCode);

    List<Map<String, dynamic>> entries = teamData.map((t) {
      final mp = 5 + rng.nextInt(30);
      final gf = rng.nextInt(60) + 10;
      final ga = rng.nextInt(50) + 5;
      final pts = mp * 2 + rng.nextInt(40) - 20;
      return {
        'name': t['name'],
        'logo': t['logo'],
        'mp': mp,
        'gf': gf,
        'ga': ga,
        'pts': pts.clamp(0, mp * 3),
      };
    }).toList();

    entries.sort((a, b) {
      final c = (b['pts'] as int).compareTo(a['pts'] as int);
      if (c != 0) return c;
      final gd = (b['gf'] as int) - (b['ga'] as int) - ((a['gf'] as int) - (a['ga'] as int));
      if (gd != 0) return gd;
      return (b['gf'] as int).compareTo(a['gf'] as int);
    });

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final pts = e['pts'] as int;
      final mp = e['mp'] as int;
      final gf = e['gf'] as int;
      final ga = e['ga'] as int;
      final w = rng.nextInt(pts ~/ 3 + 1).clamp(0, mp);
      final d = pts - w * 3;
      final l = mp - w - d;

      final formChars = ['W', 'W', 'W', 'W', 'D', 'D', 'L', 'L', 'L'];
      final form = List.generate(5, (_) => formChars[rng.nextInt(formChars.length)]).join('');

      list.add(LeagueStanding(
        position: i + 1,
        clubName: e['name'] as String,
        clubLogo: e['logo'] as String,
        matchesPlayed: mp,
        wins: w,
        draws: d,
        losses: l,
        goalsFor: gf,
        goalsAgainst: ga,
        points: pts,
        form: form,
      ));
    }

    standings[leagueId] = list;
  }

  static Match? getMatchById(String matchId) {
    try {
      return matches.firstWhere((m) => m.id == matchId);
    } catch (_) {
      return null;
    }
  }

  static Lineup getLineup(String matchId) {
    final match = getMatchById(matchId);
    if (match == null) {
      return Lineup(matchId: matchId, homeTeam: _dummyTeamLineup('Home'), awayTeam: _dummyTeamLineup('Away'));
    }

    return Lineup(
      matchId: matchId,
      homeTeam: _generateTeamLineup(match.homeTeam, matchId, 'home'),
      awayTeam: _generateTeamLineup(match.awayTeam, matchId, 'away'),
    );
  }

  static TeamLineup _generateTeamLineup(String teamName, String matchId, String side) {
    final rng = Random(matchId.hashCode + side.hashCode);
    final formation = _formations[rng.nextInt(_formations.length)];
    final positions = _getPositionsForFormation(formation);
    final players = <Player>[];

    final usedNames = <String>{};
    for (int i = 0; i < positions.length; i++) {
      final name = _generatePlayerName(rng, usedNames);
      usedNames.add(name);
      final age = 18 + rng.nextInt(20);
      players.add(Player(
        id: '${matchId}_${side}_$i',
        name: name,
        number: i + 1,
        position: positions[i],
        nationality: ['Spain', 'Brazil', 'Argentina', 'England', 'Germany', 'Italy', 'France', 'Portugal'][rng.nextInt(8)],
        age: age,
        photo: '',
        rating: (60 + rng.nextDouble() * 40).roundToDouble() / 10,
        club: teamName,
        teamName: teamName,
      ));
    }

    final subs = <Player>[];
    for (int i = 0; i < 5; i++) {
      final name = _generatePlayerName(rng, usedNames);
      usedNames.add(name);
      subs.add(Player(
        id: '${matchId}_${side}_sub_$i',
        name: name,
        number: 12 + i,
        position: positions[rng.nextInt(positions.length)],
        nationality: 'Various',
        age: 20 + rng.nextInt(18),
        photo: '',
        rating: (55 + rng.nextDouble() * 35).roundToDouble() / 10,
        club: teamName,
        teamName: teamName,
      ));
    }

    return TeamLineup(teamName: teamName, formation: formation, startingPlayers: players, substitutes: subs);
  }

  static TeamLineup _dummyTeamLineup(String teamName) {
    return TeamLineup(teamName: teamName, formation: '4-3-3', startingPlayers: [], substitutes: []);
  }

  static List<String> _getPositionsForFormation(String formation) {
    final parts = formation.split('-').map(int.parse).toList();
    final positions = <String>['GK'];
    if (parts.length == 3) {
      for (int i = 0; i < parts[0]; i++) positions.add(['CB', 'CB', 'LB', 'RB'][i < 4 ? i : i % 4]);
      for (int i = 0; i < parts[1]; i++) positions.add(['CDM', 'CM', 'CM', 'CAM'][i < 4 ? i : i % 3]);
      for (int i = 0; i < parts[2]; i++) positions.add(['LW', 'RW', 'ST', 'ST'][i < 4 ? i : i % 3]);
    } else {
      positions.addAll(['CB', 'CB', 'LB', 'RB', 'CM', 'CM', 'LW', 'RW', 'ST', 'ST']);
    }
    return positions.take(11).toList();
  }

  static List<MatchEvent> getMatchEvents(String matchId) {
    final match = getMatchById(matchId);
    if (match == null || !match.isPlayed || match.homeScore == null) return [];

    final events = <MatchEvent>[];
    final rng = Random(matchId.hashCode);
    int eventId = 0;
    final usedMinutes = <int>{};

    for (int g = 0; g < match.homeScore!; g++) {
      events.add(MatchEvent(
        id: '${matchId}_evt_${eventId++}',
        matchId: matchId,
        minute: _getUniqueMinute(rng, usedMinutes),
        type: 'goal', team: 'home',
        playerName: _generatePlayerName(rng, {}),
        assistPlayerName: _generatePlayerName(rng, {}),
      ));
    }
    for (int g = 0; g < match.awayScore!; g++) {
      events.add(MatchEvent(
        id: '${matchId}_evt_${eventId++}',
        matchId: matchId,
        minute: _getUniqueMinute(rng, usedMinutes),
        type: 'goal', team: 'away',
        playerName: _generatePlayerName(rng, {}),
        assistPlayerName: _generatePlayerName(rng, {}),
      ));
    }

    final numYellow = rng.nextInt(6);
    for (int i = 0; i < numYellow; i++) {
      events.add(MatchEvent(
        id: '${matchId}_evt_${eventId++}',
        matchId: matchId,
        minute: _getUniqueMinute(rng, usedMinutes),
        type: 'yellow_card', team: rng.nextBool() ? 'home' : 'away',
        playerName: _generatePlayerName(rng, {}),
      ));
    }

    if (rng.nextDouble() < 0.15) {
      events.add(MatchEvent(
        id: '${matchId}_evt_${eventId++}',
        matchId: matchId,
        minute: _getUniqueMinute(rng, usedMinutes),
        type: 'red_card', team: rng.nextBool() ? 'home' : 'away',
        playerName: _generatePlayerName(rng, {}),
      ));
    }

    final numSubs = 1 + rng.nextInt(5);
    for (int i = 0; i < numSubs; i++) {
      events.add(MatchEvent(
        id: '${matchId}_evt_${eventId++}',
        matchId: matchId,
        minute: _getUniqueMinute(rng, usedMinutes),
        type: 'substitution', team: rng.nextBool() ? 'home' : 'away',
        playerName: _generatePlayerName(rng, {}),
        substitutePlayerName: _generatePlayerName(rng, {}),
      ));
    }

    events.sort((a, b) => a.minute.compareTo(b.minute));
    return events;
  }

  static int _getUniqueMinute(Random rng, Set<int> used) {
    for (int i = 0; i < 100; i++) {
      final m = 1 + rng.nextInt(90);
      if (!used.contains(m)) {
        used.add(m);
        return m;
      }
    }
    final m = used.isEmpty ? 1 : used.last + 1;
    used.add(m);
    return m;
  }

  static MatchStatistics getMatchStatistics(String matchId) {
    final match = getMatchById(matchId);
    if (match == null) return _dummyStatistics(matchId);

    final rng = Random(matchId.hashCode);
    final homePoss = 35 + rng.nextInt(30);
    final homeTotalShots = (match.homeScore ?? 0) + rng.nextInt(12);
    final awayTotalShots = (match.awayScore ?? 0) + rng.nextInt(12);

    return MatchStatistics(
      matchId: matchId,
      homeTeam: TeamStatistics(
        possession: homePoss,
        shots: homeTotalShots,
        shotsOnTarget: (match.homeScore ?? 0) + rng.nextInt(4).clamp(0, homeTotalShots),
        corners: rng.nextInt(10), fouls: 5 + rng.nextInt(15),
        yellowCards: rng.nextInt(4), redCards: rng.nextInt(2),
        offsides: rng.nextInt(5), passes: 200 + rng.nextInt(400),
        passAccuracy: 65 + rng.nextInt(30),
      ),
      awayTeam: TeamStatistics(
        possession: 100 - homePoss,
        shots: awayTotalShots,
        shotsOnTarget: (match.awayScore ?? 0) + rng.nextInt(4).clamp(0, awayTotalShots),
        corners: rng.nextInt(8), fouls: 5 + rng.nextInt(15),
        yellowCards: rng.nextInt(4), redCards: rng.nextInt(2),
        offsides: rng.nextInt(5), passes: 200 + rng.nextInt(400),
        passAccuracy: 65 + rng.nextInt(30),
      ),
    );
  }

  static MatchStatistics _dummyStatistics(String matchId) {
    return MatchStatistics(
      matchId: matchId,
      homeTeam: TeamStatistics(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0, offsides: 0, passes: 0, passAccuracy: 0),
      awayTeam: TeamStatistics(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0, offsides: 0, passes: 0, passAccuracy: 0),
    );
  }

  static List<Injury> getInjuries(String matchId) {
    final match = getMatchById(matchId);
    if (match == null) return [];

    final rng = Random(matchId.hashCode * 7);
    final numInjuries = rng.nextInt(4);
    final injuries = <Injury>[];
    final usedNames = <String>{};

    for (int i = 0; i < numInjuries; i++) {
      final name = _generatePlayerName(rng, usedNames);
      usedNames.add(name);
      final severity = ['minor', 'moderate', 'severe'][rng.nextInt(3)];
      final daysToReturn = severity == 'minor' ? 3 + rng.nextInt(12) : severity == 'moderate' ? 15 + rng.nextInt(30) : 60 + rng.nextInt(120);

      injuries.add(Injury(
        id: '${matchId}_inj_$i',
        playerName: name,
        injuryType: _injuryNames[rng.nextInt(_injuryNames.length)],
        severity: severity,
        injuryDate: match.matchTime.subtract(Duration(days: rng.nextInt(5))),
        expectedReturn: match.matchTime.add(Duration(days: daysToReturn)),
        team: rng.nextBool() ? match.homeTeam : match.awayTeam,
      ));
    }

    return injuries;
  }

  static Map<String, double> getPlayerRatings(String matchId) {
    final match = getMatchById(matchId);
    if (match == null) return {};

    final rng = Random(matchId.hashCode * 13);
    final ratings = <String, double>{};

    final playerCount = 14 + rng.nextInt(8);
    for (int i = 0; i < playerCount; i++) {
      ratings[_generatePlayerName(rng, ratings.keys.toSet())] = (55 + rng.nextDouble() * 45).roundToDouble() / 10;
    }

    return ratings;
  }

  static List<LeagueStanding> getLeagueStandings(String leagueId) {
    return standings[leagueId] ?? [];
  }

  static String _generatePlayerName(Random rng, Set<String> usedNames) {
    for (int attempt = 0; attempt < 50; attempt++) {
      final name = '${_firstNames[rng.nextInt(_firstNames.length)]} ${_lastNames[rng.nextInt(_lastNames.length)]}';
      if (!usedNames.contains(name)) return name;
    }
    return 'Player ${rng.nextInt(999)}';
  }
}
