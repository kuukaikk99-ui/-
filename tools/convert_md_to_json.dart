import 'dart:convert';
import 'dart:io';

final baseDir = Directory(r'C:\\Users\\kuuka\\OneDrive\\ドキュメント\\くーの臨床工学技士国家試験対策');

List<(String, int, String, bool)> buildFilesConfig(int year) => [
      ('第$year回_類似問題_初級_午前30問.md', year, '初級', true),
      ('第$year回_類似問題_初級_午後30問.md', year, '初級', false),
      ('第$year回_類似問題_中級_午前30問.md', year, '中級', true),
      ('第$year回_類似問題_中級_午後30問.md', year, '中級', false),
      ('第$year回_類似問題_上級_午前30問.md', year, '上級', true),
      ('第$year回_類似問題_上級_午後30問.md', year, '上級', false),
    ];

final difficultyMap = {'初級': 'easy', '中級': 'normal', '上級': 'hard'};

final regField = RegExp(r'\(分野:(.+?)\)');
const regNL = r'(?:\r?\n)';
final regQuestion = RegExp('【問題】$regNL(.+?)(?=$regNL$regNL【選択肢】)', dotAll: true);
final regChoices = RegExp('【選択肢】$regNL(.+?)(?=$regNL$regNL【正答】)', dotAll: true);
final regAnswer = RegExp('【正答】$regNL(.+?)(?=$regNL$regNL【解説】)', dotAll: true);
final regExplain = RegExp('【解説】' + regNL + '(.+?)(?=' + regNL + '---|' + r'\Z)', dotAll: true);

Map<String, dynamic>? parseQuestion(String text, int id, int year, String difficulty, bool isMorning) {
  final fieldMatch = regField.firstMatch(text);
  final field = fieldMatch != null ? fieldMatch.group(1)!.trim() : '医学概論';

  final qMatch = regQuestion.firstMatch(text);
  if (qMatch == null) return null;
  final qText = qMatch.group(1)!.trim();

  final cMatch = regChoices.firstMatch(text);
  if (cMatch == null) return null;
  final cText = cMatch.group(1)!.trim();
  final choices = <String>[];
  for (final line in cText.split('\n')) {
    final l = line.trim();
    final m = RegExp(r'^[A-E]\.').hasMatch(l);
    if (l.isNotEmpty && m) {
      choices.add(l.replaceFirst(RegExp(r'^[A-E]\.\s*'), ''));
    }
  }
  if (choices.length != 5) return null;

  final aMatch = regAnswer.firstMatch(text);
  if (aMatch == null) return null;
  final aText = aMatch.group(1)!.trim();
  final letters = RegExp(r'[A-E]').allMatches(aText).map((m) => m.group(0)!).toList();
  final correct = letters.map((ch) => ch.codeUnitAt(0) - 'A'.codeUnitAt(0)).toList();

  var explanation = '';
  final eMatch = regExplain.firstMatch(text);
  if (eMatch != null) explanation = eMatch.group(1)!.trim();

  final originalLen = correct.length;
  final type = originalLen == 1 ? 'single' : 'multiple';
  if (type == 'multiple' && originalLen > 3) {
    final originalLetters = (correct.toSet().toList()..sort())
        .map((i) => String.fromCharCode('A'.codeUnitAt(0) + i))
        .join('、');
    correct.sort();
    final trimmed = correct.take(3).toList();
    final trimmedLetters = trimmed
        .map((i) => String.fromCharCode('A'.codeUnitAt(0) + i))
        .join('、');
    explanation = ('$explanation\n【注記】本問は元データで正答が$originalLen個（$originalLetters）ありましたが、\nアプリ仕様（複数選択は最大3）に合わせ、先頭3つ（$trimmedLetters）に自動調整しています。')
        .trim();
    correct
      ..clear()
      ..addAll(trimmed);
  }

  return {
    'id': id,
    'text': qText,
    'choices': choices,
    'correct': (List<int>.from(correct)..sort()),
    'type': type,
    'difficulty': difficultyMap[difficulty] ?? 'normal',
    'year': year,
    'isMorning': isMorning,
    'field': field,
    'explanation': explanation,
  };
}

Future<List<Map<String, dynamic>>> processFile(File file, int year, String difficulty, bool isMorning, int startId) async {
  final content = await file.readAsString(encoding: utf8);
  final chunks = content.split(RegExp('$regNL---$regNL'));
  final out = <Map<String, dynamic>>[];
  var id = startId;
  for (final chunk in chunks) {
    if (!chunk.contains('【問題】')) continue;
    final q = parseQuestion(chunk, id, year, difficulty, isMorning);
    if (q != null) {
      out.add(q);
      id += 1;
    }
  }
  return out;
}

Future<void> main(List<String> args) async {
  // Usage: dart convert_md_to_json.dart [year]
  final targetYear = args.isNotEmpty ? int.tryParse(args.first) ?? 34 : 34;
  final outputPath = baseDir.path + r'\\flutter_app\\assets\\questions.json';
  final existing = <dynamic>[];
  final outputFile = File(outputPath);
  if (await outputFile.exists()) {
    try {
      existing.addAll(jsonDecode(await outputFile.readAsString(encoding: utf8)) as List);
    } catch (_) {}
  }
  // 既存のうち、対象年を除外したものをベースにする（再実行時の重複防止）
  final kept = existing.where((e) => e is Map && (e['year'] != targetYear)).toList();
  // 既存の最大IDの次から採番
  final maxId = existing
      .whereType<Map>()
      .map<int>((m) => (m['id'] ?? 0) as int)
      .fold<int>(0, (p, c) => c > p ? c : p);
  var currentId = maxId + 1;

  final allParsed = <Map<String, dynamic>>[];
  final filesConfig = buildFilesConfig(targetYear);
  for (final cfg in filesConfig) {
    final fileName = cfg.$1;
    final year = cfg.$2;
    final difficulty = cfg.$3;
    final isMorning = cfg.$4;
    final file = File(baseDir.path + r'\\' + fileName);
    if (!await file.exists()) {
      stdout.writeln('File not found: $fileName');
      continue;
    }
    final list = await processFile(file, year, difficulty, isMorning, currentId);
    allParsed.addAll(list);
    currentId += list.length;
    stdout.writeln('Processed: $fileName -> ${list.length} questions');
  }

  final finalList = [...kept, ...allParsed];
  await outputFile.writeAsString(const JsonEncoder.withIndent('  ').convert(finalList), encoding: utf8);

  stdout.writeln('\nTotal questions saved: ${finalList.length}');
  stdout.writeln('  - Added year $targetYear questions: ${allParsed.length}');
}
