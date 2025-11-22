import 'package:flutter/material.dart';
import '../models/battle_models.dart';

class PlayerStatusProvider with ChangeNotifier {
  late BattlePlayer _player;

  PlayerStatusProvider() {
    // 初期化（必要に応じて初期値を調整）
    _player = BattlePlayer(
      level: 1,
      exp: 0,
      expToNext: 50,
      maxHp: 100,
      hp: 100,
      maxStamina: 40,
      stamina: 40,
      attackPower: 10, // 初期攻撃力を10に修正
      defensePower: 5,
      items: [],
      skills: [],
    );
  }

  BattlePlayer get player => _player;

  void setPlayer(BattlePlayer player) {
    _player = player;
    notifyListeners();
  }

  void updatePlayer(void Function(BattlePlayer) updater) {
    updater(_player);
    notifyListeners();
  }
}
