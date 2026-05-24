class AIQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String difficulty; // easy, medium, hard
  final String category; // common_club, wrong_player, quiz, etc.
  final DateTime createdAt;
  final bool isUsed;

  AIQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
    required this.createdAt,
    this.isUsed = false,
  });

  // تحويل من JSON
  factory AIQuestion.fromJson(Map<String, dynamic> json) {
    return AIQuestion(
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

  // تحويل إلى JSON
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

  // نسخ مع تعديلات
  AIQuestion copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    String? correctAnswer,
    String? difficulty,
    String? category,
    DateTime? createdAt,
    bool? isUsed,
  }) {
    return AIQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}
