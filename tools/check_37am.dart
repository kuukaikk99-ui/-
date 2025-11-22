import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/questions.json');
  final content = await file.readAsString();
  final List<dynamic> questions = json.decode(content);

  // 37回午前のID範囲: 37001～37090
  const startId = 37001;
  const endId = 37090;
  const expectedCount = 90;

  final ids37am = questions
      .where((q) => q['id'] >= startId && q['id'] <= endId)
      .map((q) => q['id'] as int)
      .toList()
    ..sort();

  final missingIds = <int>[];
  for (var i = startId; i <= endId; i++) {
    if (!ids37am.contains(i)) {
      missingIds.add(i);
    }
  }

  print('37回午前の取り込み状況:');
  print('ID範囲: $startId～$endId');
  print('期待数: $expectedCount問');
  print('実際数: ${ids37am.length}問');
  print('欠番: ${missingIds.length}問');
  if (missingIds.isNotEmpty) {
    print('欠番ID: $missingIds');
  }
}
