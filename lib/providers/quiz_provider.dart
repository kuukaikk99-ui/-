import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/user_answer.dart';

class QuizProvider with ChangeNotifier {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  List<UserAnswer> _userAnswers = [];
  List<int> _currentSelectedAnswers = [];

  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Question? get currentQuestion => 
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length 
          ? _questions[_currentQuestionIndex] 
          : null;
  List<int> get currentSelectedAnswers => _currentSelectedAnswers;
  int get totalQuestions => _questions.length;
  int get remainingQuestions => _questions.length - _currentQuestionIndex;
  List<UserAnswer> get userAnswers => _userAnswers;

  // クイズを開始
  void startQuiz(List<Question> questions) {
    _questions = questions;
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _currentSelectedAnswers = [];
    notifyListeners();
  }

  // 選択肢をトグル（単一選択または複数選択）
  void toggleAnswer(int choiceIndex) {
    if (currentQuestion == null) return;

    if (currentQuestion!.type == 'single') {
      // 単一選択：選択を置き換え
      _currentSelectedAnswers = [choiceIndex];
    } else {
      // 複数選択：トグル（上限3個）
      if (_currentSelectedAnswers.contains(choiceIndex)) {
        _currentSelectedAnswers.remove(choiceIndex);
      } else {
        if (_currentSelectedAnswers.length < 3) {
          _currentSelectedAnswers.add(choiceIndex);
        }
      }
    }
    notifyListeners();
  }

  // 次の問題へ進む
  bool nextQuestion() {
    if (currentQuestion == null || _currentSelectedAnswers.isEmpty) {
      return false;
    }

    // 回答を記録
    final isCorrect = currentQuestion!.isCorrectAnswer(_currentSelectedAnswers);
    _userAnswers.add(UserAnswer(
      questionId: currentQuestion!.id,
      selectedAnswers: List.from(_currentSelectedAnswers),
      isCorrect: isCorrect,
    ));

    _currentQuestionIndex++;
    _currentSelectedAnswers = [];
    notifyListeners();
    return true;
  }

  // 正答数を取得
  int get correctAnswersCount => _userAnswers.where((a) => a.isCorrect).length;

  // 不正解の問題を取得
  List<Question> getIncorrectQuestions() {
    final incorrectIds = _userAnswers
        .where((a) => !a.isCorrect)
        .map((a) => a.questionId)
        .toList();
    return _questions.where((q) => incorrectIds.contains(q.id)).toList();
  }

  // クイズをリセット
  void reset() {
    _questions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _currentSelectedAnswers = [];
    notifyListeners();
  }
}
