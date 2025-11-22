import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_result.dart';

class HistoryProvider with ChangeNotifier {
  List<QuizResult> _history = [];
  static const String _historyKey = 'quiz_history';

  List<QuizResult> get history => _history;

  // 履歴を読み込む
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson) as List<dynamic>;
      _history = decoded.map((item) => QuizResult.fromJson(item as Map<String, dynamic>)).toList();
      // 新しい順にソート
      _history.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      notifyListeners();
    }
  }

  // 履歴を追加
  Future<void> addResult(QuizResult result) async {
    _history.insert(0, result);
    await _saveHistory();
    notifyListeners();
  }

  // 履歴を保存
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _history.map((r) => r.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonList));
  }

  // 履歴をクリア
  Future<void> clearHistory() async {
    _history = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    notifyListeners();
  }
}
