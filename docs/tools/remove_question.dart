import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final idToRemove = args.isNotEmpty ? int.parse(args.first) : 1;
  const path = r'C:\\Users\\kuuka\\OneDrive\\ドキュメント\\くーの臨床工学技士国家試験対策\\flutter_app\\assets\\questions.json';
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('questions.json not found');
    exit(1);
  }
  final list = jsonDecode(await file.readAsString()) as List;
  final before = list.length;
  final filtered = list.where((e) => (e is Map && e['id'] != idToRemove)).toList();
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(filtered));
  stdout.writeln('Removed id=$idToRemove: ${before - filtered.length} item(s). Now ${filtered.length} total.');
}
