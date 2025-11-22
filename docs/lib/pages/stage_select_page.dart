import 'battle_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_models.dart';
import 'equipment_page.dart';
import '../providers/player_status_provider.dart';

// ステージ番号からMonsterを取得する関数
Monster getMonsterForStage(int stage) {
  return MonsterFactory.createForStage(stage);
}

class StageSelectPage extends StatelessWidget {
  const StageSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerStatusProvider>(context).player;
    final List<int> stages = List<int>.generate(15, (i) => i + 1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ステージ選択'),
        actions: [
          IconButton(
            icon: const Icon(Icons.construction),
            tooltip: '装備',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EquipmentPage(player: player),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'アイテム',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('所持アイテム'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: player.items.isEmpty
                          ? const Text('アイテムを持っていません。')
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final item in player.items)
                                  ListTile(
                                    title: Text(item.name),
                                    subtitle: Text(item.description),
                                  ),
                              ],
                            ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                final monster = getMonsterForStage(stage);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BattleQuizPage(initialStage: stage),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [monster.color.withOpacity(0.7), monster.color.withOpacity(0.3)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: monster.color.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 上部: ステージバッジ＋右上アイコン
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'S$stage',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                monster.icon,
                                size: 18,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // モンスター名＋一言説明
                          Text(
                            monster.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (monster.description.isNotEmpty)
                            Text(
                              monster.description,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.85),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          // 中央: 大きなモンスターアイコン
                          Expanded(
                            child: Center(
                              child: Icon(
                                monster.icon,
                                size: 72,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ),
                          // 下部: HP/攻撃ステータス
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite, size: 12, color: Colors.red),
                                    const SizedBox(width: 3),
                                    Text(
                                      'HP: ${monster.maxHp}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.flash_on, size: 12, color: Colors.orange),
                                    const SizedBox(width: 3),
                                    Text(
                                      '攻撃: ${monster.attackPower}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
