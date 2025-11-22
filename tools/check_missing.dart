import 'dart:convert';
import 'dart:io';

void main() {
  var json = jsonDecode(File('assets/questions.json').readAsStringSync());
  var ids = (json as List)
      .map((q) => q['id'] as int)
      .where((id) => id >= 35101 && id <= 35190)
      .toList()
    ..sort();
  
  var missing = <int>[];
  for (int i = 35101; i <= 35190; i++) {
    if (!ids.contains(i)) missing.add(i);
  }
  
  print('欠けているID: $missing');
  print('導入済み: ${ids.length}問');
}
