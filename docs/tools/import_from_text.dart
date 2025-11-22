import 'dart:convert';
import 'dart:io';

/// 34回 午前テキスト（assets/source/34am.txt）を解析して
/// flutter_app/assets/questions.json を上書きするスクリプト。
///
/// 想定フォーマット:
/// - 各設問は "問題<番号>" 行から開始
/// - 続く本文は最初の選択肢行まで（選択肢行は先頭が 1～5 + '．' or '.'）
/// - 選択肢は5行（1～5）
/// - その後の行に "正解：<数字>" があり、1～5のいずれか
/// - 本文中に a～e の項目が混在していても、そのまま本文として取り込む
/// - 空行は適宜無視
///
/// 出力スキーマ例:
/// {
///   "id": 34001,
///   "text": "設問本文",
///   "choices": ["選択肢1","選択肢2","選択肢3","選択肢4","選択肢5"],
///   "correct": [ 正解(0始まり) ],
///   "type": "single",
///   "difficulty": "normal",
///   "year": 34,
///   "isMorning": true,
///   "field": "第34回午前"
/// }
void main(List<String> args) async {
  // 想定配置: このスクリプトは flutter_app/tools/ 配下にある。
  // CWD は通常ワークスペース/またはスクリプトの場所から実行される想定なので、
  // スクリプトの場所を基準に相対パスを組み立てる。
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final flutterAppDir = scriptDir.parent.path; // flutter_app
  // 引数処理
  // --input=assets/source/34am.txt
  // --year=34
  // --period=am|pm
  // --mode=overwrite|append (既存questions.jsonに対して)
  String inputPath = Path.join(flutterAppDir, 'assets', 'source', '34am.txt');
  int year = 34;
  bool isMorning = true;
  String mode = 'overwrite';
  for (final a in args) {
    if (a.startsWith('--input=')) {
      inputPath = a.substring('--input='.length);
      if (!Path.isAbsolute(inputPath)) {
        inputPath = Path.join(flutterAppDir, inputPath);
      }
    } else if (a.startsWith('--year=')) {
      year = int.tryParse(a.substring('--year='.length)) ?? year;
    } else if (a.startsWith('--period=')) {
      final v = a.substring('--period='.length).toLowerCase();
      if (v == 'am' || v == 'morning') isMorning = true;
      if (v == 'pm' || v == 'afternoon') isMorning = false;
    } else if (a.startsWith('--mode=')) {
      mode = a.substring('--mode='.length);
    }
  }
  final outputPath = Path.join(flutterAppDir, 'assets', 'questions.json');

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('入力ファイルが見つかりません: $inputPath');
    exit(1);
  }

  final lines = await inputFile.readAsLines(encoding: utf8);

  final questions = <Map<String, dynamic>>[];

  int? currentNo;
  final textBuffer = StringBuffer();
  final currentChoices = <String>[];
  List<int> currentAnswers = []; // [1..5]

  void flush() {
    if (currentNo == null) return;
        if (currentChoices.length != 5 || currentAnswers.isEmpty) {
      stderr.writeln(
          '警告: 問$currentNo の解析が不完全です (choices=${currentChoices.length}, answer=${currentAnswers.isEmpty ? 'null' : currentAnswers}). スキップします。');
    } else {
      // ID: 午前は year*1000+no、午後は year*1000+100+no で衝突回避
      final id = year * 1000 + (isMorning ? currentNo! : 100 + currentNo!);
      // 先頭の番号表記（1． or 1.）はchoicesから取り除く
      final normalizedChoices = currentChoices.map((c) {
        final removed = c.replaceFirst(RegExp(r'^\s*[0-9]\s*[．\.]\s*'), '');
        return removed.trim();
      }).toList();

      questions.add({
        'id': id,
        'text': textBuffer.toString().trim(),
        'choices': normalizedChoices,
        'correct': currentAnswers.map((a) => a - 1).toList(),
        'type': currentAnswers.length >= 2 ? 'multiple' : 'single',
        'difficulty': '',
        'year': year,
        'isMorning': isMorning,
        'field': '',
        'explanation': '',
      });
    }
    // リセット
    currentNo = null;
    textBuffer.clear();
    currentChoices.clear();
    currentAnswers = [];
  }

  bool inQuestion = false;
  bool readingChoices = false;

  for (var raw in lines) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      // 空行はそのままスキップ。ただし本文の改行は保持したいので\nを追加。
      if (inQuestion && !readingChoices) {
        textBuffer.writeln();
      }
      continue;
    }

    // 問題行: "問題<番号>" のみ もしくは "問題<番号>  本文..." の両方に対応
    final qMatch = RegExp(r'^問題\s*(\d+)\s*(.*)$').firstMatch(line);
    if (qMatch != null) {
      // 新しい設問開始
      flush();
      inQuestion = true;
      readingChoices = false;
      currentNo = int.tryParse(qMatch.group(1)!);
      final trailing = qMatch.group(2)!.trim();
      if (trailing.isNotEmpty) {
        // 同一行に本文が続く場合は取り込む
        textBuffer.writeln(trailing);
      }
      continue;
    }

    if (!inQuestion) {
      // 設問開始前の行は無視（ヘッダなど）
      continue;
    }

    // 正解行（複数解答にも対応: 例 "1または2", "1 2", "1,2" など）。
    // コロンの有無や空白の有無に依存せず、「正解」または「解答」を含む行を拾う。
    if (line.contains('正解') || line.contains('解答') || line.contains('→')) {
      final tail = line;
      // 半角/全角の1～5を抽出
      final digitMatches = RegExp(r'[1-5１２３４５]').allMatches(tail);
      final digits = <int>[];
      for (final m in digitMatches) {
        final s = m.group(0)!;
        // 全角数字を半角に変換
        final code = s.codeUnitAt(0);
        int d;
        if (code >= 0xFF11 && code <= 0xFF15) { // '１'(FF11)～'５'(FF15)
          d = code - 0xFF10; // '１' -> 1
        } else {
          d = int.parse(s);
        }
        digits.add(d);
      }
      // 1～5の数字が1つも見つからない場合は未設定扱い
      if (digits.isNotEmpty) {
        // 重複を除去して昇順に
        final set = <int>{};
        for (final d in digits) {
          if (d >= 1 && d <= 5) set.add(d);
        }
        currentAnswers = set.toList()..sort();
      } else {
        currentAnswers = [];
      }
      continue;
    }

    // 選択肢行か？
    final choiceMatch =
        RegExp(r'^\s*([1-5])\s*[．\.]\s*(.*)\s*$').firstMatch(line);
    if (choiceMatch != null) {
      readingChoices = true;
      currentChoices.add('${choiceMatch.group(1)}．${choiceMatch.group(2)}');
      continue;
    }

    if (!readingChoices) {
      // 本文
      textBuffer.writeln(line);
    } else {
      // 選択肢読み取り中だが1～5以外の行は無視（注記など）
      // ただし、5個揃うまでは特に処理しない
    }
  }

  // 最終設問のflush
  flush();

  // ログ
  stdout.writeln('解析完了: ${questions.length}問');

  // 既存ファイルとのマージ
  final outFile = File(outputPath);
  List<Map<String, dynamic>> finalList = questions;
  stdout.writeln('DEBUG: mode=$mode, exists=${await outFile.exists()}');
  if (mode == 'append' && await outFile.exists()) {
    stdout.writeln('DEBUG: appendモード開始');
    try {
      final existingStr = await outFile.readAsString(encoding: utf8);
      stdout.writeln('DEBUG: 既存ファイル読み込み成功: ${existingStr.length} bytes');
      final existing = (json.decode(existingStr) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      stdout.writeln('DEBUG: 既存問題数: ${existing.length}');
      // idでマージ（新規が優先）
      final byId = <int, Map<String, dynamic>>{};
      for (final m in existing) {
        final id = (m['id'] as num).toInt();
        byId[id] = m;
      }
      for (final m in questions) {
        final id = (m['id'] as num).toInt();
        byId[id] = m;
      }
      finalList = byId.values.toList()
        ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      stdout.writeln('既存 ${existing.length} 件とマージし、合計 ${finalList.length} 件');
    } catch (e) {
      stderr.writeln('既存ファイルの読み込みに失敗: $e。上書き出力に切り替えます。');
      finalList = questions;
    }
  }
  // JSON出力（pretty）
  await outFile.create(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  await outFile.writeAsString(encoder.convert(finalList), encoding: utf8);

  stdout.writeln('出力完了: $outputPath');
}

/// 簡易パス結合
class Path {
  static String join(String a, [String? b, String? c, String? d]) {
    final parts = <String>[a];
    if (b != null) parts.add(b);
    if (c != null) parts.add(c);
    if (d != null) parts.add(d);
    return parts.join(Platform.pathSeparator);
  }

  static bool isAbsolute(String p) {
    if (p.isEmpty) return false;
    // Windows絶対パス判定（例 C:\ or \\server\share）
    final hasDrive = RegExp(r'^[a-zA-Z]:\\').hasMatch(p);
    final isUnc = p.startsWith('\\\\');
    final hasUnixRoot = p.startsWith('/');
    return hasDrive || isUnc || hasUnixRoot;
  }
}
