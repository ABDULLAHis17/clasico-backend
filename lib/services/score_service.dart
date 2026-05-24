import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// خدمة حفظ وإدارة النقاط لجميع الألعاب
class ScoreService {
  static const String _keyTotalGamesPlayed = 'total_games_played';
  static const String _keyTotalWins = 'total_wins';
  static const String _keyTotalLosses = 'total_losses';
  static const String _keyTotalScore = 'total_score';
  static const String _keyGameScores = 'game_scores';
  static const String _keyBestScores = 'best_scores';
  static const String _keyThirtyChallengeCompleted = 'thirty_challenge_completed';
  static const String _keyLastPlayedDate = 'last_played_date';

  /// حفظ نتيجة لعبة
  Future<void> saveGameResult({
    required String gameName,
    required int playerScore,
    required int computerScore,
    required bool isWin,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // تحديث الإحصائيات العامة
    final totalGames = (prefs.getInt(_keyTotalGamesPlayed) ?? 0) + 1;
    await prefs.setInt(_keyTotalGamesPlayed, totalGames);

    if (isWin) {
      final totalWins = (prefs.getInt(_keyTotalWins) ?? 0) + 1;
      await prefs.setInt(_keyTotalWins, totalWins);
    } else {
      final totalLosses = (prefs.getInt(_keyTotalLosses) ?? 0) + 1;
      await prefs.setInt(_keyTotalLosses, totalLosses);
    }

    final totalScore = (prefs.getInt(_keyTotalScore) ?? 0) + playerScore;
    await prefs.setInt(_keyTotalScore, totalScore);

    // حفظ تاريخ آخر لعب
    await prefs.setString(_keyLastPlayedDate, DateTime.now().toIso8601String());

    // حفظ نقاط اللعبة المحددة
    await _saveGameScore(gameName, playerScore, computerScore, isWin);

    // تحديث أفضل النتائج
    await _updateBestScore(gameName, playerScore);
  }

  /// حفظ نقاط لعبة محددة
  Future<void> _saveGameScore(
    String gameName,
    int playerScore,
    int computerScore,
    bool isWin,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_keyGameScores) ?? '{}';
    final scores = Map<String, dynamic>.from(json.decode(scoresJson));

    if (!scores.containsKey(gameName)) {
      scores[gameName] = {
        'played': 0,
        'wins': 0,
        'losses': 0,
        'totalPlayerScore': 0,
        'totalComputerScore': 0,
      };
    }

    scores[gameName]['played']++;
    if (isWin) {
      scores[gameName]['wins']++;
    } else {
      scores[gameName]['losses']++;
    }
    scores[gameName]['totalPlayerScore'] += playerScore;
    scores[gameName]['totalComputerScore'] += computerScore;

    await prefs.setString(_keyGameScores, json.encode(scores));
  }

  /// تحديث أفضل النتائج
  Future<void> _updateBestScore(String gameName, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final bestScoresJson = prefs.getString(_keyBestScores) ?? '{}';
    final bestScores = Map<String, dynamic>.from(json.decode(bestScoresJson));

    if (!bestScores.containsKey(gameName) || score > (bestScores[gameName] ?? 0)) {
      bestScores[gameName] = score;
      await prefs.setString(_keyBestScores, json.encode(bestScores));
    }
  }

  /// حفظ إنجاز تحدي الثلاثين
  Future<void> saveThirtyChallengeCompletion({
    required int playerTotalScore,
    required int computerTotalScore,
    required bool isWin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = (prefs.getInt(_keyThirtyChallengeCompleted) ?? 0) + 1;
    await prefs.setInt(_keyThirtyChallengeCompleted, completed);

    // حفظ أفضل نتيجة في تحدي الثلاثين
    await _updateBestScore('thirty_challenge', playerTotalScore);
  }

  /// الحصول على إحصائيات عامة
  Future<Map<String, int>> getTotalStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'gamesPlayed': prefs.getInt(_keyTotalGamesPlayed) ?? 0,
      'wins': prefs.getInt(_keyTotalWins) ?? 0,
      'losses': prefs.getInt(_keyTotalLosses) ?? 0,
      'totalScore': prefs.getInt(_keyTotalScore) ?? 0,
      'thirtyChallengeCompleted': prefs.getInt(_keyThirtyChallengeCompleted) ?? 0,
    };
  }

  /// الحصول على إحصائيات لعبة محددة
  Future<Map<String, int>> getGameStats(String gameName) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_keyGameScores) ?? '{}';
    final scores = Map<String, dynamic>.from(json.decode(scoresJson));

    if (scores.containsKey(gameName)) {
      return {
        'played': scores[gameName]['played'],
        'wins': scores[gameName]['wins'],
        'losses': scores[gameName]['losses'],
        'totalPlayerScore': scores[gameName]['totalPlayerScore'],
        'totalComputerScore': scores[gameName]['totalComputerScore'],
      };
    }

    return {
      'played': 0,
      'wins': 0,
      'losses': 0,
      'totalPlayerScore': 0,
      'totalComputerScore': 0,
    };
  }

  /// الحصول على أفضل النتائج
  Future<Map<String, int>> getBestScores() async {
    final prefs = await SharedPreferences.getInstance();
    final bestScoresJson = prefs.getString(_keyBestScores) ?? '{}';
    return Map<String, int>.from(json.decode(bestScoresJson));
  }

  /// الحصول على أفضل نتيجة للعبة محددة
  Future<int> getBestScore(String gameName) async {
    final bestScores = await getBestScores();
    return bestScores[gameName] ?? 0;
  }

  /// الحصول على آخر تاريخ لعب
  Future<DateTime?> getLastPlayedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_keyLastPlayedDate);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  /// نسبة الفوز
  Future<double> getWinRate() async {
    final stats = await getTotalStats();
    final totalGames = stats['gamesPlayed'] ?? 0;
    if (totalGames == 0) return 0.0;
    return (stats['wins']! / totalGames) * 100;
  }

  /// متوسط النقاط
  Future<double> getAverageScore() async {
    final stats = await getTotalStats();
    final totalGames = stats['gamesPlayed'] ?? 0;
    if (totalGames == 0) return 0.0;
    return stats['totalScore']! / totalGames;
  }

  /// مسح جميع الإحصائيات
  Future<void> clearAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTotalGamesPlayed);
    await prefs.remove(_keyTotalWins);
    await prefs.remove(_keyTotalLosses);
    await prefs.remove(_keyTotalScore);
    await prefs.remove(_keyGameScores);
    await prefs.remove(_keyBestScores);
    await prefs.remove(_keyThirtyChallengeCompleted);
    await prefs.remove(_keyLastPlayedDate);
  }
}
