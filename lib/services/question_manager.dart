import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/ai_question.dart';
import 'gemini_service_extended.dart';
import 'question_cache_service.dart';

class QuestionManager {
  final GeminiServiceExtended _gemini = GeminiServiceExtended();
  final QuestionCacheService _cache = QuestionCacheService();
  
  bool _isInitialized = false;
  bool _isUpdating = false;

  /// التهيئة الأولية - تحميل الأسئلة إذا كانت فارغة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🚀 بدء تهيئة مدير الأسئلة...');
    
    final counts = await _cache.getQuestionsCount();
    
    if (counts.isEmpty) {
      print('📭 لا توجد أسئلة محفوظة، سيتم التحميل الأولي...');
      await _initialLoad();
    } else {
      print('✅ تم العثور على ${counts.values.reduce((a, b) => a + b)} سؤال محفوظ');
      
      // تحديث في الخلفية إذا لزم الأمر
      if (await _cache.needsUpdate()) {
        print('🔄 الأسئلة قديمة، سيتم التحديث في الخلفية...');
        _updateInBackground();
      }
    }
    
    _isInitialized = true;
  }

  /// التحميل الأولي للأسئلة
  Future<void> _initialLoad() async {
    if (!await _hasInternet()) {
      print('❌ لا يوجد اتصال بالإنترنت للتحميل الأولي');
      return;
    }

    if (!_gemini.isConfigured()) {
      print('⚠️ Gemini API غير مُعد، سيتم استخدام الأسئلة الافتراضية');
      return;
    }

    try {
      print('📥 جاري تحميل الأسئلة الأولية...');
      
      // تحميل أسئلة لكل فئة وصعوبة
      final categories = ['common_club', 'wrong_player', 'quiz', 'jersey_number'];
      final difficulties = ['easy', 'medium', 'hard'];
      
      int totalLoaded = 0;
      
      for (var category in categories) {
        for (var difficulty in difficulties) {
          try {
            final questions = await _gemini.generateQuestions(
              count: 20, // 20 سؤال لكل مجموعة
              difficulty: difficulty,
              category: category,
              language: 'ar',
            );
            
            if (questions.isNotEmpty) {
              await _cache.cacheQuestions(questions);
              totalLoaded = totalLoaded + questions.length;
              print('✅ تم تحميل ${questions.length} سؤال لـ $category - $difficulty');
            }
            
            // انتظار قصير لتجنب تجاوز حد API
            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            print('❌ خطأ في تحميل $category - $difficulty: $e');
          }
        }
      }
      
      print('🎉 تم التحميل الأولي: $totalLoaded سؤال');
    } catch (e) {
      print('❌ خطأ في التحميل الأولي: $e');
    }
  }

  /// التحديث في الخلفية
  Future<void> _updateInBackground() async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    try {
      if (!await _hasInternet() || !_gemini.isConfigured()) {
        return;
      }
      
      print('🔄 جاري تحديث الأسئلة في الخلفية...');
      
      // تحديث فئة واحدة فقط في كل مرة لتوفير API calls
      final categories = ['common_club', 'wrong_player', 'quiz'];
      final category = categories[DateTime.now().day % categories.length];
      
      for (var difficulty in ['easy', 'medium', 'hard']) {
        try {
          final questions = await _gemini.generateQuestions(
            count: 10,
            difficulty: difficulty,
            category: category,
            language: 'ar',
          );
          
          if (questions.isNotEmpty) {
            await _cache.cacheQuestions(questions);
            print('✅ تم تحديث ${questions.length} سؤال لـ $category - $difficulty');
          }
          
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('❌ خطأ في التحديث: $e');
        }
      }
      
      // حذف الأسئلة القديمة جداً
      await _cache.removeOldQuestions(maxAgeDays: 30);
    } finally {
      _isUpdating = false;
    }
  }

  /// الحصول على سؤال
  Future<AIQuestion?> getQuestion({
    required String difficulty,
    required String category,
  }) async {
    // تأكد من التهيئة
    if (!_isInitialized) {
      await initialize();
    }
    
    // حاول الحصول على سؤال من الكاش
    final question = await _cache.getRandomQuestion(
      difficulty: difficulty,
      category: category,
    );
    
    if (question != null) {
      // علّم السؤال كمستخدم
      await _cache.markQuestionAsUsed(question.id);
      return question;
    }
    
    // إذا لم يوجد، حاول التحميل من الإنترنت
    if (await _hasInternet() && _gemini.isConfigured()) {
      print('📥 لم يتم العثور على أسئلة، جاري التحميل...');
      try {
        final questions = await _gemini.generateQuestions(
          count: 20,
          difficulty: difficulty,
          category: category,
          language: 'ar',
        );
        
        if (questions.isNotEmpty) {
          await _cache.cacheQuestions(questions);
          return questions.first;
        }
      } catch (e) {
        print('❌ خطأ في تحميل الأسئلة: $e');
      }
    }
    
    return null; // لم نجد أسئلة
  }

  /// الحصول على عدة أسئلة
  Future<List<AIQuestion>> getQuestions({
    required String difficulty,
    required String category,
    required int count,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final questions = await _cache.getQuestions(
      difficulty: difficulty,
      category: category,
      count: count,
    );
    
    // علّم الأسئلة كمستخدمة
    for (var q in questions) {
      await _cache.markQuestionAsUsed(q.id);
    }
    
    // إذا لم نحصل على العدد المطلوب، حاول التحميل
    if (questions.length < count && await _hasInternet() && _gemini.isConfigured()) {
      try {
        final newQuestions = await _gemini.generateQuestions(
          count: count - questions.length,
          difficulty: difficulty,
          category: category,
          language: 'ar',
        );
        
        if (newQuestions.isNotEmpty) {
          await _cache.cacheQuestions(newQuestions);
          questions.addAll(newQuestions);
        }
      } catch (e) {
        print('❌ خطأ في تحميل أسئلة إضافية: $e');
      }
    }
    
    return questions.take(count).toList();
  }

  /// مسح cache الأسئلة
  Future<void> clearCache() async {
    print('🗑️ مسح جميع الأسئلة المحفوظة...');
    await _cache.clearCache();
    print('✅ تم مسح الـ cache بنجاح');
  }

  /// إعادة تحميل جميع الأسئلة
  Future<void> refreshAll() async {
    if (!await _hasInternet()) {
      print('❌ لا يوجد اتصال بالإنترنت');
      return;
    }
    
    if (!_gemini.isConfigured()) {
      print('⚠️ Gemini API غير مُعد');
      return;
    }
    
    await _cache.clearCache();
    await _initialLoad();
  }

  /// الحصول على إحصائيات الأسئلة
  Future<Map<String, int>> getStatistics() async {
    return await _cache.getQuestionsCount();
  }

  /// التحقق من وجود اتصال بالإنترنت
  Future<bool> _hasInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من جاهزية النظام
  bool isReady() {
    return _gemini.isConfigured();
  }
}
