import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_question.dart';
import 'dart:convert';
import 'dart:math';

class GeminiService {
  static const String _apiKey = 'AIzaSyAKkWslPPNzm_dvfp_6DRcZvjlEX_o8ucQ'; // مفتاح API
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  /// توليد أسئلة من Gemini AI
  Future<List<AIQuestion>> generateQuestions({
    required int count,
    required String difficulty,
    required String category,
    String? language = 'ar',
  }) async {
    try {
      final prompt = _buildPrompt(count, difficulty, category, language);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        throw Exception('No response from Gemini');
      }

      return _parseResponse(response.text!, difficulty, category);
    } catch (e) {
      print('Error generating questions: $e');
      return [];
    }
  }

  /// بناء Prompt للذكاء الصناعي
  String _buildPrompt(int count, String difficulty, String category, String? language) {
    final langText = language == 'ar' ? 'بالعربية' : language == 'tr' ? 'بالتركية' : 'بالإنجليزية';
    
    String categoryPrompt = '';
    
    switch (category) {
      case 'common_club':
        categoryPrompt = '''
أنشئ $count أسئلة كروية عن النادي المشترك بين اللاعبين.
السؤال: "في أي نادي لعب هؤلاء اللاعبون معاً؟"
اعطِ 2-4 أسماء لاعبين حسب الصعوبة، و4 أندية كخيارات.
''';
        break;
      
      case 'wrong_player':
        categoryPrompt = '''
أنشئ $count أسئلة كروية عن اللاعب الخطأ (الدخيل).
السؤال: "من هو اللاعب الذي لم يلعب لهذا النادي؟"
اعطِ اسم نادي و4 لاعبين، واحد منهم لم يلعب لهذا النادي.
''';
        break;
      
      case 'quiz':
        categoryPrompt = '''
أنشئ $count أسئلة كروية عامة ومتنوعة.
أسئلة عن: تاريخ، إحصائيات، بطولات، أرقام قياسية، لاعبين، مدربين.
''';
        break;
      
      default:
        categoryPrompt = '''
أنشئ $count أسئلة كروية متنوعة.
''';
    }

    String difficultyPrompt = '';
    switch (difficulty) {
      case 'easy':
        difficultyPrompt = 'سهلة جداً - معلومات عامة يعرفها معظم الناس';
        break;
      case 'medium':
        difficultyPrompt = 'متوسطة - تحتاج معرفة جيدة بكرة القدم';
        break;
      case 'hard':
        difficultyPrompt = 'صعبة جداً - معلومات نادرة ومتخصصة';
        break;
    }

    return '''
$categoryPrompt

الصعوبة: $difficultyPrompt
اللغة: $langText

**مهم جداً:**
1. يجب أن تكون جميع الأسئلة والخيارات $langText فقط
2. اجعل الأسئلة دقيقة ومبنية على معلومات صحيحة
3. تأكد من أن الإجابة الصحيحة دقيقة 100%
4. تنوع في المواضيع

**التنسيق المطلوب (JSON فقط بدون أي نص إضافي):**
[
  {
    "question": "نص السؤال؟",
    "options": ["خيار 1", "خيار 2", "خيار 3", "خيار 4"],
    "correct": "الإجابة الصحيحة"
  }
]

أرجع JSON فقط بدون أي نص قبله أو بعده.
''';
  }

  /// تحليل رد Gemini وتحويله لأسئلة
  List<AIQuestion> _parseResponse(String response, String difficulty, String category) {
    try {
      // تنظيف الرد من أي نص إضافي
      String cleanedResponse = response.trim();
      
      // إزالة markdown code blocks إذا وجدت
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      
      cleanedResponse = cleanedResponse.trim();

      final List<dynamic> jsonList = jsonDecode(cleanedResponse);
      final List<AIQuestion> questions = [];

      for (var item in jsonList) {
        final question = AIQuestion(
          id: _generateId(),
          questionText: item['question'] as String,
          options: (item['options'] as List<dynamic>).map((e) => e as String).toList(),
          correctAnswer: item['correct'] as String,
          difficulty: difficulty,
          category: category,
          createdAt: DateTime.now(),
          isUsed: false,
        );
        questions.add(question);
      }

      return questions;
    } catch (e) {
      print('Error parsing response: $e');
      print('Response was: $response');
      return [];
    }
  }

  /// توليد ID فريد
  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return '$timestamp-$randomNum';
  }

  /// التحقق من صلاحية API Key
  bool isConfigured() {
    return _apiKey != 'YOUR_GEMINI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}
