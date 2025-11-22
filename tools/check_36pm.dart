import 'dart:convert';
import 'dart:io';

void main() async {
  final jsonFile = File('assets/questions.json');
  final jsonStr = await jsonFile.readAsString(encoding: utf8);
  final list = (json.decode(jsonStr) as List).cast<Map<String, dynamic>>();
  
  final ids = <int>{};
  for (final q in list) {
    ids.add((q['id'] as num).toInt());
  }
  
  // 36回午後のID範囲: 36101～36190
  final missing = <int>[];
  for (int i = 36101; i <= 36190; i++) {
    if (!ids.contains(i)) {
      missing.add(i);
    }
  }
  
  print('36回午後の取り込み状況:');
  print('  ID範囲: 36101～36190');
  print('  期待数: 90問');
  print('  実際数: ${90 - missing.length}問');
  
  if (missing.isEmpty) {
    print('  ✓ 全問取り込み完了');
  } else {
    print('  欠番: ${missing.length}問');
    print('  欠番ID: $missing');
  }
}
