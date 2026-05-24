import 'package:google_generative_ai/google_generative_ai.dart';

class CommentModerationService {
  static const String _apiKey = 'AIzaSyAKkWslPPNzm_dvfp_6DRcZvjlEX_o8ucQ';
  static GenerativeModel? _model;

  static GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// التحقق من التعليق إذا كان مخالفاً للآداب
  /// Returns true إذا كان التعليق مخالفاً للآداب
  static Future<bool> isInappropriateComment(String commentText) async {
    try {
      final prompt = '''
تحليل التعليق التالي وتحديد ما إذا كان يحتوي على محتوى مخالف للآداب أو مسيء أو عنيف أو يحتوي على كلمات نابية أو تمييز أو كراهية.

التعليق: "$commentText"

أجب بـ "نعم" فقط إذا كان التعليق مخالفاً للآداب، أو "لا" إذا كان التعليق مناسباً.
الرد يجب أن يكون كلمة واحدة فقط: "نعم" أو "لا"
''';

      final content = [Content.text(prompt)];
      final response = await _getModel().generateContent(content);
      
      if (response.text == null) {
        return false;
      }

      final result = response.text!.toLowerCase().trim();
      return result.contains('نعم') || result.contains('yes');
    } catch (e) {
      print('Error in comment moderation: $e');
      return false;
    }
  }

  /// الحصول على سبب حظر التعليق
  static Future<String> getModerationReason(String commentText) async {
    try {
      final prompt = '''
حلل التعليق التالي وحدد السبب الرئيسي لكونه مخالفاً للآداب بإيجاز جداً (جملة واحدة فقط):

التعليق: "$commentText"

الأسباب المحتملة:
- كلمات نابية أو مسيئة
- محتوى عنيف أو تهديدات
- تمييز أو كراهية
- محتوى جنسي أو غير لائق
- إساءة شخصية

أجب بسبب واحد فقط بشكل مختصر جداً.
''';

      final content = [Content.text(prompt)];
      final response = await _getModel().generateContent(content);
      
      return response.text ?? 'محتوى مخالف للآداب';
    } catch (e) {
      print('Error getting moderation reason: $e');
      return 'محتوى مخالف للآداب';
    }
  }
}
