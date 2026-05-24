/// أنواع مختلفة من الأسئلة للألعاب المختلفة

// 1. سؤال متعدد الخيارات (للنادي المشترك، اللاعب الخطأ)
class AIMultipleChoiceQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String difficulty;
  final String category;
  final DateTime createdAt;
  final bool isUsed;

  AIMultipleChoiceQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    this.isUsed = false,
  });

  factory AIMultipleChoiceQuestion.fromJson(Map<String, dynamic> json) {
    return AIMultipleChoiceQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswer: json['correctAnswer'] as String,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isUsed': isUsed,
    };
  }

  AIMultipleChoiceQuestion copyWith({bool? isUsed}) {
    return AIMultipleChoiceQuestion(
      id: id,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      difficulty: difficulty,
      category: category,
      createdAt: createdAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}

// 2. سؤال مفتوح (للجرس)
class AIOpenEndedQuestion {
  final String id;
  final String questionText;
  final List<String> acceptableAnswers; // الإجابات المقبولة
  final String difficulty;
  final String category;
  final DateTime createdAt;
  final bool isUsed;

  AIOpenEndedQuestion({
    required this.id,
    required this.questionText,
    required this.acceptableAnswers,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    this.isUsed = false,
  });

  factory AIOpenEndedQuestion.fromJson(Map<String, dynamic> json) {
    return AIOpenEndedQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      acceptableAnswers: (json['acceptableAnswers'] as List<dynamic>).map((e) => e as String).toList(),
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'acceptableAnswers': acceptableAnswers,
      'difficulty': difficulty,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isUsed': isUsed,
    };
  }

  AIOpenEndedQuestion copyWith({bool? isUsed}) {
    return AIOpenEndedQuestion(
      id: id,
      questionText: questionText,
      acceptableAnswers: acceptableAnswers,
      difficulty: difficulty,
      category: category,
      createdAt: createdAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}

// 3. سؤال رقمي (للمزاد)
class AINumericQuestion {
  final String id;
  final String questionText;
  final int correctAnswer;
  final String difficulty;
  final String category;
  final DateTime createdAt;
  final bool isUsed;

  AINumericQuestion({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    this.isUsed = false,
  });

  factory AINumericQuestion.fromJson(Map<String, dynamic> json) {
    return AINumericQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      correctAnswer: json['correctAnswer'] as int,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isUsed': isUsed,
    };
  }

  AINumericQuestion copyWith({bool? isUsed}) {
    return AINumericQuestion(
      id: id,
      questionText: questionText,
      correctAnswer: correctAnswer,
      difficulty: difficulty,
      category: category,
      createdAt: createdAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}

// 4. سؤال "اذكر..." (لماذا تعرف)
class AINameQuestion {
  final String id;
  final String questionText; // مثل: "اذكر لاعب برازيلي"
  final List<String> possibleAnswers; // قائمة إجابات صحيحة
  final String difficulty;
  final String category;
  final DateTime createdAt;
  final bool isUsed;

  AINameQuestion({
    required this.id,
    required this.questionText,
    required this.possibleAnswers,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    this.isUsed = false,
  });

  factory AINameQuestion.fromJson(Map<String, dynamic> json) {
    return AINameQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      possibleAnswers: (json['possibleAnswers'] as List<dynamic>).map((e) => e as String).toList(),
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'possibleAnswers': possibleAnswers,
      'difficulty': difficulty,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isUsed': isUsed,
    };
  }

  AINameQuestion copyWith({bool? isUsed}) {
    return AINameQuestion(
      id: id,
      questionText: questionText,
      possibleAnswers: possibleAnswers,
      difficulty: difficulty,
      category: category,
      createdAt: createdAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}

// 5. سؤال الانتقالات (لخمن من الانتقالات)
class AITransferQuestion {
  final String id;
  final String playerName; // اسم اللاعب
  final List<String> clubs; // قائمة الأندية بالترتيب
  final String difficulty;
  final DateTime createdAt;
  final bool isUsed;

  AITransferQuestion({
    required this.id,
    required this.playerName,
    required this.clubs,
    required this.difficulty,
    required this.createdAt,
    this.isUsed = false,
  });

  factory AITransferQuestion.fromJson(Map<String, dynamic> json) {
    return AITransferQuestion(
      id: json['id'] as String,
      playerName: json['playerName'] as String,
      clubs: (json['clubs'] as List<dynamic>).map((e) => e as String).toList(),
      difficulty: json['difficulty'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'clubs': clubs,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'isUsed': isUsed,
    };
  }

  AITransferQuestion copyWith({bool? isUsed}) {
    return AITransferQuestion(
      id: id,
      playerName: playerName,
      clubs: clubs,
      difficulty: difficulty,
      createdAt: createdAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}
