import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_question_types.dart';
import '../models/ai_question.dart';
import 'dart:convert';
import 'dart:math';

/// سيرفس Gemini المحدث لدعم جميع أنواع الأسئلة
class GeminiServiceExtended {
  static const String _apiKey = 'AIzaSyAKkWslPPNzm_dvfp_6DRcZvjlEX_o8ucQ';
  late final GenerativeModel _model;
  
  // لتخزين الأسئلة السابقة لتجنب التكرار
  final Set<String> _usedQuestions = {};

  GeminiServiceExtended() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  bool isConfigured() {
    return _apiKey != 'YOUR_GEMINI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }

  String _generateId() {
    final random = Random();
    return 'q_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(9999)}';
  }
  
  void clearUsedQuestions() {
    _usedQuestions.clear();
    print('🗑️ Cleared used questions cache');
  }
  
  // مسح تلقائي إذا تجاوز العدد 100 سؤال
  void _autoCleanUsedQuestions() {
    if (_usedQuestions.length > 100) {
      // احتفظ فقط بآخر 50 سؤال
      final recentQuestions = _usedQuestions.toList().sublist(_usedQuestions.length - 50);
      _usedQuestions.addAll(recentQuestions);
      print('🔄 Auto-cleaned used questions cache. Kept last 50 questions.');
    }
  }

  // ========== Wrapper function for compatibility ==========
  Future<List<AIQuestion>> generateQuestions({
    required int count,
    required String difficulty,
    required String category,
    String? language = 'ar',
  }) async {
    final mcQuestions = await generateMultipleChoiceQuestions(
      count: count,
      difficulty: difficulty,
      category: category,
      language: language,
    );
    
    // تحويل إلى AIQuestion
    return mcQuestions.map((q) => AIQuestion(
      id: q.id,
      questionText: q.questionText,
      options: q.options,
      correctAnswer: q.correctAnswer,
      difficulty: q.difficulty,
      category: q.category,
      createdAt: q.createdAt,
    )).toList();
  }

  // ========== 1. أسئلة متعددة الخيارات ==========
  Future<List<AIMultipleChoiceQuestion>> generateMultipleChoiceQuestions({
    required int count,
    required String difficulty,
    required String category, // 'common_club', 'wrong_player', 'quiz'
    String? language = 'ar',
  }) async {
    // مسح تلقائي إذا كان هناك الكثير من الأسئلة المستخدمة
    _autoCleanUsedQuestions();
    
    // إعادة المحاولة حتى 3 مرات للأسئلة الخاطئة
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🎲 Attempt $attempt/3 for category: $category');
        
        print('🔄 Building prompt for $count $difficulty questions...');
        final prompt = _buildMultipleChoicePrompt(count, difficulty, category, language ?? 'ar');
        print('📤 Sending request to Gemini API...');
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);
        
        if (response.text == null) {
          print('❌ No response text from Gemini');
          continue; // حاول مرة أخرى
        }
        
        print('📥 Received response from Gemini (${response.text!.length} chars)');
        print('📄 Response preview: ${response.text!.substring(0, response.text!.length > 200 ? 200 : response.text!.length)}...');
        
        final questions = await _parseMultipleChoiceResponse(response.text!, difficulty, category);
        
        if (questions.isNotEmpty) {
          print('✅ Parsed ${questions.length} valid questions successfully');
          return questions;
        }
        
        print('⚠️ No valid questions generated, retrying...');
      } catch (e) {
        print('❌ Error on attempt $attempt: $e');
        if (attempt == 3) {
          print('❌ Failed after 3 attempts');
          return [];
        }
      }
    }
    
    print('❌ Failed to generate valid questions after 3 attempts');
    return [];
  }

  // ========== معايير الصعوبة الاحترافية ==========
  String _getDifficultyGuidelines(String difficulty, String language) {
    print('📋 Loading difficulty guidelines for: $difficulty ($language)');
    
    if (language == 'ar') {
      switch (difficulty) {
        case 'easy':
          return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 **المستوى السهل - نجوم عالميون حاليون**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**🎯 الفلسفة:** أسئلة عن أشهر اللاعبين في العالم حالياً

**👤 اللاعبون المسموح بهم:**
✅ النجوم العالميون الحاليون فقط (2023-2025):
   • مهاجمون: هالاند، مبابي، كين، لوكاكو، بنزيما (السعودية)
   • أجنحة: صلاح، فينيسيوس، ساكا، رافينيا، مارتينيز
   • وسط: دي بروين، بيلينجهام، رودري، فالفيردي، برونو فيرنانديز
   • دفاع: فان دايك، رودريجر، دياس، والكر، كوندي
   
**🏆 الأندية المسموح بها:**
✅ أندية الخمس الكبار فقط:
   • إنجلترا: مانشستر سيتي، ليفربول، أرسنال، مانشستر يونايتد، تشيلسي
   • إسبانيا: ريال مدريد، برشلونة، أتلتيكو مدريد
   • ألمانيا: بايرن ميونخ، دورتموند
   • إيطاليا: إنتر، ميلان، يوفنتوس، نابولي
   • فرنسا: باريس سان جيرمان
   
**⏰ الفترة الزمنية:**
✅ 2020-2025 فقط (آخر 5 سنوات)

**❌ ممنوع منعاً باتاً:**
❌ لاعبون معتزلون
❌ لاعبون قدامى (قبل 2020)
❌ أندية صغيرة
❌ دوريات أقل

**📊 أمثلة مثالية:**
✅ "من الدخيل؟ الكل لعب لليفربول: صلاح، ماني، فان دايك، كين"
✅ "في أي نادي لعب بيلينجهام وفينيسيوس معاً؟" (ريال مدريد 2023-)
✅ "من لم يلعب لمانشستر سيتي؟ هالاند، دي بروين، رودري، صلاح"
''';
        case 'medium':
          return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔵 **المستوى المتوسط - تنوع كبير من جميع العصور!**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**🎯 الفلسفة:** مزيج متنوع من لاعبين من عصور مختلفة - حديثة، قديمة، وجيل ذهبي

**⚠️ مهم جداً - التنويع في الأسئلة:**
✅ نوّع الأسئلة من جميع العصور - لا تكرر نفس اللاعبين!
✅ استخدم لاعبين من فترات زمنية مختلفة في كل جولة
✅ امزج بين العصر الحديث والقديم والجيل الذهبي

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ **توزيع الأسئلة حسب العصور:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**📍 العصر الحديث (2020-2025) - 30% من الأسئلة:**
✅ لاعبون حاليون معروفون:
   • مهاجمون: أوسيمين، إسماعيل، ميتروفيتش، تاليسكا، مالكوم
   • أجنحة: كفاراتسخيليا، ليو، أنتوني، ماهرز، زياش
   • وسط: جابي، كامافينجا، بروزوفيتش، فابينيو، كاسيميرو
   • دفاع: أكانجي، غابريال، بريمر، كوليبالي، كونسيساو
   
**📍 الجيل الذهبي (2008-2019) - 40% من الأسئلة:**
✅ نجوم الجيل الذهبي (لاعبون معتزلون أو في نهاية المسيرة):
   • مهاجمون: فالكاو، توريس، فيلا، هونتيلار، ديفو، كروزي، بالوتيلي
   • أجنحة: روبن، ريبيري، دي ماريا، أوزيل، مودريتش (شباب)، هازارد
   • وسط: تشابي ألونسو، بيرلو، سنايدر، لامبارد، جيرارد، كاكا
   • دفاع: بيكيه، راموس (شباب)، كومباني، تشيليني، بونوتشي، فيديتش

**📍 الزمن البعيد - الأساطير (1990-2007) - 30% من الأسئلة:**
✅ أساطير كرة القدم (لاعبون قدامى):
   • مهاجمون: رونالدو البرازيلي، روماريو، بييرو، شيفتشينكو، ترينكييه، باتيستوتا
   • أجنحة: فيغو، ريفالدو، نيدفيد، جيجز، ديكو
   • وسط: زيدان، ريفالدو، سيدورف، ديكو، فيرون، ديفيدز
   • دفاع: مالديني، نيستا، كانافارو، كارلوس، كافو، بويول، تورام

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏆 **الأندية من جميع العصور:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ **أندية حديثة (2015-2025):**
   • إنجلترا: توتنهام، نيوكاسل، أستون فيلا، وست هام، ليستر
   • إسبانيا: إشبيلية، فالنسيا، فياريال، ريال بيتيس
   • ألمانيا: لايبزيغ، ليفركوزن، فرانكفورت
   • إيطاليا: لاتسيو، روما، أتالانتا، فيورنتينا
   • فرنسا: موناكو، ليون، مارسيليا

✅ **أندية الجيل الذهبي (2008-2019):**
   • أتلتيكو مدريد (عهد فالكاو، توريس)
   • تشيلسي (عهد لامبارد، دروجبا)
   • مانشستر يونايتد (عهد فيرجسون)
   • إنتر ميلان (عهد موسكو، سنايدر)
   • بايرن ميونخ (عهد روبن، ريبيري)

✅ **أندية الأساطير (1990-2007):**
   • ميلان (عهد مالديني، شيفتشينكو)
   • يوفنتوس (عهد بييرو، ديل بييرو)
   • ريال مدريد (الجلاكتيكوس: زيدان، رونالدو، فيغو)
   • برشلونة (عهد رونالدينيو، ريفالدو)
   • إنتر (عهد رونالدو)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ **الفترة الزمنية الشاملة:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 1990-2025 (35 سنة من تاريخ كرة القدم)
✅ نوّع بين العصور في كل جولة
✅ لا تكرر نفس الفترة الزمنية

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 **أمثلة مثالية من جميع العصور:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ **عصر حديث:**
"من الدخيل؟ الكل لعب لنابولي: أوسيمين، كفاراتسخيليا، لوزانو، ليو"

✅ **الجيل الذهبي:**
"من لم يلعب لتشيلسي؟ لامبارد، دروجبا، تيري، جيرارد"
"في أي نادي لعب فالكاو وأغويرو معاً؟" (أتلتيكو مدريد)

✅ **الزمن البعيد:**
"من الدخيل؟ الكل لعب لميلان: مالديني، شيفتشينكو، بييرو، نيستا"
"في أي نادي لعب زيدان وفيغو معاً؟" (ريال مدريد - الجلاكتيكوس)
"من لم يلعب ليوفنتوس؟ بييرو، ديل بييرو، نيدفيد، مالديني"

✅ **مزيج من العصور:**
"من الأسطوري الذي حمل الرقم 10 في برشلونة؟" (ريفالدو، رونالدينيو، ميسي)
''';
        case 'hard':
          return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 **المستوى الصعب - للخبراء فقط!**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**⚠️⚠️⚠️ قواعد صارمة جداً - عدم الالتزام = فشل السؤال:**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫 **ممنوع منعاً باتاً - القائمة الكاملة:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**❌ النجوم الكبار (ممنوع تماماً):**
❌ كريستيانو رونالدو، ميسي، نيمار، بنزيما، صلاح
❌ مبابي، هالاند، دي بروين، كين، لوكاكو
❌ مودريتش، كروس، بيلينجهام، فينيسيوس، رودريجو
❌ ليفاندوفسكي، سواريز، كافاني، أغويرو، فالكاو

**❌ اللاعبون المعروفون (ممنوع أيضاً):**
❌ رودري، بيدري، جافي، كامافينجا، فالفيردي
❌ ساكا، رافينيا، أنتوني، غريليش، فودن
❌ كفاراتسخيليا، أوسيمين، ليو، موسيالا
❌ فان دايك، رودريجر، دياس، والكر، كوندي
❌ ميتروفيتش، مالكوم، تاليسكا، فابينيو، كانتي

**❌ أندية الخمس الكبار الرئيسية (ممنوع):**
❌ ريال مدريد، برشلونة، مانشستر سيتي، ليفربول
❌ بايرن ميونخ، باريس سان جيرمان، تشيلسي، أرسنال
❌ مانشستر يونايتد، يوفنتوس، ميلان، إنتر، نابولي
❌ الهلال، النصر (اللاعبون المشهورون)

**👤 استخدم فقط لاعبين من هذه الفئات:**

📌 **لاعبون من الدرجة الثانية - قليلو الشهرة:**
   • مهاجمون: موسى ديابي، نيكولا بيبي، سيباستيان هالر، شرداد أزمون، ويسام بن يدر
   • أجنحة: ماكسيم لوبيز، أندريه سيلفا، جيانو ماني، كلود موريس، أرنو نوردين
   • وسط: دانيلو بيريرا، ويليام كارفاليو، هوساين العويران، سالم الدوسري، ماثيوس نونيش
   • دفاع: جايسون دينير، روبن دياز (القديم)، كيم مين-جاي، إيفان مار كوفاسيتش

📌 **أندية من الدرجة الثانية والثالثة:**
   • فرنسا: موناكو، نيس، رين، نانت، بوردو
   • ألمانيا: هيرتا برلين، شالكه، فرايبورغ، ماينتس
   • إيطاليا: جنوى، سامبدوريا، أودينيزي، إمبولي، كالياري
   • إسبانيا: سيلتا فيغو، إلتشي، خيتافي، ليفانتي، إسبانيول
   • إنجلترا: برايتون، كريستال بالاس، بيرنلي، فولهام، واتفورد
   • البرتغال: غيماريش، براغا، بوافيستا
   • هولندا: يوترخت، فيتيسه، هيرنفين
   • تركيا: قونيا سبور، ألانيا سبور، ريزة سبور
   • السعودية: الفيحاء، الفتح، الشباب، الرائد

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 **أمثلة صارمة - اتبعها بدقة:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**❌❌❌ أمثلة ممنوعة (سهلة جداً - لا تستخدمها أبداً):**

1. "من الدخيل؟ الكل لعب للهلال: نيمار، ميتروفيتش، مالكوم، كريستيانو"
   → ممنوع! لاعبون مشهورون جداً!

2. "من الدخيل؟ الكل لعب لريال مدريد: بنزيما، مودريتش، كروس، فينيسيوس"
   → ممنوع! نادي كبير + لاعبون مشهورون!

3. "من الدخيل؟ الكل لعب لنابولي: أوسيمين، كفاراتسخيليا، ليو، زيلينسكي"
   → ممنوع! لاعبون معروفون!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
**✅✅✅ أمثلة صحيحة (صعبة حقاً - استخدم هذا النمط):**

1. "من الدخيل؟ الكل لعب لواتفورد: إسماعيل سار، تروي ديني، كين سيما، ويل هيوز"
   → صحيح! نادي صغير + لاعبون غير معروفين + فترات قصيرة!

2. "من الدخيل؟ الكل لعب لخيتافي: خايمي ماتا، بورخا مايورال، إينيس أونال، خوردي ألبا"
   → صحيح! نادي إسباني صغير + لاعبون غير مشهورين!

3. "في أي نادي لعب ويليام كارفاليو وأدريان سيلفا معاً؟"
   الخيارات: ["سبورتينج لشبونة", "بيتيس", "لاتسيو", "ليستر"]
   → صحيح! نوادي متوسطة + لاعبون برتغاليون أقل شهرة!

4. "من الدخيل؟ الكل لعب لفيورنتينا: نيكولا غونزاليس، دوسان فلاهوفيتش، لوكا جوفيتش، سوفيان أمرابط"
   → صحيح! نادي إيطالي متوسط + لاعبون من الدرجة الثانية!

5. "في أي نادي لعب موسى ديمبيلي وأليكسيس سانشيز معاً؟"
   الخيارات: ["أولمبيك ليون", "توتنهام", "مارسيليا", "إنتر"]
   → صحيح! فترات قصيرة + معلومات تاريخية دقيقة!

**⏰ الفترة الزمنية:**
✅ ركز على فترات الانتقالات القصيرة (موسم واحد أو إعارة)
✅ 2012-2024 (معلومات تاريخية دقيقة)

**🎯 استراتيجيات لجعل السؤال صعب:**
1. استخدم لاعبين لعبوا للنادي لموسم واحد فقط
2. استخدم أندية من الدرجة الثانية
3. استخدم لاعبين انتقلوا كثيراً بين أندية صغيرة
4. استخدم معلومات عن إعارات قصيرة
5. اختر لاعبين من نفس الدولة لكن أندية مختلفة
6. استخدم لاعبين من نفس المركز لكن شهرة قليلة

**❌❌❌ ممنوع (تحذير نهائي):**
❌ أي لاعب مشهور عالمياً أو معروف
❌ أندية الخمس الكبار الرئيسية
❌ معلومات واضحة وسهلة يعرفها الجميع
❌ لاعبون من الدوري السعودي المشهورين (نيمار، كريستيانو، بنزيما)
❌ أندية كبيرة: ريال مدريد، برشلونة، بايرن، ليفربول، مانشستر سيتي

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔥 **تذكير أخير:**
🔥 إذا استخدمت أي لاعب من القائمة الممنوعة = فشل السؤال
🔥 استخدم فقط لاعبين غير معروفين من أندية صغيرة
🔥 الهدف: أسئلة صعبة جداً لا يعرف إجابتها إلا الخبراء!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        default:
          return '';
      }
    } else if (language == 'tr') {
      switch (difficulty) {
        case 'easy':
          return '''
**🟢 KOLAY - Çok Ünlü Oyuncular:**
⚠️ Sadece aktif oyuncular! Emekli oyuncular YASAK!
- Çok ünlü: Ronaldo, Messi, Salah, Mbappé, Haaland
- Büyük kulüpler: Barcelona, Real Madrid, Man City
- 2024-2025 aktif oyuncular
''';
        case 'medium':
          return '''
**🟡 ORTA - Daha Az Ünlü Oyuncular:**
⚠️ Sadece aktif oyuncular! Emekli oyuncular YASAK!
- Az ünlü: Grealish, Saka, Foden, Mahrez
- 2020-2025 aktif oyuncular
''';
        case 'hard':
          return '''
**🔴 ZOR - Dolaylı Sorular ve Kesin Bilgi:**
⚠️⚠️⚠️ YASAK - Çok ünlü oyuncular kullanma (kolay olur):
❌ Ronaldo, Messi, Neymar, Benzema, Salah, Mbappé, Haaland
❌ Lewandowski, Suárez, Agüero, Modrić, Kroos

✅ SADECE az bilinen oyuncular kullan:
• İkinci seviye oyuncular: Bebé, Weissam Ben Yedder, Aziz Behich, Danilo Pereira
• Küçük kulüpler: Bordeaux, Braga, Vitesse, Crystal Palace, Getafe
• Kısa dönemler (sadece 1 sezon veya kiralık)
• Tarihi detaylar - sadece uzmanların bildiği
''';
        default:
          return '';
      }
    } else {
      switch (difficulty) {
        case 'easy':
          return '''
**🟢 EASY - Very Famous Players:**
⚠️ Active players ONLY! NO retired players!
- Very famous: Ronaldo, Messi, Salah, Mbappé, Haaland, De Bruyne
- Big clubs: Barcelona, Real Madrid, Man City, Liverpool
- Active players (2024-2025)
- ❌ NO retired players (Zidane, Ronaldinho, Pirlo, etc.)
''';
        case 'medium':
          return '''
**🟡 MEDIUM - Less Famous Players:**
⚠️ Active players ONLY! NO retired players!
- Less famous: Grealish, Saka, Rodrygo, Foden, Mahrez
- Medium clubs or less stardom
- Active players (2020-2025)
- ❌ NO retired players
''';
        case 'hard':
          return '''
**🔴 HARD - Indirect Questions & Precise Information:**
⚠️⚠️⚠️ FORBIDDEN - Don't use very famous players (too easy):
❌ Ronaldo, Messi, Neymar, Benzema, Salah, Mbappé, Haaland
❌ Lewandowski, Suárez, Agüero, Modrić, Kroos, Bellingham

✅ ONLY use lesser-known players:
• Second-tier players: Bebé, Weissam Ben Yedder, Danilo Pereira, Kim Min-jae
• Small clubs: Bordeaux, Braga, Vitesse, Crystal Palace, Getafe, Elche
• Short periods (only 1 season or loan)
• Historical details - only experts know

**Strategies to make it HARD:**
1. Players who played for the club for ONLY 1 season
2. Second and third-tier clubs
3. Players who moved between small clubs frequently
4. Information about short-term loans
5. Players from the same country but different clubs

**❌ FORBIDDEN:**
❌ Any world-famous player
❌ Top 5 leagues' main clubs
❌ Obvious and easy information
''';
        default:
          return '';
      }
    }
  }

  String _buildMultipleChoicePrompt(int count, String difficulty, String category, String language) {
    final langText = language == 'ar' ? 'بالعربية' : language == 'tr' ? 'بالتركية' : 'بالإنجليزية';
    
    // تحديد معايير الصعوبة بناءً على المستوى المختار
    print('🎯 Applying difficulty level: $difficulty');
    String difficultyGuidelines = _getDifficultyGuidelines(difficulty, language);
    
    // عرض نوع اللاعبين حسب المستوى
    final difficultyInfo = difficulty == 'easy' 
        ? '🟢 نجوم عالميون (2020-2025)'
        : difficulty == 'medium'
            ? '🔵 لاعبون جيدون (2015-2025)'
            : '🔴 لاعبون غير معروفين من أندية صغيرة (2012-2024)';
    print('📊 Difficulty criteria: $difficultyInfo');
    
    if (difficulty == 'hard') {
      print('🔥 HARD MODE ACTIVATED:');
      print('   ❌ NO famous players (Ronaldo, Messi, Neymar, etc.)');
      print('   ❌ NO big clubs (Real Madrid, Barcelona, etc.)');
      print('   ✅ ONLY small clubs & unknown players');
    }
    
    // إضافة seed للتنويع
    final promptSeed = DateTime.now().millisecondsSinceEpoch;
    final randomHint = promptSeed % 100;
    
    // بناء قائمة بالأسئلة المستخدمة لتجنب التكرار
    String usedQuestionsWarning = '';
    if (_usedQuestions.isNotEmpty) {
      final usedList = _usedQuestions.take(20).join(', '); // أخذ أول 20 سؤال
      usedQuestionsWarning = language == 'ar'
          ? '\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n⛔⛔⛔ **ممنوع منعاً باتاً تكرار هذه الأسئلة:**\n${_usedQuestions.length} أسئلة مستخدمة\nآخر 20: $usedList...\n\n🔥 **يجب عليك:**\n1. استخدام لاعبين مختلفين تماماً\n2. استخدام أندية مختلفة تماماً\n3. صياغة السؤال بطريقة مختلفة\n4. لا تكرر أي سؤال أبداً!\n\n💡 Variation Seed: $randomHint\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          : language == 'tr'
              ? '\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n⛔⛔⛔ **Bu soruları ASLA TEKRARLAMAYIN:**\n${_usedQuestions.length} kullanılmış soru\nSon 20: $usedList...\n\n🔥 **Yapmanız gerekenler:**\n1. Tamamen farklı oyuncular kullanın\n2. Tamamen farklı kulüpler kullanın\n3. Soruyu farklı şekilde yazın\n4. Hiçbir soruyu tekrarlamayın!\n\n💡 Varyasyon: $randomHint\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              : '\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n⛔⛔⛔ **NEVER REPEAT these questions:**\n${_usedQuestions.length} used questions\nLast 20: $usedList...\n\n🔥 **You MUST:**\n1. Use completely different players\n2. Use completely different clubs\n3. Phrase the question differently\n4. Never repeat any question!\n\n💡 Variation Seed: $randomHint\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    } else {
      // إضافة تنويع حتى في الطلب الأول
      usedQuestionsWarning = language == 'ar'
          ? '\n\n💡 **تنويع السؤال:** استخدم مزيجاً متنوعاً من اللاعبين والأندية. Seed: $randomHint\n'
          : language == 'tr'
              ? '\n\n💡 **Varyasyon:** Oyuncular ve kulüplerin çeşitli bir karışımını kullanın. Seed: $randomHint\n'
              : '\n\n💡 **Variation:** Use a diverse mix of players and clubs. Seed: $randomHint\n';
    }
    
    String categoryPrompt = '';
    switch (category) {
      case 'common_club':
        if (language == 'ar') {
          categoryPrompt = '''
أنشئ $count أسئلة كروية عن النادي المشترك بين اللاعبين.

**صيغة السؤال - مهم جداً:**
"في أي نادي لعب [اسم اللاعب 1]، [اسم اللاعب 2]، [اسم اللاعب 3]، و[اسم اللاعب 4] معاً؟"

⚠️ **يجب ذكر أسماء اللاعبين كاملة في السؤال نفسه!**

**قواعد مهمة جداً:**
- اذكر أسماء اللاعبين بالكامل في نص السؤال
- اختر لاعبين لعبوا معاً لفترة قصيرة (موسم أو موسمين فقط) وليس لفترة طويلة
- لا تختر لاعبين مشهورين جداً لعبوا معاً لسنوات طويلة (مثل ميسي وإنييستا)
- اختر لاعبين من فترات مختلفة في النادي أو لاعبين انتقلوا بسرعة

$difficultyGuidelines

- اعطِ 4 أندية كخيارات
- واحد منها هو النادي الصحيح
''';
        } else if (language == 'tr') {
          categoryPrompt = '''
Oyuncular arasındaki ortak kulüp hakkında $count futbol sorusu oluştur.

**Soru formatı - çok önemli:**
"[Oyuncu 1 adı], [Oyuncu 2 adı], [Oyuncu 3 adı] ve [Oyuncu 4 adı] hangi kulüpte birlikte oynadılar?"

⚠️ **Oyuncu isimlerinin TAM olarak sorunun içinde belirtilmesi gerekir!**

**Çok önemli kurallar:**
- Oyuncu isimlerini sorunun metninde tam olarak belirtin
- Kısa bir süre (sadece bir veya iki sezon) birlikte oynayan oyuncuları seç, uzun süre değil
- Uzun yıllar birlikte oynayan çok ünlü oyuncuları seçme (Messi ve Iniesta gibi)
- Kulüpteki farklı dönemlerden oyuncuları veya hızlı transfer olan oyuncuları seç

**Zorluk seviyesine göre oyuncu sayısı:**
- Kolay: 4 oyuncu (tanınmış ama kısa süre birlikte oynadılar)
- Orta: 3 oyuncu (daha az ünlü oyuncular)
- Zor: Sadece 2 oyuncu (nadir oyuncular veya sadece bir sezon birlikte oynadılar)

- 4 kulüp seçeneği ver
- Bunlardan biri doğru kulüp
''';
        } else {
          categoryPrompt = '''
Create $count football questions about the common club between players.

**Question format - VERY IMPORTANT:**
"In which club did [Player 1 name], [Player 2 name], [Player 3 name], and [Player 4 name] play together?"

⚠️ **You MUST include the FULL player names IN the question text itself!**

**Very important rules:**
- ALWAYS mention the player names explicitly in the question text
- Choose players who played together for a short period (only one or two seasons), not a long time
- Don't choose very famous players who played together for many years (like Messi and Iniesta)
- Choose players from different periods at the club or players who transferred quickly

**Number of players by difficulty:**
- Easy: 4 players (known players but played together for a short time)
- Medium: 3 players (less famous players)
- Hard: Only 2 players (rare players or played together for only one season)

- Give 4 club options
- One of them is the correct club
''';
        }
        break;
      
      case 'wrong_player':
        if (language == 'ar') {
          categoryPrompt = '''
⚠️⚠️⚠️ **مهمة حرجة - عدم التسامح مع الأخطاء** ⚠️⚠️⚠️

أنشئ $count أسئلة عن "من الدخيل" بدقة **100%**.

${difficulty == 'hard' ? '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔥🔥🔥 **تحذير خاص للمستوى الصعب** 🔥🔥🔥
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⛔ **ممنوع استخدام هؤلاء اللاعبين (مشهورون جداً):**
❌ كريستيانو، ميسي، نيمار، بنزيما، صلاح، مبابي، هالاند
❌ مودريتش، كروس، بيلينجهام، فينيسيوس، دي بروين، رودري
❌ ليفاندوفسكي، سواريز، أغويرو، كين، لوكاكو
❌ فان دايك، رودريجر، دياس، أوسيمين، كفاراتسخيليا، ليو

⛔ **ممنوع استخدام هذه الأندية (كبيرة جداً):**
❌ ريال مدريد، برشلونة، بايرن ميونخ، مانشستر سيتي، ليفربول
❌ باريس سان جيرمان، مانشستر يونايتد، تشيلسي، أرسنال
❌ يوفنتوس، ميلان، إنتر، نابولي، الهلال، النصر

✅ **استخدم فقط:**
• أندية صغيرة: واتفورد، خيتافي، كالياري، فيتيسه، كريستال بالاس
• لاعبون غير معروفين من الدرجة الثانية
• فترات قصيرة (موسم واحد أو إعارة)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''' : ''}

🔴 **مسؤوليتك:**
- إذا أنشأت سؤالاً خاطئاً، سيحصل التطبيق على تقييمات سيئة وسيفشل!
- يجب أن تكون متأكداً 200% من كل لاعب
- إذا كان لديك حتى 0.001% شك، لا تستخدم ذلك اللاعب!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 **عملية التحقق الإلزامية:**

**الخطوة 1 - اختر نادٍ:**
${difficulty == 'hard' ? 'استخدم فقط أندية متوسطة وصغيرة:\n- واتفورد، كريستال بالاس، فولهام، برايتون\n- خيتافي، إلتشي، سيلتا فيغو، إسبانيول\n- كالياري، جنوى، سامبدوريا، أودينيزي\n- رين، نيس، نانت، بوردو' : 'استخدم فقط الأندية التي تعرفها بشكل ممتاز:\n- برشلونة، ريال مدريد، مانشستر يونايتد، ليفربول، تشيلسي، أرسنال\n- بايرن ميونخ، بوروسيا دورتموند، يوفنتوس، ميلان، إنتر\n- باريس سان جيرمان، مانشستر سيتي'}

**الخطوة 2 - اختر 3 لاعبين لعبوا هناك بالتأكيد:**
لكل لاعب، اسأل نفسك 3 مرات:
1️⃣ "هل لعب [اللاعب] لـ [النادي]؟" → نعم/لا/غير متأكد
2️⃣ "ما السنوات؟" → إذا لم تستطع الإجابة → تخطى!
3️⃣ "هل أنا متأكد 100%؟" → إذا لا → تخطى!

**الخطوة 3 - اختر لاعباً واحداً لم يلعب هناك أبداً:**
1️⃣ "هل لعب [اللاعب] لـ [النادي] أبداً؟" → أبداً/ربما/غير متأكد
2️⃣ إذا ربما أو غير متأكد → تخطى فوراً!
3️⃣ "هل سأراهن بحياتي؟" → إذا لا → تخطى!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 **قوائم التحقق:**

**بوروسيا دورتموند:**
✅ لعبوا: ليفاندوفسكي (2010-2014), هالاند (2020-2022), سانشو (2017-2021), بيلينجهام (2020-2023)
❌ لم يلعبوا أبداً: مبابي، فينيسيوس، صلاح، كين

**برشلونة:**
✅ لعبوا: ميسي (2004-2021), إنييستا (2002-2018), تشافي (1998-2015), نيمار (2013-2017)
❌ لم يلعبوا أبداً: كريستيانو رونالدو، بنزيما، مودريتش

**ريال مدريد:**
✅ لعبوا: رونالدو (2009-2018), بنزيما (2009-2023), مودريتش (2012-), راموس (2005-2021)
❌ لم يلعبوا أبداً: ميسي، إنييستا، تشافي، نيمار

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${difficulty == 'hard' ? '''
🔥 **أمثلة خاصة للمستوى الصعب:**

❌❌❌ **أمثلة ممنوعة (سهلة جداً):**
1. "من الدخيل؟ الكل لعب للهلال: نيمار، ميتروفيتش، مالكوم، كريستيانو"
   → ممنوع! لاعبون مشهورون + نادي كبير!

2. "من الدخيل؟ الكل لعب لدورتموند: هالاند، بيلينجهام، سانشو، مبابي"
   → ممنوع! لاعبون مشهورون جداً!

3. "من الدخيل؟ الكل لعب لنابولي: أوسيمين، كفاراتسخيليا، ليو، زيلينسكي"
   → ممنوع! لاعبون معروفون!

✅✅✅ **أمثلة صحيحة (صعبة حقاً):**
1. "من الدخيل؟ الكل لعب لواتفورد: إسماعيل سار، تروي ديني، كين سيما، جيرارد ديلوفيو"
   → صحيح! نادي صغير + لاعبون غير معروفين!

2. "من الدخيل؟ الكل لعب لخيتافي: خايمي ماتا، بورخا مايورال، إينيس أونال، أنخل رودريغيز"
   → صحيح! نادي إسباني صغير + لاعبون من الدرجة الثانية!

3. "من الدخيل؟ الكل لعب لكالياري: جواو بيدرو، ناندو رافاييل، لوكا سيجاريني، رادخا ناينغولان"
   → صحيح! نادي إيطالي صغير + فترات قصيرة!
''' : '''
✅ **مثال مثالي:**
"من الدخيل؟ الكل لعب لدورتموند ما عدا: هالاند، بيلينجهام، سانشو، مبابي"
→ هالاند ✅ (2020-2022)
→ بيلينجهام ✅ (2020-2023)
→ سانشو ✅ (2017-2021)
→ مبابي ✅ (أبداً - كان في موناكو/باريس/ريال)
→ صحيح! ✅

❌ **مثال خاطئ - لا تفعل هذا:**
"من الدخيل؟ الكل لعب لدورتموند: بيلينجهام، سانشو، هالاند، ليفاندوفسكي"
→ خطأ! ليفاندوفسكي لعب لدورتموند (2010-2014)!
→ هذا سيدمر التطبيق! ❌
'''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$difficultyGuidelines

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 **التحقق النهائي:**
1️⃣ اقرأ السؤال مرة أخرى
2️⃣ تحقق من كل لاعب من الأربعة مرة أخرى
3️⃣ اسأل: "إذا كان خاطئاً، هل سأشعر بالحرج؟" → إذا نعم، غيّره!

⚠️ تذكر: سؤال خاطئ واحد = فشل التطبيق!
''';
        } else if (language == 'tr') {
          categoryPrompt = '''
"Yabancı kim?" - Kulüpte oynamayan oyuncuyu bulma hakkında $count futbol sorusu oluştur.

**Soru formatı - çok önemli:**
"Bu oyunculardan hangisi [Takım adı] için oynamadı?"
veya "Yabancı kim? Hepsi [Takım adı] için oynadı, biri hariç"

⚠️ **Takım adının TAM olarak sorunun içinde belirtilmesi gerekir!**

**CRITICAL kurallar - çok dikkatli kontrol edin:**
1. Tanınmış bir kulüp seçin (örneğin: Barcelona, Real Madrid, Liverpool, Manchester United, Bayern Munich, Juventus, Milan, Inter, PSG, Chelsea, Arsenal)
2. 4 ünlü oyuncu seçeneği verin (tam isimlerle)
3. ✅ **CRITICAL**: 3 oyuncunun bu belirli kulüpte gerçekten ve resmi olarak oynadığından emin olun
4. ✅ **CRITICAL**: 4. oyuncunun (doğru cevap) bu kulüpte hiç oynamadığından emin olun
5. ❌ Tahmin etmeyin - %100 emin değilseniz, bu oyuncuyu kullanmayın
6. Soruyu daha zor yapmak için aynı dönemden veya ligden oyuncular kullanın

**Doğru soru örnekleri:**
✅ "Yabancı kim? Hepsi Barcelona için oynadı, biri hariç: Messi, Iniesta, Xavi, Cristiano Ronaldo" (Cevap: Ronaldo)
✅ "Bunlardan hangisi Real Madrid için oynamadı? Benzema, Ramos, Modric, Messi" (Cevap: Messi)

$difficultyGuidelines
''';
        } else {
          categoryPrompt = '''
⚠️⚠️⚠️ **CRITICAL MISSION - ZERO TOLERANCE FOR ERRORS** ⚠️⚠️⚠️

Create $count football questions about "Who's the Outsider" with **100% ACCURACY**.

🔴 **YOUR RESPONSIBILITY:**
- If you create a WRONG question, the app will get BAD REVIEWS and FAIL!
- You MUST be 200% CERTAIN about EVERY player
- If you have even 0.001% doubt, DON'T use that player!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 **MANDATORY VERIFICATION PROCESS:**

**STEP 1 - Choose a club:**
Only use clubs you KNOW EXTREMELY WELL. Safe choices:
- Barcelona, Real Madrid, Manchester United, Liverpool, Chelsea, Arsenal
- Bayern Munich, Borussia Dortmund, Juventus, AC Milan, Inter Milan
- PSG, Manchester City

**STEP 2 - Select 3 players who DEFINITELY played there:**
For EACH player, ask yourself 3 times:
1️⃣ "Did [Player] play for [Club]?" → YES/NO/UNSURE
2️⃣ "What years did [Player] play for [Club]?" → If you can't answer → SKIP!
3️⃣ "Am I 100% CERTAIN?" → If NO → SKIP!

**STEP 3 - Select 1 player who NEVER played there:**
Ask yourself:
1️⃣ "Did [Player] EVER play for [Club]?" → NEVER/MAYBE/UNSURE
2️⃣ If answer is MAYBE or UNSURE → SKIP IMMEDIATELY!
3️⃣ "Would I bet my life this player NEVER played there?" → If NO → SKIP!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 **CLUB-SPECIFIC VERIFICATION LISTS:**

**Borussia Dortmund (VERIFIED players):**
✅ PLAYED THERE: Lewandowski (2010-2014), Haaland (2020-2022), Sancho (2017-2021), 
   Bellingham (2020-2023), Reus (2012-present), Aubameyang (2013-2018), 
   Götze (2009-2013, 2016-2020), Hummels (2008-2016, 2019-present)
❌ NEVER PLAYED: Mbappé, Vinicius, Salah, Kane, De Bruyne, Grealish

**Barcelona (VERIFIED players):**
✅ PLAYED THERE: Messi (2004-2021), Iniesta (2002-2018), Xavi (1998-2015), 
   Neymar (2013-2017), Suarez (2014-2020), Lewandowski (2022-present)
❌ NEVER PLAYED: Ronaldo (CR7), Benzema, Modric, Ramos

**Real Madrid (VERIFIED players):**
✅ PLAYED THERE: Ronaldo (2009-2018), Benzema (2009-2023), Modric (2012-present),
   Ramos (2005-2021), Kroos (2014-present), Bale (2013-2022)
❌ NEVER PLAYED: Messi, Iniesta, Xavi, Neymar (went from Barca to PSG)

**Manchester United (VERIFIED players):**
✅ PLAYED THERE: Ronaldo (2003-2009, 2021-2022), Rooney (2004-2017), 
   De Gea (2011-2023), Bruno Fernandes (2020-present), Rashford (2016-present)
❌ NEVER PLAYED: Salah (never played for United), Gerrard, De Bruyne

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **PERFECT Examples:**

✅ "Who's the outsider? All played for Borussia Dortmund except: Haaland, Bellingham, Sancho, Mbappé"
   → VERIFICATION:
   - Haaland: 2020-2022 ✅
   - Bellingham: 2020-2023 ✅
   - Sancho: 2017-2021 ✅
   - Mbappé: NEVER (was at Monaco/PSG/Real Madrid) ✅
   → CORRECT! ✅

✅ "Which didn't play for Barcelona? Messi, Xavi, Iniesta, Cristiano Ronaldo"
   → VERIFICATION:
   - Messi: 2004-2021 ✅
   - Xavi: 1998-2015 ✅
   - Iniesta: 2002-2018 ✅
   - Ronaldo: NEVER (was at United/Madrid/Juve) ✅
   → CORRECT! ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ **WRONG Examples - NEVER DO THIS:**

❌ "Who's the outsider? All played for Dortmund except: Bellingham, Sancho, Haaland, Lewandowski"
   → WRONG! Lewandowski DID play for Dortmund (2010-2014)!
   → This would RUIN the app!

❌ "Which didn't play for Barcelona? Messi, Iniesta, Neymar, Ronaldo"
   → WRONG! Neymar DID play for Barcelona (2013-2017)!
   → This is a CATASTROPHIC error!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$difficultyGuidelines

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 **FINAL 3-STEP VERIFICATION:**

Before submitting ANY question:
1️⃣ Read the question again
2️⃣ Verify EACH of the 4 players ONE MORE TIME
3️⃣ Ask: "If this question is wrong, would I be embarrassed?" → If YES, CHANGE IT!

🎯 **SUCCESS CRITERIA:**
- 100% accurate information
- ZERO mistakes
- ONLY use players you're ABSOLUTELY certain about

⚠️ Remember: ONE wrong question = App failure!
''';
        }
        break;
      
      case 'quiz':
        if (language == 'ar') {
          categoryPrompt = '''
أنشئ $count أسئلة كروية عامة ومتنوعة.
مواضيع: تاريخ، إحصائيات، بطولات، أرقام قياسية، لاعبين، مدربين، أندية.

$difficultyGuidelines

- كل سؤال له 4 خيارات
- خيار واحد صحيح فقط
''';
        } else if (language == 'tr') {
          categoryPrompt = '''
Genel ve çeşitli $count futbol sorusu oluştur.
Konular: tarih, istatistikler, turnuvalar, rekorlar, oyuncular, teknik direktörler, kulüpler.

$difficultyGuidelines

- Her sorunun 4 seçeneği var
- Sadece bir doğru seçenek
''';
        } else {
          categoryPrompt = '''
Create $count general and varied football questions.
Topics: history, statistics, tournaments, records, players, coaches, clubs.

$difficultyGuidelines

- Each question has 4 options
- Only one correct option
''';
        }
        break;
      
      case 'jersey_number':
        if (language == 'ar') {
          categoryPrompt = '''
أنشئ $count أسئلة عن أرقام القمصان في كرة القدم فقط.

**صيغة السؤال - مهم جداً:**
السؤال يجب أن يكون فقط الرقم (مثل: "7" أو "10" أو "9")
لا تكتب أي نص آخر في السؤال، فقط الرقم!

**المجال:**
- كرة القدم فقط (football/soccer)
- لاعبو كرة القدم فقط
- أرقام القمصان في كرة القدم فقط

**قواعد التحقق الصارمة - مهم جداً:**
1. الإجابة الصحيحة: لاعب كرة قدم لم يحمل هذا الرقم أبداً في مسيرته
2. الخيارات الخاطئة الثلاثة: لاعبو كرة قدم حملوا هذا الرقم بالفعل
3. تحقق 100% من أن كل لاعب في الخيارات الخاطئة حمل الرقم المذكور
4. تحقق 100% من أن اللاعب في الإجابة الصحيحة لم يحمل هذا الرقم أبداً
5. استخدم فقط لاعبي كرة القدم المشهورين

**أرقام مقترحة:**
- أرقام مشهورة: 7، 9، 10، 11، 23، 8، 14، 21، 5، 6، 4، 3، 1

$difficultyGuidelines

**أمثلة صحيحة:**
- السؤال: "7" 
  الإجابة الصحيحة: "ليونيل ميسي" (لم يحمل الرقم 7 أبداً)
  الخيارات الخاطئة: ["كريستيانو رونالدو", "ديفيد بيكهام", "راؤول غونزاليس"] (كلهم حملوا الرقم 7)

- السؤال: "9"
  الإجابة الصحيحة: "محمد صلاح" (لم يحمل الرقم 9 أبداً)
  الخيارات الخاطئة: ["كريم بنزيما", "روبرت ليفاندوفسكي", "إيرلينج هالاند"] (كلهم حملوا الرقم 9)

**مهم جداً للتحقق:**
- السؤال (questionText) = الرقم فقط
- الإجابة الصحيحة = لاعب كرة قدم لم يحمل هذا الرقم أبداً في مسيرته
- الخيارات الخاطئة (3 لاعبين) = لاعبو كرة قدم حملوا هذا الرقم بالفعل
- تأكد من الدقة 100% - راجع تاريخ كل لاعب
''';
        } else if (language == 'tr') {
          categoryPrompt = '''
Sadece futbol forma numaraları hakkında $count soru oluştur.

**Soru formatı - çok önemli:**
Soru sadece numara olmalı (örneğin: "7" veya "10" veya "9")
Soruda başka metin yazma, sadece numara!

**Alan:**
- Sadece futbol (football/soccer)
- Sadece futbol oyuncuları
- Sadece futbol forma numaraları

**Katı doğrulama kuralları - çok önemli:**
1. Doğru cevap: Bu numarayı kariyerinde hiç takmamış bir futbol oyuncusu
2. Yanlış üç seçenek: Bu numarayı gerçekten takmış futbol oyuncuları
3. Yanlış seçeneklerdeki her oyuncunun bu numarayı taşıdığından %100 emin ol
4. Doğru cevaptaki oyuncunun bu numarayı hiç taşımadığından %100 emin ol
5. Sadece ünlü futbol oyuncularını kullan

**Önerilen numaralar:**
- Ünlü numaralar: 7, 9, 10, 11, 23, 8, 14, 21, 5, 6, 4, 3, 1

$difficultyGuidelines

**Doğru örnekler:**
- Soru: "7" 
  Doğru cevap: "Lionel Messi" (7 numarayı hiç takmadı)
  Yanlış seçenekler: ["Cristiano Ronaldo", "David Beckham", "Raul Gonzalez"] (hepsi 7 numarayı taşıdı)

- Soru: "9"
  Doğru cevap: "Mohamed Salah" (9 numarayı hiç takmadı)
  Yanlış seçenekler: ["Karim Benzema", "Robert Lewandowski", "Erling Haaland"] (hepsi 9 numarayı taşıdı)

**Doğrulama için çok önemli:**
- Soru (questionText) = Sadece numara
- Doğru cevap = Kariyerinde bu numarayı hiç takmamış futbol oyuncusu
- Yanlış seçenekler (3 oyuncu) = Bu numarayı gerçekten takmış futbol oyuncuları
- %100 doğruluk - her oyuncunun geçmişini kontrol et
''';
        } else {
          categoryPrompt = '''
Create $count questions about football jersey numbers only.

**Question format - VERY IMPORTANT:**
The question must be ONLY the number (like: "7" or "10" or "9")
Do NOT write any other text in the question, ONLY the number!

**Domain:**
- Football/soccer only
- Football players only
- Football jersey numbers only

**Strict verification rules - VERY IMPORTANT:**
1. Correct answer: A football player who NEVER wore this number in their career
2. Three wrong options: Football players who DID wear this number
3. Verify 100% that each player in wrong options wore this number
4. Verify 100% that the player in correct answer NEVER wore this number
5. Use only famous football players

**Suggested numbers:**
- Famous numbers: 7, 9, 10, 11, 23, 8, 14, 21, 5, 6, 4, 3, 1

$difficultyGuidelines

**Correct examples:**
- Question: "7" 
  Correct answer: "Lionel Messi" (never wore number 7)
  Wrong options: ["Cristiano Ronaldo", "David Beckham", "Raul Gonzalez"] (all wore number 7)

- Question: "9"
  Correct answer: "Mohamed Salah" (never wore number 9)
  Wrong options: ["Karim Benzema", "Robert Lewandowski", "Erling Haaland"] (all wore number 9)

**VERY IMPORTANT for verification:**
- Question (questionText) = Number only
- Correct answer = Football player who NEVER wore this number in their career
- Wrong options (3 players) = Football players who DID wear this number
- 100% accuracy - check each player's history
''';
        }
        break;
    }

    // تعليمة واضحة في البداية
    String languageInstruction = language == 'ar' 
        ? '⚠️ مهم: اكتب جميع النصوص بالعربية فقط (الأسئلة، الخيارات، أسماء اللاعبين، أسماء الأندية).'
        : language == 'tr'
            ? '⚠️ Önemli: Tüm metinleri sadece Türkçe yazın (sorular, seçenekler, oyuncu isimleri, kulüp isimleri).'
            : '⚠️ Important: Write ALL texts in ENGLISH ONLY (questions, options, player names, club names).';
    
    // إضافة seed للتنويع
    final random = Random();
    final variationSeed = random.nextInt(1000000);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // تعليمات مخصصة حسب مستوى الصعوبة
    String variationInstruction = '';
    
    if (difficulty == 'hard') {
      variationInstruction = language == 'ar'
          ? '''🎲 تحذير خاص للمستوى الصعب:

⛔⛔⛔ **ممنوع استخدام هؤلاء (مشهورون جداً):**
❌ هالاند، مبابي، صلاح، بيلينجهام، فينيسيوس، دي بروين، رودري
❌ نيمار، كريستيانو، بنزيما، مودريتش، ليفاندوفسكي، سواريز

✅ **يجب استخدام فقط:**
• لاعبون غير معروفين من أندية صغيرة
• أندية من الدرجة الثانية: بوردو، براغا، جنوى، فيتيسه، كريستال بالاس
• فترات قصيرة جداً (موسم واحد أو إعارة)
• معلومات تاريخية دقيقة لا يعرفها إلا الخبراء

رقم التنويع: $variationSeed-$timestamp'''
          : language == 'tr'
              ? '''🎲 Zor seviye için özel uyarı:

⛔⛔⛔ **YASAK - çok ünlüler (kolay olur):**
❌ Haaland, Mbappé, Salah, Bellingham, Vinicius, De Bruyne, Rodri
❌ Neymar, Cristiano, Benzema, Modrić, Lewandowski, Suárez

✅ **Sadece kullan:**
• Az bilinen oyuncular - küçük kulüplerden
• İkinci seviye kulüpler: Bordeaux, Braga, Genoa, Vitesse, Crystal Palace
• Çok kısa dönemler (1 sezon veya kiralık)
• Tarihi detaylar - sadece uzmanlar bilir

Varyasyon: $variationSeed-$timestamp'''
              : '''🎲 Special warning for HARD level:

⛔⛔⛔ **FORBIDDEN - too famous (makes it easy):**
❌ Haaland, Mbappé, Salah, Bellingham, Vinicius, De Bruyne, Rodri
❌ Neymar, Cristiano, Benzema, Modrić, Lewandowski, Suárez

✅ **ONLY use:**
• Lesser-known players from small clubs
• Second-tier clubs: Bordeaux, Braga, Genoa, Vitesse, Crystal Palace
• Very short periods (1 season or loan)
• Historical details - only experts know

Variation: $variationSeed-$timestamp''';
    } else {
      variationInstruction = language == 'ar'
          ? '''🎲 مهم - تنوع كبير جداً مطلوب: 
- أنشئ أسئلة جديدة ومختلفة تماماً عن أي أسئلة سابقة
- 🌍 **تنوع جغرافي**: استخدم أندية من دوريات مختلفة
- ✅ تأكد من صحة كل معلومة قبل إضافتها
- رقم التنويع: $variationSeed-$timestamp'''
          : language == 'tr'
              ? '''🎲 Önemli - çok fazla çeşitlilik gerekli:
- Önceki sorulardan tamamen farklı yeni sorular oluşturun
- 🌍 **Coğrafi çeşitlilik**: Farklı liglerden kulüpler kullanın
- ✅ Her bilgiyi eklemeden önce doğruluğunu onaylayın
- Varyasyon numarası: $variationSeed-$timestamp'''
              : '''🎲 Important - EXTREME variety required:
- Create completely NEW and DIFFERENT questions from any previous ones
- 🌍 **Geographic diversity**: Use clubs from different leagues
- ✅ VERIFY each piece of information before adding it
- Variation seed: $variationSeed-$timestamp''';
    }

    // تعليمة واضحة للعدد المطلوب
    String countInstruction = language == 'ar'
        ? '📝 يجب إنشاء $count أسئلة بالضبط - لا أكثر ولا أقل!'
        : language == 'tr'
            ? '📝 Tam olarak $count soru oluşturulmalıdır - ne fazla ne eksik!'
            : '📝 You MUST create exactly $count questions - no more, no less!';

    return '''
$languageInstruction

$countInstruction

$usedQuestionsWarning

$variationInstruction

$categoryPrompt

${language == 'ar' ? 'اللغة:' : language == 'tr' ? 'Dil:' : 'Language:'} $langText

${language == 'ar' ? '**أمثلة على أسئلة متنوعة وجيدة (ركّز على الحديث!):**' : language == 'tr' ? '**Çeşitli ve iyi soru örnekleri (moderne odaklanın!):**' : '**Examples of diverse and good questions (focus on modern!):**'}
${language == 'ar' ? '''
✅ **الفترة الحديثة (2018-2025) - 70% من الأسئلة:**
- "من الدخيل؟ جميعهم لعبوا لمانشستر سيتي ما عدا واحد: هالاند، دي بروين، رودري، مبابي" (مبابي - باريس/ريال مدريد)
- "في أي نادي لعب بيلينجهام وفينيسيوس معاً؟" (ريال مدريد 2023-)
- "من لم يلعب لتشيلسي مؤخراً؟ حكيم زياش، كريستيان بوليسيتش، كاي هافرتز، خاليفيوري" (خاليفيوري - نابولي)

✅ **فترة الانتقال (2010-2017) - 20% من الأسئلة:**
- "في أي نادي لعب دي بروين وصلاح معاً؟" (تشيلسي 2013-2016)
- "من الدخيل؟ الكل لعب ليوفنتوس: بوغبا، بيرلو، دي ليخت، توتي" (توتي - روما)

✅ **الأساطير (1990-2009) - 10% من الأسئلة:**
- "في أي نادي لعب زلاتان وإيتو معاً؟" (إنتر ميلان 2009)
- "من لم يلعب لبوكا جونيورز؟ مارادونا، ريكيلمي، تيفيز، ميسي" (ميسي)
''' : language == 'tr' ? '''
✅ **Modern dönem (2018-2025) - %70 sorular:**
- "Yabancı kim? Hepsi Manchester City'de oynadı: Haaland, De Bruyne, Rodri, Mbappé" (Mbappé - PSG/Real Madrid)
- "Bellingham ve Vinicius hangi kulüpte birlikte oynadılar?" (Real Madrid 2023-)
- "Chelsea'de yakın zamanda oynamayan kim? Hakim Ziyech, Christian Pulisic, Kai Havertz, Kvaratskhelia" (Kvaratskhelia - Napoli)

✅ **Geçiş dönemi (2010-2017) - %20 sorular:**
- "De Bruyne ve Salah hangi kulüpte birlikte oynadı?" (Chelsea 2013-2016)
- "Yabancı kim? Hepsi Juventus'ta oynadı: Pogba, Pirlo, De Ligt, Totti" (Totti - Roma)

✅ **Efsaneler (1990-2009) - %10 sorular:**
- "Zlatan ve Eto'o hangi kulüpte oynadı?" (Inter Milan 2009)
- "Boca Juniors'ta oynamayan kim? Maradona, Riquelme, Tevez, Messi" (Messi)
''' : '''
✅ **Modern era (2018-2025) - 70% of questions:**
- "Who's the outsider? All played for Manchester City: Haaland, De Bruyne, Rodri, Mbappé" (Mbappé - PSG/Real Madrid)
- "In which club did Bellingham and Vinicius play together?" (Real Madrid 2023-)
- "Who didn't play for Chelsea recently? Hakim Ziyech, Christian Pulisic, Kai Havertz, Kvaratskhelia" (Kvaratskhelia - Napoli)

✅ **Transition period (2010-2017) - 20% of questions:**
- "In which club did De Bruyne and Salah play together?" (Chelsea 2013-2016)
- "Who's the outsider? All played for Juventus: Pogba, Pirlo, De Ligt, Totti" (Totti - Roma)

✅ **Legends (1990-2009) - 10% of questions:**
- "In which club did Zlatan and Eto'o play together?" (Inter Milan 2009)
- "Who didn't play for Boca Juniors? Maradona, Riquelme, Tevez, Messi" (Messi)
'''}

${language == 'ar' ? '**أمثلة على أسئلة يجب تجنبها (سهلة جداً):**' : language == 'tr' ? '**Kaçınılması gereken soru örnekleri (çok kolay):**' : '**Examples of questions to avoid (too easy):**'}
${language == 'ar' ? '''
- ❌ "في أي نادي لعب ميسي وإنييستا معاً؟" (برشلونة - لعبوا معاً لأكثر من 10 سنوات)
- ❌ "في أي نادي لعب رونالدو ورونالدينيو معاً؟" (معروف جداً)
''' : language == 'tr' ? '''
- ❌ "Messi ve Iniesta hangi kulüpte birlikte oynadı?" (Barcelona - 10 yıldan fazla birlikte oynadılar)
- ❌ "Ronaldo ve Ronaldinho hangi kulüpte birlikte oynadı?" (Çok ünlü)
''' : '''
- ❌ "In which club did Messi and Iniesta play together?" (Barcelona - played together for 10+ years)
- ❌ "In which club did Ronaldo and Ronaldinho play together?" (Too famous)
'''}

${language == 'ar' ? '**مهم جداً - يجب التحقق من الدقة:**' : language == 'tr' ? '**Çok önemli - Doğruluğu kontrol edin:**' : '**CRITICAL - Verify Accuracy:**'}
${category == 'wrong_player' && language == 'ar' ? '''
⚠️⚠️⚠️ **تحذير شديد للعبة "من الدخيل":**
1. تحقق 3 مرات من كل لاعب قبل وضعه في السؤال!
2. ✅ الثلاثة لاعبين يجب أن يكونوا لعبوا فعلاً للنادي المذكور
3. ✅ اللاعب الرابع (الإجابة الصحيحة) يجب ألا يكون لعب أبداً للنادي المذكور
4. ❌ إذا شككت ولو 1%، لا تستخدم هذا اللاعب!
5. استخدم فقط لاعبين مشهورين تعرف تاريخهم جيداً
''' : category == 'wrong_player' && language == 'tr' ? '''
⚠️⚠️⚠️ **"Yabancı Kim" oyunu için çok sıkı uyarı:**
1. Her oyuncuyu soruya koymadan önce 3 kez kontrol edin!
2. ✅ 3 oyuncu bahsedilen kulüpte gerçekten oynamış olmalı
3. ✅ 4. oyuncu (doğru cevap) bahsedilen kulüpte hiç oynamamış olmalı
4. ❌ %1 bile şüphe duyarsanız, o oyuncuyu kullanmayın!
5. Sadece tarihini iyi bildiğiniz ünlü oyuncuları kullanın
''' : category == 'wrong_player' && language == 'en' ? '''
⚠️⚠️⚠️ **EXTREME WARNING for "Who's the Outsider" game:**
1. Triple-check EVERY player before putting them in the question!
2. ✅ The 3 players MUST have actually played for the mentioned club
3. ✅ The 4th player (correct answer) MUST NEVER have played for the mentioned club
4. ❌ If you have even 1% doubt, DON'T use that player!
5. Only use famous players whose history you know well
''' : ''}

${language == 'ar' ? '''
1. جميع النصوص والأسماء والأندية يجب أن تكون بالعربية فقط
2. ✅ تحقق من صحة المعلومات 100% قبل إنشاء السؤال
3. ✅ ${category == 'common_club' ? 'تأكد أن اللاعبين المذكورين لعبوا فعلاً معاً في نفس النادي' : category == 'wrong_player' ? 'للاعبين الثلاثة: يجب أن يكونوا لعبوا للنادي. اللاعب الرابع: يجب ألا يكون لعب للنادي' : 'تأكد من صحة المعلومات'}
4. ✅ تأكد من صحة الإجابة - الإجابة الصحيحة يجب أن تكون دقيقة تماماً
5. ❌ لا تخمن أو تفترض - استخدم معلومات موثوقة فقط
6. 🌍 **تنوع جغرافي هائل**: استخدم أندية من كل القارات والدوريات (بريميرليج، لاليغا، سيريا آيه، بوندسليغا، ليغ 1، إيريديفيزي، الدوري البرتغالي، الدوري التركي، الدوري الأرجنتيني، البرازيلي)
7. ⏰ **تركيز زمني محدد - الأولوية للحديث**:
  • 70% من الأسئلة عن الفترة 2018-2025 (اللاعبون الحاليون والنشطون)
  • 20% من الأسئلة عن الفترة 2010-2017 (جيل الانتقال)
  • 10% من الأسئلة عن الفترة 1990-2009 (الأساطير فقط)
8. 🎯 **أنواع مختلفة من الأندية**: أندية كبيرة، متوسطة، تاريخية، صاعدة حديثاً
9. 👥 **التركيز على الجيل الحالي**: معظم الأسئلة عن لاعبين مثل هالاند، مبابي، فينيسيوس، بيلينجهام، ساكا، رودري، دي بروين، صلاح، كين، لوكاكو، كاسيميرو
10. ${category == 'common_club' ? 'اختر لاعبين لعبوا معاً لفترة قصيرة (موسم أو موسمين)' : 'استخدم لاعبين من نفس الحقبة أو الدوري'}
''' : language == 'tr' ? '''
1. Tüm metinler, isimler ve kulüpler sadece Türkçe olmalıdır
2. ✅ Soruyu oluşturmadan önce %100 bilgi doğruluğunu kontrol edin
3. ✅ ${category == 'common_club' ? 'Belirtilen oyuncuların gerçekten aynı kulüpte birlikte oynadığından emin olun' : category == 'wrong_player' ? '3 oyuncu için: Kulüpte oynamış olmalılar. 4. oyuncu için: Kulüpte oynamamış olmalı' : 'Bilgilerin doğruluğundan emin olun'}
4. ✅ Cevabın doğruluğunu onaylayın - doğru cevap tam olarak kesin olmalıdır
5. ❌ Tahmin etmeyin veya varsaymayın - sadece güvenilir bilgiler kullanın
6. 🌍 **Muazzam coğrafi çeşitlilik**: Tüm kıtalardan ve liglerden kulüpler kullanın (Premier League, La Liga, Serie A, Bundesliga, Ligue 1, Eredivisie, Primeira Liga, Süper Lig, Arjantin ligi, Brezilya ligi)
7. ⏰ **Belirli zaman odağı - Moderne öncelik**:
  • %70 sorular 2018-2025 dönemi hakkında (mevcut ve aktif oyuncular)
  • %20 sorular 2010-2017 dönemi hakkında (geçiş nesli)
  • %10 sorular 1990-2009 dönemi hakkında (sadece efsaneler)
8. 🎯 **Farklı kulüp türleri**: Büyük, orta, tarihi, yeni yükselen kulüpler
9. 👥 **Mevcut nesle odaklanın**: Çoğu soru şu oyuncular hakkında: Haaland, Mbappé, Vinicius, Bellingham, Saka, Rodri, De Bruyne, Salah, Kane, Lukaku, Casemiro
10. ${category == 'common_club' ? 'Kısa süre birlikte oynayan oyuncuları seçin (bir veya iki sezon)' : 'Aynı dönemden veya ligden oyuncular kullanın'}
''' : '''
1. ALL texts, names, and clubs must be in ENGLISH ONLY
2. ✅ VERIFY 100% information accuracy before creating the question
3. ✅ ${category == 'common_club' ? 'ENSURE the mentioned players actually played together at the same club' : category == 'wrong_player' ? 'For 3 players: They MUST have played for the club. For 4th player: They MUST NOT have played for the club' : 'Ensure information accuracy'}
4. ✅ CONFIRM the correct answer - the correct answer must be absolutely accurate
5. ❌ DO NOT guess or assume - use only reliable information
6. 🌍 **MASSIVE geographic diversity**: Use clubs from ALL continents and leagues (Premier League, La Liga, Serie A, Bundesliga, Ligue 1, Eredivisie, Primeira Liga, Süper Lig, Argentine league, Brazilian league)
7. ⏰ **Specific time focus - Priority to Modern**:
  • 70% of questions about 2018-2025 period (current and active players)
  • 20% of questions about 2010-2017 period (transition generation)
  • 10% of questions about 1990-2009 period (only legends)
8. 🎯 **Different club types**: Big clubs, medium clubs, historical clubs, newly rising clubs
9. 👥 **Focus on current generation**: Most questions about players like: Haaland, Mbappé, Vinicius, Bellingham, Saka, Rodri, De Bruyne, Salah, Kane, Lukaku, Casemiro
10. ${category == 'common_club' ? 'Choose players who played together for short period (one or two seasons)' : 'Use players from the same era or league'}
'''}

${language == 'ar' ? '**التنسيق (JSON فقط):**' : language == 'tr' ? '**Format (sadece JSON):**' : '**Format (JSON only):**'}
${category == 'wrong_player' && language == 'ar' ? '''
[
  {
    "question": "من الدخيل؟ جميعهم لعبوا لريال مدريد ما عدا واحد",
    "options": ["كريم بنزيما", "سيرخيو راموس", "لوكا مودريتش", "ليونيل ميسي"],
    "correct": "ليونيل ميسي"
  }
]

⚠️ لاحظ: ميسي لم يلعب أبداً لريال مدريد. الثلاثة الآخرون لعبوا لريال مدريد!
''' : category == 'common_club' && language == 'ar' ? '''
[
  {
    "question": "في أي نادي لعب زلاتان إبراهيموفيتش وصامويل إيتو معاً؟",
    "options": ["برشلونة", "ريال مدريد", "إنتر ميلان", "يوفنتوس"],
    "correct": "إنتر ميلان"
  }
]

⚠️ لاحظ: السؤال يحتوي على أسماء اللاعبين بالكامل!

⚠️ تحقق مرة أخرى من صحة كل سؤال قبل إرجاعه.
⚠️ يجب أن يحتوي الـ JSON على $count أسئلة بالضبط!
أرجع JSON فقط بدون نص إضافي.
''' : category == 'wrong_player' && language == 'tr' ? '''
[
  {
    "question": "Yabancı kim? Hepsi Real Madrid için oynadı, biri hariç",
    "options": ["Karim Benzema", "Sergio Ramos", "Luka Modrić", "Lionel Messi"],
    "correct": "Lionel Messi"
  }
]

⚠️ Dikkat: Messi Real Madrid için hiç oynamadı. Diğer 3'ü Real Madrid için oynadı!
''' : category == 'common_club' && language == 'tr' ? '''
[
  {
    "question": "Zlatan İbrahimović ve Samuel Eto'o hangi kulüpte birlikte oynadılar?",
    "options": ["Barcelona", "Real Madrid", "Inter Milan", "Juventus"],
    "correct": "Inter Milan"
  }
]

⚠️ Dikkat: Soru oyuncu isimlerinin tamamını içeriyor!

⚠️ Her soruyu döndürmeden önce doğruluğunu bir kez daha kontrol edin.
⚠️ JSON tam olarak $count soru içermelidir!
Sadece JSON döndür, ek metin yok.
''' : category == 'wrong_player' && language == 'en' ? '''
[
  {
    "question": "Who's the outsider? All played for Real Madrid except one",
    "options": ["Karim Benzema", "Sergio Ramos", "Luka Modrić", "Lionel Messi"],
    "correct": "Lionel Messi"
  }
]

⚠️ NOTICE: Messi NEVER played for Real Madrid. The other 3 DID play for Real Madrid!
''' : category == 'common_club' && language == 'en' ? '''
[
  {
    "question": "In which club did Zlatan Ibrahimović and Samuel Eto'o play together?",
    "options": ["Barcelona", "Real Madrid", "Inter Milan", "Juventus"],
    "correct": "Inter Milan"
  }
]

⚠️ NOTICE: The question includes the FULL player names!

⚠️ DOUBLE-CHECK the accuracy of each question before returning it.
⚠️ The JSON MUST contain exactly $count questions!
Return JSON only without additional text.
''' : '''
[
  {
    "question": "Sample question based on category",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correct": "Option 1"
  }
]

Return JSON only without additional text.
'''}
''';
  }

  // ========== التحقق الأساسي من بنية الأسئلة ==========
  List<AIMultipleChoiceQuestion> _verifyBasicQuestionStructure(List<AIMultipleChoiceQuestion> questions) {
    final verifiedQuestions = <AIMultipleChoiceQuestion>[];
    
    for (var question in questions) {
      bool isValid = true;
      String errorMessage = '';
      
      // 1️⃣ التحقق: يجب أن يكون هناك 4 خيارات بالضبط
      if (question.options.length != 4) {
        isValid = false;
        errorMessage = 'عدد الخيارات ليس 4 (${question.options.length})';
      }
      
      // 2️⃣ التحقق: الإجابة الصحيحة موجودة في الخيارات
      if (isValid && !question.options.contains(question.correctAnswer)) {
        isValid = false;
        errorMessage = 'الإجابة الصحيحة "${question.correctAnswer}" غير موجودة في الخيارات';
      }
      
      // 3️⃣ التحقق: لا توجد خيارات مكررة
      if (isValid) {
        final uniqueOptions = question.options.toSet();
        if (uniqueOptions.length != question.options.length) {
          isValid = false;
          errorMessage = 'يوجد خيارات مكررة';
        }
      }
      
      // 4️⃣ التحقق: الإجابة الصحيحة تظهر مرة واحدة فقط
      if (isValid) {
        final correctAnswerCount = question.options.where((opt) => opt == question.correctAnswer).length;
        if (correctAnswerCount != 1) {
          isValid = false;
          errorMessage = 'الإجابة الصحيحة تظهر $correctAnswerCount مرات بدلاً من مرة واحدة';
        }
      }
      
      // 5️⃣ التحقق: السؤال والخيارات ليست فارغة
      if (isValid) {
        if (question.questionText.trim().isEmpty) {
          isValid = false;
          errorMessage = 'السؤال فارغ';
        } else if (question.options.any((opt) => opt.trim().isEmpty)) {
          isValid = false;
          errorMessage = 'أحد الخيارات فارغ';
        }
      }
      
      if (isValid) {
        verifiedQuestions.add(question);
        print('✅ سؤال صحيح: ${question.questionText.substring(0, question.questionText.length > 50 ? 50 : question.questionText.length)}...');
      } else {
        print('❌ سؤال مرفوض: $errorMessage');
        print('   السؤال: ${question.questionText}');
        print('   الخيارات: ${question.options}');
        print('   الإجابة الصحيحة: ${question.correctAnswer}');
      }
    }
    
    return verifiedQuestions;
  }

  // ========== التحقق المتقدم من صحة أسئلة "من الدخيل" ==========
  Future<List<AIMultipleChoiceQuestion>> _verifyWrongPlayerQuestions(List<AIMultipleChoiceQuestion> questions) async {
    final verifiedQuestions = <AIMultipleChoiceQuestion>[];
    
    for (var question in questions) {
      try {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔍 Verifying: ${question.questionText}');
        print('📝 Options: ${question.options.join(", ")}');
        print('✅ Correct Answer: ${question.correctAnswer}');
        
        // استخراج اسم النادي من السؤال
        final clubName = _extractClubName(question.questionText);
        if (clubName == null) {
          print('❌ Could not extract club name from question');
          continue;
        }
        print('🏟️ Club: $clubName');
        
        // التحقق من كل لاعب
        final prompt = '''
You are a strict football fact checker. Verify this "Who's the Outsider" question for 100% accuracy.

**Question:** ${question.questionText}
**Club:** $clubName
**Options:** ${question.options.join(", ")}
**Claimed Correct Answer (outsider):** ${question.correctAnswer}

**YOUR MISSION:**
Check if this question is CORRECT or WRONG.

**Verification Steps:**
1. For each of the 4 players, verify:
   - Did they play for $clubName? (YES/NO)
   - What years? (if YES)
   
2. Check the logic:
   - 3 players MUST have played for $clubName
   - 1 player (correct answer) MUST NOT have played for $clubName
   
**Response format (JSON only):**
{
  "isCorrect": true/false,
  "playersVerification": {
    "${question.options[0]}": "played 20XX-20XX" or "NEVER played",
    "${question.options[1]}": "played 20XX-20XX" or "NEVER played",
    "${question.options[2]}": "played 20XX-20XX" or "NEVER played",
    "${question.options[3]}": "played 20XX-20XX" or "NEVER played"
  },
  "error": "description of error if isCorrect=false",
  "confidence": "high/medium/low"
}

BE STRICT! Return JSON only.
''';
        
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);
        
        if (response.text == null) {
          print('❌ No verification response');
          continue;
        }
        
        String cleaned = response.text!.trim();
        cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
        
        final result = jsonDecode(cleaned);
        final isCorrect = result['isCorrect'] as bool;
        
        print('📊 Verification Result: ${isCorrect ? "✅ CORRECT" : "❌ WRONG"}');
        if (result['playersVerification'] != null) {
          print('👥 Players Verification:');
          (result['playersVerification'] as Map).forEach((player, status) {
            print('   - $player: $status');
          });
        }
        if (!isCorrect && result['error'] != null) {
          print('⚠️ Error: ${result['error']}');
        }
        print('🎯 Confidence: ${result['confidence']}');
        
        if (isCorrect) {
          verifiedQuestions.add(question);
          print('✅ Question ACCEPTED');
        } else {
          print('❌ Question REJECTED - Contains errors!');
        }
        
      } catch (e) {
        print('❌ Error verifying question: $e');
        // في حالة الخطأ، نرفض السؤال للأمان
      }
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return verifiedQuestions;
  }
  
  String? _extractClubName(String question) {
    // قائمة بأسماء الأندية الشائعة
    final commonClubs = [
      'Barcelona', 'Real Madrid', 'Manchester United', 'Manchester City',
      'Liverpool', 'Chelsea', 'Arsenal', 'Bayern Munich', 'Borussia Dortmund',
      'Juventus', 'AC Milan', 'Inter Milan', 'PSG', 'Atletico Madrid',
      'Tottenham', 'Leicester', 'Sevilla', 'Valencia', 'Napoli', 'Roma',
      'برشلونة', 'ريال مدريد', 'مانشستر يونايتد', 'مانشستر سيتي',
      'ليفربول', 'تشيلسي', 'أرسنال', 'بايرن ميونخ', 'بوروسيا دورتموند',
      'يوفنتوس', 'ميلان', 'إنتر ميلان', 'باريس سان جيرمان', 'أتلتيكو مدريد',
      'توتنهام', 'ليستر', 'إشبيلية', 'فالنسيا', 'نابولي', 'روما',
    ];
    
    // ابحث عن أي نادي من القائمة في السؤال
    for (var club in commonClubs) {
      if (question.contains(club)) {
        return club;
      }
    }
    
    // إذا لم نجد، نحاول regex
    final patterns = [
      RegExp(r'for\s+([A-Z][a-zA-Z\s]+?)(?:\s+except|:|\?)'),
      RegExp(r'لنادي\s+([أ-ي\s]+?)(?:\s+ما\s+عدا|:|؟)'),
      RegExp(r'لـ\s*([أ-ي\s]+?)(?:\s+ما\s+عدا|:|؟)'),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(question);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    
    // إذا لم نجد، نرجع null
    return null;
  }

  Future<List<AIMultipleChoiceQuestion>> _parseMultipleChoiceResponse(String response, String difficulty, String category) async {
    try {
      print('🔧 Parsing response...');
      String cleanedResponse = response.trim();
      print('📝 Original response length: ${response.length}');
      
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
        print('✂️ Removed ```json prefix');
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
        print('✂️ Removed ``` prefix');
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
        print('✂️ Removed ``` suffix');
      }
      cleanedResponse = cleanedResponse.trim();
      
      print('📝 Cleaned response: ${cleanedResponse.substring(0, cleanedResponse.length > 300 ? 300 : cleanedResponse.length)}...');
      
      print('🔍 Attempting JSON decode...');
      final List<dynamic> jsonList = jsonDecode(cleanedResponse);
      print('✅ JSON decoded successfully, found ${jsonList.length} items');
      
      final questions = jsonList.map((item) {
        final questionText = item['question'] as String;
        final options = (item['options'] as List<dynamic>).map((e) => e as String).toList();
        final correctAnswer = item['correct'] as String;
        
        // إضافة السؤال إلى قائمة الأسئلة المستخدمة (مع hash فريد)
        final questionHash = '$questionText|${options.join("|")}|$correctAnswer';
        _usedQuestions.add(questionHash);
        
        return AIMultipleChoiceQuestion(
          id: _generateId(),
          questionText: questionText,
          options: options,
          correctAnswer: correctAnswer,
          difficulty: difficulty,
          category: category,
          createdAt: DateTime.now(),
        );
      }).toList();
      
      print('✅ Converted to ${questions.length} AIMultipleChoiceQuestion objects');
      
      // ✅ التحقق الأساسي من جميع الأسئلة
      print('🔍 Verifying all questions for basic correctness...');
      final basicVerifiedQuestions = _verifyBasicQuestionStructure(questions);
      print('📊 Basic verification: ${basicVerifiedQuestions.length}/${questions.length} questions passed');
      
      // ✅ التحقق المتقدم من صحة الأسئلة (خاصة لـ wrong_player)
      if (category == 'wrong_player') {
        print('🔍 Verifying "wrong_player" questions for advanced accuracy...');
        final verifiedQuestions = await _verifyWrongPlayerQuestions(basicVerifiedQuestions);
        print('📊 Advanced verification: ${verifiedQuestions.length}/${basicVerifiedQuestions.length} questions are correct');
        print('📊 Total used questions now: ${_usedQuestions.length}');
        return verifiedQuestions;
      }
      
      print('📊 Total used questions now: ${_usedQuestions.length}');
      return basicVerifiedQuestions;
    } catch (e, stackTrace) {
      print('❌ Error parsing response: $e');
      print('📚 Stack trace: $stackTrace');
      print('📄 Failed response was: $response');
      return [];
    }
  }

  // ========== 2. أسئلة مفتوحة (الجرس) ==========
  Future<List<AIOpenEndedQuestion>> generateOpenEndedQuestions({
    required int count,
    required String difficulty,
    String language = 'ar',
    Set<String>? usedQuestions, // ✅ قائمة الأسئلة المستخدمة
  }) async {
    try {
      // بناء الـ prompt حسب اللغة
      final String difficultyText = difficulty == 'easy' ? 
          (language == 'ar' ? 'سهلة' : language == 'en' ? 'Easy' : 'Kolay') : 
          difficulty == 'medium' ? 
          (language == 'ar' ? 'متوسطة' : language == 'en' ? 'Medium' : 'Orta') : 
          (language == 'ar' ? 'صعبة' : language == 'en' ? 'Hard' : 'Zor');
      
      // ✅ إضافة الأسئلة المستخدمة في الـ prompt
      String avoidQuestionsSection = '';
      if (usedQuestions != null && usedQuestions.isNotEmpty) {
        final questionsToAvoid = usedQuestions.take(20).join('", "'); // أخذ آخر 20 سؤال
        avoidQuestionsSection = language == 'ar'
            ? '\n\n🚫 تجنب تكرار هذه الأسئلة:\n"$questionsToAvoid"\n\n✅ يجب أن تكون جميع الأسئلة مختلفة تماماً عن القائمة أعلاه.'
            : language == 'en'
            ? '\n\n🚫 AVOID repeating these questions:\n"$questionsToAvoid"\n\n✅ ALL questions must be completely DIFFERENT from the list above.'
            : '\n\n🚫 Bu soruları tekrarlama:\n"$questionsToAvoid"\n\n✅ TÜM sorular yukarıdaki listeden tamamen FARKLI olmalıdır.';
      }
      
      final prompt = language == 'ar' 
          ? '''
⚽ أنشئ $count أسئلة عن كرة القدم فقط (Football/Soccer).

🚫 قواعد صارمة:
- يُسمح فقط بأسئلة عن: لاعبي كرة القدم، أندية كرة القدم، منتخبات كرة القدم، بطولات كرة القدم، مدربي كرة القدم، ملاعب كرة القدم
- ممنوع منعاً باتاً: رياضات أخرى، تاريخ عام، جغرافيا، ثقافة، سياسة، أي موضوع ليس كرة قدم
$avoidQuestionsSection

✅ أمثلة صحيحة:
- "من فاز بكأس العالم 2022؟"
- "من مدرب ريال مدريد؟"
- "أين يلعب محمد صلاح؟"

❌ أمثلة ممنوعة:
- "في أي عام تم بناء برج إيفل؟" (ليس كرة قدم)
- "من اخترع الهاتف؟" (ليس كرة قدم)

الصعوبة: $difficultyText

**أمثلة للأسئلة المطلوبة:**
- "من هو مدرب ريال مدريد الحالي؟" → ["كارلو أنشيلوتي", "أنشيلوتي", "Carlo Ancelotti"]
- "أي منتخب فاز بكأس العالم 2022؟" → ["الأرجنتين", "Argentina", "منتخب الأرجنتين"]
- "أين يلعب كريستيانو رونالدو الآن؟" → ["النصر", "نادي النصر", "Al Nassr"]

**التنسيق (JSON فقط):**
[
  {
    "question": "السؤال؟",
    "acceptableAnswers": ["إجابة 1", "إجابة 2", "إجابة 3"]
  }
]

⚠️ تأكد 100% أن جميع الأسئلة عن كرة القدم فقط وليست مكررة.
أرجع JSON فقط، بدون أي نص إضافي.
'''
          : language == 'en' 
          ? '''
⚽ Generate $count FOOTBALL/SOCCER questions ONLY.

🚫 STRICT RULES:
- ONLY allowed: Football/Soccer players, clubs, national teams, tournaments, coaches, stadiums
- STRICTLY FORBIDDEN: Other sports, general history, geography, culture, politics, ANY non-football topic
$avoidQuestionsSection

✅ Correct examples:
- "Who won the 2022 World Cup?"
- "Who is Real Madrid's coach?"
- "Where does Mohamed Salah play?"

❌ FORBIDDEN examples:
- "When was the Eiffel Tower built?" (NOT football)
- "Who invented the telephone?" (NOT football)

Difficulty: $difficultyText

**Required question examples:**
- "Who is Real Madrid's current coach?" → ["Carlo Ancelotti", "Ancelotti"]
- "Which country won the 2022 World Cup?" → ["Argentina", "Argentine national team"]
- "Where does Cristiano Ronaldo play now?" → ["Al Nassr", "Saudi Arabia"]

**Format (JSON only):**
[
  {
    "question": "Question?",
    "acceptableAnswers": ["Answer 1", "Answer 2", "Answer 3"]
  }
]

⚠️ Ensure 100% ALL questions are about FOOTBALL/SOCCER ONLY and NOT repeated.
Return JSON only, no additional text.
'''
          : '''
⚽ SADECE $count FUTBOL sorusu oluştur.

🚫 KESİN KURALLAR:
- SADECE izin verilen: Futbol oyuncuları, kulüpler, milli takımlar, turnuvalar, antrenörler, stadyumlar
- KESİNLİKLE YASAK: Diğer sporlar, genel tarih, coğrafya, kültür, politika, futbol olmayan HERHANGİ bir konu
$avoidQuestionsSection

✅ Doğru örnekler:
- "2022 Dünya Kupası'nı kim kazandı?"
- "Real Madrid'in antrenörü kim?"
- "Mohamed Salah nerede oynuyor?"

❌ YASAK örnekler:
- "Eyfel Kulesi ne zaman inşa edildi?" (Futbol DEĞİL)
- "Telefonu kim icat etti?" (Futbol DEĞİL)

Zorluk: $difficultyText

**Gerekli soru örnekleri:**
- "Real Madrid'in şu anki antrenörü kim?" → ["Carlo Ancelotti", "Ancelotti"]
- "2022 Dünya Kupası'nı hangi ülke kazandı?" → ["Arjantin", "Arjantin milli takımı"]
- "Cristiano Ronaldo şimdi nerede oynuyor?" → ["Al Nassr", "Suudi Arabistan"]

**Format (sadece JSON):**
[
  {
    "question": "Soru?",
    "acceptableAnswers": ["Cevap 1", "Cevap 2", "Cevap 3"]
  }
]

⚠️ %100 TÜM soruların SADECE FUTBOL hakkında olduğundan ve tekrarlanmadığından emin ol.
Sadece JSON döndür, ek metin yok.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      return jsonList.map((item) => AIOpenEndedQuestion(
        id: _generateId(),
        questionText: item['question'] as String,
        acceptableAnswers: (item['acceptableAnswers'] as List<dynamic>).map((e) => e as String).toList(),
        difficulty: difficulty,
        category: 'bell',
        createdAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // ========== 3. أسئلة رقمية (المزاد) ==========
  Future<List<AINumericQuestion>> generateNumericQuestions({
    required int count,
    required String difficulty,
    String language = 'ar',
  }) async {
    try {
      final prompt = '''
أنشئ $count أسئلة كروية رقمية بالعربية.
كل سؤال إجابته رقم.

الصعوبة: ${difficulty == 'easy' ? 'سهلة' : difficulty == 'medium' ? 'متوسطة' : 'صعبة'}

أمثلة:
- "كم عدد كؤوس العالم التي فازت بها البرازيل؟" → 5
- "كم عدد أهداف ميسي مع برشلونة؟" → 672

**التنسيق (JSON فقط):**
[
  {
    "question": "السؤال؟",
    "answer": 123
  }
]

أرجع JSON فقط.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      return jsonList.map((item) => AINumericQuestion(
        id: _generateId(),
        questionText: item['question'] as String,
        correctAnswer: item['answer'] as int,
        difficulty: difficulty,
        category: 'auction',
        createdAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // ========== 4. أسئلة "اذكر..." (ماذا تعرف) ==========
  Future<List<AINameQuestion>> generateNameQuestions({
    required int count,
    required String difficulty,
    String language = 'ar',
  }) async {
    try {
      final prompt = '''
أنشئ $count أسئلة كروية بصيغة "اذكر..." بالعربية.
كل سؤال له 8-10 إجابات صحيحة ممكنة.

الصعوبة: ${difficulty == 'easy' ? 'سهلة' : difficulty == 'medium' ? 'متوسطة' : 'صعبة'}

أمثلة:
- "اذكر لاعب برازيلي" → ["نيمار", "فينيسيوس", "كاسيميرو", ...]
- "اذكر نادي إنجليزي" → ["ليفربول", "مانشستر يونايتد", ...]

**التنسيق (JSON فقط):**
[
  {
    "question": "اذكر...",
    "possibleAnswers": ["إجابة 1", "إجابة 2", "..."]
  }
]

أرجع JSON فقط.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      return jsonList.map((item) => AINameQuestion(
        id: _generateId(),
        questionText: item['question'] as String,
        possibleAnswers: (item['possibleAnswers'] as List<dynamic>).map((e) => e as String).toList(),
        difficulty: difficulty,
        category: 'name',
        createdAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // ========== 5. أسئلة الانتقالات ==========
  Future<List<AITransferQuestion>> generateTransferQuestions({
    required int count,
    required String difficulty,
    String language = 'ar',
  }) async {
    try {
      String prompt;
      
      if (language == 'ar') {
        prompt = '''
أنشئ $count قوائم انتقالات لاعبين كرة قدم بالعربية.
كل قائمة تحتوي على اسم لاعب وأندية لعب لها بالترتيب الزمني.

الصعوبة: ${difficulty == 'easy' ? 'لاعبين مشهورين (4-6 أندية)' : difficulty == 'medium' ? 'لاعبين معروفين (6-8 أندية)' : 'لاعبين نادرين (8-10 أندية)'}

أمثلة:
- "كريستيانو رونالدو" → ["سبورتينغ لشبونة", "مانشستر يونايتد", "ريال مدريد", "يوفنتوس", "مانشستر يونايتد", "النصر"]

**التنسيق (JSON فقط):**
[
  {
    "playerName": "اسم اللاعب",
    "clubs": ["نادي 1", "نادي 2", "نادي 3", "..."]
  }
]

أرجع JSON فقط.
''';
      } else if (language == 'en') {
        prompt = '''
Generate $count football player transfer history lists in English.
Each list contains a player name and clubs they played for in chronological order.

Difficulty: ${difficulty == 'easy' ? 'Famous players (4-6 clubs)' : difficulty == 'medium' ? 'Well-known players (6-8 clubs)' : 'Rare players (8-10 clubs)'}

Examples:
- "Cristiano Ronaldo" → ["Sporting Lisbon", "Manchester United", "Real Madrid", "Juventus", "Manchester United", "Al Nassr"]

**Format (JSON only):**
[
  {
    "playerName": "Player Name",
    "clubs": ["Club 1", "Club 2", "Club 3", "..."]
  }
]

Return JSON only.
''';
      } else if (language == 'tr') {
        prompt = '''
$count futbol oyuncusu transfer geçmişi listesi oluştur (Türkçe).
Her liste, bir oyuncu adı ve kronolojik sırayla oynadığı kulüpleri içerir.

Zorluk: ${difficulty == 'easy' ? 'Ünlü oyuncular (4-6 kulüp)' : difficulty == 'medium' ? 'Tanınmış oyuncular (6-8 kulüp)' : 'Nadir oyuncular (8-10 kulüp)'}

Örnekler:
- "Cristiano Ronaldo" → ["Sporting Lizbon", "Manchester United", "Real Madrid", "Juventus", "Manchester United", "Al Nassr"]

**Format (sadece JSON):**
[
  {
    "playerName": "Oyuncu Adı",
    "clubs": ["Kulüp 1", "Kulüp 2", "Kulüp 3", "..."]
  }
]

Sadece JSON döndür.
''';
      } else {
        // Default to English
        prompt = '''
Generate $count football player transfer history lists in English.
Each list contains a player name and clubs they played for in chronological order.

Difficulty: ${difficulty == 'easy' ? 'Famous players (4-6 clubs)' : difficulty == 'medium' ? 'Well-known players (6-8 clubs)' : 'Rare players (8-10 clubs)'}

Examples:
- "Cristiano Ronaldo" → ["Sporting Lisbon", "Manchester United", "Real Madrid", "Juventus", "Manchester United", "Al Nassr"]

**Format (JSON only):**
[
  {
    "playerName": "Player Name",
    "clubs": ["Club 1", "Club 2", "Club 3", "..."]
  }
]

Return JSON only.
''';
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      return jsonList.map((item) => AITransferQuestion(
        id: _generateId(),
        playerName: item['playerName'] as String,
        clubs: (item['clubs'] as List<dynamic>).map((e) => e as String).toList(),
        difficulty: difficulty,
        createdAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error generating from Gemini: $e');
      print('📦 Using fallback transfer questions...');
      
      // ✅ أسئلة احتياطية في حالة فشل Gemini
      return _getFallbackTransferQuestions(count, difficulty, language);
    }
  }
  
  // ✅ أسئلة انتقالات ثابتة كـ fallback
  List<AITransferQuestion> _getFallbackTransferQuestions(int count, String difficulty, String language) {
    try {
      // قائمة أسئلة متنوعة
      final List<Map<String, dynamic>> allQuestions = language == 'ar' ? [
      // لاعبين سهلين (4-6 أندية)
      {
        'playerName': 'كريستيانو رونالدو',
        'clubs': ['سبورتينغ لشبونة', 'مانشستر يونايتد', 'ريال مدريد', 'يوفنتوس', 'مانشستر يونايتد', 'النصر'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'ليونيل ميسي',
        'clubs': ['برشلونة ب', 'برشلونة', 'باريس سان جيرمان', 'إنتر ميامي'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'نيمار جونيور',
        'clubs': ['سانتوس', 'برشلونة', 'باريس سان جيرمان', 'الهلال'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'كريم بنزيما',
        'clubs': ['أولمبيك ليون', 'ريال مدريد', 'الاتحاد'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'محمد صلاح',
        'clubs': ['المقاولون العرب', 'بازل', 'تشيلسي', 'فيورنتينا', 'روما', 'ليفربول'],
        'difficulty': 'easy'
      },
      
      // لاعبين متوسطين (6-8 أندية)
      {
        'playerName': 'زلاتان إبراهيموفيتش',
        'clubs': ['مالمو', 'أياكس', 'يوفنتوس', 'إنتر ميلان', 'برشلونة', 'ميلان', 'باريس سان جيرمان', 'مانشستر يونايتد', 'لوس أنجلوس جالاكسي', 'ميلان'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'دافيد بيكهام',
        'clubs': ['مانشستر يونايتد', 'ريال مدريد', 'لوس أنجلوس جالاكسي', 'ميلان', 'باريس سان جيرمان'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'كاكا',
        'clubs': ['ساو باولو', 'ميلان', 'ريال مدريد', 'ميلان', 'ساو باولو', 'نيويورك سيتي', 'أورلاندو سيتي'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'روبن',
        'clubs': ['جرونينجن', 'بي إس في آيندهوفن', 'تشيلسي', 'ريال مدريد', 'بايرن ميونخ', 'جرونينجن'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'فرانك ريبيري',
        'clubs': ['ستاد بريست', 'أليس', 'ميتز', 'غلطة سراي', 'مارسيليا', 'بايرن ميونخ', 'فيورنتينا', 'ساليرنيتانا'],
        'difficulty': 'medium'
      },
      
      // لاعبين صعبين (8-10 أندية)
      {
        'playerName': 'نيكولاس أنيلكا',
        'clubs': ['باريس سان جيرمان', 'آرسنال', 'ريال مدريد', 'باريس سان جيرمان', 'ليفربول', 'مانشستر سيتي', 'فنربخشة', 'بولتون', 'تشيلسي', 'شنغهاي شينخوا', 'يوفنتوس', 'وست بروميتش', 'مومباي سيتي'],
        'difficulty': 'hard'
      },
      {
        'playerName': 'صامويل إيتو',
        'clubs': ['ريال مدريد ب', 'ليغانيس', 'إسبانيول', 'ريال مايوركا', 'برشلونة', 'إنتر ميلان', 'أنجي', 'تشيلسي', 'إيفرتون', 'سامبدوريا', 'أنطاليا سبور', 'قطر الرياضي'],
        'difficulty': 'hard'
      },
      {
        'playerName': 'روبرتو كارلوس',
        'clubs': ['بالميراس', 'إنتر ميلان', 'ريال مدريد', 'فنربخشة', 'كورينثيانز', 'أنجي'],
        'difficulty': 'hard'
      },
      
      // أسئلة إضافية للتنويع
      {
        'playerName': 'رياض محرز',
        'clubs': ['لوهافر', 'ليستر سيتي', 'مانشستر سيتي', 'الأهلي السعودي'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'سادو ماني',
        'clubs': ['ميتز', 'ريد بول سالزبورغ', 'ساوثهامبتون', 'ليفربول', 'بايرن ميونخ', 'النصر'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'لوكا مودريتش',
        'clubs': ['دينامو زغرب', 'إنتر زابرشيتش', 'توتنهام', 'ريال مدريد'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'تياغو سيلفا',
        'clubs': ['فلومينينسي', 'ميلان', 'باريس سان جيرمان', 'تشيلسي'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'أندريا بيرلو',
        'clubs': ['بريشيا', 'إنتر ميلان', 'ريجينا', 'ميلان', 'يوفنتوس', 'نيويورك سيتي'],
        'difficulty': 'hard'
      },
      {
        'playerName': 'ديدييه دروغبا',
        'clubs': ['لومان', 'غانغان', 'مارسيليا', 'تشيلسي', 'شنغهاي شينخوا', 'غلطة سراي', 'تشيلسي', 'مونتريال إمباكت', 'فينيكس رايزينغ'],
        'difficulty': 'hard'
      },
      {
        'playerName': 'رونالدينيو',
        'clubs': ['غريميو', 'باريس سان جيرمان', 'برشلونة', 'ميلان', 'فلامينغو', 'أتلتيكو مينيرو', 'كويريتارو', 'فلومينينسي'],
        'difficulty': 'hard'
      },
      {
        'playerName': 'جيانلويجي بوفون',
        'clubs': ['بارما', 'يوفنتوس', 'باريس سان جيرمان', 'يوفنتوس', 'بارما'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'واين روني',
        'clubs': ['إيفرتون', 'مانشستر يونايتد', 'إيفرتون', 'دي سي يونايتد', 'ديربي كاونتي'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'جيرارد',
        'clubs': ['ليفربول', 'لوس أنجلوس جالاكسي'],
        'difficulty': 'easy'
      },
    ] : language == 'en' ? [
      // English questions
      {
        'playerName': 'Cristiano Ronaldo',
        'clubs': ['Sporting Lisbon', 'Manchester United', 'Real Madrid', 'Juventus', 'Manchester United', 'Al Nassr'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'Lionel Messi',
        'clubs': ['Barcelona B', 'Barcelona', 'Paris Saint-Germain', 'Inter Miami'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'Neymar Jr',
        'clubs': ['Santos', 'Barcelona', 'Paris Saint-Germain', 'Al Hilal'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'Zlatan Ibrahimović',
        'clubs': ['Malmö', 'Ajax', 'Juventus', 'Inter Milan', 'Barcelona', 'Milan', 'Paris Saint-Germain', 'Manchester United', 'LA Galaxy', 'Milan'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'David Beckham',
        'clubs': ['Manchester United', 'Real Madrid', 'LA Galaxy', 'Milan', 'Paris Saint-Germain'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'Nicolas Anelka',
        'clubs': ['Paris Saint-Germain', 'Arsenal', 'Real Madrid', 'Paris Saint-Germain', 'Liverpool', 'Manchester City', 'Fenerbahçe', 'Bolton', 'Chelsea', 'Shanghai Shenhua', 'Juventus', 'West Bromwich', 'Mumbai City'],
        'difficulty': 'hard'
      },
    ] : [
      // Turkish questions
      {
        'playerName': 'Cristiano Ronaldo',
        'clubs': ['Sporting Lizbon', 'Manchester United', 'Real Madrid', 'Juventus', 'Manchester United', 'Al Nassr'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'Lionel Messi',
        'clubs': ['Barcelona B', 'Barcelona', 'Paris Saint-Germain', 'Inter Miami'],
        'difficulty': 'easy'
      },
      {
        'playerName': 'Arda Turan',
        'clubs': ['Galatasaray', 'Atletico Madrid', 'Barcelona', 'Başakşehir', 'Galatasaray'],
        'difficulty': 'medium'
      },
      {
        'playerName': 'Hakan Şükür',
        'clubs': ['Sakaryaspor', 'Bursaspor', 'Galatasaray', 'Torino', 'Inter Milan', 'Parma', 'Blackburn', 'Galatasaray'],
        'difficulty': 'hard'
      },
    ];
    
    // فلترة حسب الصعوبة
    final filtered = allQuestions.where((Map<String, dynamic> q) => 
      difficulty == 'all' || q['difficulty'] == difficulty
    ).toList();
    
    // خلط الأسئلة
    filtered.shuffle();
    
    // أخذ العدد المطلوب
    final selected = filtered.take(count.clamp(0, filtered.length)).toList();
    
      // تحويل إلى AITransferQuestion
      return selected.map((item) => AITransferQuestion(
        id: _generateId(),
        playerName: item['playerName'] as String,
        clubs: List<String>.from(item['clubs']),  // ✅ تصحيح التحويل
        difficulty: item['difficulty'] as String,
        createdAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error in fallback questions: $e');
      // ✅ في أسوأ الحالات، أرجع قائمة فارغة
      return [];
    }
  }

  // ========== 6. أسئلة "ماذا تعرف" (What Do You Know) ==========
  Future<List<Map<String, dynamic>>> generateWhatDoYouKnowQuestions({
    required int count,
    String language = 'ar',
    String difficulty = 'medium', // easy, medium, hard
  }) async {
    try {
      print('🔄 Generating $count "What Do You Know" questions, language: $language, difficulty: $difficulty');
      
      // إعداد قائمة الأسئلة المستخدمة سابقاً
      String usedQuestionsText = '';
      if (_usedQuestions.isNotEmpty) {
        usedQuestionsText = language == 'ar' 
            ? '\n\n**⚠️⚠️⚠️ ممنوع منعاً باتاً تكرار هذه الأسئلة:**\n${_usedQuestions.take(30).join('\n❌ ')}\n\n🔥 **يجب إنشاء أسئلة جديدة ومختلفة تماماً!**\n'
            : '\n\n**⚠️⚠️⚠️ FORBIDDEN - Do NOT repeat these questions:**\n${_usedQuestions.take(30).join('\n❌ ')}\n\n🔥 **Create COMPLETELY NEW and DIFFERENT questions!**\n';
      }
      
      // إضافة seed للتنويع
      final variationSeed = DateTime.now().millisecondsSinceEpoch % 10000;
      
      final prompt = _buildWhatDoYouKnowPrompt(count, language, difficulty, variationSeed) + usedQuestionsText;
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response from Gemini');
      
      print('📥 Received response from Gemini');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      print('✅ Parsed ${jsonList.length} questions successfully');
      
      final questions = jsonList.map((item) {
        final question = item['question'] as String;
        // تتبع الأسئلة المستخدمة
        _usedQuestions.add(question);
        
        return {
          'id': _generateId(),
          'question': question,
          'category': item['category'] as String,
          'possibleAnswers': (item['possibleAnswers'] as List).map((a) => a.toString()).toList(),
        };
      }).toList();
      
      // الحفاظ على آخر 100 سؤال فقط في الذاكرة
      if (_usedQuestions.length > 100) {
        final recentQuestions = _usedQuestions.toList().sublist(_usedQuestions.length - 100);
        _usedQuestions.clear();
        _usedQuestions.addAll(recentQuestions);
      }
      
      print('📊 Total questions tracked: ${_usedQuestions.length}');
      
      return questions;
    } catch (e) {
      print('❌ Error generating questions: $e');
      return [];
    }
  }

  String _buildWhatDoYouKnowPrompt(int count, String language, String difficulty, int variationSeed) {
    if (language == 'ar') {
      // تحديد المعايير حسب الصعوبة
      String difficultyGuidelines = '';
      if (difficulty == 'easy') {
        difficultyGuidelines = '''
**📊 المستوى: سهل**
- استخدم لاعبين وأندية مشهورة جداً (2020-2025)
- الأسماء يجب أن يعرفها معظم الناس
- أمثلة: كريستيانو رونالدو، ميسي، ريال مدريد، برشلونة
''';
      } else if (difficulty == 'medium') {
        difficultyGuidelines = '''
**📊 المستوى: متوسط**
- مزيج من اللاعبين المشهورين والمعروفين (2015-2025)
- أندية من الدرجة الأولى ولكن ليست الأكبر
- أمثلة: كاسيميرو، رافينيا، أتلتيكو مدريد، نابولي
''';
      } else {
        difficultyGuidelines = '''
**📊 المستوى: صعب**
- لاعبون جيدون لكن أقل شهرة (2012-2025)
- أندية من الدرجة الثانية أو أقل شهرة
- مدربين أقل شهرة لكن ناجحين
- أمثلة: دانيلو بيريرا، جايسون دينير، خيتافي، ريال سوسيداد
- ركز على: لاعبين من دوريات أقل شهرة، أندية صغيرة، مدربين صاعدين
''';
      }
      
      return '''
🎲 **Variation Seed: $variationSeed** - استخدم هذا الرقم لتنويع الأسئلة!

أنشئ $count أسئلة لعبة "ماذا تعرف" بالعربية.

$difficultyGuidelines

**نوع اللعبة:** لعبة تنافسية - اللاعب يجب أن يعطي إجابة صحيحة من قائمة الإجابات الممكنة

**🎯 أنواع الأسئلة (متنوعة جداً - اختر بعشوائية):**
1. لاعبين يبدأون بحرف معين (مثل: اذكر لاعب يبدأ بحرف ر / ف / ج / ز)
2. أندية من دوري معين (مثل: اذكر نادي من الدوري الفرنسي / البرتغالي / التركي)
3. لاعبين من جنسية معينة (مثل: اذكر لاعب أرجنتيني / بلجيكي / كرواتي)
4. مدربين مشهورين (مثل: اذكر مدرب ألماني / إيطالي / فرنسي)
5. لاعبين في مركز معين (مثل: اذكر ظهير أيمن مشهور / لاعب وسط دفاعي)
6. أندية فازت بدوري (مثل: اذكر نادي فاز بالدوري الألماني / الإيطالي)
7. لاعبين ينتهي اسمهم بحرف معين (مثل: اذكر لاعب ينتهي اسمه بحرف و / ي)
8. أندية من مدينة معينة (مثل: اذكر نادي من مدينة مدريد / ميلانو / لندن)
9. لاعبين يلعبون في دوري معين (مثل: اذكر لاعب يلعب في الدوري الهولندي)
10. مدافعين مشهورين (مثل: اذكر مدافع يلعب في البريميرليج)

**⚠️ أنواع أسئلة ممنوعة (تجنبها تماماً):**
❌ أي سؤال عن جوائز فردية (الكرة الذهبية، أفضل لاعب، الحذاء الذهبي، إلخ)
❌ أسئلة عن أحداث في سنة محددة
❌ أسئلة تاريخية دقيقة
❌ أسئلة عن أرقام أو إحصائيات
❌ أسئلة عن "الأفضل" أو "الأكثر" (ذاتية)
❌ لا تكرر نفس الحرف أو الدوري أو الجنسية في نفس المجموعة

**✅ ركز على:**
✅ أسماء اللاعبين/الأندية/المدربين (واضحة ومحددة)
✅ تنويع كبير: حروف مختلفة، دوريات مختلفة، جنسيات مختلفة
✅ مراكز مختلفة: حراس، مدافعين، وسط، مهاجمين
✅ الدوريات والبطولات (مستمرة)
✅ الجنسيات والمراكز (ثابتة)
✅ الحروف والأبجدية (بسيطة)

**📋 معايير الجودة الصارمة:**
1. كل سؤال يجب أن يكون له **على الأقل 10-15 إجابة صحيحة واضحة**
2. الإجابات يجب أن تكون **مشهورة ومعروفة عالمياً**
3. تنوع في الأسئلة (أندية، لاعبين، مدربين، جنسيات، مراكز)
4. **استخدم أسماء باللغة العربية** - مثال: "محمد صلاح" ✅ وليس "Mohamed Salah" ❌
5. **تحقق 3 مرات من دقة كل إجابة** - لا توجد إجابات خاطئة أبداً!
6. **استخدم فقط لاعبين ناشطين حالياً أو أساطير معروفة** (2018-2025)

**✅ أمثلة ممتازة (نوّع مثل هذه):**

مثال 1 - حرف:
{
  "question": "اذكر لاعب يبدأ بحرف (ر)",
  "category": "لاعبين",
  "possibleAnswers": ["رودري", "رافينيا", "رودريجو", "رافاييل فاران", "رحيم سترلينج", "روبن دياس", "رومانيولي", "رونالدينيو", "روبرت ليفاندوفسكي", "رياض محرز"]
}

مثال 2 - دوري:
{
  "question": "اذكر نادي من الدوري البرتغالي",
  "category": "أندية",
  "possibleAnswers": ["بورتو", "بنفيكا", "سبورتينغ لشبونة", "براغا", "غيماريش", "بوافيستا", "ماريتيمو", "فاريرينسي", "بيلينينسيش", "ناسيونال"]
}

مثال 3 - جنسية:
{
  "question": "اذكر لاعب بلجيكي مشهور",
  "category": "لاعبين",
  "possibleAnswers": ["كيفين دي بروين", "روميلو لوكاكو", "تيبو كورتوا", "إيدن هازارد", "يانيك كاراسكو", "أكسل فيتسيل", "يوري تيليمانز", "جيريمي دوكو", "ليندرو ديناير", "درايس ميرتنز"]
}

مثال 4 - مركز:
{
  "question": "اذكر ظهير أيسر مشهور",
  "category": "مدافعين",
  "possibleAnswers": ["أندي روبرتسون", "ألفونسو ديفيز", "بن تشيلويل", "لوك شو", "تيو هيرنانديز", "مارتشيلو", "أليكس تيليس", "داني روز", "جوردي ألبا", "فيران مينيدي"]
}

مثال 5 - مركز محدد:
{
  "question": "اذكر لاعب وسط دفاعي مشهور",
  "category": "لاعبين",
  "possibleAnswers": ["كاسيميرو", "رودري", "فابينيو", "ديكلان رايس", "جورجينيو", "بوسكيتس", "كانتي", "توماس بارتي", "دوغلاس لويس", "زوبيمندي"]
}

مثال 6 - دوري أقل شهرة:
{
  "question": "اذكر نادي من الدوري التركي",
  "category": "أندية",
  "possibleAnswers": ["غلطة سراي", "فنربخشة", "بشيكتاش", "طرابزون سبور", "باشاك شهير", "قونيا سبور", "ألانيا سبور", "غازي عنتاب", "قاسم باشا", "ريزة سبور"]
}

مثال 7 - مدربين:
{
  "question": "اذكر مدرب إيطالي مشهور",
  "category": "مدربين",
  "possibleAnswers": ["كارلو أنشيلوتي", "ماسيميليانو أليغري", "سيموني إنزاغي", "روبرتو مانشيني", "ماوريسيو ساري", "كلاوديو رانييري", "لوتشيانو سباليتي", "جيان بييرو غاسبيريني", "ستيفانو بيولي", "أنتونيو كونتي"]
}

**التنسيق (JSON فقط):**
[
  {
    "question": "السؤال بالعربية",
    "category": "الفئة (لاعبين / أندية / مدربين / حراس / جنسية)",
    "possibleAnswers": ["إجابة 1", "إجابة 2", "...", "إجابة 10"]
  }
]

**⚠️ مهم جداً:**
1. كل سؤال يحتاج **8-12 إجابة ممكنة**
2. الإجابات يجب أن تكون **بالعربية فقط**
3. تنوع في الأسئلة
4. أسماء مشهورة ومعروفة

أرجع JSON فقط.
''';
    } else {
      return '''
Create $count "What Do You Know" game questions in English.

**Game Type:** Competitive game - player must give a correct answer from possible answers list

**🎯 Question Types (varied):**
1. Players starting with a letter (e.g., Name a player starting with M)
2. Clubs from a league (e.g., Name a Spanish club)
3. Players who won awards (e.g., Name a Ballon d'Or winner)
4. Players from nationality (e.g., Name a Brazilian player)
5. Famous coaches (e.g., Name a Spanish coach)
6. Players in position (e.g., Name a famous goalkeeper)

**📋 Quality Criteria:**
1. Each question must have **at least 8-12 possible correct answers**
2. Answers must be **famous and well-known**
3. Variety in questions (clubs, players, coaches, nationalities, positions)
4. **Use names in ENGLISH**

**✅ Excellent Examples:**

{
  "question": "Name a player starting with K",
  "category": "players",
  "possibleAnswers": ["Kylian Mbappe", "Kevin De Bruyne", "Karim Benzema", "Kante", "Kane", "Kroos", "Kaka", "Kompany", "Keane"]
}

**Format (JSON only):**
[
  {
    "question": "Question in English",
    "category": "Category (players / clubs / coaches / goalkeepers / nationality)",
    "possibleAnswers": ["Answer 1", "Answer 2", "...", "Answer 10"]
  }
]

**⚠️ Important:**
1. Each question needs **8-12 possible answers**
2. Famous and well-known names
3. Variety in questions

Return JSON only.
''';
    }
  }

  // ========== 7. أسئلة التلميحات (Hint Questions) ==========
  Future<List<Map<String, dynamic>>> generateHintQuestions({
    required int count,
    required String type, // 'player', 'coach', 'club'
    required String difficulty,
    String language = 'ar',
  }) async {
    try {
      print('🔄 Generating $count hint questions for type: $type, difficulty: $difficulty, language: $language');
      
      // إعداد قائمة الأسئلة المستخدمة سابقاً للبرومبت
      String usedQuestionsText = '';
      if (_usedQuestions.isNotEmpty) {
        usedQuestionsText = '\n\n**⚠️ تجنب هذه الأسئلة المستخدمة سابقاً:**\n';
        usedQuestionsText += _usedQuestions.take(20).join('\n- ');
      }
      
      final prompt = _buildHintPrompt(count, type, difficulty, language) + usedQuestionsText;
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response from Gemini');
      
      print('📥 Received response from Gemini (${response.text!.length} chars)');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      print('✅ Parsed ${jsonList.length} hint questions successfully');
      
      final questions = jsonList.map((item) {
        final answer = (item['answer'] as String).trim();
        // للعربية: لا نحول لأحرف كبيرة
        // للإنجليزية والتركية: نحول لأحرف كبيرة
        final finalAnswer = language == 'ar' ? answer : answer.toUpperCase();
        
        // إضافة السؤال للأسئلة المستخدمة
        _usedQuestions.add(finalAnswer);
        
        return {
          'id': _generateId(),
          'hint': item['hint'] as String,
          'answer': finalAnswer,
          'type': type,
          'difficulty': difficulty,
        };
      }).toList();
      
      print('📊 Total used questions: ${_usedQuestions.length}');
      
      return questions;
    } catch (e) {
      print('❌ Error generating hint questions: $e');
      return [];
    }
  }

  String _buildHintPrompt(int count, String type, String difficulty, String language) {
    final typeText = type == 'player'
        ? (language == 'ar' ? 'لاعب' : language == 'tr' ? 'oyuncu' : 'player')
        : type == 'coach'
            ? (language == 'ar' ? 'مدرب' : language == 'tr' ? 'teknik direktör' : 'coach')
            : (language == 'ar' ? 'نادي' : language == 'tr' ? 'kulüp' : 'club');

    if (language == 'ar') {
      return '''
أنت خبير كرة قدم محترف. أنشئ $count أسئلة تلميحية ممتعة ودقيقة عن $typeText كرة قدم بالعربية.

**نوع السؤال:** $typeText
**الصعوبة:** ${difficulty == 'easy' ? 'سهل (مشهورين جداً - نجوم العالم)' : difficulty == 'medium' ? 'متوسط (معروفين - نجوم جيدين)' : 'صعب (أقل شهرة - نجوم محليين)'}

**🌍 التنويع الجغرافي (مهم جداً):**
- دوريات أوروبية: الدوري الإنجليزي، الإسباني، الإيطالي، الألماني، الفرنسي
- الدوري السعودي: لاعبين مشهورين انتقلوا للسعودية
- الدوري التركي: جالاتا سراي، فنربخشة، بشيكتاش
- دوريات عالمية أخرى: أمريكا، البرازيل، الأرجنتين

**⏰ التركيز الزمني:**
- 60% من الأسئلة عن الموسم الحالي 2024-2025
- 25% من الأسئلة عن الفترة 2020-2023
- 10% من الأسئلة عن الفترة 2015-2019
- 5% من الأسئلة عن أساطير كرة القدم (2000-2014)

**🎯 معايير الجودة:**
1. **الدقة 100%** - تأكد من كل معلومة قبل كتابتها
2. **التلميحات واضحة ومحددة** - استخدم أرقام، تواريخ، ألقاب
3. **لا تذكر الاسم مباشرة** - استخدم وصف مميز
4. **معلومات مثيرة** - إنجازات، أرقام قياسية، مواقف شهيرة
5. **تنوع في المصادر** - من دوريات ومنتخبات مختلفة

**أمثلة حسب النوع:**

${type == 'player' ? '''
**أمثلة متنوعة للاعبين (احترافية ودقيقة):**

✅ أمثلة ممتازة (موسم 2024-2025):

**مهاجمين:**
- "هداف الدوري الإنجليزي موسم 2023-2024 النرويجي من مانشستر سيتي"
  → "ارلينج هالاند"
  
- "النجم الفرنسي الذي انتقل من باريس سان جيرمان لريال مدريد موسم 2024"
  → "كيليان مبابي"

- "المصري الذي يلعب لليفربول ويلقب بالفرعون المصري"
  → "محمد صلاح"

**لاعبي وسط:**
- "الإنجليزي الشاب الذي انتقل لريال مدريد موسم 2023 وفاز بجائزة الكرة الذهبية للاعب الشاب"
  → "جود بيلينجهام"

- "صانع ألعاب مانشستر سيتي البلجيكي صاحب التمريرات الحاسمة"
  → "كيفين دي بروين"

**الدوري السعودي:**
- "البرتغالي الأسطورة الذي انتقل للنصر موسم 2023"
  → "كريستيانو رونالدو"

- "البرازيلي الذي انتقل للهلال ويلعب مع نيمار"
  → "مالكوم"

**مدافعين وحراس:**
- "حارس مرمى ليفربول البرازيلي الأفضل في العالم"
  → "أليسون بيكر"

- "المدافع الهولندي قائد ليفربول"
  → "فيرجيل فان دايك"

❌ أمثلة سيئة (تجنبها):
- "اللاعب الذي سجل 100 هدف" ← غير محدد
- "أفضل لاعب في العالم" ← عام جداً
- "الفائز بالكرة الذهبية 2025" ← مستقبلي
''' : type == 'coach' ? '''
**أمثلة متنوعة للمدربين (موسم 2024-2025):**

✅ أمثلة ممتازة:

- "مدرب مانشستر سيتي الإسباني الذي فاز بثلاثية الدوري موسم 2022-2023"
  → "بيب جوارديولا"

- "مدرب ريال مدريد الإيطالي صاحب الرقم القياسي في دوري الأبطال بخمس بطولات"
  → "كارلو انشيلوتي"

- "المدرب الألماني الذي قاد ليفربول لكأس الدوري الإنجليزي وحقق نهضة كبيرة"
  → "يورجن كلوب"

- "مدرب برشلونة الإسباني الشاب الذي كان لاعباً في النادي"
  → "تشافي هيرنانديز"

- "المدرب الإسباني الذي يدرب الهلال السعودي ويملك خبرة أوروبية كبيرة"
  → "جورجي خيسوس"

❌ أمثلة سيئة:
- "أفضل مدرب في العالم" ← غير محدد
- "المدرب الذي فاز بكل شيء" ← عام جداً
''' : '''
**أمثلة متنوعة للأندية (حديثة ودقيقة):**

✅ أمثلة ممتازة:

**دوريات أوروبية:**
- "النادي الإنجليزي الذي فاز بثلاثية الدوري والكأس ودوري الأبطال موسم 2022-2023"
  → "مانشستر سيتي"

- "النادي الإسباني صاحب الرقم القياسي في دوري الأبطال بخمسة عشر لقباً"
  → "ريال مدريد"

- "النادي الألماني من بافاريا الذي يلعب في ملعب الأليانز أرينا"
  → "بايرن ميونخ"

- "النادي الإنجليزي الأحمر من ليفربول صاحب الأنصار المتعصبين"
  → "ليفربول"

**الدوري السعودي:**
- "نادي الرياض الأصفر الذي يضم كريستيانو رونالدو"
  → "النصر"

- "النادي الأزرق من الرياض بطل الدوري السعودي عدة مرات"
  → "الهلال"

**الدوري التركي:**
- "النادي التركي الأصفر والأحمر من اسطنبول بطل الدوري"
  → "جالاتا سراي"

❌ أمثلة سيئة:
- "النادي الأكثر شعبية" ← غير محدد
- "الفريق الأفضل" ← عام جداً
'''}

**التنسيق (JSON فقط):**
[
  {
    "hint": "التلميح هنا",
    "answer": "الإجابة بالأحرف العربية فقط"
  }
]

**⚠️ تعليمات نهائية حاسمة:**

1. **دقة 100%** - تحقق من كل معلومة ثلاث مرات
2. **الإجابة بالأحرف العربية فقط** - مثال: "محمد صلاح" ✅ وليس "MOHAMED SALAH" ❌
3. **تنوع جغرافي** - غطي دوريات مختلفة (إنجلترا، إسبانيا، السعودية، تركيا)
4. **معلومات حديثة** - ركز على موسم 2024-2025
5. **تلميحات واضحة** - استخدم أرقام محددة، تواريخ، ألقاب مميزة
6. **تجنب التكرار** - لا تكرر نفس اللاعبين إذا طُلب منك عدة مرات
7. **اجعلها ممتعة** - استخدم معلومات مثيرة ومشوقة

**🎯 نصيحة ذهبية:** اجعل التلميح يحكي قصة مثيرة عن اللاعب/المدرب/النادي!

أرجع JSON فقط بدون نص إضافي.
''';
    } else if (language == 'tr') {
      return '''
$typeText hakkında $count ipucu sorusu oluştur (Türkçe).

**Soru tipi:** $typeText
**Zorluk:** ${difficulty == 'easy' ? 'Kolay (çok ünlü)' : difficulty == 'medium' ? 'Orta (tanınmış)' : 'Zor (az bilinen)'}

**Zaman odağı:**
- %70 sorular 2018-2025 dönemi hakkında
- %20 sorular 2010-2017 dönemi hakkında
- %10 sorular 1990-2009 dönemi hakkında

**⚠️ Kesinlik kuralları:**
1. **Her bilgiyi üç kez kontrol et** - asla tahmin etme
2. **Sadece belgelenmiş bilgiler kullan** - gerçek başarılar ve doğru sayılar
3. **İpucu %100 doğru olmalı** - tarihleri ve sayıları kontrol et
4. **İsmi doğrudan söyleme** ipucunda
5. **Ayırt edici bilgiler kullan** - lakaplar, başarılar, belirli dönemler

**Format (sadece JSON):**
[
  {
    "hint": "İpucu buraya",
    "answer": "TÜRKÇE BÜYÜK HARFLERLE CEVAP"
  }
]

**⚠️ Son talimatlar:**
1. **Her bilgiyi üç kez kontrol et** eklemeden önce
2. **%100 emin olmadığın bilgileri kullanma**
3. **Cevap sadece Türkçe karakterlerle olmalı** - Ç, Ğ, İ, Ö, Ş, Ü kullan
4. **Tarihler ve sayılar tamamen doğru olmalı**
5. **Güvenilir kaynaklardan bilgi kullan**
- Örnek: "PEP GUARDİOLA" ✅ (Türkçe), "PEP GUARDIOLA" ❌ (İngilizce)

Sadece JSON döndür.
''';
    } else {
      return '''
Create $count hint questions about football $typeText in English.

**Question type:** $typeText
**Difficulty:** ${difficulty == 'easy' ? 'Easy (very famous)' : difficulty == 'medium' ? 'Medium (well-known)' : 'Hard (less known)'}

**Time focus:**
- 70% questions about 2018-2025 period (modern era)
- 20% questions about 2010-2017 period
- 10% questions about 1990-2009 period

**⚠️ Strict accuracy rules:**
1. **Verify every fact three times** - never guess
2. **Use only documented information** - real achievements and accurate numbers
3. **Hint must be 100% accurate** - verify dates and numbers
4. **Don't mention the name directly** in the hint
5. **Use distinctive information** - nicknames, achievements, specific periods

${type == 'player' ? '''
**Player examples (verify accuracy):**

✅ Correct:
- Hint: "Premier League top scorer 2023-2024, Norwegian striker from Manchester City"
  Answer: "ERLING HAALAND"

- Hint: "Liverpool's Egyptian star who won African Player of the Year three times"
  Answer: "MOHAMED SALAH"

- Hint: "Argentine who won the 2022 World Cup and currently plays for Inter Miami"
  Answer: "LIONEL MESSI"

❌ Wrong - don't use inaccurate information:
- "Player who scored 100 goals" ← verify the actual number
- "Winner of 2025 Ballon d'Or" ← use only documented years
''' : type == 'coach' ? '''
**Coach examples (verify accuracy):**

✅ Correct:
- Hint: "Spanish Manchester City manager who won the Champions League in 2022-2023"
  Answer: "PEP GUARDIOLA"

- Hint: "Italian Real Madrid coach with record five Champions League titles"
  Answer: "CARLO ANCELOTTI"

- Hint: "Portuguese coach who led Portugal to Euro 2016 victory"
  Answer: "FERNANDO SANTOS"

❌ Wrong - don't use inaccurate information:
- "Coach who won ten championships" ← verify the count
- "Best coach in history" ← use specific achievements
''' : '''
**Club examples (verify accuracy):**

✅ Correct:
- Hint: "English club that won the treble of Premier League, FA Cup and Champions League in 2022-2023"
  Answer: "MANCHESTER CITY"

- Hint: "Spanish club with record fifteen Champions League titles"
  Answer: "REAL MADRID"

- Hint: "German club from Bavaria that plays at Allianz Arena"
  Answer: "BAYERN MUNICH"

❌ Wrong - don't use inaccurate information:
- "Most popular club" ← use specific achievements
- "Team that won all trophies" ← be accurate
'''}

**Format (JSON only):**
[
  {
    "hint": "hint text here",
    "answer": "ANSWER IN CAPITAL LETTERS"
  }
]

**⚠️ Final instructions:**
1. **Triple-check every fact** before including it
2. **Don't use any information you're not 100% sure about**
3. **Dates and numbers must be completely accurate**
4. **Use information from reliable sources only**
5. **Answer must be in CAPITAL LETTERS**

Return JSON only.
''';
    }
  }
  
  // ========== توليد سؤال عادل (بدون معرفة اللاعب) ==========
  Future<String?> generateBlindQuestion({
    required List<Map<String, dynamic>> previousQuestions,
    String language = 'ar',
  }) async {
    try {
      print('🎯 Generating FAIR question (no cheating)...');
      
      // بناء قائمة الأسئلة السابقة
      String previousQA = '';
      if (previousQuestions.isNotEmpty) {
        previousQA += '**Previous Questions & Answers:**\n';
        for (var i = 0; i < previousQuestions.length; i++) {
          final q = previousQuestions[i];
          previousQA += '${i + 1}. Q: "${q['question']}" → A: ${q['answer'] ? "YES" : "NO"}\n';
        }
      } else {
        previousQA = '**This is the first question.**\n';
      }
      
      final prompt = '''
You are playing "Guess the Player" game. Generate a strategic yes/no question to identify a football player.

$previousQA

**CRITICAL RULES - PLAY FAIR:**
1. You DON'T know who the target player is
2. Generate questions based ONLY on previous answers
3. Think like a real detective - build knowledge step by step
4. Start with broad questions (nationality, position, league)
5. Then narrow down (club, age, achievements)
6. NEVER contradict previous YES answers
7. NEVER repeat previous questions

**Strategy Guide:**

**First Question (no previous answers):**
- Start broad: nationality, continent, position, or league
- Good examples in Arabic:
  * "هل اللاعب من أوروبا؟" (Is the player from Europe?)
  * "هل اللاعب مهاجم؟" (Is the player a forward?)
  * "هل يلعب في أحد الدوريات الخمس الكبرى؟" (Plays in top 5 leagues?)
  * "هل اللاعب من أمريكا الجنوبية؟" (Is from South America?)

**After Some YES Answers:**
- Narrow down based on what you know
- If "from Europe" = YES → Ask "من إسبانيا؟" or "من إنجلترا؟"
- If "forward" = YES + "Premier League" = YES → Ask "يلعب لليفربول؟"

**Build Logically:**
- Questions 1-2: Broad (continent/position/league type)
- Questions 3-4: Medium (specific country/league)
- Questions 5-6: Specific (club/age range)
- Questions 7+: Very specific (achievements, shirt number)

**Examples of Good Question Flow:**
Q1: "هل اللاعب من أمريكا الجنوبية؟" → YES
Q2: "هل اللاعب من البرازيل؟" → YES
Q3: "هل يلعب في أوروبا؟" → YES
Q4: "هل يلعب في الدوري الإسباني؟" → YES
Q5: "هل يلعب في ريال مدريد؟" → YES

**Response format (JSON only):**
{
  "reasoning": "Why this question makes sense based on previous answers",
  "question": "your strategic question in $language language"
}

Return JSON only. Think strategically but DON'T CHEAT!
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        print('❌ No response from Gemini');
        return null;
      }
      
      String responseText = response.text!.trim();
      print('📥 Generated FAIR question: $responseText');
      
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = json.decode(responseText);
      final question = result['question'] as String;
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🤔 COMPUTER THINKING (FAIR):');
      print('💭 Reasoning: ${result['reasoning']}');
      print('❓ Question: $question');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return question;
    } catch (e) {
      print('❌ Error generating fair question: $e');
      return null;
    }
  }
  
  // ========== توليد سؤال منطقي للكمبيوتر (للاعب البشري فقط - يعرف الإجابة) ==========
  Future<String?> generateSmartQuestion({
    required Map<String, dynamic> targetPlayerInfo,
    required List<Map<String, dynamic>> previousQuestions,
    String language = 'ar',
  }) async {
    try {
      print('🤔 Generating smart question...');
      
      // بناء قائمة الأسئلة والأجوبة السابقة
      String previousQA = '';
      if (previousQuestions.isNotEmpty) {
        previousQA = '\n**Previous Questions & Answers:**\n';
        for (var i = 0; i < previousQuestions.length; i++) {
          final q = previousQuestions[i];
          previousQA += '${i + 1}. Q: "${q['question']}" -> A: ${q['answer'] ? "YES" : "NO"}\n';
        }
      }
      
      final prompt = '''
You are a smart AI playing "Guess the Player" game. Generate the next logical question to ask.

**Target Player (hidden from opponent):**
- Name: ${targetPlayerInfo['name']}
- Nationality: ${targetPlayerInfo['nationality']}
- Position: ${targetPlayerInfo['position']}
- League: ${targetPlayerInfo['league']}
- Age: ${targetPlayerInfo['age']}
- Club: ${targetPlayerInfo['club']}
- Is Retired: ${targetPlayerInfo['isRetired']}

$previousQA

**CRITICAL INSTRUCTIONS - ANALYZE BEFORE ASKING:**
1. **Step 1: Review What You Know**
   - Analyze ALL previous answers
   - Extract confirmed facts (YES answers)
   - Exclude wrong guesses (NO answers)

2. **Step 2: Identify Next Best Question**
   - What information would NARROW DOWN the player most?
   - Start broad (nationality, position) then get specific (club, age)
   - Build logically on previous answers

3. **Step 3: Generate Strategic Question**
   - Generate ONE smart yes/no question in $language language
   - MUST be logical based on confirmed facts
   - NEVER contradict previous YES answers
   - NEVER repeat previous questions
   - Use strategic thinking to identify the player

**Example Strategy:**
Previous: "Brazilian?" → YES
Next Good Questions:
- "يلعب في أوروبا؟" (plays in Europe?)
- "مهاجم؟" (forward?)
- "يلعب في ريال مدريد؟" (plays for Real Madrid?)

Next BAD Questions:
- "أرجنتيني؟" (Argentinian?) ← Contradicts "Brazilian"
- "يلعب في آسيا؟" (plays in Asia?) ← Less strategic

**More Examples:**
Scenario 1:
Q1: "من أوروبا؟" → NO
Q2: "من أمريكا الجنوبية؟" → YES
→ Good next: "من البرازيل؟" or "من الأرجنتين؟"

Scenario 2:
Q1: "يلعب في الدوري الإنجليزي؟" → YES
Q2: "مهاجم؟" → YES
→ Good next: "يلعب في ليفربول؟" or "يلعب في مانشستر سيتي؟"

**Important:**
- Think like a detective - eliminate possibilities
- Ask questions that give maximum information
- Build your knowledge step by step
- Be smart and strategic!

**Response format (JSON only):**
{
  "analysis": "Brief analysis of what you know so far",
  "strategy": "Why this question makes sense",
  "question": "your strategic question here in $language"
}

Return JSON only. BE SMART!
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        print('❌ No response from Gemini');
        return null;
      }
      
      String responseText = response.text!.trim();
      print('📥 Generated question response: $responseText');
      
      // تنظيف النص
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = json.decode(responseText);
      final question = result['question'] as String;
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🤔 COMPUTER THINKING:');
      print('📊 Analysis: ${result['analysis']}');
      print('🎯 Strategy: ${result['strategy']}');
      print('❓ Question: $question');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return question;
    } catch (e) {
      print('❌ Error generating question: $e');
      return null;
    }
  }
  
  // ========== قرار التخمين ==========
  Future<bool> shouldMakeGuess({
    required List<Map<String, dynamic>> previousQuestions,
    required int minQuestions,
  }) async {
    try {
      print('🤔 Checking if should make guess...');
      
      if (previousQuestions.length < minQuestions) {
        print('❌ Not enough questions: ${previousQuestions.length}/$minQuestions');
        return false;
      }
      
      // بناء قائمة الأسئلة والأجوبة
      String previousQA = '';
      for (var i = 0; i < previousQuestions.length; i++) {
        final q = previousQuestions[i];
        previousQA += '${i + 1}. Q: "${q['question']}" -> A: ${q['answer'] ? "YES" : "NO"}\n';
      }
      
      final prompt = '''
You are playing "Guess the Player" game. Based on the questions and answers so far, decide if you have enough information to make an educated guess.

**Questions & Answers so far:**
$previousQA

**Instructions:**
1. You asked ${previousQuestions.length} questions so far
2. Analyze if the answers narrow down to a specific player or small group
3. If you can confidently identify the player, return true
4. If you need more information, return false
5. Be strategic - don't guess too early or too late

**Response format (JSON only):**
{
  "shouldGuess": true/false,
  "confidence": "high/medium/low",
  "reasoning": "brief explanation"
}

Return JSON only.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        print('❌ No response from Gemini');
        return false;
      }
      
      String responseText = response.text!.trim();
      print('📥 Should guess response: $responseText');
      
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = json.decode(responseText);
      final shouldGuess = result['shouldGuess'] as bool;
      
      print(shouldGuess ? '✅ Ready to guess!' : '❌ Need more questions');
      print('🎯 Confidence: ${result['confidence']}');
      print('💡 Reasoning: ${result['reasoning']}');
      
      return shouldGuess;
    } catch (e) {
      print('❌ Error checking if should guess: $e');
      return false;
    }
  }
  
  // ========== تخمين اسم اللاعب ==========
  Future<String?> guessPlayerName({
    required List<Map<String, dynamic>> previousQuestions,
  }) async {
    try {
      print('🎯 Guessing player name...');
      
      // بناء قائمة الأسئلة والأجوبة
      String previousQA = '';
      for (var i = 0; i < previousQuestions.length; i++) {
        final q = previousQuestions[i];
        previousQA += '${i + 1}. Q: "${q['question']}" -> A: ${q['answer'] ? "YES" : "NO"}\n';
      }
      
      final prompt = '''
You are playing "Guess the Player" game. Based on the questions and answers, guess the player's name.

**Questions & Answers:**
$previousQA

**CRITICAL INSTRUCTIONS - ANALYZE DEEPLY:**
1. **Step 1: Extract Information**
   - From YES answers: What do we KNOW about the player?
   - From NO answers: What can we EXCLUDE?
   
2. **Step 2: Build Player Profile**
   - Nationality: (from answers)
   - Position: (from answers)
   - League: (from answers)
   - Club: (from answers)
   - Age range: (from answers)
   - Other traits: (from answers)

3. **Step 3: Match with Real Players**
   - Think of famous players who match ALL the criteria
   - Exclude players who contradict ANY answer
   - Consider current season (2024/2025)

4. **Step 4: Make Best Guess**
   - Choose the player who matches MOST answers
   - Be realistic - consider player popularity and relevance
   - Return FULL ENGLISH NAME (e.g., "Cristiano Ronaldo", "Lionel Messi", "Vinicius Junior")

**Examples of Analysis:**
Example 1:
- Q: "Brazilian?" → YES
- Q: "Plays in La Liga?" → YES
- Q: "Forward?" → YES
- Q: "Plays for Real Madrid?" → YES
- Q: "Age under 25?" → YES
→ Analysis: Brazil + La Liga + Real Madrid + Forward + Young = **Vinicius Junior**

Example 2:
- Q: "Portuguese?" → YES
- Q: "Plays in Saudi League?" → YES
- Q: "Forward?" → YES
- Q: "Over 35 years old?" → YES
→ Analysis: Portugal + Saudi League + Forward + 35+ = **Cristiano Ronaldo**

Example 3:
- Q: "Egyptian?" → YES
- Q: "Plays in Premier League?" → YES
- Q: "Forward?" → YES
- Q: "Plays for Liverpool?" → YES
→ Analysis: Egypt + Premier League + Liverpool + Forward = **Mohamed Salah**

**Important:**
- USE LOGIC and FOOTBALL KNOWLEDGE
- Think like a real football fan
- Match the answers to actual famous players
- Don't guess randomly - analyze carefully!

**Response format (JSON only):**
{
  "analysis": "Step by step analysis of the answers",
  "matchedPlayers": ["Player 1", "Player 2"],
  "playerName": "Final Guess - Full Player Name in English",
  "confidence": "high/medium/low",
  "reasoning": "Why this player matches the answers"
}

Return JSON only. THINK CAREFULLY!
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        print('❌ No response from Gemini');
        return null;
      }
      
      String responseText = response.text!.trim();
      print('📥 Guess response: $responseText');
      
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = json.decode(responseText);
      final playerName = result['playerName'] as String;
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🧠 COMPUTER ANALYSIS:');
      print('📊 Analysis: ${result['analysis']}');
      print('👥 Matched Players: ${result['matchedPlayers']}');
      print('🎯 Final Guess: $playerName');
      print('💪 Confidence: ${result['confidence']}');
      print('💭 Reasoning: ${result['reasoning']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return playerName;
    } catch (e) {
      print('❌ Error guessing player name: $e');
      return null;
    }
  }
  
  // ========== التحقق من سؤال اللاعب ==========
  Future<bool> verifyQuestionAnswer({
    required String question,
    required Map<String, dynamic> playerInfo,
  }) async {
    try {
      print('🔍 Verifying question: "$question"');
      print('📋 Player: ${playerInfo['name']} - ${playerInfo['nationality']}');
      
      final prompt = '''
You are a football expert. Answer this yes/no question about a football player with 100% accuracy.

**Question:** $question

**Player Information (MUST BE USED):**
- Name: ${playerInfo['name']}
- Nationality: ${playerInfo['nationality']}
- Position: ${playerInfo['position']}
- League: ${playerInfo['league']}
- Age: ${playerInfo['age']}
- Club: ${playerInfo['club']}
- Is Retired: ${playerInfo['isRetired']}

**CRITICAL INSTRUCTIONS:**
1. The question may be in Arabic, English, or Turkish
2. Match nationalities correctly (player's nationality is in English):
   - "برازيلي" / "Brazilian" / "Brezilyalı" = Brazil
   - "أرجنتيني" / "Argentinian" / "Arjantinli" = Argentina
   - "برتغالي" / "Portuguese" / "Portekizli" = Portugal
   - "مصري" / "Egyptian" / "Mısırlı" = Egypt
   - "سعودي" / "Saudi" / "Suudi" = Saudi Arabia
   - "إنجليزي" / "English" / "İngiliz" = England
   - "إسباني" / "Spanish" / "İspanyol" = Spain
   - "فرنسي" / "French" / "Fransız" = France
   - "ألماني" / "German" / "Alman" = Germany
   - "إيطالي" / "Italian" / "İtalyan" = Italy
   - "هولندي" / "Dutch" / "Hollandalı" = Netherlands
   - "بلجيكي" / "Belgian" / "Belçikalı" = Belgium
   - "نرويجي" / "Norwegian" / "Norveçli" = Norway
   And ALL other nationalities
3. Use the EXACT information provided above
4. For nationality questions, translate the question to match the player's nationality field
5. Be 100% accurate - double check before answering
6. The player's nationality is ALWAYS in English (e.g., "Brazil", "Argentina", "Egypt")

**Examples:**
- Question: "هل اللاعب برازيلي؟" + Nationality: "Brazil" → Answer: true
- Question: "Is the player Brazilian?" + Nationality: "Brazil" → Answer: true
- Question: "هل اللاعب أرجنتيني؟" + Nationality: "Brazil" → Answer: false

**Response format (JSON only):**
{
  "answer": true/false,
  "reasoning": "brief explanation of why",
  "confidence": "high"
}

Return JSON only. BE ACCURATE!
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        print('❌ No response from Gemini');
        return false;
      }
      
      String responseText = response.text!.trim();
      print('📥 Answer response: $responseText');
      
      // تنظيف النص
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = json.decode(responseText);
      final answer = result['answer'] as bool;
      
      print(answer ? '✅ Answer: YES' : '❌ Answer: NO');
      print('💭 Reasoning: ${result['reasoning']}');
      
      return answer;
    } catch (e) {
      print('❌ Error verifying question: $e');
      return false;
    }
  }
  
  // ========== التحقق من تخمين اللاعب ==========
  Future<bool> verifyPlayerGuess({
    required String guessedName,
    required String correctName,
    required Map<String, dynamic> playerInfo,
  }) async {
    try {
      print('🔍 Verifying player guess: "$guessedName" vs "$correctName"');
      print('📋 Player Info: ${playerInfo['nationality']} - ${playerInfo['position']}');
      
      final prompt = '''
You are a STRICT football expert. Verify if the guessed player name is CORRECT with MAXIMUM accuracy.

**Guessed Name:** "$guessedName"
**Correct Name:** "$correctName"

**Player Information:**
- Nationality: ${playerInfo['nationality']}
- Position: ${playerInfo['position']}
- League: ${playerInfo['league']}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 **STRICT RULES - Follow carefully:**

1. **EXACT MATCH** → TRUE
   - "Mohamed Salah" = "Mohamed Salah" ✅
   
2. **LAST NAME ONLY (if famous)** → TRUE  
   - "Salah" = "Mohamed Salah" ✅
   - "Messi" = "Lionel Messi" ✅
   - "Ronaldo" = "Cristiano Ronaldo" (if Portuguese) ✅
   - "Haaland" = "Erling Haaland" ✅
   
3. **FIRST + LAST NAME** → TRUE
   - "Lionel Messi" = "Lionel Messi" ✅
   
4. **MINOR SPELLING VARIATIONS** → TRUE
   - "Mohamed" = "Muhammad" ✅
   - "Cristiano" = "Christiano" ✅
   
5. **LANGUAGE VARIATIONS** → TRUE
   - "صلاح" = "Salah" ✅ (Arabic)
   - "ميسي" = "Messi" ✅ (Arabic)

6. **FAMOUS NICKNAMES** → TRUE
   - "CR7" = "Cristiano Ronaldo" ✅
   - "Leo" = "Lionel Messi" ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ **REJECT IF:**

1. **WRONG PLAYER** → FALSE
   - "Messi" ≠ "Ronaldo" ❌
   - "Salah" ≠ "Mane" ❌

2. **TOO VAGUE** → FALSE
   - "Mohamed" for "Mohamed Salah" ❌ (too many Mohameds)
   - "Ahmed" for "Ahmed Hassan" ❌ (too common)
   - "Ali" for "Ali Mabkhout" ❌ (too common)

3. **ONLY FIRST NAME (if not unique)** → FALSE
   - "Cristiano" for "Cristiano Ronaldo" ❌ (need last name or "CR7")
   - "Lionel" for "Lionel Messi" ❌ (need last name or "Leo" or "Messi")

4. **RANDOM TEXT** → FALSE
   - "football" ❌
   - "player" ❌
   - gibberish ❌

5. **NATIONALITY/POSITION MISMATCH** → FALSE
   - If guess doesn't match the player info ❌

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **Accept Examples:**
- Guess: "Salah" + Correct: "Mohamed Salah" → TRUE
- Guess: "Messi" + Correct: "Lionel Messi" → TRUE
- Guess: "Haaland" + Correct: "Erling Haaland" → TRUE
- Guess: "CR7" + Correct: "Cristiano Ronaldo" → TRUE
- Guess: "صلاح" + Correct: "Mohamed Salah" → TRUE

❌ **Reject Examples:**
- Guess: "Mohamed" + Correct: "Mohamed Salah" → FALSE (too vague)
- Guess: "Ahmed" + Correct: "Ahmed Hassan" → FALSE (too common)
- Guess: "player" + Correct: "Lionel Messi" → FALSE (nonsense)
- Guess: "Messi" + Correct: "Cristiano Ronaldo" → FALSE (wrong player)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
**Response format (JSON only):**
{
  "isCorrect": true/false,
  "reason": "brief explanation",
  "confidence": "high/medium/low"
}

⚠️ **BE STRICT! Only accept if you're 100% certain it's the correct player!**
Return JSON only.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        print('❌ No response from Gemini');
        return _simpleNameMatch(guessedName, correctName);
      }
      
      String responseText = response.text!.trim();
      print('📥 Verification response: $responseText');
      
      // تنظيف النص
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = json.decode(responseText);
      final isCorrect = result['isCorrect'] as bool;
      
      print(isCorrect ? '✅ Correct guess!' : '❌ Wrong guess!');
      print('💡 Reason: ${result['reason']}');
      print('🎯 Confidence: ${result['confidence']}');
      
      return isCorrect;
    } catch (e) {
      print('❌ Error verifying guess: $e');
      // في حالة الخطأ، نستخدم مقارنة بسيطة
      return _simpleNameMatch(guessedName, correctName);
    }
  }
  
  bool _simpleNameMatch(String guess, String correct) {
    guess = guess.toLowerCase().trim();
    correct = correct.toLowerCase().trim();
    
    print('🔍 Simple name match: "$guess" vs "$correct"');
    
    // مقارنة مباشرة
    if (guess == correct) {
      print('✅ Exact match!');
      return true;
    }
    
    // تحقق من الأسماء الجزئية
    if (correct.contains(guess) && guess.length >= 4) {
      print('✅ Partial match (guess in correct)!');
      return true;
    }
    
    if (guess.contains(correct) && correct.length >= 4) {
      print('✅ Partial match (correct in guess)!');
      return true;
    }
    
    // قسّم الأسماء وقارن كل جزء
    final guessParts = guess.split(' ');
    final correctParts = correct.split(' ');
    
    // إذا كان أحد أجزاء الاسم يطابق تماماً
    for (var guessPart in guessParts) {
      for (var correctPart in correctParts) {
        if (guessPart.length >= 4 && correctPart.length >= 4) {
          if (guessPart == correctPart) {
            print('✅ Name part match: "$guessPart"!');
            return true;
          }
          // مسافة تحرير صغيرة للأجزاء
          if (_levenshteinDistance(guessPart, correctPart) <= 1) {
            print('✅ Name part similar: "$guessPart" ≈ "$correctPart"!');
            return true;
          }
        }
      }
    }
    
    // تحقق من الأسماء المتشابهة (مسافة Levenshtein)
    if (_levenshteinDistance(guess, correct) <= 3) {
      print('✅ Similar names (edit distance)!');
      return true;
    }
    
    print('❌ No match found');
    return false;
  }
  
  int _levenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) {
      return _levenshteinDistance(s2, s1);
    }
    
    if (s2.isEmpty) {
      return s1.length;
    }
    
    List<int> previousRow = List<int>.generate(s2.length + 1, (i) => i);
    
    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];
      
      for (int j = 0; j < s2.length; j++) {
        int insertions = previousRow[j + 1] + 1;
        int deletions = currentRow[j] + 1;
        int substitutions = previousRow[j] + (s1[i] != s2[j] ? 1 : 0);
        
        currentRow.add([insertions, deletions, substitutions].reduce((a, b) => a < b ? a : b));
      }
      
      previousRow = currentRow;
    }
    
    return previousRow.last;
  }
  
  // ========== 8. تحليل الإجابة الصوتية ==========
  Future<Map<String, dynamic>> analyzeVoiceAnswer({
    required String voiceAnswer,
    required List<String> correctAnswers,
    required String question,
    String language = 'ar',
  }) async {
    try {
      print('🎤 Analyzing voice answer: "$voiceAnswer"');
      
      final prompt = language == 'ar' ? '''
أنت خبير في تحليل الإجابات الصوتية لأسئلة كرة القدم.

**السؤال:** $question

**الإجابات الصحيحة المحتملة:**
${correctAnswers.map((a) => '- $a').join('\n')}

**الإجابة الصوتية من اللاعب:** "$voiceAnswer"

**مهمتك:**
1. حلل الإجابة الصوتية وتحقق إذا كانت تطابق أو قريبة جداً من أي إجابة صحيحة
2. تعامل مع الأخطاء الإملائية البسيطة (1-2 حرف)
3. تعامل مع الاختلافات في الكتابة (مثل: "محمد صلاح" = "صلاح" = "Mohamed Salah")
4. تعامل مع النطق المختلف للأسماء الأجنبية بالعربية
5. كن مرناً مع الأسماء الطويلة (الاسم الأخير كافي)
6. إذا كانت الإجابة خاطئة، اشرح السبب بوضوح

**أمثلة:**
- "محمد صلاح" ✅ يطابق "محمد صلاح"
- "صلاح" ✅ يطابق "محمد صلاح" (الاسم الأخير كافي)
- "مبابي" ✅ يطابق "كيليان مبابي"
- "كرستيانو رونالدو" ✅ يطابق "كريستيانو رونالدو" (خطأ إملائي بسيط)
- "ميسي" ✅ يطابق "ليونيل ميسي"
- "محمد" ❌ يطابق "محمد صلاح" (الاسم الأول فقط - غامض جداً)
- "عثمان ديمبلي" ❌ لا يطابق سؤال "من فاز بالكرة الذهبية" (لم يفز بها أبداً)
- "أحمد" ❌ لا يطابق "محمد صلاح" (خطأ واضح)

**التنسيق (JSON فقط):**
{
  "isCorrect": true أو false,
  "matchedAnswer": "الإجابة الصحيحة التي تطابقت" أو null,
  "confidence": رقم من 0 إلى 100,
  "reason": "سبب القرار - اشرح بوضوح لماذا خطأ أو صح"
}

أرجع JSON فقط بدون نص إضافي.
''' : '''
You are an expert in analyzing voice answers for football questions.

**Question:** $question

**Correct possible answers:**
${correctAnswers.map((a) => '- $a').join('\n')}

**Voice answer from player:** "$voiceAnswer"

**Your task:**
1. Analyze if the voice answer matches or is very close to any correct answer
2. Handle simple spelling errors (1-2 characters)
3. Handle different writings (e.g., "Mohamed Salah" = "Salah")
4. Handle different pronunciations of foreign names
5. Be flexible with long names (last name is enough)

**Examples:**
- "Salah" ✅ matches "Mohamed Salah" (last name is enough)
- "Mbappe" ✅ matches "Kylian Mbappe"
- "Christiano Ronaldo" ✅ matches "Cristiano Ronaldo" (minor spelling)
- "Mohamed" ❌ matches "Mohamed Salah" (first name only - too ambiguous)
- "Ahmed" ❌ doesn't match "Mohamed Salah" (clear error)

**Format (JSON only):**
{
  "isCorrect": true or false,
  "matchedAnswer": "matched correct answer" or null,
  "confidence": number from 0 to 100,
  "reason": "reason for decision"
}

Return JSON only without extra text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return {
          'isCorrect': false,
          'matchedAnswer': null,
          'confidence': 0,
          'reason': 'No response from AI',
        };
      }
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final result = jsonDecode(cleaned);
      print('✅ AI Analysis: ${result['isCorrect'] ? 'CORRECT ✓' : 'WRONG ✗'} (${result['confidence']}%) - ${result['reason']}');
      
      return {
        'isCorrect': result['isCorrect'] ?? false,
        'matchedAnswer': result['matchedAnswer'],
        'confidence': result['confidence'] ?? 0,
        'reason': result['reason'] ?? '',
      };
    } catch (e) {
      print('❌ Error analyzing voice answer: $e');
      return {
        'isCorrect': false,
        'matchedAnswer': null,
        'confidence': 0,
        'reason': 'Error: $e',
      };
    }
  }

  // ========== 9. تحليل الإجابة مع التحقق من التكرار ==========
  Future<Map<String, dynamic>> analyzeAnswerWithDuplicateCheck({
    required String playerAnswer,
    required List<String> correctAnswers,
    required List<String> usedAnswers,
    required String question,
    String language = 'ar',
  }) async {
    try {
      print('🔍 Analyzing answer with duplicate check: "$playerAnswer"');
      
      final prompt = language == 'ar' ? '''
أنت خبير محترف خارق في كرة القدم العالمية. مهمتك تحليل إجابة لاعب في لعبة "ماذا تعرف" بدقة 100%.

**السؤال:** $question

**الإجابات المستخدمة سابقاً في هذه الجولة:**
${usedAnswers.isEmpty ? 'لا يوجد' : usedAnswers.map((a) => '- $a').join('\n')}

**إجابة اللاعب:** "$playerAnswer"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 **خطوات التحليل بالترتيب:**

**الخطوة 1: تحديد الاسم الكامل للاعب**
- إذا كتب اللاعب اسم مختصر (مثل "ساني")، ابحث عن الاسم الكامل
- أمثلة:
  * "ساني" → الاسم الكامل: "ليروا ساني" (Leroy Sané)
  * "صلاح" → الاسم الكامل: "محمد صلاح" (Mohamed Salah)
  * "مبابي" → الاسم الكامل: "كيليان مبابي" (Kylian Mbappé)
  * "رونالدو" → الاسم الكامل: "كريستيانو رونالدو" (Cristiano Ronaldo)

**الخطوة 2: تحليل السؤال**
- إذا السؤال عن حرف معين:
  * احكم على **أول كلمة في الإجابة التي كتبها اللاعب**
  * إذا كتب اسم واحد → احكم عليه مباشرة
  * إذا كتب اسمين أو أكثر → احكم على الكلمة الأولى
  
  أمثلة:
  * "ميسي" → احكم على "ميسي" → يبدأ بحرف "م" ✅
  * "ليونيل ميسي" → احكم على "ليونيل" → يبدأ بحرف "ل" ✅
  * "صلاح" → احكم على "صلاح" → يبدأ بحرف "ص" ✅
  * "محمد صلاح" → احكم على "محمد" → يبدأ بحرف "م" ✅
  * "رونالدو" → احكم على "رونالدو" → يبدأ بحرف "ر" ✅
  * "كريستيانو رونالدو" → احكم على "كريستيانو" → يبدأ بحرف "ك" ✅
  * "مبابي" → احكم على "مبابي" → يبدأ بحرف "م" ✅
  * "ماستانتونو" → احكم على "ماستانتونو" → يبدأ بحرف "م" ✅

**الخطوة 3: التحقق من التكرار**
- هل الإجابة الحالية مطابقة أو قريبة جداً من إجابة مستخدمة سابقاً؟
- تحقق من:
  * الاسم الكامل vs الاسم المختصر (مثال: "محمد صلاح" = "صلاح")
  * العربي vs الإنجليزي (مثال: "ميسي" = "Messi")
  * الأخطاء الإملائية البسيطة (1-2 حرف)
  * نفس اللاعب بأشكال مختلفة

**الخطوة 4: التحقق من الصحة**
إذا لم تكن مكررة، تحقق:
- هل هو لاعب/نادي حقيقي ومشهور؟
- هل ينطبق عليه شرط السؤال بناءً على الاسم الكامل؟
- هل المعلومة صحيحة 100%؟

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **أمثلة صحيحة:**

السؤال: "اذكر لاعب يبدأ بحرف (م)"
• "ميسي" → ✅ أول كلمة "ميسي" تبدأ بحرف م
• "ليونيل ميسي" → ❌ أول كلمة "ليونيل" تبدأ بحرف ل وليس م
• "محمد صلاح" → ✅ أول كلمة "محمد" تبدأ بحرف م
• "مبابي" → ✅ أول كلمة "مبابي" تبدأ بحرف م
• "ماستانتونو" → ✅ أول كلمة "ماستانتونو" تبدأ بحرف م
• "مودريتش" → ✅ أول كلمة "مودريتش" تبدأ بحرف م
• "Messi" → ✅ أول كلمة "Messi" تبدأ بحرف M
• "Mbappe" → ✅ أول كلمة "Mbappe" تبدأ بحرف M

السؤال: "اذكر لاعب يبدأ بحرف (ل)"
• "ليونيل ميسي" → ✅ أول كلمة "ليونيل" تبدأ بحرف ل
• "لوكا مودريتش" → ✅ أول كلمة "لوكا" تبدأ بحرف ل
• "ليروا ساني" → ✅ أول كلمة "ليروا" تبدأ بحرف ل

السؤال: "اذكر لاعب يبدأ بحرف (ر)"
• "رونالدو" → ✅ أول كلمة "رونالدو" تبدأ بحرف ر
• "كريستيانو رونالدو" → ❌ أول كلمة "كريستيانو" تبدأ بحرف ك وليس ر
• "راموس" → ✅ أول كلمة "راموس" تبدأ بحرف ر

السؤال: "اذكر لاعب يبدأ بحرف (ص)"
• "صلاح" → ✅ أول كلمة "صلاح" تبدأ بحرف ص
• "محمد صلاح" → ❌ أول كلمة "محمد" تبدأ بحرف م وليس ص

السؤال: "اذكر نادي من الدوري الإسباني"
• "برشلونة" → ✅ نادي إسباني
• "ريال مدريد" → ✅ نادي إسباني
• "إشبيلية" → ✅ نادي إسباني
• "Barcelona" → ✅ (نفس برشلونة بالإنجليزي)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ **أمثلة خاطئة:**

السؤال: "اذكر لاعب يبدأ بحرف (م)"
• "ليونيل ميسي" → ❌ أول كلمة "ليونيل" تبدأ بحرف "ل" وليس "م"
• "كريستيانو رونالدو" → ❌ أول كلمة "كريستيانو" تبدأ بحرف "ك" وليس "م"
• "رونالدو" → ❌ أول كلمة "رونالدو" تبدأ بحرف "ر" وليس "م"
• "Ronaldo" → ❌ أول كلمة "Ronaldo" تبدأ بحرف R وليس M

السؤال: "اذكر لاعب يبدأ بحرف (ل)"
• "محمد صلاح" → ❌ أول كلمة "محمد" تبدأ بحرف "م" وليس "ل"
• "صلاح" → ❌ أول كلمة "صلاح" تبدأ بحرف "ص" وليس "ل"
• "ميسي" → ❌ أول كلمة "ميسي" تبدأ بحرف "م" وليس "ل"

السؤال: "اذكر لاعب يبدأ بحرف (ر)"
• "كريستيانو رونالدو" → ❌ أول كلمة "كريستيانو" تبدأ بحرف "ك" وليس "ر"

عام:
• "محمد" → ❌ غامض جداً (يوجد محمد صلاح، محمد النني، إلخ)
• "تشيلسي" للسؤال عن الدوري الإسباني → ❌ نادي إنجليزي
• "كورة" → ❌ ليس اسم لاعب أو نادي

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔁 **أمثلة تكرار:**

إجابات مستخدمة: ["محمد صلاح", "ميسي"]

• "صلاح" → ✅ مكرر (نفس محمد صلاح)
• "محمد صلاح" → ✅ مكرر (نفسه تماماً)
• "Salah" → ✅ مكرر (نفس محمد صلاح بالإنجليزي)
• "ليونيل ميسي" → ✅ مكرر (نفس ميسي)
• "Messi" → ✅ مكرر (نفس ميسي بالإنجليزي)
• "مبابي" → ❌ ليس مكرر (لاعب مختلف)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 **التنسيق المطلوب (JSON فقط):**

{
  "isDuplicate": true أو false,
  "isCorrect": true أو false,
  "matchedAnswer": "الاسم الكامل الصحيح للاعب/النادي",
  "confidence": رقم من 0 إلى 100,
  "reason": "سبب واضح ومختصر للقرار"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ **قواعد مهمة جداً:**

1. إذا مكرر → isDuplicate=true, isCorrect=false
2. إذا غير مكرر وصحيح → isDuplicate=false, isCorrect=true
3. إذا غير مكرر وخطأ → isDuplicate=false, isCorrect=false
4. كن دقيقاً 100% - استخدم معرفتك الكاملة بكرة القدم
5. لا تقبل إجابات غامضة (مثل "محمد" فقط)
6. تأكد من المعلومة قبل قبول الإجابة
7. matchedAnswer يجب أن يكون الاسم الكامل والصحيح
8. confidence يجب أن يعكس درجة تأكدك

🔴 **القاعدة الذهبية للحروف:**
- عند السؤال عن حرف معين، **احكم دائماً على أول كلمة كتبها اللاعب**
- لا تفكر في الاسم الكامل! احكم على ما كتبه اللاعب فقط!
- أمثلة:
  * "ميسي" للحرف (م) → ✅ صحيح لأن "ميسي" تبدأ بحرف م
  * "ليونيل ميسي" للحرف (م) → ❌ خطأ لأن "ليونيل" تبدأ بحرف ل
  * "صلاح" للحرف (ص) → ✅ صحيح لأن "صلاح" تبدأ بحرف ص
  * "محمد صلاح" للحرف (م) → ✅ صحيح لأن "محمد" تبدأ بحرف م
  * "رونالدو" للحرف (ر) → ✅ صحيح لأن "رونالدو" تبدأ بحرف ر
  * "ماستانتونو" للحرف (م) → ✅ صحيح لأن "ماستانتونو" تبدأ بحرف م
  * "مبابي" للحرف (م) → ✅ صحيح لأن "مبابي" تبدأ بحرف م

أرجع JSON فقط بدون أي نص إضافي قبله أو بعده.
''' : '''
You are a super expert football analyst. Analyze player answers in "What Do You Know" game with 100% accuracy.

**Question:** $question

**Previously used answers this round:**
${usedAnswers.isEmpty ? 'None' : usedAnswers.map((a) => '- $a').join('\n')}

**Player's answer:** "$playerAnswer"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 **Analysis Steps (in order):**

**Step 1: Identify the full player name**
- If player wrote a shortened name (like "Sané"), find the full name
- Examples:
  * "Sané" → Full name: "Leroy Sané"
  * "Salah" → Full name: "Mohamed Salah"
  * "Mbappe" → Full name: "Kylian Mbappé"
  * "Ronaldo" → Full name: "Cristiano Ronaldo"

**Step 2: Analyze the question**
- If question asks about a specific letter:
  * Judge the **FIRST WORD the player wrote**
  * If wrote one name → judge it directly
  * If wrote two or more names → judge the first word
  
  Examples:
  * "Messi" → judge "Messi" → starts with "M" ✅
  * "Lionel Messi" → judge "Lionel" → starts with "L" ✅
  * "Salah" → judge "Salah" → starts with "S" ✅
  * "Mohamed Salah" → judge "Mohamed" → starts with "M" ✅
  * "Ronaldo" → judge "Ronaldo" → starts with "R" ✅
  * "Cristiano Ronaldo" → judge "Cristiano" → starts with "C" ✅
  * "Mbappe" → judge "Mbappe" → starts with "M" ✅
  * "Mastantuono" → judge "Mastantuono" → starts with "M" ✅

**Step 3: Check for duplicates**
- Is the current answer identical or very similar to a previously used answer?
- Check for:
  * Full name vs shortened name (e.g., "Mohamed Salah" = "Salah")
  * Arabic vs English (e.g., "ميسي" = "Messi")
  * Minor spelling errors (1-2 characters)
  * Same player in different forms

**Step 4: Verify correctness**
If not duplicate, check:
- Is it a real and famous player/club?
- Does it meet the question's condition based on the full name?
- Is the information 100% accurate?

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **Correct Examples:**

Question: "Name a player starting with M"
• "Messi" → ✅ First word "Messi" starts with M
• "Lionel Messi" → ❌ First word "Lionel" starts with L not M
• "Mohamed Salah" → ✅ First word "Mohamed" starts with M
• "Mbappe" → ✅ First word "Mbappe" starts with M
• "Mastantuono" → ✅ First word "Mastantuono" starts with M
• "Modric" → ✅ First word "Modric" starts with M

Question: "Name a player starting with L"
• "Lionel Messi" → ✅ First word "Lionel" starts with L
• "Luka Modric" → ✅ First word "Luka" starts with L
• "Leroy Sané" → ✅ First word "Leroy" starts with L

Question: "Name a player starting with R"
• "Ronaldo" → ✅ First word "Ronaldo" starts with R
• "Cristiano Ronaldo" → ❌ First word "Cristiano" starts with C not R
• "Ramos" → ✅ First word "Ramos" starts with R

Question: "Name a player starting with S"
• "Salah" → ✅ First word "Salah" starts with S
• "Mohamed Salah" → ❌ First word "Mohamed" starts with M not S

Question: "Name a Spanish league club"
• "Barcelona" → ✅ Spanish club
• "Real Madrid" → ✅ Spanish club
• "Sevilla" → ✅ Spanish club
• "برشلونة" → ✅ (Barcelona in Arabic)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ **Wrong Examples:**

Question: "Name a player starting with M"
• "Lionel Messi" → ❌ First word "Lionel" starts with "L" not "M"
• "Cristiano Ronaldo" → ❌ First word "Cristiano" starts with "C" not "M"
• "Ronaldo" → ❌ First word "Ronaldo" starts with "R" not "M"

Question: "Name a player starting with L"
• "Mohamed Salah" → ❌ First word "Mohamed" starts with "M" not "L"
• "Salah" → ❌ First word "Salah" starts with "S" not "L"
• "Messi" → ❌ First word "Messi" starts with "M" not "L"

Question: "Name a player starting with R"
• "Cristiano Ronaldo" → ❌ First word "Cristiano" starts with "C" not "R"

General:
• "Mohamed" → ❌ Too ambiguous (many players named Mohamed)
• "Chelsea" for Spanish league → ❌ English club, not Spanish
• "Football" → ❌ Not a player or club name

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔁 **Duplicate Examples:**

Used answers: ["Mohamed Salah", "Messi"]

• "Salah" → ✅ Duplicate (same as Mohamed Salah)
• "Mohamed Salah" → ✅ Duplicate (exact match)
• "صلاح" → ✅ Duplicate (same as Mohamed Salah in Arabic)
• "Lionel Messi" → ✅ Duplicate (same as Messi)
• "ميسي" → ✅ Duplicate (same as Messi in Arabic)
• "Mbappe" → ❌ Not duplicate (different player)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 **Required Format (JSON only):**

{
  "isDuplicate": true or false,
  "isCorrect": true or false,
  "matchedAnswer": "full correct player/club name",
  "confidence": number from 0 to 100,
  "reason": "clear and concise reason for decision"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ **Critical Rules:**

1. If duplicate → isDuplicate=true, isCorrect=false
2. If not duplicate and correct → isDuplicate=false, isCorrect=true
3. If not duplicate and wrong → isDuplicate=false, isCorrect=false
4. Be 100% accurate - use your complete football knowledge
5. Don't accept ambiguous answers (like "Mohamed" only)
6. Verify information before accepting
7. matchedAnswer must be the full correct name
8. confidence must reflect your certainty level

🔴 **GOLDEN RULE FOR LETTERS:**
- When question asks about a specific letter, **ALWAYS judge the FIRST WORD the player wrote**
- Don't think about full names! Judge what the player actually wrote!
- Examples:
  * "Messi" for letter (M) → ✅ Correct because "Messi" starts with M
  * "Lionel Messi" for letter (M) → ❌ Wrong because "Lionel" starts with L
  * "Salah" for letter (S) → ✅ Correct because "Salah" starts with S
  * "Mohamed Salah" for letter (M) → ✅ Correct because "Mohamed" starts with M
  * "Ronaldo" for letter (R) → ✅ Correct because "Ronaldo" starts with R
  * "Mastantuono" for letter (M) → ✅ Correct because "Mastantuono" starts with M
  * "Mbappe" for letter (M) → ✅ Correct because "Mbappe" starts with M

Return JSON only without any extra text before or after.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return {
          'isDuplicate': false,
          'isCorrect': false,
          'matchedAnswer': null,
          'confidence': 0,
          'reason': 'No response from AI',
        };
      }
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final result = jsonDecode(cleaned);
      print('✅ AI Analysis: Duplicate=${result['isDuplicate']}, Correct=${result['isCorrect']} (${result['confidence']}%)');
      print('💡 Reason: ${result['reason']}');
      
      return {
        'isDuplicate': result['isDuplicate'] ?? false,
        'isCorrect': result['isCorrect'] ?? false,
        'matchedAnswer': result['matchedAnswer'],
        'confidence': result['confidence'] ?? 0,
        'reason': result['reason'] ?? '',
      };
    } catch (e) {
      print('❌ Error analyzing answer with duplicate check: $e');
      return {
        'isDuplicate': false,
        'isCorrect': false,
        'matchedAnswer': null,
        'confidence': 0,
        'reason': 'Error: $e',
      };
    }
  }

  // ========== 10. توليد إجابة للكمبيوتر ==========
  Future<Map<String, dynamic>> generateComputerAnswer({
    required String question,
    required List<String> usedAnswers,
    String language = 'ar',
  }) async {
    try {
      print('🤖 Generating computer answer for: "$question"');
      
      final prompt = language == 'ar' ? '''
أنت خبير محترف في كرة القدم العالمية. مهمتك توليد إجابة واحدة صحيحة 100% للسؤال.

**السؤال:** $question

**إجابات محظورة (مستخدمة سابقاً - لا تكررها أبداً):**
${usedAnswers.isEmpty ? 'لا يوجد' : usedAnswers.map((a) => '- $a').join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ **قواعد صارمة - يجب اتباعها 100%:**

1. **تحقق من الشرط بدقة شديدة:**
   - إذا السؤال: "اذكر لاعب يبدأ بحرف (م)"
     ✅ صحيح: محمد صلاح (يبدأ بحرف م)
     ✅ صحيح: ميسي (يبدأ بحرف م)
     ✅ صحيح: مبابي (يبدأ بحرف م)
     ❌ خطأ: بنزيما (يبدأ بحرف ب وليس م)
     ❌ خطأ: رونالدو (يبدأ بحرف ر وليس م)
     ❌ خطأ: صلاح (يبدأ بحرف ص وليس م)

2. **تحقق من الحرف الأول:**
   - اقرأ السؤال بعناية وحدد الحرف المطلوب
   - تأكد أن إجابتك تبدأ بنفس الحرف بالضبط
   - الحرف الأول هو الأهم!

3. **لا تكرر الإجابات:**
   - تحقق من القائمة المحظورة
   - لا تستخدم نفس الإجابة بصيغة مختلفة

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **أمثلة صحيحة:**

📝 السؤال: "اذكر لاعب يبدأ بحرف (م)"
محظور: ["محمد صلاح", "ميسي"]

التفكير:
- الحرف المطلوب: م
- لاعبين يبدأون بحرف م: محمد صلاح ❌ (محظور), ميسي ❌ (محظور), مبابي ✅, مودريتش ✅, مانويل نوير ✅
- الإجابة: "كيليان مبابي" ✅

📝 السؤال: "اذكر لاعب يبدأ بحرف (ب)"
محظور: ["بنزيما"]

التفكير:
- الحرف المطلوب: ب
- لاعبين يبدأون بحرف ب: بنزيما ❌ (محظور), بيكهام ✅, بيليه ✅, بوسكيتس ✅
- الإجابة: "ديفيد بيكهام" ✅

❌ **أمثلة خاطئة:**

📝 السؤال: "اذكر لاعب يبدأ بحرف (م)"
- "بنزيما" ❌ - يبدأ بحرف ب وليس م!
- "رونالدو" ❌ - يبدأ بحرف ر وليس م!
- "صلاح" ❌ - يبدأ بحرف ص وليس م!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 **التنسيق (JSON فقط):**

{
  "success": true,
  "answer": "الاسم الكامل الصحيح (يجب أن يبدأ بالحرف المطلوب!)"
}

⚠️ **إذا لم تجد إجابة صحيحة جديدة:**
{
  "success": false,
  "answer": ""
}

🔴 **تحذير نهائي:**
- قبل إرجاع الإجابة، تأكد 100% أنها تبدأ بالحرف المطلوب في السؤال
- لا ترجع إجابة خاطئة أبداً
- الدقة أهم من السرعة

أرجع JSON فقط بدون أي نص إضافي.
''' : '''
You are a professional football expert. Generate ONE 100% correct answer for the question.

**Question:** $question

**Banned answers (already used - NEVER repeat these):**
${usedAnswers.isEmpty ? 'None' : usedAnswers.map((a) => '- $a').join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ **STRICT RULES - Must follow 100%:**

1. **Verify condition with extreme precision:**
   - If question: "Name a player starting with M"
     ✅ Correct: Mohamed Salah (starts with M)
     ✅ Correct: Messi (starts with M)
     ✅ Correct: Mbappe (starts with M)
     ❌ Wrong: Benzema (starts with B, not M)
     ❌ Wrong: Ronaldo (starts with R, not M)
     ❌ Wrong: Salah (starts with S, not M)

2. **Check the first letter:**
   - Read the question carefully and identify the required letter
   - Make sure your answer starts with exactly that letter
   - The first letter is the most important!

3. **Don't repeat answers:**
   - Check the banned list
   - Don't use the same answer in different form

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **Correct Examples:**

📝 Question: "Name a player starting with M"
Banned: ["Mohamed Salah", "Messi"]

Thinking:
- Required letter: M
- Players starting with M: Mohamed Salah ❌ (banned), Messi ❌ (banned), Mbappe ✅, Modric ✅, Manuel Neuer ✅
- Answer: "Kylian Mbappe" ✅

📝 Question: "Name a player starting with B"
Banned: ["Benzema"]

Thinking:
- Required letter: B
- Players starting with B: Benzema ❌ (banned), Beckham ✅, Pele ✅, Busquets ✅
- Answer: "David Beckham" ✅

❌ **Wrong Examples:**

📝 Question: "Name a player starting with M"
- "Benzema" ❌ - starts with B, not M!
- "Ronaldo" ❌ - starts with R, not M!
- "Salah" ❌ - starts with S, not M!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 **Format (JSON only):**

{
  "success": true,
  "answer": "full correct name (MUST start with required letter!)"
}

⚠️ **If can't find a correct new answer:**
{
  "success": false,
  "answer": ""
}

🔴 **FINAL WARNING:**
- Before returning the answer, verify 100% it starts with the required letter
- NEVER return a wrong answer
- Accuracy is more important than speed

Return JSON only without any extra text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return {
          'success': false,
          'answer': '',
        };
      }
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final result = jsonDecode(cleaned);
      print('✅ Generated computer answer: "${result['answer']}"');
      
      return {
        'success': result['success'] ?? false,
        'answer': result['answer'] ?? '',
      };
    } catch (e) {
      print('❌ Error generating computer answer: $e');
      return {
        'success': false,
        'answer': '',
      };
    }
  }
  
  // ============================================
  // 🎪 The Auction - Questions Generation & Analysis
  // ============================================
  
  /// تحليل إجابات اللاعب في لعبة المزاد
  Future<Map<String, dynamic>> analyzeAuctionAnswers({
    required String question,
    required List<String> playerAnswers,
    required int requiredCount,
    required int correctCount,
    String language = 'ar',
  }) async {
    try {
      print('🔍 Analyzing ${playerAnswers.length} answers for question: "$question"');
      
      final prompt = language == 'ar' ? '''
أنت محلل دقيق جداً لإجابات لعبة المزاد الكروية.

**السؤال:**
$question

**المعلومات:**
- الإجابات المطلوبة من اللاعب: $requiredCount
- العدد الصحيح الإجمالي المتاح: $correctCount

**إجابات اللاعب (${playerAnswers.length} إجابة):**
${playerAnswers.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

**مهمتك الدقيقة:**

**خطوة 1 - فهم السؤال:**
- افهم بالضبط ماذا يطلب السؤال
- مثال: إذا كان السؤال "اذكر لاعبين برازيليين لعبوا لريال مدريد" → الإجابة يجب أن تكون لاعبين برازيليين + لعبوا لريال مدريد فقط

**خطوة 2 - تحليل كل إجابة:**
- تحقق من كل إجابة بشكل منفصل
- هل الإجابة صحيحة 100%؟
- هل تنطبق على السؤال تماماً؟
- هل هي مكررة؟

**خطوة 3 - قواعد ذكية للإدخال الصوتي:**

**✅ اقبل الأخطاء الإملائية والنطق (تحليل ذكي!):**

**أمثلة على الأخطاء المقبولة:**
- "ماسكيرانو" = "ماسكرانو" ✅ (نفس اللاعب)
- "مسكرانه" = "ماسكرانو" ✅ (خطأ نطق بسيط)
- "دي ماريا" = "دي ماريا" ✅ (نفس اللاعب)
- "ميسى" = "ميسي" ✅ (خطأ إملائي بسيط)
- "رونالدو" = "كريستيانو رونالدو" ✅ (اسم مختصر)
- "سيرجيو راموس" = "راموس" ✅ (اسم مختصر)
- "محمد صلاح" = "صلاح" ✅ (اسم مختصر)
- "كريم بنزيما" = "بنزيما" ✅ (اسم مختصر)

**🔍 كيف تحلل الأسماء المشابهة:**
1. قارن الاسم صوتياً (كيف ينطق)
2. تحقق من التشابه الإملائي (80% تشابه على الأقل)
3. تحقق من الاسم المختصر (الكنية أو اسم العائلة فقط)
4. إذا كان الاسم قريب جداً → اعتبره صحيح ✅

**❌ لا تقبل (خطأ واضح في المعنى):**
- إجابة خاطئة تماماً (نيمار عندما السؤال عن لاعبي ريال مدريد - نيمار لم يلعب لريال)
- إجابة مكررة (نفس اللاعب مرتين)
- إجابة غامضة (اسم غير واضح أو غير معروف)
- لاعب من نادي/دولة خاطئة تماماً

**⚡ القاعدة الذهبية:**
- إذا كان الاسم **قريب جداً** من اسم لاعب صحيح (80%+ تشابه) → اقبله ✅
- إذا كان الاسم مختصر للاعب صحيح → اقبله ✅
- إذا كان خطأ نطق بسيط من الإدخال الصوتي → اقبله ✅
- فقط ارفض الأخطاء الواضحة في **المعنى** وليس **الشكل**!

**خطوة 4 - التنسيق:**
أرجع JSON فقط:
{
  "correctCount": <عدد الإجابات الصحيحة فقط>,
  "correctAnswers": ["<قائمة الإجابات الصحيحة>"],
  "wrongAnswers": ["<قائمة الإجابات الخاطئة مع السبب>"],
  "analysis": "<تحليل مختصر: X إجابات صحيحة من Y>"
}

**مثال 1 - أخطاء نطق (اقبلها!):**
إجابات: ["رونالدو", "مارسيلو", "كاسيميرو", "فينيسيس"]
السؤال: "اذكر لاعبين برازيليين لعبوا لريال مدريد"

التحليل الصحيح:
{
  "correctCount": 4,
  "correctAnswers": ["رونالدو", "مارسيلو", "كاسيميرو", "فينيسيوس (فينيسيس)"],
  "wrongAnswers": [],
  "analysis": "4 إجابات صحيحة من 4. 'فينيسيس' هو خطأ نطق لـ 'فينيسيوس' - مقبول!"
}

**مثال 2 - خطأ حقيقي (ارفضه!):**
إجابات: ["رونالدو", "مارسيلو", "نيمار", "كاسيميرو"]
السؤال: "اذكر لاعبين برازيليين لعبوا لريال مدريد"

التحليل الصحيح:
{
  "correctCount": 3,
  "correctAnswers": ["رونالدو", "مارسيلو", "كاسيميرو"],
  "wrongAnswers": ["نيمار - لم يلعب لريال مدريد (لعب لبرشلونة)"],
  "analysis": "3 إجابات صحيحة من 4. نيمار لم يلعب لريال مدريد."
}

**مثال 3 - أسماء مختصرة (اقبلها!):**
إجابات: ["ميسي", "مارادونا", "مسكرانه", "اجويرو"]
السؤال: "اذكر لاعبين أرجنتينيين لعبوا لبرشلونة"

التحليل الصحيح:
{
  "correctCount": 3,
  "correctAnswers": ["ميسي", "ماسكرانو (مسكرانه)", "أجويرو (اجويرو)"],
  "wrongAnswers": ["مارادونا - لم يلعب لبرشلونة"],
  "analysis": "3 إجابات صحيحة من 4. 'مسكرانه' هو خطأ نطق لـ 'ماسكرانو' - مقبول!"
}

**⚠️ مهم جداً:**
- كن دقيقاً 100% في التحليل
- لا تتساهل مع الإجابات الخاطئة
- العدد في correctCount يجب أن يكون دقيق تماماً!

أرجع JSON فقط، بدون أي نص قبله أو بعده!
''' : '''
You are a precise analyzer for auction game answers.

**Question:**
$question

**Required Count:** $requiredCount
**Total Correct Count:** $correctCount

**Player's Answers:**
${playerAnswers.map((a) => '- $a').join('\n')}

**Your Task:**
1. Analyze each answer precisely
2. Verify correctness (does it match the question?)
3. Count only correct answers
4. Accept spelling/pronunciation errors but reject factually wrong answers

**✅ ACCEPT (Smart Analysis for Voice Input):**

**Examples of ACCEPTABLE errors:**
- "Mascherano" = "Masch eran o" ✅ (pronunciation error)
- "Di Maria" = "DiMaria" ✅ (spacing error)
- "Messi" = "Messy" ✅ (spelling error)
- "Ronaldo" = "Cristiano Ronaldo" ✅ (shortened name)
- "Sergio Ramos" = "Ramos" ✅ (surname only)
- "Mohamed Salah" = "Salah" ✅ (surname only)

**🔍 How to Analyze Similar Names:**
1. Compare phonetically (how it sounds)
2. Check spelling similarity (80%+ match)
3. Check shortened names (nickname or surname)
4. If very similar → accept ✅

**❌ REJECT (Clear factual errors):**
- Completely wrong player (Neymar for Real Madrid question - Neymar never played for Real)
- Duplicate answer (same player twice)
- Wrong club/country entirely
- Unclear/unknown name

**⚡ Golden Rule:**
- Accept **form/pronunciation** errors ✅
- Reject **factual/meaning** errors ❌
- If 80%+ similar to correct name → accept ✅

**Format (JSON only):**
{
  "correctCount": <number of correct answers>,
  "correctAnswers": [<list of correct answers>],
  "wrongAnswers": [<list of wrong answers>],
  "analysis": "<brief analysis>"
}

Return JSON only, no extra text!
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return {'correctCount': 0};
      }
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final result = jsonDecode(cleaned);
      print('✅ Analysis: ${result['correctCount']} correct out of ${playerAnswers.length}');
      
      return {
        'correctCount': result['correctCount'] ?? 0,
        'correctAnswers': result['correctAnswers'] ?? [],
        'wrongAnswers': result['wrongAnswers'] ?? [],
        'analysis': result['analysis'] ?? '',
      };
      
    } catch (e) {
      print('❌ Error analyzing answers: $e');
      return {'correctCount': 0};
    }
  }
  
  /// توليد إجابات للكمبيوتر في لعبة المزاد
  Future<List<String>> generateAuctionAnswersForComputer({
    required String question,
    required int requiredCount,
    String language = 'ar',
  }) async {
    try {
      print('🤖 Generating $requiredCount answers for computer...');
      
      final prompt = language == 'ar' ? '''
أنت كمبيوتر يلعب لعبة المزاد الكروية.

**السؤال:**
$question

**المطلوب:**
أعطني $requiredCount إجابة صحيحة للسؤال أعلاه.

**التعليمات:**
- أعطني إجابات صحيحة 100%
- لا تكرر الإجابات
- كن دقيقاً
- إجابات مباشرة بدون شرح

**التنسيق (JSON فقط):**
{
  "answers": ["إجابة 1", "إجابة 2", ...]
}

أرجع JSON فقط، بدون أي نص إضافي!
''' : '''
You are a computer playing the auction game.

**Question:**
$question

**Required:**
Give me $requiredCount correct answers to the question above.

**Instructions:**
- Provide 100% correct answers
- No duplicates
- Be precise
- Direct answers without explanations

**Format (JSON only):**
{
  "answers": ["answer 1", "answer 2", ...]
}

Return JSON only, no extra text!
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return [];
      }
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final result = jsonDecode(cleaned);
      final answers = (result['answers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      print('🤖 Computer generated ${answers.length} answers: $answers');
      
      return answers;
      
    } catch (e) {
      print('❌ Error generating computer answers: $e');
      return [];
    }
  }
  
  /// استخراج أسماء اللاعبين من النص الصوتي
  Future<List<String>> extractPlayerNamesFromVoice({
    required String voiceText,
    required String question,
    String language = 'ar',
  }) async {
    try {
      print('🎤 Extracting player names from voice text: "$voiceText"');
      
      final prompt = language == 'ar' ? '''
أنت مستخرج ذكي لأسماء اللاعبين من النص الصوتي.

**السؤال:**
$question

**النص المنطوق:**
"$voiceText"

**مهمتك:**
1. استخرج جميع أسماء اللاعبين/الأندية/المدربين المذكورة في النص
2. تجاهل الكلمات الزائدة مثل: "أعتقد", "ربما", "أيضاً", "و", إلخ
3. صحح الأخطاء الإملائية البسيطة في الأسماء
4. أعد قائمة نظيفة بالأسماء فقط

**أمثلة:**

**مثال 1:**
النص: "رونالدو و ميسي و نيمار أيضاً"
الاستخراج: ["رونالدو", "ميسي", "نيمار"]

**مثال 2:**
النص: "أعتقد أن ريال مدريد وبرشلونة وبايرن ميونخ"
الاستخراج: ["ريال مدريد", "برشلونة", "بايرن ميونخ"]

**مثال 3:**
النص: "زيدان كان مدرب جيد وأنشيلوتي أيضاً ومورينيو"
الاستخراج: ["زيدان", "أنشيلوتي", "مورينيو"]

**التنسيق (JSON فقط):**
{
  "names": ["اسم 1", "اسم 2", ...]
}

**⚠️ مهم:**
- استخرج الأسماء فقط، لا شرح
- صحح الأخطاء الإملائية
- لا تضف أسماء غير موجودة في النص
- أرجع JSON فقط بدون أي نص إضافي

استخرج الأسماء الآن:
''' : '''
You are a smart player name extractor from voice text.

**Question:**
$question

**Spoken Text:**
"$voiceText"

**Your Task:**
1. Extract all player/club/coach names mentioned in the text
2. Ignore filler words like: "I think", "maybe", "also", "and", etc.
3. Fix minor spelling errors in names
4. Return a clean list of names only

**Examples:**

**Example 1:**
Text: "Ronaldo and Messi and also Neymar"
Extraction: ["Ronaldo", "Messi", "Neymar"]

**Example 2:**
Text: "I think Real Madrid and Barcelona and Bayern Munich"
Extraction: ["Real Madrid", "Barcelona", "Bayern Munich"]

**Example 3:**
Text: "Zidane was a good coach and also Ancelotti and Mourinho"
Extraction: ["Zidane", "Ancelotti", "Mourinho"]

**Format (JSON only):**
{
  "names": ["name 1", "name 2", ...]
}

**⚠️ Important:**
- Extract names only, no explanations
- Fix spelling errors
- Don't add names not in the text
- Return JSON only, no extra text

Extract the names now:
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return [];
      }
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final result = jsonDecode(cleaned);
      final names = (result['names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      print('✅ Extracted ${names.length} names: $names');
      
      return names;
      
    } catch (e) {
      print('❌ Error extracting names from voice: $e');
      return [];
    }
  }
  
  /// توليد أسئلة لعبة المزاد
  Future<List<Map<String, dynamic>>> generateAuctionQuestions({
    required int count,
    String language = 'ar',
    String difficulty = 'mixed',
    int? seed,
  }) async {
    // إعادة المحاولة حتى 3 مرات إذا كانت الأسئلة بلغة خاطئة
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('🎪 Attempt $attempt/3: Generating $count auction questions in $language (difficulty: $difficulty, seed: $seed)...');
        
        final prompt = _buildAuctionPrompt(count, language, difficulty, seed);
        
        final response = await _model.generateContent([Content.text(prompt)]);
        final text = response.text;
        
        if (text == null || text.isEmpty) {
          print('❌ Empty response from Gemini');
          continue; // حاول مرة أخرى
        }
        
        print('📥 Received response, parsing...');
        
        // استخراج JSON من الرد
        String cleaned = text.trim();
        if (cleaned.startsWith('```json')) {
          cleaned = cleaned.substring(7);
        } else if (cleaned.startsWith('```')) {
          cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.length - 3);
        }
        cleaned = cleaned.trim();
        
        final jsonList = jsonDecode(cleaned) as List;
        
        final questions = jsonList.map((item) {
          return {
            'id': _generateId(),
            'question': item['question'] as String,
            'correctAnswer': item['correctAnswer'] as int,
            'difficulty': item['difficulty'] ?? 2,
          };
        }).toList();
      
        // ✅ فلترة الأسئلة السيئة والتحقق من اللغة
        final filteredQuestions = questions.where((q) {
          final question = (q['question'] as String).toLowerCase();
          final originalQuestion = q['question'] as String;
          
          // فلترة الأسئلة العربية
          if (language == 'ar') {
            // ✅ التحقق الصارم: يجب أن يحتوي على حروف عربية
            final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(originalQuestion);
            if (!hasArabic) {
              print('⚠️ [$attempt] تم تجاهل سؤال ليس بالعربية: $originalQuestion');
              return false;
            }
            
            // ✅ التحقق من عدم وجود كلمات إنجليزية كثيرة
            final englishWords = RegExp(r'\b[a-zA-Z]{3,}\b').allMatches(originalQuestion).length;
            if (englishWords > 2) { // السماح بكلمتين إنجليزيتين فقط (أسماء)
              print('⚠️ [$attempt] تم تجاهل سؤال يحتوي على كلمات إنجليزية كثيرة: $originalQuestion');
              return false;
            }
            
            // رفض أسئلة "كم"
            if (question.contains('كم ') || 
                question.contains('كم؟') || 
                question.startsWith('كم') ||
                question.contains('عدد الأهداف') ||
                question.contains('عدد البطولات') ||
                question.contains('كم هدف') ||
                question.contains('كم مرة')) {
              print('⚠️ [$attempt] تم تجاهل سؤال سيئ: $originalQuestion');
              return false;
            }
          }
          
          // فلترة الأسئلة الإنجليزية
          if (language == 'en') {
            // التحقق من أن السؤال بالإنجليزية
            final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(originalQuestion);
            if (!hasEnglish) {
              print('⚠️ [$attempt] Ignored non-English question: $originalQuestion');
              return false;
            }
            
            // التحقق من عدم وجود حروف عربية
            final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(originalQuestion);
            if (hasArabic) {
              print('⚠️ [$attempt] Ignored question with Arabic: $originalQuestion');
              return false;
            }
            
            if (question.contains('how many ') ||
                question.startsWith('how many') ||
                question.contains('how many goals') ||
                question.contains('how many times') ||
                question.contains('how many trophies')) {
              print('⚠️ [$attempt] Ignored bad question: $originalQuestion');
              return false;
            }
          }
          
          // فلترة الأسئلة التركية
          if (language == 'tr') {
            // التحقق من عدم وجود حروف عربية
            final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(originalQuestion);
            if (hasArabic) {
              print('⚠️ [$attempt] Arapça içeren soru göz ardı edildi: $originalQuestion');
              return false;
            }
            
            if (question.contains('kaç ') ||
                question.contains('kaç?') ||
                question.startsWith('kaç') ||
                question.contains('kaç gol') ||
                question.contains('kaç kez') ||
                question.contains('kaç kupa')) {
              print('⚠️ [$attempt] Kötü soru göz ardı edildi: $originalQuestion');
              return false;
            }
          }
          
          return true;
        }).toList();
        
        print('📊 [$attempt] Filtered ${filteredQuestions.length} valid questions from ${questions.length}');
        
        // ✅ إذا كان لدينا أسئلة كافية باللغة الصحيحة، أرجعها
        if (filteredQuestions.length >= count * 0.5) { // على الأقل 50% من الأسئلة صحيحة
          print('✅ [$attempt] Successfully generated ${filteredQuestions.length} auction questions in $language');
          return filteredQuestions;
        } else {
          print('⚠️ [$attempt] Not enough valid questions (${filteredQuestions.length}/${count}). Retrying...');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 1)); // انتظر قليلاً قبل إعادة المحاولة
            continue;
          }
        }
        
      } catch (e) {
        print('❌ [$attempt] Error generating auction questions: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 1));
          continue;
        }
      }
    }
    
    // إذا فشلت كل المحاولات
    print('❌ Failed to generate valid auction questions after 3 attempts');
    return [];
  }
  
  String _buildAuctionPrompt(int count, String language, String difficulty, int? seed) {
    final seedInfo = seed != null ? '''

**🎲 معرف التوليد الفريد: $seed**

⚠️ **تعليمات التنويع الصارمة:**
- هذا معرف فريد - استخدمه لتوليد أسئلة مختلفة تماماً
- ❌ لا تكرر أسئلة مثل: "اذكر لاعبين برازيليين لعبوا لريال مدريد"
- ✅ نوّع الجنسيات: برازيليين، أرجنتينيين، مصريين، جزائريين، فرنسيين، إيطاليين، ألمان...
- ✅ نوّع الأندية: ريال مدريد، برشلونة، مانشستر يونايتد، ليفربول، بايرن، ميلان، إنتر...
- ✅ نوّع الدوريات: الإنجليزي، الإسباني، الألماني، الإيطالي، الفرنسي...
- ✅ نوّع الفترات الزمنية: منذ 2000، منذ 2010، في التسعينات، في الثمانينات...
- ✅ نوّع المواضيع: لاعبين، مدربين، أندية، دول، بطولات، حراس، مدافعين...
- ✅ كن إبداعياً! اختر زوايا مختلفة للأسئلة
''' : '';
    
    if (language == 'ar') {
      String difficultyGuidelines = '';
      if (difficulty == 'easy') {
        difficultyGuidelines = '''
**📊 مستوى سهل:**
- الإجابة بين 3-15
- أسئلة بسيطة ومعروفة
- ✅ مثال صحيح: "اذكر دول فازت بكأس العالم" (correctAnswer: 8)
- ✅ مثال صحيح: "اذكر أندية فازت بدوري الأبطال أكثر من 5 مرات" (correctAnswer: 6)
''';
      } else if (difficulty == 'hard') {
        difficultyGuidelines = '''
**📊 مستوى صعب:**
- الإجابة بين 30-100+
- أسئلة تحتاج معرفة عميقة
- ✅ مثال صحيح: "اذكر لاعبين أرجنتينيين لعبوا في الدوري الإنجليزي" (correctAnswer: 35)
- ✅ مثال صحيح: "اذكر مدافعين برازيليين لعبوا في أوروبا منذ 2000" (correctAnswer: 50)
''';
      } else {
        difficultyGuidelines = '''
**📊 مستوى متنوع:**
- مزيج من الأسئلة السهلة (3-15) والمتوسطة (15-30) والصعبة (30-100+)
- تنويع في الصعوبة
''';
      }
      
      return '''
🚨🚨🚨 **تحذير صارم: اللغة العربية فقط!** 🚨🚨🚨

⛔ **محظورات صارمة:**
- ❌ ممنوع منعاً باتاً استخدام اللغة الإنجليزية في الأسئلة
- ❌ ممنوع كتابة الأسئلة بالإنجليزية
- ❌ ممنوع خلط العربية والإنجليزية
- ❌ إذا كتبت سؤال بالإنجليزية سيتم رفضه تلقائياً

✅ **مطلوب:**
- ✅ جميع الأسئلة بالعربية 100%
- ✅ استخدم الحروف العربية فقط: ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي
- ✅ الأسماء بالعربية: ميسي، رونالدو، ريال مدريد، برشلونة، مانشستر يونايتد
- ✅ الصيغ العربية: "اذكر"، "لاعبين"، "أندية"، "مدربين"

**مثال خاطئ (ممنوع!):**
❌ "Name Brazilian players who played for Real Madrid"

**مثال صحيح (مطلوب!):**
✅ "اذكر لاعبين برازيليين لعبوا لريال مدريد"

أنشئ $count أسئلة لعبة "المزاد" **بالعربية فقط**.$seedInfo

$difficultyGuidelines

**🎪 نوع اللعبة:**
- لعبة مزاد تنافسية
- يُطرح سؤال يتطلب **تعداد أسماء** (أسماء لاعبين، أندية، مدربين، إلخ)
- اللاعبان يتزايدان على عدد الأسماء التي يمكنهم ذكرها
- من يفوز بالمزاد يجب أن **يذكر الأسماء** بالتفصيل (وليس مجرد رقم!)

**⚠️⚠️⚠️ مهم جداً - قواعد صارمة:**
- ❌❌❌ ممنوع منعاً باتاً: أي سؤال يبدأ بـ "كم" أو "كم عدد"
- ❌ لا تطرح أسئلة عن "عدد الأهداف" أو "عدد البطولات" (الإجابة رقم فقط!)
- ❌ لا تطرح أسئلة مثل: "كم هدف سجل كريستيانو؟" - ممنوع!
- ❌ لا تطرح أسئلة مثل: "كم مرة فاز ريال مدريد؟" - ممنوع!
- ✅✅✅ فقط اطرح أسئلة عن "أسماء اللاعبين" أو "أسماء الأندية" (الإجابة قائمة أسماء!)
- ✅ استخدم صيغة: "اذكر لاعبين..." أو "اذكر أندية..." أو "اذكر مدربين..."
- اللاعب يجب أن يذكر **أسماء** وليس أرقام!

**📊 توزيع الأسئلة المطلوب:**
- **70% أسئلة محددة وصعبة** (مجال ضيق ومحصور) 🔥
- **30% أسئلة متنوعة** (عامة)

**🎯 أنواع الأسئلة المحددة (70% - أولوية عالية):**

**⚠️ مهم جداً عن صيغة السؤال:**
- ❌ لا تكتب: "كم لاعب برازيلي..." أو "كم مدرب..."
- ❌ لا تضع العدد في السؤال: "اذكر 5 لاعبين..." أو "اذكر أسماء 10 مدربين..."
- ❌ لا تضع ملاحظة في السؤال: "(يجب أن يكون الإجابة 10)"
- ✅ استخدم فقط: "اذكر لاعبين برازيليين لعبوا لريال مدريد"
- ✅ السؤال نظيف بدون أي أرقام أو توضيحات!
- ✅ العدد الصحيح يكون في `correctAnswer` فقط!

**💡 أفكار متنوعة للأسئلة (نوّع بينها!):**

**النوع 1 - لاعبون في أندية (نوّع الجنسيات والأندية!):**
- لاعبون برازيليون/أرجنتينيون/مصريون/فرنسيون/ألمان/إيطاليون/إسبان
- في أندية: ريال مدريد، برشلونة، مانشستر يونايتد، ليفربول، بايرن، ميلان، يوفنتوس، تشيلسي، أرسنال...
- فترات: في التاريخ، منذ 2000، منذ 2010، في التسعينات...

**النوع 2 - مراكز معينة:**
- حراس مرمى، مدافعون، لاعبو وسط، مهاجمون
- في أندية مختلفة

**النوع 3 - إنجازات:**
- لاعبون فازوا بكأس العالم والكرة الذهبية
- لاعبون سجلوا في نهائيات دوري الأبطال
- لاعبون لعبوا في 3 دوريات كبرى مختلفة

**النوع 4 - أندية:**
- أندية فازت بدوريات محددة (الإنجليزي، الإسباني، الإيطالي، الألماني...)
- أندية فازت ببطولات أوروبية
- أندية عربية/آسيوية/أفريقية

**النوع 5 - مدربون:**
- مدربون درّبوا أندية معينة
- مدربون فازوا ببطولات
- مدربون من جنسيات معينة

**النوع 6 - دول:**
- دول فازت ببطولات (كأس العالم، كأس أمم...)
- دول شاركت في مونديالات

**النوع 7 - أسئلة إبداعية:**
- لاعبون انتقلوا بين ناديَيْ المدينة نفسها (مانشستر، مدريد، ميلان...)
- لاعبون لعبوا لمنتخبات مختلفة
- لاعبون بدأوا ثم عادوا لنفس النادي

**🎯 أنواع الأسئلة العامة (30%):**
1. اذكر دول فازت بكأس العالم (8 دول)
2. اذكر لاعبين فازوا بالكرة الذهبية منذ 2000 (8-12 لاعب)
3. اذكر أندية فازت بدوري الأبطال أكثر من 5 مرات (5-7 أندية)

**⚠️ متطلبات صارمة:**
1. السؤال يجب أن يكون واضح ومحدد
2. الإجابة يجب أن تكون **قائمة أسماء** (ليس مجرد رقم!)
3. اللاعب يجب أن يذكر الأسماء بالتفصيل (مثل: ميسي، رونالدو، نيمار...)
4. **لا أسئلة عن "كم هدف" أو "كم بطولة"** - فقط أسئلة عن الأسماء!
5. العدد يجب أن يكون معقول (3-20) حتى يمكن اللعب
6. **تأكد 100% من دقة العدد** - تحقق 3 مرات!

**❌❌❌ أمثلة خاطئة (لا تفعل هذا!):**

❌ خطأ 1 - وضع عدد في السؤال:
{
  "question": "اذكر أسماء 5 لاعبين برازيليين لعبوا لريال مدريد",  ← ممنوع!
  "correctAnswer": 12,
  "difficulty": 2
}

❌ خطأ 2 - وضع ملاحظة في السؤال:
{
  "question": "اذكر مدربين درّبوا ريال مدريد منذ 2010 (يجب أن يكون الإجابة 10 مدربين)",  ← ممنوع!
  "correctAnswer": 10,
  "difficulty": 2
}

❌ خطأ 3 - استخدام "كم":
{
  "question": "كم لاعب برازيلي لعب لريال مدريد؟",  ← ممنوع!
  "correctAnswer": 12,
  "difficulty": 2
}

**✅✅✅ أمثلة متنوعة (كل مرة اختر أمثلة مختلفة!):**

**مجموعة أمثلة 1 (لا تستخدمها دائماً!):**
1. اذكر لاعبين إيطاليين لعبوا لليوفنتوس (correctAnswer: 15)
2. اذكر أندية إنجليزية فازت بالدوري الأوروبي منذ 2000 (correctAnswer: 8)
3. اذكر مهاجمين أفارقة لعبوا في الدوري الإسباني (correctAnswer: 10)

**مجموعة أمثلة 2 (نوّع!):**
1. اذكر لاعبين ألمان لعبوا لبايرن ميونخ (correctAnswer: 18)
2. اذكر مدربين إيطاليين درّبوا في الدوري الإنجليزي (correctAnswer: 9)
3. اذكر أندية فرنسية فازت بالدوري الفرنسي منذ 2010 (correctAnswer: 7)

**مجموعة أمثلة 3 (إبداع!):**
1. اذكر لاعبين انتقلوا من برشلونة لريال مدريد أو العكس (correctAnswer: 6)
2. اذكر حراس مرمى لعبوا لأرسنال منذ 2000 (correctAnswer: 8)
3. اذكر دول أفريقية تأهلت لكأس العالم 2022 (correctAnswer: 5)

**مجموعة أمثلة 4 (تنوع جغرافي!):**
1. اذكر لاعبين سنغاليين لعبوا في الدوريات الأوروبية الكبرى (correctAnswer: 12)
2. اذكر أندية هولندية فازت بدوري الأبطال (correctAnswer: 4)
3. اذكر لاعبين بلجيكيين لعبوا لتشيلسي (correctAnswer: 7)

**مجموعة أمثلة 5 (تاريخية!):**
1. اذكر لاعبين فازوا بكرة اليورو الذهبية (correctAnswer: 9)
2. اذكر أندية أوروبية فازت بثلاثية في موسم واحد (correctAnswer: 8)
3. اذكر مدربين فازوا بدوري الأبطال مع ناديين مختلفين (correctAnswer: 5)

⚠️ **مهم:** استخدم seed ($seed) لاختيار مجموعة أمثلة مختلفة في كل مرة!

**❌ أمثلة سيئة (تجنبها بشدة!):**
❌ "كم هدف سجل ميسي في كأس العالم 2022؟" - الإجابة رقم فقط (7)! ليست قائمة أسماء!
❌ "كم مرة فاز ريال مدريد بدوري الأبطال؟" - الإجابة رقم فقط (14)! ليست أسماء!
❌ "كم بطولة فاز بها برشلونة؟" - رقم فقط! ممنوع!
❌ "كم لاعب مشهور؟" - غير محدد!
❌ "كم لاعب برازيلي في أوروبا؟" - مجال واسع جداً! استخدم نادي محدد
❌ "كم هدف سجل في الموسم؟" - رقم فقط وليس أسماء!

**✅ أمثلة ممتازة (تتطلب ذكر أسماء):**
✅ "اذكر لاعبين برازيليين لعبوا لريال مدريد" - يحتاج ذكر: رونالدو، كاسيميرو، إلخ
✅ "اذكر دول فازت بكأس العالم" - يحتاج ذكر: البرازيل، ألمانيا، إلخ
✅ "اذكر أندية فازت بالدوري الإنجليزي منذ 2010" - يحتاج ذكر الأسماء
✅ "اذكر مدربين درّبوا برشلونة منذ 2000" - يحتاج ذكر الأسماء

**🎯 قاعدة ذهبية:**
- ❌ إذا كانت الإجابة مجرد **رقم** (مثل: 7، 14، 450) = ممنوع!
- ✅ إذا كانت الإجابة **قائمة أسماء** (مثل: ميسي، رونالدو، نيمار) = ممتاز!
- **70% محددة** (مجال ضيق) + **30% عامة**
- العدد بين **3-20** (معقول للعب)

**التنسيق (JSON فقط):**
[
  {
    "question": "السؤال بالعربية",
    "correctAnswer": 15,
    "difficulty": 2
  }
]

**ملاحظة مهمة:** أرجع JSON array فقط، بدون أي نص إضافي!
''';
    } else if (language == 'en') {
      String difficultyGuidelines = '';
      if (difficulty == 'easy') {
        difficultyGuidelines = '''
**📊 Easy Level:**
- Answer between 3-15
- Simple and well-known questions
- ✅ Correct example: "Name countries that won the World Cup" (correctAnswer: 8)
- ✅ Correct example: "Name clubs that won Champions League more than 5 times" (correctAnswer: 6)
''';
      } else if (difficulty == 'hard') {
        difficultyGuidelines = '''
**📊 Hard Level:**
- Answer between 30-100+
- Questions requiring deep knowledge
- ✅ Correct example: "Name Argentine players who played in Premier League" (correctAnswer: 35)
- ✅ Correct example: "Name Brazilian defenders who played in Europe since 2000" (correctAnswer: 50)
''';
      } else {
        difficultyGuidelines = '''
**📊 Mixed Level:**
- Mix of easy (3-15), medium (15-30), and hard (30-100+) questions
- Variety in difficulty
''';
      }
      
      return '''
⚠️⚠️⚠️ **CRITICAL: English Language Only!** ⚠️⚠️⚠️
- ALL questions must be in English 100%
- Do NOT use Arabic or any other language
- Use English names for players and clubs (e.g., Messi, Real Madrid, Barcelona)

Create $count questions for "The Auction" game in English only.$seedInfo

$difficultyGuidelines

**🎪 Game Type:**
- Competitive auction game
- A question requires **listing NAMES** (names of players, clubs, managers, etc.)
- Two players bid on how many NAMES they can list
- Auction winner must **list the NAMES** in detail (not just a number!)

**⚠️⚠️⚠️ VERY IMPORTANT - STRICT RULES:**
- ❌❌❌ ABSOLUTELY FORBIDDEN: Any question starting with "How many"
- ❌ NO questions about "how many goals" or "how many trophies" (answer is just a number!)
- ❌ NO questions like: "How many goals did Ronaldo score?" - FORBIDDEN!
- ❌ NO questions like: "How many times did Real Madrid win?" - FORBIDDEN!
- ✅✅✅ ONLY ask questions about "name players" or "name clubs" (answer is a list of names!)
- ✅ Use format: "Name players..." or "Name clubs..." or "Name managers..."
- Player must list **NAMES** not numbers!

**📊 Required Distribution:**
- **70% specific & challenging questions** (narrow scope) 🔥
- **30% general questions**

**🎯 Specific Question Types (70% - HIGH PRIORITY):**

**⚠️ CRITICAL - Question Format:**
- ❌ DON'T write: "How many Brazilian players..." or "How many managers..."
- ❌ DON'T put count in question: "Name 5 players..." or "Name 10 managers..."
- ❌ DON'T add notes in question: "(must be 10 answers)" or "(answer should be 8)"
- ✅ ONLY use: "Name Brazilian players who played for Real Madrid"
- ✅ Question must be clean without ANY numbers or clarifications!
- ✅ The correct count goes ONLY in `correctAnswer` field!

**Type 1 - Players in specific club:**
1. Name Brazilian players who played for Real Madrid (10-15 players)
2. Name Argentine players who played for Barcelona since 2000 (8-12 players)
3. Name goalkeepers who played for Manchester United since 2000 (6-10)
4. Name Egyptian players who played in Premier League (5-10)

**Type 2 - Players with specific achievement:**
1. Name players who won World Cup and Ballon d'Or in same year (5-8 players)
2. Name players who scored in 5 different Champions League finals (3-5)
3. Name goalkeepers who won Ballon d'Or (1 - Yashin)

**Type 3 - Clubs in specific league:**
1. Name clubs that won Premier League since 2010 (5-6 clubs)
2. Name clubs that won Champions League since 2010 (8-10 clubs)
3. Name Arab clubs that participated in Club World Cup (5-8)

**Type 4 - Managers in specific club:**
1. Name managers who coached Real Madrid since 2010 (8-12)
2. Name managers who coached Barcelona since 2000 (10-15)
3. Name managers who won Champions League with English club (6-10)

**Type 5 - Players from specific nationality:**
1. Name Egyptian players who played in Premier League (5-10)
2. Name Algerian players who played in Ligue 1 (10-15)
3. Name Saudi players who played in La Liga (3-6)

**🎯 General Questions (30% only):**
1. Name countries that won World Cup (8 countries)
2. Name players who won Ballon d'Or since 2010 (5-8 players)
3. Name clubs that won Champions League more than 5 times (5-7)

**⚠️ Strict Requirements:**
1. Question must be clear and specific
2. Answer must be **list of NAMES** (not just a number!)
3. Player must list the names in detail (e.g., Messi, Ronaldo, Neymar...)
4. **NO questions about "how many goals" or "how many trophies"** - only about names!
5. Count must be reasonable (3-20) to make it playable
6. **Verify accuracy 100%** - check 3 times!

**✅ Excellent Examples (require listing NAMES):**

Example 1:
{
  "question": "Name Brazilian players who played for Real Madrid",
  "correctAnswer": 12,
  "difficulty": 2
}
[Answer: Ronaldo, Roberto Carlos, Marcelo, Casemiro, Vinicius, etc.]

Example 2:
{
  "question": "Name countries that won the World Cup",
  "correctAnswer": 8,
  "difficulty": 1
}
[Answer: Brazil, Germany, Italy, Argentina, France, Spain, England, Uruguay]

Example 3:
{
  "question": "Name clubs that won Premier League since 2010",
  "correctAnswer": 6,
  "difficulty": 2
}
[Answer: Man City, Chelsea, Man United, Leicester, Liverpool, Arsenal]

Example 4:
{
  "question": "Name managers who coached Real Madrid since 2010",
  "correctAnswer": 10,
  "difficulty": 2
}
[Answer: Mourinho, Ancelotti, Zidane, Benitez, Lopetegui, etc.]

**❌ Bad Examples (AVOID!):**
❌ "How many goals did Messi score in World Cup 2022?" - Answer is just number (7)! Not names!
❌ "How many times did Real Madrid win Champions League?" - Number only (14)! Forbidden!
❌ "How many trophies Barcelona won?" - Number only! Not allowed!
❌ "How many famous players?" - Not specific!

**✅ Golden Rule:**
- ❌ If answer is just a **number** (like 7, 14, 450) = FORBIDDEN!
- ✅ If answer is **list of NAMES** (like Messi, Ronaldo, Neymar) = EXCELLENT!

**Format (JSON only):**
[
  {
    "question": "Question in English",
    "correctAnswer": 15,
    "difficulty": 2
  }
]

**Important:** Return JSON array only, no extra text!
''';
    } else {
      // Turkish
      String difficultyGuidelines = '';
      if (difficulty == 'easy') {
        difficultyGuidelines = '''
**📊 Kolay Seviye:**
- Cevap 3-15 arası
- Basit ve bilinen sorular
- ✅ Doğru örnek: "Dünya Kupası kazanan ülkeleri sayın" (correctAnswer: 8)
- ✅ Doğru örnek: "5'ten fazla Şampiyonlar Ligi kazanan kulüpleri sayın" (correctAnswer: 6)
''';
      } else if (difficulty == 'hard') {
        difficultyGuidelines = '''
**📊 Zor Seviye:**
- Cevap 30-100+ arası
- Derin bilgi gerektiren sorular
- ✅ Doğru örnek: "Premier League'de oynayan Arjantinli oyuncuları sayın" (correctAnswer: 35)
- ✅ Doğru örnek: "2000'den beri Avrupa'da oynayan Brezilyalı savunma oyuncularını sayın" (correctAnswer: 50)
''';
      } else {
        difficultyGuidelines = '''
**📊 Karışık Seviye:**
- Kolay (3-15), orta (15-30) ve zor (30-100+) soruların karışımı
- Zorlukta çeşitlilik
''';
      }
      
      return '''
⚠️⚠️⚠️ **ÖNEMLİ: Sadece Türkçe!** ⚠️⚠️⚠️
- Tüm sorular %100 Türkçe olmalı
- İngilizce veya başka bir dil kullanmayın
- Oyuncular ve kulüpler için Türkçe isimler kullanın

"Müzayede" oyunu için Türkçe'de $count soru oluşturun.$seedInfo

$difficultyGuidelines

**🎪 Oyun Türü:**
- Rekabetçi müzayede oyunu
- Soru **isimlerin listelenmesini** gerektirir (oyuncu, kulüp, teknik direktör isimleri vs.)
- İki oyuncu kaç isim sayabilecekleri üzerine teklif verir
- Müzayedeyi kazanan **isimleri detaylı olarak** saymalı (sadece sayı değil!)

**⚠️⚠️⚠️ ÇOK ÖNEMLİ - KATÎ KURALLAR:**
- ❌❌❌ KESINLIKLE YASAK: "Kaç" ile başlayan sorular
- ❌ "Kaç gol" veya "kaç kupa" hakkında sorular yasak (cevap sadece sayı!)
- ❌ "Ronaldo kaç gol attı?" gibi sorular - YASAK!
- ❌ "Real Madrid kaç kez kazandı?" gibi sorular - YASAK!
- ✅✅✅ SADECE "oyuncu isimleri" veya "kulüp isimleri" hakkında sorular sorun (cevap isim listesi!)
- ✅ Format kullanın: "... oyuncuları sayın" veya "... kulüpleri sayın" veya "... teknik direktörleri sayın"
- Oyuncu **isimleri** saymalı, sayı değil!

**📊 Gerekli Dağılım:**
- **%70 spesifik & zorlayıcı sorular** (dar kapsam) 🔥
- **%30 genel sorular**

**✅ Mükemmel Örnekler (İSİMLER gerektirir):**

Örnek 1:
{
  "question": "Real Madrid için oynayan Brezilyalı oyuncuları sayın",
  "correctAnswer": 12,
  "difficulty": 2
}

Örnek 2:
{
  "question": "Dünya Kupası kazanan ülkeleri sayın",
  "correctAnswer": 8,
  "difficulty": 1
}

Örnek 3:
{
  "question": "2010'dan beri Premier League kazanan kulüpleri sayın",
  "correctAnswer": 6,
  "difficulty": 2
}

**Format (sadece JSON):**
[
  {
    "question": "Türkçe soru",
    "correctAnswer": 15,
    "difficulty": 2
  }
]

**Önemli:** Sadece JSON array dön, ekstra metin yok!
''';
    }
  }

  // ========== التحقق من صحة الإجابة مع تدقيق إملائي ==========
  Future<Map<String, dynamic>> validateAnswer({
    required String question,
    required String playerAnswer,
    required List<String> acceptableAnswers,
    String language = 'ar',
  }) async {
    try {
      final prompt = language == 'ar'
          ? '''
تحقق من صحة إجابة اللاعب مع تدقيق إملائي ومعنوي.

السؤال: "$question"
إجابة اللاعب: "$playerAnswer"
الإجابات الصحيحة المقبولة: ${acceptableAnswers.join(', ')}

⚽ التعليمات:
1. قارن إجابة اللاعب مع الإجابات الصحيحة
2. **اقبل الإجابة إذا كانت:**
   - مطابقة تماماً
   - بها أخطاء إملائية بسيطة (1-2 حرف)
   - معنى قريب أو مرادف
   - نفس الاسم بصيغة مختلفة (مثلاً: "الأرجنتين" = "ارجنتين" = "Argentina")
   - نقص أو زيادة حروف بسيطة
   
3. **ارفض الإجابة إذا كانت:**
   - مختلفة تماماً
   - إجابة خاطئة واضحة
   - لا علاقة لها بالسؤال

**Format (JSON only):**
{
  "isCorrect": true/false,
  "reason": "سبب القبول أو الرفض"
}

أرجع JSON فقط.
'''
          : language == 'en'
          ? '''
Verify the correctness of the player's answer with spelling and meaning check.

Question: "$question"
Player's Answer: "$playerAnswer"
Acceptable Correct Answers: ${acceptableAnswers.join(', ')}

⚽ Instructions:
1. Compare player's answer with correct answers
2. **Accept the answer if:**
   - Exact match
   - Minor spelling errors (1-2 characters)
   - Close meaning or synonym
   - Same name in different format (e.g., "Argentina" = "Argentine")
   - Minor missing or extra characters
   
3. **Reject the answer if:**
   - Completely different
   - Clearly wrong
   - Unrelated to the question

**Format (JSON only):**
{
  "isCorrect": true/false,
  "reason": "reason for acceptance or rejection"
}

Return JSON only.
'''
          : '''
Oyuncunun cevabını yazım ve anlam kontrolü ile doğrula.

Soru: "$question"
Oyuncunun Cevabı: "$playerAnswer"
Kabul Edilen Doğru Cevaplar: ${acceptableAnswers.join(', ')}

⚽ Talimatlar:
1. Oyuncunun cevabını doğru cevaplarla karşılaştır
2. **Cevabı kabul et eğer:**
   - Tam eşleşme
   - Küçük yazım hataları (1-2 karakter)
   - Yakın anlam veya eşanlamlı
   - Aynı isim farklı formatta
   - Küçük eksik veya fazla karakterler
   
3. **Cevabı reddet eğer:**
   - Tamamen farklı
   - Açıkça yanlış
   - Soruyla ilgisiz

**Format (sadece JSON):**
{
  "isCorrect": true/false,
  "reason": "kabul veya red nedeni"
}

Sadece JSON döndür.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response from AI');
      
      String cleaned = response.text!.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final Map<String, dynamic> result = jsonDecode(cleaned);
      print('🤖 AI Validation Result: ${result['isCorrect']} - ${result['reason']}');
      
      return result;
    } catch (e) {
      print('❌ Error validating answer with AI: $e');
      // Fallback to simple comparison
      final normalizedAnswer = playerAnswer.toLowerCase().trim();
      final isCorrect = acceptableAnswers.any((acceptable) =>
          normalizedAnswer == acceptable.toLowerCase().trim());
      
      return {
        'isCorrect': isCorrect,
        'reason': isCorrect ? 'Exact match' : 'No match found (fallback)',
      };
    }
  }

  // ========== التحقق من اسم اللاعب بذكاء ==========
  Future<bool> validatePlayerName({
    required String playerAnswer,
    required String correctPlayerName,
    String language = 'ar',
  }) async {
    try {
      String prompt;
      
      if (language == 'ar') {
        prompt = '''
هل إجابة اللاعب صحيحة؟

الإجابة الصحيحة: "$correctPlayerName"
إجابة اللاعب: "$playerAnswer"

⚽ تحقق:
- هل الاسمان متطابقان أو متشابهان؟
- هل توجد أخطاء إملائية بسيطة فقط (1-3 أحرف)؟
- هل الاسم نفسه بصيغة مختلفة؟
- مثال: "محمد صلاح" = "صلاح" = "Mohamed Salah" = "محمد صلح" (خطأ بسيط)

**أرجع فقط:**
- "true" إذا كانت الإجابة صحيحة أو قريبة جداً
- "false" إذا كانت الإجابة خاطئة تماماً
''';
      } else if (language == 'en') {
        prompt = '''
Is the player's answer correct?

Correct Answer: "$correctPlayerName"
Player's Answer: "$playerAnswer"

⚽ Check:
- Are the names matching or similar?
- Are there only minor spelling errors (1-3 characters)?
- Is it the same name in different format?
- Example: "Mohamed Salah" = "Salah" = "محمد صلاح" = "Mohamed Salach" (minor error)

**Return only:**
- "true" if the answer is correct or very close
- "false" if the answer is completely wrong
''';
      } else {
        prompt = '''
Oyuncunun cevabı doğru mu?

Doğru Cevap: "$correctPlayerName"
Oyuncunun Cevabı: "$playerAnswer"

⚽ Kontrol et:
- İsimler eşleşiyor veya benzer mi?
- Sadece küçük yazım hataları var mı (1-3 karakter)?
- Aynı isim farklı formatta mı?
- Örnek: "Mohamed Salah" = "Salah" = "محمد صلاح" = "Mohamed Salach" (küçük hata)

**Sadece döndür:**
- "true" cevap doğruysa veya çok yakınsa
- "false" cevap tamamen yanlışsa
''';
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception('No response');
      
      String result = response.text!.trim().toLowerCase();
      result = result.replaceAll('"', '').replaceAll("'", '').trim();
      
      print('🤖 AI Player Name Validation: "$playerAnswer" vs "$correctPlayerName" = $result');
      
      return result.contains('true');
    } catch (e) {
      print('❌ Error validating player name: $e');
      // Fallback to simple comparison
      final normalized1 = playerAnswer.toLowerCase().trim();
      final normalized2 = correctPlayerName.toLowerCase().trim();
      return normalized1.contains(normalized2) || normalized2.contains(normalized1);
    }
  }
}
