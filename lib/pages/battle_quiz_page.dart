// lib/pages/battle_quiz_page.dart
//
// このファイルでは、臨床工学技士国家試験の4択問題を使った
// 「バトルモード」画面を実装する。
// ・プレイヤーとモンスターのHPを持つ
// ・問題に正解するとモンスターにダメージ
// ・不正解だとプレイヤーがダメージ
// ・どちらかのHPが0以下になったら勝敗を判定する
//
// 既存の QuizProvider から問題データを取得して利用する。
// くーのアプリの「通常の問題画面」と同じ Question モデルを使う想定。
// Copilot で足りない部分を補完させたり、プロジェクトに合わせて修正する。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/battle_models.dart';
import '../providers/player_status_provider.dart';
import '../models/question.dart';
import '../providers/quiz_provider.dart';
import '../repositories/question_repository.dart';

import '../widgets/battle_background.dart';
import 'equipment_page.dart';

class BattleQuizPage extends StatefulWidget {
  final int initialStage;
  const BattleQuizPage({super.key, required this.initialStage});

  @override
  State<BattleQuizPage> createState() => _BattleQuizPageState();
}

class _BattleQuizPageState extends State<BattleQuizPage> with SingleTickerProviderStateMixin {
      // ダメージ表示用フラグ・値
      bool _showDamage = false;
      int _damageValue = 0;
    // MISS表示用フラグ
    bool _showMiss = false;
  late BattlePlayer _player;
  late Monster _monster;

  int _stage = 1;  // 現在のステージ
  int _currentIndex = 0;
  int _turn = 1;
  bool _isAnswered = false;
  int? _selectedIndex;
  bool? _isCorrect;

  // スキル関連
  Skill? _selectedSkill;

  // 簡単なアニメーション用フラグ
  bool _monsterHit = false;
  bool _playerHit = false;

  // モンスター登場アニメーション用
  late AnimationController _entranceController;

  // ドロップした装備
  Equipment? _lastDroppedEquipment;

  // バトルモード用：現在の問題プールをシャッフルして再セット
  void _shuffleQuestionsInProvider() {
    try {
      final quizProvider = context.read<QuizProvider>();
      if (quizProvider.questions.isEmpty) return;
      final shuffled = List<Question>.from(quizProvider.questions)..shuffle();
      // startQuiz を使って問題順のみ更新（Battle 側は独自のインデックスを持つため問題なし）
      quizProvider.startQuiz(shuffled);
    } catch (e) {
      debugPrint('問題シャッフル中にエラー: $e');
    }
  }

  Future<void> _loadQuestions({bool forceReload = false}) async {
    // QuizProviderから問題を取得
    try {
      final quizProvider = context.read<QuizProvider>();
      // 強制リロードするか、問題がない場合に読み込む
      if (forceReload || quizProvider.questions.isEmpty) {
        final repository = QuestionRepository();
        final List<Question> allQuestions = await repository.loadAllQuestions();
        // 第34〜38回のみ抽出
        final filtered = allQuestions.where((q) => q.year >= 34 && q.year <= 38).toList();
        filtered.shuffle();
        final List<Question> battleQuestions = filtered.take(90).toList();
        quizProvider.startQuiz(battleQuestions);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // エラーハンドリング
      debugPrint('問題の読み込みエラー: $e');
    }
  }

  // 現在のステージ番号に応じてモンスターを生成し、
  // ターン数や問題インデックスをリセットする。
  void _startStage() {
    setState(() {
      _monster = MonsterFactory.createForStage(_stage);

      _currentIndex = 0;
      _turn = 1;
      _isAnswered = false;
      _selectedIndex = null;
      _isCorrect = null;
      _selectedSkill = null;
      // ステージ開始時の全回復は削除
    });
  }

  @override
  void initState() {
    super.initState();

    // AnimationController を初期化
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 問題を読み込む＆シャッフル
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repository = QuestionRepository();
      final List<Question> questions = await repository.loadAllQuestions();
      final filtered = questions.where((q) => q.year >= 34 && q.year <= 38).toList();
      filtered.shuffle();
      final quizProvider = context.read<QuizProvider>();
      quizProvider.startQuiz(filtered.take(90).toList());
      _currentIndex = 0;

      // モンスター登場アニメーションを再生
      _entranceController.reset();
      _entranceController.forward();
    });

    // ==== プレイヤー初期化（Providerから取得） ====
    final provider = Provider.of<PlayerStatusProvider>(context, listen: false);
    _player = provider.player;

    // 初回のみ装備・アイテム・スキルをセット（レベル1時のみ）
    if (_player.level == 1 && _player.equipInventory.isEmpty) {
      _player.items.addAll([
        Item(
          name: '救急キット',
          description: 'HPを50回復する',
          healAmount: 50,
        ),
        Item(
          name: 'エナジードリンク',
          description: 'スタミナを20回復する',
          staminaRestore: 20,
        ),
      ]);
      _player.skills.addAll([
        Skill(
          name: '土下座',
          type: SkillType.defend,
          description: 'このターンの被ダメージを20%軽減と攻撃力80%低下',
          staminaCost: 5,
          power: 20, // 被ダメージ20%軽減
          cooldownTurns: 3,
        ),
      ]);
      final memoPad = Equipment(
        name: '新人CEのメモ帳',
        slot: EquipmentSlot.weapon,
        attackBonus: 1,
        defenseBonus: 0,
        rarity: EquipmentRarity.N,
        description: '新人臨床工学技士が最初に持つ必須アイテム。命を守る知識がここに書かれている。',
      );
      _player.addEquipment(memoPad);
      _player.equip(memoPad);
      final jisshuWear = Equipment(
        name: '実習着',
        slot: EquipmentSlot.armor,
        attackBonus: 0,
        defenseBonus: 1,
        rarity: EquipmentRarity.N,
        description: '軽く動ける実習用白衣。まだ頼りないが、初心の証。',
      );
      _player.addEquipment(jisshuWear);
      _player.equip(jisshuWear);
    }

    // ==== 最初のステージ開始 ====
    _stage = widget.initialStage;
    _startStage();
  }

  // 選択肢がタップされたときの処理。
  // 新仕様：
  // 1. プレイヤーが問題に回答
  // 2. 正解ならプレイヤー攻撃。不正解なら攻撃失敗
  // 3. モンスターが必ず攻撃
  void _onAnswerSelected(bool isCorrect, int selectedIndex) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedIndex = selectedIndex;
      _isCorrect = isCorrect;

      int damageToMonster = 0;
      int damageToPlayer = 0;

      // 1. プレイヤー攻撃（正解時のみ）
      if (isCorrect) {
        // 基本攻撃
        damageToMonster = _player.attackPower;
        // スキルが選択されていたら反映
        if (_selectedSkill != null && _selectedSkill!.isAvailable) {
          final skill = _selectedSkill!;
          if (_player.stamina >= skill.staminaCost) {
            _player.useStamina(skill.staminaCost);
            switch (skill.type) {
              case SkillType.attack:
                damageToMonster = (_player.attackPower * skill.power).round();
                break;
              case SkillType.heal:
                _player.hp += skill.power.round();
                if (_player.hp > _player.maxHp) {
                  _player.hp = _player.maxHp;
                }
                break;
              case SkillType.defend:
                if (skill.name == '土下座') {
                  // ダメージ計算時のみ攻撃力0.2倍
                  damageToMonster = (_player.attackPower * 0.2).round();
                }
                // 他の防御系スキルもここで処理可能
                break;
            }
            skill.putOnCooldown();
          }
        }
        // 実際のダメージ計算（攻撃力-敵防御力、最低0）
        final actualDamage = damageToMonster - _monster.defensePower;
        final finalDamage = actualDamage > 0 ? actualDamage : 0;
        _monster.takeDamage(finalDamage);
        _monsterHit = finalDamage > 0;
        // ダメージ表示
        if (finalDamage > 0) {
          setState(() {
            _damageValue = finalDamage;
            _showDamage = true;
          });
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            setState(() {
              _showDamage = false;
            });
          });
        }
        // 正解したので経験値付与
        _player.gainExp(10);
      } else {
        // 不正解時は攻撃失敗（ダメージ0）
        damageToMonster = 0;
        _monsterHit = false;
        // MISS表示
        setState(() {
          _showMiss = true;
        });
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _showMiss = false;
          });
        });
      }

      // 2. モンスター攻撃（毎ターン必ず）
      damageToPlayer = _monster.attackPower;
      // 防御スキルが選択されていて利用可能ならダメージ半減
      if (_selectedSkill != null &&
          _selectedSkill!.isAvailable &&
          _selectedSkill!.type == SkillType.defend &&
          _player.stamina >= _selectedSkill!.staminaCost) {
        _player.useStamina(_selectedSkill!.staminaCost);
        damageToPlayer = (damageToPlayer * 0.5).round();
        _selectedSkill!.putOnCooldown();
      }
      // プレイヤーにダメージを与える（防御力を考慮）
      final actualDamage = damageToPlayer - _player.defensePower;
      final finalDamage = actualDamage > 0 ? actualDamage : 1; // 最低1ダメージ
      _player.hp -= finalDamage;
      if (_player.hp < 0) _player.hp = 0;
      _playerHit = true;
      // ステータス変更をProviderに通知
      Provider.of<PlayerStatusProvider>(context, listen: false).updatePlayer((p) {});

      // アニメーションフラグを少しして戻す
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() {
          _monsterHit = false;
          _playerHit = false;
        });
      });

      // 勝敗判定
      if (_monster.hp <= 0) {
        _showResultDialog(true);
        return;
      }
      if (_player.hp <= 0) {
        _showResultDialog(false);
        return;
      }

      // ターン終了処理
      _endTurn();
    });
  }

  void _endTurn() {
    _turn++;
    _player.tickSkillCooldowns();

    // 回答後にスキル選択はリセット
    // 回答後にスキル選択はリセット
    _selectedSkill = null;
  }
  // 「次の問題へ」ボタンが押されたときの処理。
  void _goToNextQuestion(int totalQuestions) {
    if (_currentIndex + 1 >= totalQuestions) {
      // 問題がもうない場合は、「バトル終了」として結果を出してもOK。
      // ここでは一旦「モンスターのHPが残っていたら負け」という扱いにする。
      final isWin = _monster.hp <= 0 && _player.hp > 0;
      _showResultDialog(isWin);
      return;
    }

    setState(() {
      _currentIndex++;
      _isAnswered = false;
      _selectedIndex = null;
      _isCorrect = null;
    });
  }

  void _useItem(Item item) {
    setState(() {
      _player.healWithItem(item);
      _player.items.remove(item);
    });
  }

  void _showItemDialog() {
    if (_player.items.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('アイテム'),
          content: const Text('アイテムを持っていません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('アイテムを使う'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in _player.items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.description),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _useItem(item);
                      },
                      child: const Text('使う'),
                    ),
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
  }

  // 勝敗ダイアログを表示
  void _showResultDialog(bool isWin) {
    // 勝利したときだけドロップ判定＆全回復
    Equipment? droppedEquip;
    Item? droppedItem;
    if (isWin) {
      // HPとスタミナを全回復
      setState(() {
        _player.hp = _player.maxHp;
        _player.stamina = _player.maxStamina;
      });
      final dropResult = EquipmentDropTable.rollDrop(_stage);
      if (dropResult != null) {
        droppedEquip = dropResult.equipment;
        droppedItem = dropResult.item;
        setState(() {
          if (droppedEquip != null) {
            _lastDroppedEquipment = droppedEquip;
            _player.addEquipment(droppedEquip);
          } else {
            _lastDroppedEquipment = null;
          }
          if (droppedItem != null) {
            _player.items.add(droppedItem);
          }
        });
        // 装備追加後に明示的に画面更新
        if (droppedEquip != null) {
          setState(() {});
        }
      } else {
        setState(() {
          _lastDroppedEquipment = null;
        });
      }
    } else {
      setState(() {
        _lastDroppedEquipment = null;
        _player.reset(); // 敗北時にステータス・装備・アイテム・スキルを初期化
      });
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String dropText = '';
        if (droppedEquip != null) {
          dropText = '\n\n【装備ドロップ】${droppedEquip.name} を手に入れた！';
        } else if (droppedItem != null) {
          dropText = '\n\n【アイテムドロップ】${droppedItem.name} を手に入れた！';
        }
        return AlertDialog(
          title: Text(isWin ? 'ステージ$_stage クリア！' : '敗北…'),
          content: Text(
            isWin
                ? 'モンスターを倒した！$dropText\n\n次のステージに挑戦しますか？'
                : 'HP が0になってしまった…もう一度チャレンジしよう。',
          ),
          actions: [
            if (isWin)
              TextButton(
                onPressed: () async {
                  // 同じステージに再挑戦
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  await _loadQuestions(forceReload: true);
                  _shuffleQuestionsInProvider();
                  _startStage();
                },
                child: const Text('同じステージに再挑戦'),
              ),
            if (!isWin)
              TextButton(
                onPressed: () async {
                  // 敗北時の再挑戦
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  await _loadQuestions(forceReload: true);
                  _shuffleQuestionsInProvider();
                  _startStage();
                },
                child: const Text('もう一度挑戦'),
              ),
            TextButton(
              onPressed: () {
                // ステージ選択に戻る
                Navigator.of(context).pop(); // ダイアログ閉じる
                Navigator.of(context).pop(); // バトル画面を閉じる
              },
              child: const Text('ステージ選択に戻る'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final questions = quizProvider.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('バトルモード')),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('問題を読み込んでいます...'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('まず他のモードで問題を読み込んでから、バトルモードを開始してください')),
                );
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        )),
      );
    }

    final totalQuestions = questions.length;
    final question = questions[_currentIndex];
    final text = question.text;
    final List<String> options = question.choices;
    final int correctIndex = question.correct.isNotEmpty ? question.correct[0] : 0;
    final playerHpRatio = _player.maxHp == 0 ? 0.0 : _player.hp / _player.maxHp;
    final staminaRatio = _player.maxStamina == 0 ? 0.0 : _player.stamina / _player.maxStamina;

    // 装備中のactiveSkillを抽出（全スロット・全枠対応）
    final List<Skill> equippedSkills = _player.equipment.values
      .expand((list) => list)
      .where((e) => e != null && e.activeSkill != null)
      .map((e) => e!.activeSkill!)
      .toList();
    // プレイヤーの基本スキルと合成
    final List<Skill> availableSkills = [..._player.skills, ...equippedSkills];

    return Scaffold(
        backgroundColor: Colors.black, // 背景を黒に
        appBar: AppBar(
          title: Text('バトルモード - ステージ$_stage ターン$_turn'),
          backgroundColor: Colors.black.withOpacity(0.7), // AppBarを半透明に
          actions: [
          IconButton(
            icon: const Icon(Icons.construction),
            tooltip: '装備',
            onPressed: () async {
              // 装備画面を開いて、戻ってきたらステータスを更新
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EquipmentPage(player: _player),
                ),
              );
              setState(() {}); // ステータスバー更新
            },
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: _showItemDialog,
            tooltip: 'アイテム',
          ),
        ],
      ),
      body: BattleBackground(
        stage: _stage,
        child: Column(
          children: [
          // ===== プレイヤーステータス =====
          AnimatedOpacity(
            opacity: _playerHit ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lv.${_player.level} HP:${_player.hp}/${_player.maxHp}'),
                        LinearProgressIndicator(
                          value: playerHpRatio.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        Text('スタミナ:${_player.stamina}/${_player.maxStamina}'),
                        LinearProgressIndicator(
                          value: staminaRatio.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('攻撃:${_player.attackPower}'),
                      Text('防御:${_player.defensePower}'),
                      Text('EXP:${_player.exp}/${_player.expToNext}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ===== モンスター表示エリア（DQ風） =====
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildMonsterWithAnimation(),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // ===== コマンドウィンドウエリア =====
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  // スキル選択エリア
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'スキル:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final skill in availableSkills)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(
                                      '${skill.name}${skill.isAvailable ? '' : ' (${skill.currentCooldown})'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    selected: _selectedSkill == skill,
                                    onSelected: skill.isAvailable
                                        ? (selected) {
                                            setState(() {
                                              _selectedSkill = selected ? skill : null;
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_selectedSkill != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedSkill!.description,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 問題と選択肢
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '問題 ${_currentIndex + 1} / $totalQuestions',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  text,
                                  style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.3),
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      for (int i = 0; i < options.length; i++)
                                        SizedBox(
                                          width: 140,
                                          child: Card(
                                            elevation: (_isAnswered && i == _selectedIndex) ? 4 : 2,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            color: _isAnswered ? _getOptionColor(i, correctIndex) ?? Colors.white : Colors.white,
                                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            child: InkWell(
                                              onTap: _isAnswered
                                                  ? null
                                                  : () {
                                                      final isCorrect = (i == correctIndex);
                                                      _onAnswerSelected(isCorrect, i);
                                                    },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Radio<int>(
                                                      value: i,
                                                      groupValue: _selectedIndex,
                                                      onChanged: _isAnswered
                                                          ? null
                                                          : (value) {
                                                              if (value == null) return;
                                                              final isCorrect = (i == correctIndex);
                                                              _onAnswerSelected(isCorrect, i);
                                                            },
                                                    ),
                                                    Text(
                                                      options[i],
                                                      style: const TextStyle(fontSize: 13, height: 1.2),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ), // ← Expandedの閉じ括弧追加
                  // アイテム＆次へボタン
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showItemDialog,
                            icon: const Icon(Icons.medical_services),
                            label: Text(
                              'アイテム (${_player.items.length})',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isAnswered
                                ? () => _goToNextQuestion(totalQuestions)
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('次の問題へ', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // 回答後、選択肢の背景色を決めるためのヘルパー。
  
      // ステージ別のモンスター登場アニメーションを生成
      Widget _buildMonsterWithAnimation() {
        Widget monsterDisplay = Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Text(
                  _monster.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 画像があれば表示、なければ代わりにアイコンを表示
                SizedBox(
                  height: 120,
                  child: AnimatedScale(
                    scale: _monsterHit ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _monsterHit ? Colors.red.withOpacity(0.3) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _monster.imagePath.isNotEmpty
                          ? Image.asset(
                              _monster.imagePath,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              _monster.icon,
                              size: 80,
                              color: _monster.color,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // モンスターの最大HPに応じてHPバーの最大長を変化
                      const double minRatio = 0.5; // 一番弱い敵でも50%幅
                      const int hpMin = 60;        // ステージ1相当
                      const int hpMax = 330;       // ステージ10相当（これ以上は最大幅）
                      final double t = ((_monster.maxHp - hpMin) / (hpMax - hpMin)).clamp(0.0, 1.0);
                      final double barWidth = constraints.maxWidth * (minRatio + (1 - minRatio) * t);

                      return Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: barWidth,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: LinearProgressIndicator(
                              value: (_monster.maxHp == 0 ? 0.0 : _monster.hp / _monster.maxHp).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_monster.color),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text('モンスター HP: ${_monster.hp} / ${_monster.maxHp}'),
              ],
            ),
            if (_showMiss)
              Positioned(
                top: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MISS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            if (_showDamage)
              Positioned(
                top: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Text(
                    '-$_damageValue',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );

        // ステージに応じたアニメーションを適用
        return _applyStageAnimation(monsterDisplay, _monster.stage);
      }

      // ステージ番号に応じて登場アニメーションを切り替える
      Widget _applyStageAnimation(Widget child, int stage) {
        final animation = CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeOut,
        );

        switch (stage) {
          case 1:
            // ステージ1: スケール+フェード (透析スライム)
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                child: child,
              ),
            );

          case 2:
            // ステージ2: シェイク+フェード (IABPゴーレム)
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.elasticOut,
                )),
                child: child,
              ),
            );

          case 3:
            // ステージ3: エネルギー波展開 (ECMOドラゴン)
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.elasticOut,
                )),
                child: child,
              ),
            );

          case 4:
            // ステージ4: 霧から出現 (人工呼吸ケルベロス)
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );

          case 5:
            // ステージ5: 暗闇から浮上 (PCPSリヴァイアサン)
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );

          case 6:
            // ステージ6: 炎のパーティクル (血液浄化フェニックス)
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.5, end: 1.0).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOut,
                )),
                child: RotationTransition(
                  turns: Tween<double>(begin: 0.1, end: 0.0).animate(animation),
                  child: child,
                ),
              ),
            );

          case 7:
            // ステージ7: 稲妻 (ペースメーカーキング)
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.3, 1.0),
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            );

          case 8:
            // ステージ8: 電撃ショック (除細動デーモン)
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.bounceOut,
                )),
                child: child,
              ),
            );

          case 9:
            // ステージ9: スポットライト (麻酔器タイタン)
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: _entranceController,
                curve: Curves.easeIn,
              )),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.2, end: 1.0).animate(animation),
                child: child,
              ),
            );

          case 10:
            // ステージ10: データの柱 (ME機器エンペラー)
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );

          default:
            // ステージ11+: グリッチ効果 (ICUシャドウ)
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.5, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutExpo,
                )),
                child: child,
              ),
            );
        }
      }

  Color? _getOptionColor(int index, int correctIndex) {
    if (!_isAnswered) return null;
    if (index == correctIndex) {
      return Colors.green[300]; // より明るい緑に変更
    }
    if (index == _selectedIndex && _isCorrect == false) {
      return Colors.red[300]; // より明るい赤に変更
    }
    return null;
  }


  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }
}
