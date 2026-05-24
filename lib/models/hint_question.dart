class HintQuestion {
  final String id;
  final String hint;
  final String answer;
  final String type; // 'player', 'coach', 'club'
  final String difficulty;
  final DateTime createdAt;

  HintQuestion({
    required this.id,
    required this.hint,
    required this.answer,
    required this.type,
    required this.difficulty,
    required this.createdAt,
  });

  factory HintQuestion.fromJson(Map<String, dynamic> json) {
    return HintQuestion(
      id: json['id'] ?? '',
      hint: json['hint'] ?? '',
      answer: (json['answer'] ?? '').toUpperCase().trim(),
      type: json['type'] ?? 'player',
      difficulty: json['difficulty'] ?? 'medium',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hint': hint,
      'answer': answer,
      'type': type,
      'difficulty': difficulty,
    };
  }
}
