class Question {
  final int id;
  final String text;
  final List<String> choices;
  final List<int> correct; // 正答のインデックス（0-4）
  final String type; // "single" or "multiple"
  final String difficulty; // "easy", "normal", "hard"
  final int year; // 34-38
  final bool isMorning; // 午前: true, 午後: false
  final String field; // 分野名
  final String explanation; // 解説

  Question({
    required this.id,
    required this.text,
    required this.choices,
    required this.correct,
    required this.type,
    required this.difficulty,
    required this.year,
    required this.isMorning,
    required this.field,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      text: json['text'] as String,
      choices: List<String>.from(json['choices'] as List),
      correct: List<int>.from(json['correct'] as List),
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      year: json['year'] as int,
      isMorning: json['isMorning'] as bool,
      field: json['field'] as String,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'choices': choices,
      'correct': correct,
      'type': type,
      'difficulty': difficulty,
      'year': year,
      'isMorning': isMorning,
      'field': field,
      'explanation': explanation,
    };
  }

  bool isCorrectAnswer(List<int> userAnswers) {
    if (userAnswers.length != correct.length) return false;
    final sortedUser = List<int>.from(userAnswers)..sort();
    final sortedCorrect = List<int>.from(correct)..sort();
    for (int i = 0; i < sortedUser.length; i++) {
      if (sortedUser[i] != sortedCorrect[i]) return false;
    }
    return true;
  }
}
