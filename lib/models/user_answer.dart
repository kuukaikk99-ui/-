class UserAnswer {
  final int questionId;
  final List<int> selectedAnswers;
  final bool isCorrect;

  UserAnswer({
    required this.questionId,
    required this.selectedAnswers,
    required this.isCorrect,
  });
}
