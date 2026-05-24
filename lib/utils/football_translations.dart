/// Comprehensive position mapping: scraped Arabic → Professional Arabic short name
/// Covers all known player_position values from the SoccerWiki dataset
const Map<String, String> positionToProArabic = {
  // 🧤 حراسة المرمى
  'حارس المرمى': 'حارس مرمى',
  'حم': 'حارس مرمى',
  'GK': 'حارس مرمى',
  'Goalkeeper': 'حارس مرمى',

  // 🛡️ الدفاع
  'سدادة': 'قلب دفاع',                         // CB
  'دافير لعب الكرة': 'قلب دفاع',               // CB – ball-playing defender
  'عموما المدافع': 'قلب دفاع',                  // CB – general defender
  'وينج باك': 'ظهير',                            // LB/RB/LWB/RWB
  'CB': 'قلب دفاع',
  'Center Back': 'قلب دفاع',
  'LB': 'ظهير أيسر',
  'RB': 'ظهير أيمن',
  'LWB': 'ظهير أيسر متقدم',
  'RWB': 'ظهير أيمن متقدم',
  'Wing Back': 'ظهير',
  'Defender': 'مدافع',
  'DF': 'مدافع',
  'D': 'مدافع',

  // ⚙️ الوسط
  'لاعب خط الوسط العام': 'وسط',                // CM
  'لاعب خط وسط مربع إلى مربع': 'وسط',         // CM – box-to-box
  'لاعب خط الوسط الحائز على الكرة': 'وسط دفاعي',  // CDM
  'صانع لعب متقدم': 'وسط هجومي',               // CAM
  'صانع اللعب': 'وسط هجومي',                    // CAM – playmaker
  'صانع الالعاب المتاخر': 'وسط دفاعي',          // CDM – deep-lying playmaker
  'CDM': 'وسط دفاعي',
  'CM': 'وسط',
  'CAM': 'وسط هجومي',
  'LM': 'وسط أيسر',
  'RM': 'وسط أيمن',
  'Central Midfielder': 'وسط',
  'Defensive Midfielder': 'وسط دفاعي',
  'Attacking Midfielder': 'وسط هجومي',
  'Playmaker': 'وسط هجومي',
  'Box-to-Box Midfielder': 'وسط',
  'Midfielder': 'وسط',
  'MF': 'وسط',

  // ⚡ الهجوم
  'الجناح': 'جناح',                              // LW/RW
  'إلى الأمام واسعة': 'جناح',                    // Wide forward → winger
  'الانتهاء': 'مهاجم صريح',                      // ST – finisher
  'الرجل المستهدف او المقصود': 'مهاجم صريح',    // ST – target man
  'عميق الكذب إلى الأمام': 'مهاجم ثاني',       // SS – second striker
  'جنرال إلى الأمام': 'مهاجم',                   // CF – general forward
  'LW': 'جناح أيسر',
  'RW': 'جناح أيمن',
  'ST': 'مهاجم صريح',
  'CF': 'مهاجم',
  'SS': 'مهاجم ثاني',
  'Winger': 'جناح',
  'Striker': 'مهاجم صريح',
  'Target Man': 'مهاجم صريح',
  'Second Striker': 'مهاجم ثاني',
  'Forward': 'مهاجم',
  'FW': 'مهاجم',
  'F': 'مهاجم',

  // إضافي
  'Manager': 'المدرب',
  'Coach': 'المدرب',
  'المدرب': 'المدرب',
};

/// Maps Arabic position names (from SoccerWiki scrape) → English abbreviation
const Map<String, String> positionArToEn = {
  // Goalkeepers
  'حارس المرمى': 'GK',
  'حم': 'GK',
  'حارس مرمى': 'GK',
  // Defenders
  'سدادة': 'CB',
  'دافير لعب الكرة': 'CB',
  'عموما المدافع': 'CB',
  'وينج باك': 'WB',
  'قلب دفاع': 'CB',
  'ظهير': 'WB',
  'ظهير أيسر': 'LB',
  'ظهير أيمن': 'RB',
  'ظهير أيسر متقدم': 'LWB',
  'ظهير أيمن متقدم': 'RWB',
  'مدافع': 'DF',
  // Midfielders
  'لاعب خط الوسط العام': 'CM',
  'لاعب خط وسط مربع إلى مربع': 'CM',
  'لاعب خط الوسط الحائز على الكرة': 'CDM',
  'صانع لعب متقدم': 'CAM',
  'صانع اللعب': 'CAM',
  'صانع الالعاب المتاخر': 'CDM',
  'وسط': 'CM',
  'وسط دفاعي': 'CDM',
  'وسط هجومي': 'CAM',
  'وسط أيسر': 'LM',
  'وسط أيمن': 'RM',
  // Forwards
  'الجناح': 'W',
  'إلى الأمام واسعة': 'W',
  'جناح': 'W',
  'جناح أيسر': 'LW',
  'جناح أيمن': 'RW',
  'الانتهاء': 'ST',
  'الرجل المستهدف او المقصود': 'ST',
  'مهاجم صريح': 'ST',
  'عميق الكذب إلى الأمام': 'SS',
  'مهاجم ثاني': 'SS',
  'جنرال إلى الأمام': 'CF',
  'مهاجم': 'CF',
};

/// Maps Arabic nationality → English
const Map<String, String> nationalityArToEn = {
  'إنكلترا': 'England',
  'اسكتلندا': 'Scotland',
  'ويلز': 'Wales',
  'ايرلندا': 'Ireland',
  'النرويج': 'Norway',
  'المانيا': 'Germany',
  'فرنسا': 'France',
  'اسبانيا': 'Spain',
  'ايطاليا': 'Italy',
  'برازيل': 'Brazil',
  'ارجنتين': 'Argentina',
  'هولندا': 'Netherlands',
  'بلجيكا': 'Belgium',
  'البرتغال': 'Portugal',
  'تركيا': 'Turkey',
  'الدنمارك': 'Denmark',
  'السويد': 'Sweden',
  'صربيا': 'Serbia',
  'كرواتيا': 'Croatia',
  'سويسرا': 'Switzerland',
  'النمسا': 'Austria',
  'بولندا': 'Poland',
  'التشيك': 'Czech Republic',
  'اليونان': 'Greece',
  'رومانيا': 'Romania',
  'اوكرانيا': 'Ukraine',
  'روسيا': 'Russia',
  'اليابان': 'Japan',
  'كوريا الجنوبية': 'South Korea',
  'المغرب': 'Morocco',
  'مصر': 'Egypt',
  'نيجيريا': 'Nigeria',
  'الجزائر': 'Algeria',
  'تونس': 'Tunisia',
  'السنغال': 'Senegal',
  'غانا': 'Ghana',
  'الكاميرون': 'Cameroon',
  'ساحل العاج': 'Ivory Coast',
  'امريكا': 'USA',
  'المكسيك': 'Mexico',
  'كولومبيا': 'Colombia',
  'تشيلي': 'Chile',
  'أوروغواي': 'Uruguay',
  'باراغواي': 'Paraguay',
  'اكوادور': 'Ecuador',
  'بيرو': 'Peru',
  'استراليا': 'Australia',
  'هنغاريا': 'Hungary',
  'سلوفاكيا': 'Slovakia',
  'سلوفينيا': 'Slovenia',
  'بلغاريا': 'Bulgaria',
  'البوسنة والهرسك': 'Bosnia',
  'الجبل الأسود': 'Montenegro',
  'مقدونيا الشمالية': 'North Macedonia',
  'ألبانيا': 'Albania',
  'جورجيا': 'Georgia',
  'أرمينيا': 'Armenia',
  'فنلندا': 'Finland',
  'آيسلندا': 'Iceland',
  'جامايكا': 'Jamaica',
  'كوستاريكا': 'Costa Rica',
  'بنما': 'Panama',
  'هندوراس': 'Honduras',
  'فنزويلا': 'Venezuela',
  'بوليفيا': 'Bolivia',
  'كينيا': 'Kenya',
  'مالي': 'Mali',
  'غينيا': 'Guinea',
  'بوركينا فاسو': 'Burkina Faso',
  'الكونغو': 'DR Congo',
  'جنوب أفريقيا': 'South Africa',
  'زيمبابوي': 'Zimbabwe',
  'زامبيا': 'Zambia',
  'الغابون': 'Gabon',
  'ترينيداد وتوباغو': 'Trinidad & Tobago',
  'كندا': 'Canada',
  'ايران': 'Iran',
  'العراق': 'Iraq',
  'السعودية': 'Saudi Arabia',
  'الإمارات': 'UAE',
  'قطر': 'Qatar',
  'الكويت': 'Kuwait',
  'الصين': 'China',
};

/// Maps Arabic nationality → flag emoji
const Map<String, String> nationalityToFlag = {
  'إنكلترا': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
  'اسكتلندا': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
  'ويلز': '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
  'ايرلندا': '🇮🇪',
  'النرويج': '🇳🇴',
  'المانيا': '🇩🇪',
  'فرنسا': '🇫🇷',
  'اسبانيا': '🇪🇸',
  'ايطاليا': '🇮🇹',
  'برازيل': '🇧🇷',
  'ارجنتين': '🇦🇷',
  'هولندا': '🇳🇱',
  'بلجيكا': '🇧🇪',
  'البرتغال': '🇵🇹',
  'تركيا': '🇹🇷',
  'الدنمارك': '🇩🇰',
  'السويد': '🇸🇪',
  'صربيا': '🇷🇸',
  'كرواتيا': '🇭🇷',
  'سويسرا': '🇨🇭',
  'النمسا': '🇦🇹',
  'بولندا': '🇵🇱',
  'التشيك': '🇨🇿',
  'اليونان': '🇬🇷',
  'رومانيا': '🇷🇴',
  'اوكرانيا': '🇺🇦',
  'روسيا': '🇷🇺',
  'اليابان': '🇯🇵',
  'كوريا الجنوبية': '🇰🇷',
  'المغرب': '🇲🇦',
  'مصر': '🇪🇬',
  'نيجيريا': '🇳🇬',
  'الجزائر': '🇩🇿',
  'تونس': '🇹🇳',
  'السنغال': '🇸🇳',
  'غانا': '🇬🇭',
  'الكاميرون': '🇨🇲',
  'ساحل العاج': '🇨🇮',
  'امريكا': '🇺🇸',
  'المكسيك': '🇲🇽',
  'كولومبيا': '🇨🇴',
  'تشيلي': '🇨🇱',
  'أوروغواي': '🇺🇾',
  'باراغواي': '🇵🇾',
  'اكوادور': '🇪🇨',
  'بيرو': '🇵🇪',
  'استراليا': '🇦🇺',
  'هنغاريا': '🇭🇺',
  'سلوفاكيا': '🇸🇰',
  'سلوفينيا': '🇸🇮',
  'بلغاريا': '🇧🇬',
  'البوسنة والهرسك': '🇧🇦',
  'الجبل الأسود': '🇲🇪',
  'مقدونيا الشمالية': '🇲🇰',
  'ألبانيا': '🇦🇱',
  'جورجيا': '🇬🇪',
  'أرمينيا': '🇦🇲',
  'فنلندا': '🇫🇮',
  'آيسلندا': '🇮🇸',
  'جامايكا': '🇯🇲',
  'كوستاريكا': '🇨🇷',
  'بنما': '🇵🇦',
  'هندوراس': '🇭🇳',
  'فنزويلا': '🇻🇪',
  'بوليفيا': '🇧🇴',
  'كينيا': '🇰🇪',
  'مالي': '🇲🇱',
  'غينيا': '🇬🇳',
  'بوركينا فاسو': '🇧🇫',
  'الكونغو': '🇨🇩',
  'جنوب أفريقيا': '🇿🇦',
  'زيمبابوي': '🇿🇼',
  'زامبيا': '🇿🇲',
  'الغابون': '🇬🇦',
  'ترينيداد وتوباغو': '🇹🇹',
  'كندا': '🇨🇦',
  'ايران': '🇮🇷',
  'العراق': '🇮🇶',
  'السعودية': '🇸🇦',
  'الإمارات': '🇦🇪',
  'قطر': '🇶🇦',
  'الكويت': '🇰🇼',
  'الصين': '🇨🇳',
};

/// Translate a position string to professional Arabic.
/// Works with both scraped Arabic names AND English abbreviations.
String translatePosition(String? position, {String locale = 'en'}) {
  if (position == null || position.isEmpty) return 'لاعب';
  
  // Always return the professional Arabic name from the unified map
  final proAr = positionToProArabic[position];
  if (proAr != null) return proAr;
  
  // If the position is already a known pro-Arabic value, return it as-is
  if (positionToProArabic.containsValue(position)) return position;
  
  // Return original if not found in any map
  return position;
}

/// Translate a nationality string. Falls back to original if not found.
String translateNationality(String? nationality, {String locale = 'en'}) {
  if (nationality == null) return 'Unknown';
  if (locale == 'en') {
    return nationalityArToEn[nationality] ?? nationality;
  }
  return nationality;
}

/// Get flag emoji for a nationality. Falls back to 🏳️
String getNationalityFlag(String? nationality) {
  if (nationality == null) return '🏳️';
  return nationalityToFlag[nationality] ?? '🏳️';
}
