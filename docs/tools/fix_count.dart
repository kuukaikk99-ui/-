import 'dart:convert';
import 'dart:io';

// Usage: dart fix_count.dart <year:int> <difficulty:easy|normal|hard> <session:am|pm>
// Removes one question if the specified subset has > 30 items (takes the highest id).

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('Usage: dart fix_count.dart <year> <difficulty:easy|normal|hard> <session:am|pm>');
    exit(64);
  }
  final year = int.tryParse(args[0]);
  final diff = args[1];
  final session = args[2];
  if (year == null || !['easy','normal','hard'].contains(diff) || !['am','pm'].contains(session)) {
    stderr.writeln('Invalid arguments');
    exit(64);
  }
  final isMorning = session == 'am';

  const path = r'C:\\Users\\kuuka\\OneDrive\\ドキュメント\\くーの臨床工学技士国家試験対策\\flutter_app\\assets\\questions.json';
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('questions.json not found');
    exit(1);
  }

  final list = (jsonDecode(await file.readAsString()) as List).cast<Map<String, dynamic>>();
  bool sel(Map<String, dynamic> q) => q['year'] == year && q['difficulty'] == diff && q['isMorning'] == isMorning;

  final subset = list.where(sel).toList();
  stdout.writeln('Count before -> year:$year diff:$diff ${isMorning ? '午前' : '午後'}: ${subset.length}');

  if (subset.length > 30) {
    subset.sort((a,b)=> (a['id'] as int).compareTo(b['id'] as int));
    final removeId = subset.last['id'] as int;
    list.removeWhere((q) => q['id'] == removeId);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(list));
    final after = list.where(sel).length;
    stdout.writeln('Removed id=$removeId. Count after: $after. Total: ${list.length}');
  } else {
    stdout.writeln('No action needed.');
  }
}