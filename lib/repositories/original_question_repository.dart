import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class OriginalQuestionRepository {
  static const String _key = 'original_questions';

  Future<List<Question>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    return list
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Question> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final list = questions.map((q) => q.toJson()).toList();
    await prefs.setString(_key, json.encode(list));
  }

  Future<Question> add(Question q) async {
    final list = await load();
    // 原則としてマイナスIDで重複回避
    final nextId = (list.where((e) => e.id < 0).map((e) => e.id).fold<int>(0, (p, n) => n < p ? n : p)) - 1;
    final created = Question(
      id: nextId == -1 ? -1 : nextId,
      text: q.text,
      choices: q.choices,
      correct: q.correct,
      type: q.type,
      difficulty: q.difficulty,
      year: 0,
      isMorning: false,
      field: q.field,
      explanation: q.explanation,
    );
    list.insert(0, created);
    await saveAll(list);
    return created;
  }

  Future<void> update(Question q) async {
    final list = await load();
    final idx = list.indexWhere((e) => e.id == q.id);
    if (idx >= 0) {
      list[idx] = q;
      await saveAll(list);
    }
  }

  Future<void> delete(int id) async {
    final list = await load();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }
}
