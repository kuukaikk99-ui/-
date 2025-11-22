import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/questions.json');
  if (!await file.exists()) {
    stderr.writeln('assets/questions.json が見つかりません');
    exit(1);
  }
  final content = await file.readAsString();
  final List<dynamic> questions = json.decode(content);

  // 38回午前のID範囲: 38001～38090
  const startId = 38001;
  const endId = 38090;
  const expectedCount = 90;

  final ids = questions
      .where((q) => q['id'] is int && q['id'] >= startId && q['id'] <= endId)
      .map((q) => q['id'] as int)
      .toList()
    ..sort();

  final missingIds = <int>[];
  for (var i = startId; i <= endId; i++) {
    if (!ids.contains(i)) {
      missingIds.add(i);
    }
  }

  print('38回午前の取り込み状況:');
  print('ID範囲: $startId～$endId');
  print('期待数: $expectedCount問');
  print('実際数: ${ids.length}問');
  print('欠番: ${missingIds.length}問');
  if (missingIds.isNotEmpty) {
    print('欠番ID: $missingIds');
  }
}
