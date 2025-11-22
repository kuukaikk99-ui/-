import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuestionRepository {
  List<Question>? _allQuestions;

  // JSONからすべての問題を読み込む
  Future<List<Question>> loadAllQuestions() async {
    if (_allQuestions != null) {
      return _allQuestions!;
    }

    final String jsonString = await rootBundle.loadString('assets/questions.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    _allQuestions = jsonList.map((json) => Question.fromJson(json as Map<String, dynamic>)).toList();
    return _allQuestions!;
  }

  // 年度別・午前午後・難易度別で30問取得
  Future<List<Question>> getQuestionsByYearPeriodDifficulty({
    required int year,
    required bool isMorning,
    required String difficulty,
  }) async {
    final questions = await loadAllQuestions();
    return questions
        .where((q) => q.year == year && q.isMorning == isMorning && q.difficulty == difficulty)
        .toList();
  }

  // 年度別・午前午後でミックス90問（全難易度）取得
  Future<List<Question>> getQuestionsByYearPeriodMixed({
    required int year,
    required bool isMorning,
  }) async {
    final questions = await loadAllQuestions();
    final filtered = questions.where((q) => q.year == year && q.isMorning == isMorning).toList();
    filtered.shuffle();
    return filtered;
  }

  // 難易度別・午前午後で30問取得（全年度から）
  Future<List<Question>> getQuestionsByDifficultyPeriod({
    required String difficulty,
    required bool isMorning,
  }) async {
    final questions = await loadAllQuestions();
    final filtered = questions.where((q) => q.difficulty == difficulty && q.isMorning == isMorning).toList();
    filtered.shuffle();
    return filtered.take(30).toList();
  }

  // 総合試験モード：全年度から午前90問＋午後90問＝180問
  Future<List<Question>> getComprehensiveQuestions() async {
    final questions = await loadAllQuestions();
    final morningQuestions = questions.where((q) => q.isMorning).toList()..shuffle();
    final afternoonQuestions = questions.where((q) => !q.isMorning).toList()..shuffle();
    
    final selectedMorning = morningQuestions.take(90).toList();
    final selectedAfternoon = afternoonQuestions.take(90).toList();
    
    return [...selectedMorning, ...selectedAfternoon]..shuffle();
  }

  // 年度範囲（例: 34〜38回）からランダム取得。
  // isMorning: true=午前のみ, false=午後のみ, null=両方混在
  // count: 取得件数（上限は存在数まで）
  Future<List<Question>> getQuestionsByYearRangeRandom({
    required int startYear,
    required int endYear,
    bool? isMorning,
    int count = 30,
  }) async {
    final questions = await loadAllQuestions();
    final filtered = questions.where((q) {
      final inRange = q.year >= startYear && q.year <= endYear;
      if (!inRange) return false;
      if (isMorning == null) return true;
      return q.isMorning == isMorning;
    }).toList();
    filtered.shuffle();
    if (count <= 0) return filtered; // 0以下なら全件
    return filtered.take(count).toList();
  }

  // 特定の問題IDリストから問題を取得（復習用）
  Future<List<Question>> getQuestionsByIds(List<int> ids) async {
    final questions = await loadAllQuestions();
    return questions.where((q) => ids.contains(q.id)).toList();
  }
}
