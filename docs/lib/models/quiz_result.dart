class QuizResult {
  final DateTime dateTime;
  final int totalQuestions;
  final int correctAnswers;
  final String mode; // 例: "Year 34 Morning Easy", "Difficulty Hard", "Comprehensive"
  
  QuizResult({
    required this.dateTime,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.mode,
  });

  double get accuracy => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'datetime': dateTime.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'mode': mode,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      dateTime: DateTime.parse(json['datetime'] as String),
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      mode: json['mode'] as String,
    );
  }
}
