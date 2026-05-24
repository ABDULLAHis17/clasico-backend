import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_question.dart';

class QuestionCacheService {
  static const String _lastUpdateKey = 'last_questions_update';
  static const int _updateIntervalDays = 7; // تحديث كل 7 أيام

  /// حفظ الأسئلة في ملف JSON
  Future<void> cacheQuestions(List<AIQuestion> questions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/questions_cache.json');

      // قراءة الأسئلة الموجودة
      List<AIQuestion> existingQuestions = await _readQuestionsFromFile();

      // إضافة الأسئلة الجديدة
      existingQuestions.addAll(questions);

      // حذف التكرارات
      final uniqueQuestions = <String, AIQuestion>{};
      for (var q in existingQuestions) {
        uniqueQuestions[q.id] = q;
      }

      // حفظ الأسئلة
      final jsonList = uniqueQuestions.values.map((q) => q.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      // تحديث تاريخ آخر تحديث
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      print('✅ تم حفظ ${uniqueQuestions.length} سؤال');
    } catch (e) {
      print('❌ خطأ في حفظ الأسئلة: $e');
    }
  }

  /// قراءة الأسئلة من الملف
  Future<List<AIQuestion>> _readQuestionsFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/questions_cache.json');

      if (!await file.exists()) {
        return [];
      }

      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      return jsonList.map((json) => AIQuestion.fromJson(json)).toList();
    } catch (e) {
      print('❌ خطأ في قراءة الأسئلة: $e');
      return [];
    }
  }

  /// الحصول على أسئلة حسب الفلتر
  Future<List<AIQuestion>> getQuestions({
    required String difficulty,
    required String category,
    required int count,
    bool onlyUnused = true,
  }) async {
    try {
      final allQuestions = await _readQuestionsFromFile();

      // فلترة الأسئلة
      var filteredQuestions = allQuestions
          .where(
            (q) =>
                q.difficulty == difficulty &&
                q.category == category &&
                (!onlyUnused || !q.isUsed),
          )
          .toList();

      // إذا لم نجد أسئلة غير مستخدمة، نستخدم أي أسئلة
      if (filteredQuestions.isEmpty && onlyUnused) {
        filteredQuestions = allQuestions
            .where((q) => q.difficulty == difficulty && q.category == category)
            .toList();

        // إعادة تعيين جميع الأسئلة كغير مستخدمة
        if (filteredQuestions.isNotEmpty) {
          await _resetUsedQuestions(category, difficulty);
        }
      }

      // خلط عشوائي
      filteredQuestions.shuffle();

      // إرجاع العدد المطلوب
      return filteredQuestions.take(count).toList();
    } catch (e) {
      print('❌ خطأ في الحصول على الأسئلة: $e');
      return [];
    }
  }

  /// الحصول على سؤال عشوائي واحد
  Future<AIQuestion?> getRandomQuestion({
    required String difficulty,
    required String category,
  }) async {
    final questions = await getQuestions(
      difficulty: difficulty,
      category: category,
      count: 1,
    );

    return questions.isNotEmpty ? questions.first : null;
  }

  /// تعليم السؤال كمستخدم
  Future<void> markQuestionAsUsed(String questionId) async {
    try {
      final allQuestions = await _readQuestionsFromFile();

      // تحديث السؤال
      final updatedQuestions = allQuestions.map((q) {
        if (q.id == questionId) {
          return q.copyWith(isUsed: true);
        }
        return q;
      }).toList();

      // حفظ التحديث
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/questions_cache.json');
      final jsonList = updatedQuestions.map((q) => q.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('❌ خطأ في تعليم السؤال: $e');
    }
  }

  /// إعادة تعيين الأسئلة المستخدمة
  Future<void> _resetUsedQuestions(String category, String difficulty) async {
    try {
      final allQuestions = await _readQuestionsFromFile();

      final updatedQuestions = allQuestions.map((q) {
        if (q.category == category && q.difficulty == difficulty) {
          return q.copyWith(isUsed: false);
        }
        return q;
      }).toList();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/questions_cache.json');
      final jsonList = updatedQuestions.map((q) => q.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      print('🔄 تم إعادة تعيين الأسئلة لـ $category - $difficulty');
    } catch (e) {
      print('❌ خطأ في إعادة التعيين: $e');
    }
  }

  /// التحقق من الحاجة للتحديث
  Future<bool> needsUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (lastUpdateStr == null) {
        return true; // لم يتم التحديث من قبل
      }

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;

      return daysSinceUpdate >= _updateIntervalDays;
    } catch (e) {
      return true; // في حالة الخطأ، نفترض أننا نحتاج للتحديث
    }
  }

  /// الحصول على عدد الأسئلة المحفوظة
  Future<Map<String, int>> getQuestionsCount() async {
    try {
      final allQuestions = await _readQuestionsFromFile();

      final Map<String, int> counts = {};

      for (var q in allQuestions) {
        final key = '${q.category}_${q.difficulty}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  /// حذف جميع الأسئلة المحفوظة
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/questions_cache.json');

      if (await file.exists()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUpdateKey);

      print('🗑️ تم حذف جميع الأسئلة المحفوظة');
    } catch (e) {
      print('❌ خطأ في حذف الكاش: $e');
    }
  }

  /// تحديث الأسئلة القديمة
  Future<void> removeOldQuestions({int maxAgeDays = 30}) async {
    try {
      final allQuestions = await _readQuestionsFromFile();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));

      final recentQuestions = allQuestions
          .where((q) => q.createdAt.isAfter(cutoffDate))
          .toList();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/questions_cache.json');
      final jsonList = recentQuestions.map((q) => q.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      print(
        '🧹 تم حذف ${allQuestions.length - recentQuestions.length} سؤال قديم',
      );
    } catch (e) {
      print('❌ خطأ في حذف الأسئلة القديمة: $e');
    }
  }
}
