import 'package:flutter/material.dart';
import '../models/battle_models.dart';

class EquipmentPage extends StatefulWidget {
  final BattlePlayer player;
  const EquipmentPage({super.key, required this.player});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}
//
// プレイヤーの装備を確認・変更する画面。
// ・現在ステータス
// ・装備中（武器/防具/アクセ）
// ・所持装備一覧 → 「装備する」ボタン

class _EquipmentPageState extends State<EquipmentPage> {
  late BattlePlayer _player;

  // 0: weapon, 1: armor, 2: accessory
  int _tabIndex = 0;

  EquipmentSlot get _currentSlot =>
      _tabIndex == 0 ? EquipmentSlot.weapon : _tabIndex == 1 ? EquipmentSlot.armor : EquipmentSlot.accessory;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  // 簡易レアリティ判定（UI用）
  ({String label, Color color}) _rarityOf(Equipment e) {
    switch (e.rarity) {
      case EquipmentRarity.N:
        return (label: 'N', color: Colors.grey);
      case EquipmentRarity.R:
        return (label: 'R', color: Colors.blue);
      case EquipmentRarity.SR:
        return (label: 'SR', color: Colors.purple);
      case EquipmentRarity.SSR:
        return (label: 'SSR', color: Colors.amber);
      case EquipmentRarity.LR:
        return (label: 'LR', color: Colors.redAccent);
    }
  }

  Widget _slotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon:
        // メモ帳風: 白四角 + 横線2本
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Positioned(
                left: 6,
                top: 10,
                right: 6,
                child: Container(height: 2, color: Colors.grey.shade500),
              ),
              Positioned(
                left: 6,
                top: 20,
                right: 6,
                child: Container(height: 2, color: Colors.grey.shade400),
              ),
            ],
          ),
        );
      case EquipmentSlot.armor:
        // ベスト風: 薄い長方形2つ
        return SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 14, height: 26, decoration: BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 4),
                Container(width: 14, height: 26, decoration: BoxDecoration(color: Colors.blueGrey.shade300, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        );
      case EquipmentSlot.accessory:
        // リング: 枠線だけの円
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber.shade600, width: 3)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('装備')),
      body: Stack(
        children: [
          // 背景グラデーション + デコライン
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F9FA), Color(0xFFE9ECEF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -20,
            child: Container(width: 140, height: 2, color: Colors.grey.withOpacity(0.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCharacterCard(),
                  const SizedBox(height: 12),
                  _buildTabs(),
                  const SizedBox(height: 8),
                  _buildEquipListForCurrentTab(),
                ],
              ),
            ),
          ),
          _equippedFloatingPanel(),
        ],
      ),
    );
  }

  Widget _buildCharacterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: Colors.black12)],
      ),
      child: Row(
        children: [
          // Avatar風の円
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade600]),
              boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: Colors.black12)],
            ),
            child: const Center(
              child: Icon(Icons.medical_services, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lv.${_player.level}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('HP: ${_player.hp} / ${_player.maxHp}'),
                Text('スタミナ: ${_player.stamina} / ${_player.maxStamina}'),
                Text('攻撃: ${_player.attackPower}'),
                Text('防御: ${_player.defensePower}'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    Widget pill(String text, int index) {
      final selected = _tabIndex == index;
      return GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: selected
                ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700])
                : null,
            color: selected ? null : Colors.grey.shade200,
          ),
          child: Text(text, style: TextStyle(color: selected ? Colors.white : Colors.black)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            pill('武器', 0),
            pill('防具', 1),
            pill('アクセサリ', 2),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.black12),
      ],
    );
  }

  Widget _buildEquipListForCurrentTab() {
    final list = _player.equipInventory.where((e) => e.slot == _currentSlot).toList();
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('このカテゴリの装備はまだ手に入れていません。', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return Column(
      children: [
        for (final equip in list) _buildEquipCard(equip),
      ],
    );
  }

  Widget _buildEquipCard(Equipment equip) {
    // アクセサリは2枠対応
    final isEquipped = equip.slot == EquipmentSlot.accessory
        ? _player.equipment[EquipmentSlot.accessory]!.contains(equip)
        : _player.equipment[equip.slot]![0] == equip;
    final rarity = _rarityOf(equip);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.blue.withOpacity(.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rarity.color, width: 2),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _slotIcon(equip.slot),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(equip.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        // レアリティバッジ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarity.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: rarity.color.withOpacity(0.4)),
                          ),
                          child: Text(rarity.label, style: TextStyle(color: rarity.color, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_buildEquipDescription(equip), style: const TextStyle(color: Colors.black87)),
                    if (equip.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          equip.description,
                          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isEquipped
                  ? const SizedBox.shrink()
                  : ElevatedButton(
                      onPressed: () {
                        setState(() => _player.equip(equip));
                      },
                      child: const Text('装備する'),
                    ),
            ],
          ),
          if (isEquipped)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: const Text('装備中', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _equippedFloatingPanel() {
    String equipName(EquipmentSlot slot) {
      if (slot == EquipmentSlot.accessory) {
        final accs = _player.equipment[EquipmentSlot.accessory] ?? [null, null];
        final names = accs.map((e) => e?.name ?? 'なし').toList();
        return names.join(' / ');
      } else {
        return _player.equipment[slot]![0]?.name ?? 'なし';
      }
    }

    return Positioned(
      right: 20,
      bottom: 20,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('現在装備', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('武器: ${equipName(EquipmentSlot.weapon)}'),
            Text('防具: ${equipName(EquipmentSlot.armor)}'),
            Text('アクセ: ${equipName(EquipmentSlot.accessory)}'),
          ],
        ),
      ),
    );
  }

  String _buildEquipDescription(Equipment equip) {
    final parts = <String>[];
    if (equip.attackBonus != 0) {
      parts.add('攻+${equip.attackBonus}');
    }
    if (equip.defenseBonus != 0) {
      parts.add('防+${equip.defenseBonus}');
    }
    if (equip.maxHpBonus != 0) {
      parts.add('HP+${equip.maxHpBonus}');
    }
    if (equip.maxStaminaBonus != 0) {
      parts.add('スタミナ+${equip.maxStaminaBonus}');
    }
    if (parts.isEmpty) return '補正なし';
    return parts.join(' / ');
  }
}
