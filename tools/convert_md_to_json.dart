import 'dart:convert';
import 'dart:io';

class Question {
  final int id;
  final String text;
  final List<String> choices;
  final List<int> correct;
  final String type;
  final String difficulty;
  final int year;
  final bool isMorning;
  final String field;
  final String explanation;

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

  Map<String, dynamic> toJson() => {
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

final difficultyMap = {
  '初級': 'easy',
  '中級': 'normal',
  '上級': 'hard',
};

Question? parseMarkdownQuestion(String text, int questionId, int year,
    String difficultyJa, bool isMorning) {
  final fieldMatch = RegExp(r'\(分野:(.+?)\)').firstMatch(text);
  final field = fieldMatch != null ? fieldMatch.group(1)! : '医学概論';

  final qMatch = RegExp(r'【問題】\r?\n(.+?)\r?\n+【選択肢】', dotAll: true)
      .firstMatch(text);
  if (qMatch == null) return null;
  final questionText = qMatch.group(1)!.trim();

  final cMatch = RegExp(r'【選択肢】\r?\n(.+?)\r?\n+【正答】', dotAll: true)
      .firstMatch(text);
  if (cMatch == null) return null;
  final choicesSection = cMatch.group(1)!.trim();
  final choices = <String>[];
  for (final line in choicesSection.split('\n')) {
    final l = line.trim();
    final m = RegExp(r'^[A-E]\.[\s]*(.+)').firstMatch(l);
    if (m != null) {
      choices.add(m.group(1)!.trim());
    }
  }
  if (choices.length != 5) return null;

  final aMatch = RegExp(r'【正答】\r?\n(.+?)\r?\n+【解説】', dotAll: true)
      .firstMatch(text);
  if (aMatch == null) return null;
  final answerText = aMatch.group(1)!.trim();
  final letters = RegExp(r'[A-E]').allMatches(answerText).map((m) => m.group(0)!).toList();
  final correct = letters.map((l) => l.codeUnitAt(0) - 'A'.codeUnitAt(0)).toList();
  correct.sort();

  final eMatch = RegExp(r'【解説】\r?\n(.+?)(?=\r?\n---|\Z)', dotAll: true)
      .firstMatch(text);
  final explanation = eMatch != null ? eMatch.group(1)!.trim() : '';

  final type = correct.length == 1 ? 'single' : 'multiple';
  var finalExplanation = explanation;
  if (type == 'multiple' && correct.length > 3) {
    final originalLetters = letters;
    final trimmed = correct.take(3).toList();
    final trimmedLetters = trimmed.map((i) => String.fromCharCode('A'.codeUnitAt(0) + i)).toList();
    final note = '\n【注記】本問は元データで正答が${originalLetters.length}個（${originalLetters.join('、')}）ありましたが、\nアプリ仕様（複数選択は最大3）に合わせ、先頭3つ（${trimmedLetters.join('、')}）に自動調整しています。';
    finalExplanation = (finalExplanation + note).trim();
  }

  return Question(
    id: questionId,
    text: questionText,
    choices: choices,
    correct: correct.length > 3 ? correct.take(3).toList() : correct,
    type: type,
    difficulty: difficultyMap[difficultyJa] ?? 'normal',
    year: year,
    isMorning: isMorning,
    field: field,
    explanation: finalExplanation,
  );
}

List<Question> processFile(File file, int year, String difficulty, bool isMorning, int startId) {
  final content = file.readAsStringSync();
  final parts = content.split(RegExp(r'\r?\n---\r?\n'));
  final result = <Question>[];
  var id = startId;
  for (final part in parts) {
    if (part.contains('【問題】')) {
      final q = parseMarkdownQuestion(part, id, year, difficulty, isMorning);
      if (q != null) {
        result.add(q);
        id += 1;
      }
    }
  }
  return result;
}

void main(List<String> args) {
  final baseDir = Directory(r'C:\Users\kuuka\OneDrive\ドキュメント\くーの臨床工学技士国家試験対策');
  final files = [
    // 第34回
    {'name': '第34回_類似問題_初級_午前30問.md', 'year': 34, 'difficulty': '初級', 'morning': true},
    {'name': '第34回_類似問題_初級_午後30問.md', 'year': 34, 'difficulty': '初級', 'morning': false},
    {'name': '第34回_類似問題_中級_午前30問.md', 'year': 34, 'difficulty': '中級', 'morning': true},
    {'name': '第34回_類似問題_中級_午後30問.md', 'year': 34, 'difficulty': '中級', 'morning': false},
    {'name': '第34回_類似問題_上級_午前30問.md', 'year': 34, 'difficulty': '上級', 'morning': true},
    {'name': '第34回_類似問題_上級_午後30問.md', 'year': 34, 'difficulty': '上級', 'morning': false},
    // 第35回
    {'name': '第35回_類似問題_初級_午前30問.md', 'year': 35, 'difficulty': '初級', 'morning': true},
    {'name': '第35回_類似問題_初級_午後30問.md', 'year': 35, 'difficulty': '初級', 'morning': false},
    {'name': '第35回_類似問題_中級_午前30問.md', 'year': 35, 'difficulty': '中級', 'morning': true},
    {'name': '第35回_類似問題_中級_午後30問.md', 'year': 35, 'difficulty': '中級', 'morning': false},
    {'name': '第35回_類似問題_上級_午前30問.md', 'year': 35, 'difficulty': '上級', 'morning': true},
    {'name': '第35回_類似問題_上級_午後30問.md', 'year': 35, 'difficulty': '上級', 'morning': false},
  ];

  var currentId = 1000;
  final collected = <Question>[];
  final yearCounts = <int, int>{};

  for (final cfg in files) {
    final file = File('${baseDir.path}\\${cfg['name']}');
    if (file.existsSync()) {
      final qs = processFile(file, cfg['year'] as int, cfg['difficulty'] as String, cfg['morning'] as bool, currentId);
      collected.addAll(qs);
      yearCounts[cfg['year'] as int] = (yearCounts[cfg['year'] as int] ?? 0) + qs.length;
      currentId += qs.length;
      stdout.writeln('Processed: ${cfg['name']} -> ${qs.length} questions');
    } else {
      stdout.writeln('File not found: ${cfg['name']}');
    }
  }

  final outputPath = File('${baseDir.path}\\flutter_app\\assets\\questions.json');
  final existing = <dynamic>[];
  if (outputPath.existsSync()) {
    try {
      existing.addAll(jsonDecode(outputPath.readAsStringSync()) as List<dynamic>);
    } catch (_) {}
  }
  final samples = existing.where((e) => (e is Map) && (e['id'] is int) && (e['id'] as int) < 1000).toList();
  final finalList = [
    ...samples,
    ...collected.map((q) => q.toJson()),
  ];
  outputPath.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(finalList), encoding: utf8);

  stdout.writeln('\nTotal questions saved: ${finalList.length}');
  stdout.writeln('  - Sample questions: ${samples.length}');
  for (final y in (yearCounts.keys.toList()..sort())) {
    stdout.writeln('  - Year $y questions: ${yearCounts[y]}');
  }
}
