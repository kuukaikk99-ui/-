import 'package:flutter/material.dart';
import '../models/battle_models.dart';

class PlayerStatusBar extends StatelessWidget {
  final BattlePlayer player;
  const PlayerStatusBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // アイコン
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade300,
              child: Text('Lv.${player.level}', style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            // HP/スタミナ/攻撃/防御
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HP: ${player.hp} / ${player.maxHp}'),
                  Text('スタミナ: ${player.stamina} / ${player.maxStamina}'),
                  Text('攻撃: ${player.attackPower}  防御: ${player.defensePower}'),
                ],
              ),
            ),
            // 装備
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('武器: ${player.equipment[EquipmentSlot.weapon]![0]?.name ?? "なし"}', style: const TextStyle(fontSize: 12)),
                Text('防具: ${player.equipment[EquipmentSlot.armor]![0]?.name ?? "なし"}', style: const TextStyle(fontSize: 12)),
                Text('アクセ: ${_accessoryNames(player)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // アクセサリ2枠の名前を連結して表示
  String _accessoryNames(BattlePlayer player) {
    final accs = player.equipment[EquipmentSlot.accessory] ?? [null, null];
    final names = accs.map((e) => e?.name ?? 'なし').toList();
    return names.join(' / ');
  }
}
