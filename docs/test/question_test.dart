import 'package:flutter_test/flutter_test.dart';
import 'package:clinical_engineer_quiz/models/question.dart';

void main() {
  group('Question Model Tests', () {
    test('単一選択問題の正答判定 - 正解の場合', () {
      final question = Question(
        id: 1,
        text: 'テスト問題',
        choices: ['A', 'B', 'C', 'D', 'E'],
        correct: [2], // C が正解
        type: 'single',
        difficulty: 'easy',
        year: 34,
        isMorning: true,
        field: 'テスト分野',
        explanation: 'テスト解説',
      );

      expect(question.isCorrectAnswer([2]), true);
    });

    test('単一選択問題の正答判定 - 不正解の場合', () {
      final question = Question(
        id: 1,
        text: 'テスト問題',
        choices: ['A', 'B', 'C', 'D', 'E'],
        correct: [2],
        type: 'single',
        difficulty: 'easy',
        year: 34,
        isMorning: true,
        field: 'テスト分野',
        explanation: 'テスト解説',
      );

      expect(question.isCorrectAnswer([0]), false);
      expect(question.isCorrectAnswer([1]), false);
      expect(question.isCorrectAnswer([3]), false);
    });

    test('複数選択問題の正答判定 - 正解の場合', () {
      final question = Question(
        id: 2,
        text: 'テスト問題',
        choices: ['A', 'B', 'C', 'D', 'E'],
        correct: [0, 2, 4], // A, C, E が正解
        type: 'multiple',
        difficulty: 'normal',
        year: 34,
        isMorning: true,
        field: 'テスト分野',
        explanation: 'テスト解説',
      );

      expect(question.isCorrectAnswer([0, 2, 4]), true);
      expect(question.isCorrectAnswer([4, 0, 2]), true); // 順不同でも正解
      expect(question.isCorrectAnswer([2, 4, 0]), true);
    });

    test('複数選択問題の正答判定 - 不正解の場合', () {
      final question = Question(
        id: 2,
        text: 'テスト問題',
        choices: ['A', 'B', 'C', 'D', 'E'],
        correct: [0, 2, 4],
        type: 'multiple',
        difficulty: 'normal',
        year: 34,
        isMorning: true,
        field: 'テスト分野',
        explanation: 'テスト解説',
      );

      expect(question.isCorrectAnswer([0, 2]), false); // 数が足りない
      expect(question.isCorrectAnswer([0, 1, 2]), false); // 誤った選択肢を含む
      expect(question.isCorrectAnswer([0, 2, 3]), false);
      expect(question.isCorrectAnswer([1, 3, 4]), false);
    });

    test('複数選択問題の正答判定 - 選択数が異なる場合', () {
      final question = Question(
        id: 2,
        text: 'テスト問題',
        choices: ['A', 'B', 'C', 'D', 'E'],
        correct: [0, 2, 4],
        type: 'multiple',
        difficulty: 'normal',
        year: 34,
        isMorning: true,
        field: 'テスト分野',
        explanation: 'テスト解説',
      );

      expect(question.isCorrectAnswer([0]), false); // 1つしか選択していない
      expect(question.isCorrectAnswer([0, 2, 4, 3]), false); // 4つ選択している
    });

    test('JSONシリアライゼーション - toJson', () {
      final question = Question(
        id: 1,
        text: 'テスト問題',
        choices: ['A', 'B', 'C', 'D', 'E'],
        correct: [2],
        type: 'single',
        difficulty: 'easy',
        year: 34,
        isMorning: true,
        field: 'テスト分野',
        explanation: 'テスト解説',
      );

      final json = question.toJson();

      expect(json['id'], 1);
      expect(json['text'], 'テスト問題');
      expect(json['choices'], ['A', 'B', 'C', 'D', 'E']);
      expect(json['correct'], [2]);
      expect(json['type'], 'single');
      expect(json['difficulty'], 'easy');
      expect(json['year'], 34);
      expect(json['isMorning'], true);
      expect(json['field'], 'テスト分野');
      expect(json['explanation'], 'テスト解説');
    });

    test('JSONデシリアライゼーション - fromJson', () {
      final json = {
        'id': 1,
        'text': 'テスト問題',
        'choices': ['A', 'B', 'C', 'D', 'E'],
        'correct': [2],
        'type': 'single',
        'difficulty': 'easy',
        'year': 34,
        'isMorning': true,
        'field': 'テスト分野',
        'explanation': 'テスト解説',
      };

      final question = Question.fromJson(json);

      expect(question.id, 1);
      expect(question.text, 'テスト問題');
      expect(question.choices, ['A', 'B', 'C', 'D', 'E']);
      expect(question.correct, [2]);
      expect(question.type, 'single');
      expect(question.difficulty, 'easy');
      expect(question.year, 34);
      expect(question.isMorning, true);
      expect(question.field, 'テスト分野');
      expect(question.explanation, 'テスト解説');
    });
  });

  group('Quiz Scoring Tests', () {
    test('全問正解の場合', () {
      final questions = [
        Question(
          id: 1,
          text: '問題1',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [0],
          type: 'single',
          difficulty: 'easy',
          year: 34,
          isMorning: true,
          field: '分野1',
          explanation: '解説1',
        ),
        Question(
          id: 2,
          text: '問題2',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [1, 2, 3],
          type: 'multiple',
          difficulty: 'normal',
          year: 34,
          isMorning: true,
          field: '分野2',
          explanation: '解説2',
        ),
      ];

      final userAnswers = [
        [0], // 問題1: 正解
        [1, 2, 3], // 問題2: 正解
      ];

      int correctCount = 0;
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].isCorrectAnswer(userAnswers[i])) {
          correctCount++;
        }
      }

      expect(correctCount, 2);
      expect(correctCount / questions.length * 100, 100.0);
    });

    test('一部正解の場合', () {
      final questions = [
        Question(
          id: 1,
          text: '問題1',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [0],
          type: 'single',
          difficulty: 'easy',
          year: 34,
          isMorning: true,
          field: '分野1',
          explanation: '解説1',
        ),
        Question(
          id: 2,
          text: '問題2',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [1, 2, 3],
          type: 'multiple',
          difficulty: 'normal',
          year: 34,
          isMorning: true,
          field: '分野2',
          explanation: '解説2',
        ),
        Question(
          id: 3,
          text: '問題3',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [4],
          type: 'single',
          difficulty: 'hard',
          year: 34,
          isMorning: true,
          field: '分野3',
          explanation: '解説3',
        ),
      ];

      final userAnswers = [
        [0], // 問題1: 正解
        [1, 2], // 問題2: 不正解（数が足りない）
        [3], // 問題3: 不正解
      ];

      int correctCount = 0;
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].isCorrectAnswer(userAnswers[i])) {
          correctCount++;
        }
      }

      expect(correctCount, 1);
      expect((correctCount / questions.length * 100).roundToDouble(), 33.0);
    });

    test('全問不正解の場合', () {
      final questions = [
        Question(
          id: 1,
          text: '問題1',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [0],
          type: 'single',
          difficulty: 'easy',
          year: 34,
          isMorning: true,
          field: '分野1',
          explanation: '解説1',
        ),
        Question(
          id: 2,
          text: '問題2',
          choices: ['A', 'B', 'C', 'D', 'E'],
          correct: [1, 2, 3],
          type: 'multiple',
          difficulty: 'normal',
          year: 34,
          isMorning: true,
          field: '分野2',
          explanation: '解説2',
        ),
      ];

      final userAnswers = [
        [1], // 問題1: 不正解
        [0, 2, 4], // 問題2: 不正解
      ];

      int correctCount = 0;
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].isCorrectAnswer(userAnswers[i])) {
          correctCount++;
        }
      }

      expect(correctCount, 0);
      expect(correctCount / questions.length * 100, 0.0);
    });
  });
}
