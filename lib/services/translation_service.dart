import 'package:google_generative_ai/google_generative_ai.dart';

class TranslationService {
  static const String _apiKey = 'AIzaSyAKkWslPPNzm_dvfp_6DRcZvjlEX_o8ucQ';
  
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash-lite',
    apiKey: _apiKey,
  );

  static Future<String> translateText(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    try {
      final languageNames = {
        'ar': 'Arabic',
        'en': 'English',
        'tr': 'Turkish',
      };

      final fromLang = languageNames[fromLanguage] ?? 'Arabic';
      final toLang = languageNames[toLanguage] ?? 'English';

      final prompt = '''You are a professional translator.
Translate the following text from $fromLang to $toLang.
IMPORTANT: You MUST reply in $toLang. Do not reply in English unless $toLang is English.
Provide ONLY the translated text without any quotes or explanations.

Text to translate:
$text''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      }
      throw Exception('Translation failed: Empty response');
    } catch (e) {
      print('Translation error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('quota') || errorStr.contains('429') || errorStr.contains('rate limit')) {
        throw Exception('تم تجاوز الحد المسموح للاستخدام المجاني للذكاء الاصطناعي. يرجى المحاولة بعد دقيقة.');
      }
      throw Exception('حدث خطأ أثناء الترجمة. يرجى المحاولة مرة أخرى.');
    }
  }
}
