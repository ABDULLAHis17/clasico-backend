import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the Clasico FastAPI backend.
/// Base URL points to the locally running Docker container.
class ApiService {
  static const String baseUrl = 'https://clasico.onrender.com';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ─────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/token');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> register(String email, String password, {String? displayName}) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (displayName != null) body['display_name'] = displayName;
      
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await login(email, password);
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return _getOne('/users/me');
  }

  Future<bool> updateProfile({
    String? username,
    String? phoneNumber,
    String? displayName,
    String? favoritePlayer,
    String? favoriteTeam,
    String? favoriteNationalTeam,
    String? favoriteLeague,
  }) async {
    final uri = Uri.parse('$baseUrl/users/me/profile');
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (displayName != null) body['display_name'] = displayName;
      if (favoritePlayer != null) body['favorite_player'] = favoritePlayer;
      if (favoriteTeam != null) body['favorite_team'] = favoriteTeam;
      if (favoriteNationalTeam != null) body['favorite_national_team'] = favoriteNationalTeam;
      if (favoriteLeague != null) body['favorite_league'] = favoriteLeague;

      final response = await _client.put(
        uri,
        headers: _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/users/me/password');
    try {
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    return _getList('/users/search', queryParams: {'q': query});
  }

  // ─────────────────────────────────────────
  // Generic helpers
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getList(String path,
      {Map<String, String?>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams != null
          ? {for (var e in queryParams.entries) if (e.value != null) e.key: e.value!}
          : null,
    );
    final response = await _client.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> _getOne(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _post(String path, dynamic body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _getHeaders(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _patch(String path, dynamic body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.patch(
      uri,
      headers: _getHeaders(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.delete(uri, headers: _getHeaders()).timeout(const Duration(seconds: 10));
    return response.statusCode == 200;
  }

  // ─────────────────────────────────────────
  // Leagues
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeagues() =>
      _getList('/leagues/');

  Future<Map<String, dynamic>?> getLeague(String id) =>
      _getOne('/leagues/$id');

  Future<List<Map<String, dynamic>>> getLeagueTeams(String leagueId, {String? search, int limit = 50, int offset = 0}) =>
      _getList('/leagues/$leagueId/teams', queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

  // ─────────────────────────────────────────
  // Matches
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMatches({String? leagueId}) =>
      _getList('/matches/', queryParams: {'league_id': leagueId});

  Future<Map<String, dynamic>?> getMatch(String id) =>
      _getOne('/matches/$id');

  // ─────────────────────────────────────────
  // Teams
  // ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getTeamDetails(String id) =>
      _getOne('/teams/$id');

  // ─────────────────────────────────────────
  // News
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNews({String? leagueId}) =>
      _getList('/news/', queryParams: {'league_id': leagueId});

  Future<Map<String, dynamic>?> getNewsItem(String id) =>
      _getOne('/news/$id');

  // ─────────────────────────────────────────
  // Players
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPlayers({String? search, int limit = 50, int offset = 0}) =>
      _getList('/players/', queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

  Future<Map<String, dynamic>?> getPlayer(String id) =>
      _getOne('/players/$id');

  // ─────────────────────────────────────────
  // Teams
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeams({String? search, String? teamType, int limit = 50, int offset = 0}) =>
      _getList('/teams/', queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (teamType != null && teamType.isNotEmpty) 'team_type': teamType,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

  Future<Map<String, dynamic>?> getTeam(String id) =>
      _getOne('/teams/$id');

  Future<Map<String, dynamic>?> getTeamByName(String name) =>
      _getOne('/teams/by-name/${Uri.encodeComponent(name)}');

  // ─────────────────────────────────────────
  // Stadiums
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStadiums({String? search, int limit = 50, int offset = 0}) =>
      _getList('/stadiums/', queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

  Future<Map<String, dynamic>?> getStadium(String id) =>
      _getOne('/stadiums/$id');

  // ─────────────────────────────────────────
  // Coaches
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCoaches({String? search, int limit = 50, int offset = 0}) =>
      _getList('/coaches/', queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

  Future<Map<String, dynamic>?> getCoach(String id) =>
      _getOne('/coaches/$id');

  // ─────────────────────────────────────────
  // Public Feedback
  // ─────────────────────────────────────────
  
  Future<bool> submitFeedback(String message, {String? email}) async {
    final response = await _post('/feedback/', {
      'message': message,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    return response != null;
  }

  // ─────────────────────────────────────────
  // Admin Endpoints
  // ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getAdminStats() =>
      _getOne('/admin/dashboard/stats');

  Future<List<Map<String, dynamic>>> getAdminUsers({String? search, String? status, String? role}) =>
      _getList('/admin/users/', queryParams: {'search': search, 'status': status, 'role': role});

  Future<Map<String, dynamic>?> getAdminUserDetail(String id) =>
      _getOne('/admin/users/$id');

  Future<Map<String, dynamic>?> updateUserRole(String id, List<String> roles) =>
      _patch('/admin/users/$id/role', {'roles': roles});

  Future<Map<String, dynamic>?> banUser(String id, {
    required String type,
    required String reason,
    int? durationDays,
    String? gameCode,
    String? ipAddress,
  }) => _post('/admin/users/$id/ban', {
    'type': type,
    'reason': reason,
    'duration_days': durationDays,
    'game_code': gameCode,
    'ip_address': ipAddress,
  });

  Future<Map<String, dynamic>?> unbanUser(String id) =>
      _post('/admin/users/$id/unban', {});

  Future<List<Map<String, dynamic>>> getReportedComments() =>
      _getList('/admin/comments/reported');

  Future<bool> deleteComment(String id) =>
      _delete('/admin/comments/$id');

  Future<List<Map<String, dynamic>>> getAuditLogs() =>
      _getList('/admin/audit-logs/');

  Future<List<Map<String, dynamic>>> getAdminFeedback() =>
      _getList('/admin/feedback/');

  Future<bool> resolveAdminFeedback(int id, {bool reject = false}) async {
    final action = reject ? 'reject' : 'resolve';
    final response = await _patch('/admin/feedback/$id/$action', {});
    return response != null;
  }

  // ─────────────────────────────────────────
  // Generate & Match Details
  // ─────────────────────────────────────────

  Future<bool> generateMockMatches() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/matches/generate'), headers: _getHeaders())
          .timeout(const Duration(seconds: 60));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMatchLineup(String matchId) async {
    return _getOne('/matches/$matchId/lineup');
  }

  Future<List<Map<String, dynamic>>> getMatchEvents(String matchId) async {
    return _getList('/matches/$matchId/events');
  }

  Future<Map<String, dynamic>?> getMatchStatistics(String matchId) async {
    return _getOne('/matches/$matchId/statistics');
  }

  Future<List<Map<String, dynamic>>> getMatchInjuries(String matchId) async {
    return _getList('/matches/$matchId/injuries');
  }

  Future<List<Map<String, dynamic>>> getLeagueStandings(String leagueId) async {
    return _getList('/matches/standings/$leagueId');
  }

  // ─────────────────────────────────────────
  // Health check
  // ─────────────────────────────────────────

  Future<bool> isApiAvailable() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
