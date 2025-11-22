import 'dart:convert';
import 'dart:io';

void main() async {
  const path = r'C:\\Users\\kuuka\\OneDrive\\ドキュメント\\くーの臨床工学技士国家試験対策\\flutter_app\\assets\\questions.json';
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('questions.json not found');
    exit(1);
  }
  final list = (jsonDecode(await file.readAsString()) as List).cast<Map<String, dynamic>>();

  bool isTarget(Map<String, dynamic> q, {required bool morning}) =>
      (q['year'] == 34 && q['difficulty'] == 'normal' && q['isMorning'] == morning);

  final morning = list.where((q) => isTarget(q, morning: true)).toList();
  final afternoon = list.where((q) => isTarget(q, morning: false)).toList();

  stdout.writeln('Counts before -> 中級 午前:${morning.length}, 午後:${afternoon.length}');

  bool changed = false;
  // 優先: 件数が31の方から1問削除。複数31なら午前を優先して削除。
  if (morning.length > 30) {
    morning.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    final removeId = morning.last['id'] as int;
    list.removeWhere((q) => q['id'] == removeId);
    stdout.writeln('Removed from 午前: id=$removeId');
    changed = true;
  } else if (afternoon.length > 30) {
    afternoon.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    final removeId = afternoon.last['id'] as int;
    list.removeWhere((q) => q['id'] == removeId);
    stdout.writeln('Removed from 午後: id=$removeId');
    changed = true;
  } else {
    stdout.writeln('No subset has >30. No change.');
  }

  if (changed) {
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(list));
    final m2 = list.where((q) => isTarget(q, morning: true)).length;
    final a2 = list.where((q) => isTarget(q, morning: false)).length;
    stdout.writeln('Counts after  -> 中級 午前:$m2, 午後:$a2');
    stdout.writeln('Total: ${list.length}');
  }
}