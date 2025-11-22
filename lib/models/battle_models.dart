// lib/models/battle_models.dart
//
// バトルモード用のモデルクラスまとめ。
// ・Item …… 回復アイテムなど
// ・Equipment …… 武器/防具/アクセサリ
// ・Skill …… スキル（攻撃・防御・回復）
// ・BattlePlayer …… プレイヤー（レベル/経験値/スタミナなど）
// ・Monster …… 敵モンスター
// ・MonsterFactory …… ステージ番号に応じてモンスターを作る補助クラス

import 'dart:math';
import 'package:flutter/material.dart';

// ==== アイテム ====

enum ItemEffectType {
  none,
  attackBoost,
  attackAdd,
  defenseBoost,
  damageReduce,
  cureAll,
  blockAttack,
  multiBoost,
}

class Item {
  String name;
  String description;
  int healAmount; // HP回復量
  int staminaRestore; // スタミナ回復量
  ItemEffectType effectType;
  double effectValue;
  int effectDuration;
  double percentHeal;

  Item({
    required this.name,
    required this.description,
    this.healAmount = 0,
    this.staminaRestore = 0,
    this.effectType = ItemEffectType.none,
    this.effectValue = 0,
    this.effectDuration = 0,
    this.percentHeal = 0,
  });
}

// ==== 装備 ====

enum EquipmentSlot { weapon, armor, accessory }

enum EquipmentRarity { N, R, SR, SSR, LR }

class Equipment {
  String name;
  EquipmentSlot slot;
  int attackBonus;
  int defenseBonus;
  int maxHpBonus;
  int maxStaminaBonus;
  EquipmentRarity rarity;
  String description;
  Skill? activeSkill; // 装備のアクティブスキル（発動型）

  Equipment({
    required this.name,
    required this.slot,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.maxHpBonus = 0,
    this.maxStaminaBonus = 0,
    this.rarity = EquipmentRarity.N,
    this.description = '',
    this.activeSkill,
  });
}

// ==== スキル ====

enum SkillType { attack, defend, heal }

class Skill {
  String name;
  SkillType type;
  String description;
  int staminaCost;
  double power; // 攻撃力倍率・回復量・防御倍率など
  int cooldownTurns; // 何ターンに1回使えるか
  int currentCooldown;
  int fixedDamage;

  Skill({
    required this.name,
    required this.type,
    required this.description,
    required this.staminaCost,
    required this.power,
    required this.cooldownTurns,
    this.currentCooldown = 0,
    this.fixedDamage = 0,
  });

  bool get isAvailable => currentCooldown == 0;

  void putOnCooldown() {
    currentCooldown = cooldownTurns;
  }

  void tickCooldown() {
    if (currentCooldown > 0) {
      currentCooldown--;
    }
  }
}

// ==== プレイヤー ====

class BattlePlayer {
  int level;
  int exp;
  int expToNext;

  int maxHp;
  int hp;

  int maxStamina;
  int stamina;

  int attackPower;
  int defensePower;

  final List<Item> items;
  final List<Skill> skills;
  final Map<EquipmentSlot, List<Equipment?>> equipment;
  final List<Equipment> equipInventory;  // 所持している装備一覧

  BattlePlayer({
    required this.level,
    required this.exp,
    required this.expToNext,
    required this.maxHp,
    required this.hp,
    required this.maxStamina,
    required this.stamina,
    required this.attackPower,
    required this.defensePower,
    required this.items,
    required this.skills,
    List<Equipment>? equipInventory,
  }) : equipment = {
          EquipmentSlot.weapon: [null],
          EquipmentSlot.armor: [null],
          EquipmentSlot.accessory: [null, null], // アクセサリ2枠
        },
        equipInventory = equipInventory ?? [];

  void takeDamage(int damage) {
    int reduced = damage - defensePower;
    if (reduced < 0) reduced = 0;
    hp -= reduced;
    if (hp < 0) hp = 0;
  }

  /// 防御力を無視した固定ダメージを受ける
  void takeFixedDamage(int fixedDamage) {
    hp -= fixedDamage;
    if (hp < 0) hp = 0;
  }

  void useStamina(int amount) {
    stamina -= amount;
    if (stamina < 0) stamina = 0;
  }

  void healWithItem(Item item) {
    hp += item.healAmount;
    if (hp > maxHp) hp = maxHp;

    stamina += item.staminaRestore;
    if (stamina > maxStamina) stamina = maxStamina;
  }

  void equip(Equipment newEquip) {
    final slot = newEquip.slot;
    if (slot == EquipmentSlot.accessory) {
      // アクセサリ枠は2つまで
      // 既に同じ装備があれば何もしない
      if (equipment[slot]!.contains(newEquip)) return;
      // 空き枠に装備
      for (int i = 0; i < equipment[slot]!.length; i++) {
        if (equipment[slot]![i] == null) {
          equipment[slot]![i] = newEquip;
          maxHp += newEquip.maxHpBonus;
          maxStamina += newEquip.maxStaminaBonus;
          attackPower += newEquip.attackBonus;
          defensePower += newEquip.defenseBonus;
          if (hp > maxHp) hp = maxHp;
          if (stamina > maxStamina) stamina = maxStamina;
          return;
        }
      }
      // 2枠埋まっていたら最初の枠を上書き
      final old = equipment[slot]![0];
      if (old != null) {
        maxHp -= old.maxHpBonus;
        maxStamina -= old.maxStaminaBonus;
        attackPower -= old.attackBonus;
        defensePower -= old.defenseBonus;
      }
      equipment[slot]![0] = newEquip;
      maxHp += newEquip.maxHpBonus;
      maxStamina += newEquip.maxStaminaBonus;
      attackPower += newEquip.attackBonus;
      defensePower += newEquip.defenseBonus;
      if (hp > maxHp) hp = maxHp;
      if (stamina > maxStamina) stamina = maxStamina;
    } else {
      // 武器・防具は1枠
      final old = equipment[slot]![0];
      if (old != null) {
        maxHp -= old.maxHpBonus;
        maxStamina -= old.maxStaminaBonus;
        attackPower -= old.attackBonus;
        defensePower -= old.defenseBonus;
      }
      equipment[slot]![0] = newEquip;
      maxHp += newEquip.maxHpBonus;
      maxStamina += newEquip.maxStaminaBonus;
      attackPower += newEquip.attackBonus;
      defensePower += newEquip.defenseBonus;
      if (hp > maxHp) hp = maxHp;
      if (stamina > maxStamina) stamina = maxStamina;
    }
  }

  void gainExp(int amount) {
    exp += amount;
    while (exp >= expToNext) {
      exp -= expToNext;
      _levelUp();
    }
  }

  void _levelUp() {
    level++;
    maxHp += 10;
    maxStamina += 5;
    attackPower += 3;
    defensePower += 2;

    hp = maxHp;
    stamina = maxStamina;

    expToNext = (expToNext * 1.3).round();
  }

  void tickSkillCooldowns() {
    for (final skill in skills) {
      skill.tickCooldown();
    }
    // 装備のactiveSkillもクールダウン進行
    for (final equip in equipInventory) {
      if (equip.activeSkill != null) {
        equip.activeSkill!.tickCooldown();
      }
    }
  }

  // 装備をインベントリに追加
  void addEquipment(Equipment equip) {
    equipInventory.add(equip);
  }

  /// プレイヤーのステータス・装備・アイテム・スキルを初期化（敗北時用）
  void reset() {
    level = 1;
    exp = 0;
    expToNext = 50;
    maxHp = 100;
    hp = 100;
    maxStamina = 30;
    stamina = 30;
    attackPower = 10; // 初期攻撃力を10に設定
    defensePower = 5;
    items.clear();
    skills.clear();
    equipment[EquipmentSlot.weapon] = [null];
    equipment[EquipmentSlot.armor] = [null];
    equipment[EquipmentSlot.accessory] = [null, null];
    equipInventory.clear();
  }
}

// ==== モンスター ====

/// モンスター種別（ドロップ判定などで利用）
enum MonsterType {
  dialysisSlime, // 透析スライム（Stage1）
  iabpGolem, // IABPゴーレム（Stage2）
  ecmoDragon, // ECMOドラゴン（Stage3）
  ventCerberus, // 人工呼吸ケルベロス（Stage4）
  pcpsLeviathan, // PCPSリヴァイアサン（Stage5）
  bloodPuriPhoenix, // 血液浄化フェニックス（Stage6）
  pacemakerKing, // ペースメーカーキング（Stage7）
  defibDemon, // 除細動デーモン（Stage8）
  anesthesiaTitan, // 麻酔器タイタン（Stage9）
  meEmperor, // ME機器エンペラー（Stage10）
  icuShadow, // ICUシャドウ（Stage11以降）
}

class Monster {
  String name;
  int maxHp;
  int hp;
  int attackPower;
  int defensePower;
  String imagePath;
  IconData icon;  // モンスターのアイコン
  Color color;    // モンスターの色
  int stage;      // ステージ番号
  MonsterType type; // モンスター種別
  String description; // 一言説明

  Monster({
    required this.name,
    required this.maxHp,
    required this.hp,
    required this.attackPower,
    required this.defensePower,
    required this.imagePath,
    required this.icon,
    required this.color,
    required this.stage,
    required this.type,
    required this.description,
  });

  void takeDamage(int damage) {
    int reduced = damage - defensePower;
    if (reduced < 0) reduced = 0;
    hp -= reduced;
    if (hp < 0) hp = 0;
  }
}

// ==== モンスター生成用ファクトリ（ステージごとに違う敵を出す） ====

class MonsterFactory {
  /// ステージ番号からモンスターを生成する。
  /// ステージが上がるほど HP / 攻撃 / 防御 が少しずつ上昇する。
  static Monster createForStage(int stage) {
    // ここでステータスの基本値を段階的に強くしている
    final baseHp = 60 + (stage - 1) * 90;      // ステージごとに +90（3倍）
    final baseAttack = 10 + (stage - 1) * 30;  // ステージごとに +30（3倍）
    final baseDef = 1 + (stage - 1) * 10;      // ステージごとに +10

    switch (stage) {
      case 1:
        return Monster(
          name: '透析スライム',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.bubble_chart,
          color: Colors.teal,
          stage: 1,
          type: MonsterType.dialysisSlime,
          description: 'ぷるぷるしてるが油断禁物。',
        );
      case 2:
        return Monster(
          name: 'IABPゴーレム',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.shield,
          color: Colors.brown,
          stage: 2,
          type: MonsterType.iabpGolem,
          description: '鉄壁のサポート型巨人。',
        );
      case 3:
        return Monster(
          name: 'ECMOドラゴン',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.local_fire_department,
          color: Colors.redAccent,
          stage: 3,
          type: MonsterType.ecmoDragon,
          description: '循環を支配する災厄の竜。',
        );
      case 4:
        return Monster(
          name: '人工呼吸ケルベロス',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.air,
          color: Colors.lightBlue,
          stage: 4,
          type: MonsterType.ventCerberus,
          description: '3つの頭が3つの呼吸法を操る。',
        );
      case 5:
        return Monster(
          name: 'PCPSリヴァイアサン',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.water,
          color: Colors.indigo,
          stage: 5,
          type: MonsterType.pcpsLeviathan,
          description: '深海から現れる巨大循環の主。',
        );
      case 6:
        return Monster(
          name: '血液浄化フェニックス',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.auto_awesome,
          color: Colors.orange,
          stage: 6,
          type: MonsterType.bloodPuriPhoenix,
          description: '不純物を焼き尽くす再生の鳥。',
        );
      case 7:
        return Monster(
          name: 'ペースメーカーキング',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.favorite,
          color: Colors.pink,
          stage: 7,
          type: MonsterType.pacemakerKing,
          description: '律動を司る王。',
        );
      case 8:
        return Monster(
          name: '除細動デーモン',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.bolt,
          color: Colors.yellow,
          stage: 8,
          type: MonsterType.defibDemon,
          description: '稲妻の悪魔。',
        );
      case 9:
        return Monster(
          name: '麻酔器タイタン',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.science,
          color: Colors.green,
          stage: 9,
          type: MonsterType.anesthesiaTitan,
          description: '眠りの巨神。',
        );
      case 10:
        return Monster(
          name: 'ME機器エンペラー',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.workspace_premium,
          color: Colors.amber,
          stage: 10,
          type: MonsterType.meEmperor,
          description: '医療工学を極めし皇帝。',
        );
      default:
        return Monster(
          name: 'ICUシャドウ Lv.$stage',
          maxHp: baseHp,
          hp: baseHp,
          attackPower: baseAttack,
          defensePower: baseDef,
          imagePath: '',
          icon: Icons.monitor_heart,
          color: Colors.deepPurple,
          stage: stage,
          type: MonsterType.icuShadow,
          description: '深淵に潜む“影の患者”。',
        );
    }
  }
}

// ==== 装備ドロップテーブル ====

class EquipmentDropTable {
    /// ステージごとのアイテムリスト
    static List<Item> itemsForStage(int stage) {
      switch (stage) {
        case 1:
          return [
            Item(
              name: '透析スライム・浄化ジェル',
              description: 'HPを20回復',
              healAmount: 20,
            ),
            Item(
              name: '透析スライム・濾過ブースター',
              description: '次の攻撃のダメージ1.2倍',
              effectType: ItemEffectType.attackBoost,
              effectValue: 1.2,
            ),
          ];
        case 2:
          return [
            Item(
              name: 'IABP・圧補助パック',
              description: 'HPを25回復',
              healAmount: 25,
            ),
            Item(
              name: 'IABP・駆動加速チップ',
              description: '次の攻撃ダメージ+5',
              effectType: ItemEffectType.attackAdd,
              effectValue: 5,
            ),
          ];
        case 3:
          return [
            Item(
              name: 'ECMO・酸素化フラスコ',
              description: '最大HPの20%回復',
              percentHeal: 0.2,
            ),
            Item(
              name: 'ECMO・加温循環スパーク',
              description: '攻撃力を2ターン+30%',
              effectType: ItemEffectType.attackBoost,
              effectValue: 1.3,
              effectDuration: 2,
            ),
          ];
        case 4:
          return [
            Item(
              name: '気道加湿カプセル',
              description: '防御力+5（3ターン）',
              effectType: ItemEffectType.defenseBoost,
              effectValue: 5,
              effectDuration: 3,
            ),
            Item(
              name: 'ケルベロスの咆哮瓶',
              description: '攻撃力+10（1ターン）',
              effectType: ItemEffectType.attackAdd,
              effectValue: 10,
              effectDuration: 1,
            ),
          ];
        case 5:
          return [
            Item(
              name: '深海冷却パック',
              description: '受けるダメージ-20%（2ターン）',
              effectType: ItemEffectType.damageReduce,
              effectValue: 0.8,
              effectDuration: 2,
            ),
            Item(
              name: 'PCPS海流チャージャー',
              description: '次の攻撃+8',
              effectType: ItemEffectType.attackAdd,
              effectValue: 8,
            ),
          ];
        case 6:
          return [
            Item(
              name: '再生の炎塊（ほむらだま）',
              description: 'HPを40回復',
              healAmount: 40,
            ),
            Item(
              name: 'フェニックス・浄化の羽',
              description: '状態異常完全回復',
              effectType: ItemEffectType.cureAll,
            ),
          ];
        case 7:
          return [
            Item(
              name: '王家の電気回復薬',
              description: 'HP35回復',
              healAmount: 35,
            ),
            Item(
              name: 'ペーシング強化ルーン',
              description: '攻撃+15（1ターン）',
              effectType: ItemEffectType.attackAdd,
              effectValue: 15,
              effectDuration: 1,
            ),
          ];
        case 8:
          return [
            Item(
              name: 'ショックエネルギー残渣（ざんさ）',
              description: '次の攻撃+12',
              effectType: ItemEffectType.attackAdd,
              effectValue: 12,
            ),
            Item(
              name: '雷撃耐性ジェル',
              description: '受けるダメージ-30%（1ターン）',
              effectType: ItemEffectType.damageReduce,
              effectValue: 0.7,
              effectDuration: 1,
            ),
          ];
        case 9:
          return [
            Item(
              name: '鎮静ミスト',
              description: 'HP45回復',
              healAmount: 45,
            ),
            Item(
              name: '麻酔ガス強化弾',
              description: '敵の攻撃を1回無効化',
              effectType: ItemEffectType.blockAttack,
              effectDuration: 1,
            ),
          ];
        case 10:
          return [
            Item(
              name: 'ME皇帝の修復ユニット',
              description: '最大HPの40%回復',
              percentHeal: 0.4,
            ),
            Item(
              name: '皇帝制御インジェクター',
              description: '2ターン攻撃+20%、防御+20%',
              effectType: ItemEffectType.multiBoost,
              effectValue: 0.2,
              effectDuration: 2,
            ),
          ];
        default:
          return [
            Item(
              name: '虚無の結晶液',
              description: 'HPをランダムに（20〜60）回復',
              healAmount: 0, // 実装時はランダム値を使う
            ),
            Item(
              name: '深淵因子カプセル',
              description: '攻撃+20（1ターン）',
              effectType: ItemEffectType.attackAdd,
              effectValue: 20,
              effectDuration: 1,
            ),
          ];
      }
    }
  static final Random _rand = Random();

  /// モンスターごとに落ちる可能性のある装備一覧
  static List<Equipment> _candidatesForMonster(MonsterType type, {int? levelForIcuShadow}) {
    switch (type) {
      case MonsterType.dialysisSlime:
        return [
          Equipment(
            name: '滴下チューブ',
            slot: EquipmentSlot.weapon,
            attackBonus: 1,
            defenseBonus: 1,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: '滴下テンポアップ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +30%\nノーリスクで扱いやすい',
              staminaCost: 3,
              power: 1.3,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '除水パック',
            slot: EquipmentSlot.armor,
            maxHpBonus: 10,
            defenseBonus: 2,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: '除水ガード',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -40%',
              staminaCost: 4,
              power: 0.6,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '生体濾過コア',
            slot: EquipmentSlot.weapon,
            attackBonus: 3,
            defenseBonus: 3,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: '濾過エネルギーブラスト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +50%\nこのターンの被ダメージ -20%',
              staminaCost: 5,
              power: 1.5,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '超純水クリスタル',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 25,
            defenseBonus: 5,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: 'クリアウォーターヒール',
              type: SkillType.heal,
              description: 'HPを 最大HPの25%回復\nこのターンの被ダメージ -20%',
              staminaCost: 6,
              power: 0.25,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '透析王のメモリ核',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 40,
            attackBonus: 10,
            defenseBonus: 10,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '透析王の乱撃',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +120%（2.2倍）\n固定ダメージ +30',
              staminaCost: 8,
              power: 2.2,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.iabpGolem:
        return [
          Equipment(
            name: '補助バルーン片',
            slot: EquipmentSlot.weapon,
            attackBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: 'ミニ・インフレーション',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +25%\n（Nは軽い火力バフ）',
              staminaCost: 3,
              power: 1.25,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '駆動チューブ',
            slot: EquipmentSlot.weapon,
            attackBonus: 4,
            defenseBonus: 2,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'タイミングブースト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +45%\n（Rは単体強化の上位）',
              staminaCost: 4,
              power: 1.45,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: 'コンソール基板',
            slot: EquipmentSlot.armor,
            attackBonus: 6,
            defenseBonus: 3,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: 'エラーチェックガード',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -45%\nこのターンの正解ダメージ +15%\n（SRは複合：守り主体＋ちょい攻撃）',
              staminaCost: 5,
              power: 0.55,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: 'インフレーション・コア',
            slot: EquipmentSlot.accessory,
            attackBonus: 12,
            defenseBonus: 4,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: 'ハイパーインフレーション',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +80%\nHPを 最大HPの10%回復\n（SSRは強力火力＋軽い回復）',
              staminaCost: 6,
              power: 1.8,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '心拍同期バルーンハート',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 40,
            attackBonus: 18,
            defenseBonus: 8,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '完全同期バースト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +150%（2.5倍）\n固定ダメージ +40\n（LRは“ド派手火力”＋確定ダメージ）',
              staminaCost: 8,
              power: 2.5,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.ecmoDragon:
        return [
          Equipment(
            name: '酸素化ウロコ',
            slot: EquipmentSlot.armor,
            defenseBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: '酸素化シールド',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -30%\n（Nは軽い防御）',
              staminaCost: 3,
              power: 0.7,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '遠心ポンプの爪',
            slot: EquipmentSlot.weapon,
            attackBonus: 5,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'スピンカッター',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +45%\n（R武器は単発の火力アップ）',
              staminaCost: 4,
              power: 1.45,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '酸素化翼膜フラップ',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 20,
            defenseBonus: 4,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: '酸素補給',
              type: SkillType.heal,
              description: 'HPを 最大HPの20%回復\nこのターンの被ダメージ -20%\n（SRは回復＋軽防御の複合）',
              staminaCost: 5,
              power: 0.2,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '炎竜カニューレ',
            slot: EquipmentSlot.weapon,
            attackBonus: 10,
            defenseBonus: 6,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '炎竜ブレス',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +110%（2.1倍）\n（SSRはシンプルに強火力）',
              staminaCost: 7,
              power: 2.1,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '完全循環の心臓核',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 60,
            attackBonus: 15,
            defenseBonus: 12,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '完全循環モード',
              type: SkillType.attack,
              description: 'thisターンの正解ダメージ +130%（2.3倍）\nHPを 最大HPの25%回復\n（LRは“強火力＋実用回復”の最高位）',
              staminaCost: 8,
              power: 2.3,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.ventCerberus:
        return [
          Equipment(
            name: '気道ガイド',
            slot: EquipmentSlot.weapon,
            defenseBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: 'エアウェイブースト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +25%\n（N武器は軽い攻撃ブースト）',
              staminaCost: 3,
              power: 1.25,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '加温加湿ユニット（旧）',
            slot: EquipmentSlot.armor,
            defenseBonus: 5,
            maxHpBonus: 10,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'あったか保護',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -35%\n（R防具はしっかり守る）',
              staminaCost: 4,
              power: 0.65,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '3連気道バルブ',
            slot: EquipmentSlot.accessory,
            defenseBonus: 8,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: 'トリプルガード',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -45%\n（3つのバルブ＝強ガード）',
              staminaCost: 5,
              power: 0.55,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '三頭呼吸チャンバー',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 40,
            defenseBonus: 12,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '三頭換気',
              type: SkillType.heal,
              description: 'HPを 最大HPの20%回復\nこのターンの正解ダメージ +35%\n（SSRは攻撃と回復の両方を兼ねる）',
              staminaCost: 6,
              power: 0.2,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '吠え猛る人工呼吸マスク',
            slot: EquipmentSlot.weapon,
            maxHpBonus: 60,
            defenseBonus: 18,
            attackBonus: 10,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '三頭咆哮',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +150%（2.5倍）\n（LRは圧倒的な火力特化）',
              staminaCost: 8,
              power: 2.5,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.pcpsLeviathan:
        return [
          Equipment(
            name: '脱血チューブ',
            slot: EquipmentSlot.weapon,
            attackBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: '脱血チャージ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +25%\nさらに 最大HPの5%自傷\n（N武器はリスク付きの火力アップ）',
              staminaCost: 3,
              power: 1.25,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '送血フィン',
            slot: EquipmentSlot.weapon,
            attackBonus: 5,
            defenseBonus: 3,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'フィンブレード',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +40%\nさらに 敵防御を10%無視\n（R武器は安定攻撃＋防御無視で強め）',
              staminaCost: 5,
              power: 1.4,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '海底圧チャンバー',
            slot: EquipmentSlot.armor,
            maxHpBonus: 25,
            defenseBonus: 6,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: '深海圧シールド',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -45%\n（SRは強めの防御特化。深海＝高圧防御）',
              staminaCost: 4,
              power: 0.55,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '深海PCPSコア',
            slot: EquipmentSlot.accessory,
            attackBonus: 12,
            defenseBonus: 10,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: 'ディープポンプ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +70%\n（SSRは単純な高倍率火力アップ）',
              staminaCost: 6,
              power: 1.7,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '深淵循環エンジン',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 90,
            attackBonus: 18,
            defenseBonus: 15,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '深淵フルサイクル',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +100%（2倍）\nHPを 最大HPの10%回復\n（LRは火力＋回復のハイブリッド最強格）',
              staminaCost: 7,
              power: 2.0,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.bloodPuriPhoenix:
        return [
          Equipment(
            name: '浄化フィルター片',
            slot: EquipmentSlot.armor,
            maxHpBonus: 10,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: '軽浄化',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -25%\n（Nは軽い防御。浄化のイメージで小軽減）',
              staminaCost: 3,
              power: 0.75,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '火炎ダイアライザ',
            slot: EquipmentSlot.weapon,
            maxHpBonus: 20,
            defenseBonus: 3,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'フレアクラッシュ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +45%\n（火炎武器らしく素直に火力UP）',
              staminaCost: 5,
              power: 1.45,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '再生血液チャンバー',
            slot: EquipmentSlot.weapon,
            maxHpBonus: 30,
            attackBonus: 5,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: 'リジェネブレイク',
              type: SkillType.heal,
              description: 'HPを 最大HPの10%回復\nこのターン正解ダメージ +30%\n（SRは“再生”をテーマに攻撃＋回復の中間）',
              staminaCost: 5,
              power: 0.1,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '転生再循環コア',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 50,
            attackBonus: 10,
            defenseBonus: 8,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '転生ブースト',
              type: SkillType.heal,
              description: 'HPを 最大HPの25%回復\nこのターン正解ダメージ +40%\n（SSRは転生テーマの強力回復＋攻撃）',
              staminaCost: 6,
              power: 0.25,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '不死の浄化クリスタル',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 100,
            attackBonus: 20,
            defenseBonus: 20,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '不死フェニックスバースト',
              type: SkillType.heal,
              description: 'このターンの正解ダメージ +120%（2.2倍）\nHPを 最大HPの20%回復\n（LRはフェニックス＝蘇りの極致。火力＆回復の最高峰）',
              staminaCost: 7,
              power: 0.2,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.pacemakerKing:
        return [
          Equipment(
            name: 'リード線片',
            slot: EquipmentSlot.weapon,
            attackBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: 'リードショック',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +20%\n（Nはシンプルな火力UP）',
              staminaCost: 2,
              power: 1.2,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: 'ペーシングユニット（準上位）',
            slot: EquipmentSlot.weapon,
            attackBonus: 6,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'ペーシングブースト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +35%\nさらに敵防御を10%無視\n（Rは防御無視付きの火力UP）',
              staminaCost: 4,
              power: 1.35,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: 'デュアルチャンバー制御核',
            slot: EquipmentSlot.armor,
            attackBonus: 8,
            defenseBonus: 4,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: 'デュアルガード',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -40%\n（SRは防御特化。2室制御で安定防御）',
              staminaCost: 4,
              power: 0.6,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '王冠ペーシングコントローラ',
            slot: EquipmentSlot.accessory,
            attackBonus: 12,
            defenseBonus: 8,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '王冠ブースト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +60%\n（SSRは王冠の力で大幅火力UP）',
              staminaCost: 6,
              power: 1.6,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '電気伝導の王冠',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 70,
            attackBonus: 20,
            defenseBonus: 12,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '伝導フルチャージ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +100%（2倍）\nHPを最大HPの10%回復\n（LRは火力＋回復の最強格）',
              staminaCost: 7,
              power: 2.0,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.defibDemon:
        return [
          Equipment(
            name: '低圧パッド',
            slot: EquipmentSlot.armor,
            defenseBonus: 2,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: 'ソフトショック',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -20%\n（Nは軽いガード。低圧＝ソフトな衝撃）',
              staminaCost: 3,
              power: 0.8,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '高圧ショックパッド',
            slot: EquipmentSlot.weapon,
            attackBonus: 6,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: 'ショックスイング',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +40%\n（R武器は“高圧ショック”らしく火力強め）',
              staminaCost: 5,
              power: 1.4,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '電撃制御ユニット',
            slot: EquipmentSlot.weapon,
            attackBonus: 9,
            defenseBonus: 4,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: 'エレキチャージ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +60%\n（SRは火力寄り。電撃チャージ＝瞬間火力）',
              staminaCost: 5,
              power: 1.6,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '魔雷ショックモジュール',
            slot: EquipmentSlot.accessory,
            attackBonus: 15,
            defenseBonus: 8,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '魔雷ブースト',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +90%\n（SSRは電撃の極み。魔雷＝ほぼ倍火力）',
              staminaCost: 6,
              power: 1.9,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '終焉の雷撃コア',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 80,
            attackBonus: 25,
            defenseBonus: 15,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '終焉雷撃',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +150%（2.5倍）\n追加固定ダメージ 60\n（LRは破滅の一撃。最強の雷撃火力）',
              staminaCost: 8,
              power: 2.5,
              cooldownTurns: 5,
              fixedDamage: 60,
            ),
          ),
        ];
      case MonsterType.anesthesiaTitan:
        return [
          Equipment(
            name: 'ガスフロー管',
            slot: EquipmentSlot.armor,
            defenseBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: '眠りのガード',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -25%\n（Nは軽い鎮静防御）',
              staminaCost: 3,
              power: 0.75,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: '麻酔濃度コンソール',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 20,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: '濃度ショット',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +35%\n（麻酔濃度＝意識低下ショット → 攻撃ブースト）',
              staminaCost: 4,
              power: 1.35,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '鎮静増幅リング',
            slot: EquipmentSlot.weapon,
            maxHpBonus: 30,
            attackBonus: 5,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: '鎮静ウェーブ',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +50%\n（鎮静ウェーブ＝広がる眠気 → SR火力として標準）',
              staminaCost: 5,
              power: 1.5,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '麻酔支配レギュレーター',
            slot: EquipmentSlot.weapon,
            maxHpBonus: 50,
            attackBonus: 12,
            defenseBonus: 10,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '全身鎮静ブレイク',
              type: SkillType.attack,
              description: 'このターンの正解ダメージ +80%\n（SSRは巨体を一撃で眠らせる威力 → 高倍率）',
              staminaCost: 6,
              power: 1.8,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: '永眠の巨人コア',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 120,
            attackBonus: 18,
            defenseBonus: 25,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '永眠フィニッシュ',
              type: SkillType.heal,
              description: 'このターンの正解ダメージ +130%（2.3倍）\nHP 15%回復\n（LRは“永眠”のイメージ → 高火力＋回復の巨人仕様）',
              staminaCost: 7,
              power: 0.15,
              cooldownTurns: 5,
            ),
          ),
        ];
      case MonsterType.meEmperor:
        return [
          Equipment(
            name: '制御パネルの破片',
            slot: EquipmentSlot.weapon,
            attackBonus: 3,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: 'パネルクラッシュ',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +25%\n（Nは標準的な攻撃補正）',
              staminaCost: 3,
              power: 1.25,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: 'ME回路結晶',
            slot: EquipmentSlot.accessory,
            defenseBonus: 5,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: '安定化パルス',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -25%\n（回路の安定化＝ダメージ抑制のR枠）',
              staminaCost: 4,
              power: 0.75,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '機器統合ハーネス',
            slot: EquipmentSlot.weapon,
            attackBonus: 8,
            defenseBonus: 8,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: 'ハーネスシンクロ',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +50%\n（SR武器は万能強化。機器をまとめて力を引き出すイメージ）',
              staminaCost: 5,
              power: 1.5,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '神聖MEアーマー',
            slot: EquipmentSlot.armor,
            maxHpBonus: 80,
            attackBonus: 15,
            defenseBonus: 20,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '神聖シールド',
              type: SkillType.defend,
              description: 'このターンの被ダメージ -45%\n（SSRは皇帝の守り＝強力なシールド）',
              staminaCost: 5,
              power: 0.55,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: '皇覇スレイブコア',
            slot: EquipmentSlot.accessory,
            maxHpBonus: 150,
            attackBonus: 25,
            defenseBonus: 30,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '皇覇バースト',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +160%（2.6倍）\n追加固定ダメージ 80\n（皇帝の最終装備：圧倒的火力。全機器の力を支配）',
              staminaCost: 8,
              power: 2.6,
              cooldownTurns: 5,
              fixedDamage: 80,
            ),
          ),
        ];
      case MonsterType.icuShadow:
        return [
          Equipment(
            name: 'シャドウタグLv.N',
            slot: EquipmentSlot.accessory,
            rarity: EquipmentRarity.N,
            activeSkill: Skill(
              name: '影の一撃',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +20%\n（影の初歩的干渉。軽い火力UP）',
              staminaCost: 3,
              power: 1.2,
              cooldownTurns: 2,
            ),
          ),
          Equipment(
            name: 'シャドウタグLv.R',
            slot: EquipmentSlot.accessory,
            rarity: EquipmentRarity.R,
            activeSkill: Skill(
              name: '影の包囲',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +30%\nこのターンの被ダメージ -10%\n（影がまとわりつき攻守の微強化）',
              staminaCost: 4,
              power: 1.3,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: 'シャドウタグLv.SR',
            slot: EquipmentSlot.accessory,
            rarity: EquipmentRarity.SR,
            activeSkill: Skill(
              name: '闇の渦動',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +50%\nこのターン被ダメージ -15%\n（渦巻く影が力を引き出し、同時にダメージも吸収）',
              staminaCost: 5,
              power: 1.5,
              cooldownTurns: 3,
            ),
          ),
          Equipment(
            name: 'シャドウ晶核Lv.SSR',
            slot: EquipmentSlot.accessory,
            rarity: EquipmentRarity.SSR,
            activeSkill: Skill(
              name: '虚無の波動',
              type: SkillType.heal,
              description: 'このターン正解ダメージ +80%\nHPを 最大HPの15%回復\n（虚無エネルギーにより攻撃と再生を両立する高性能）',
              staminaCost: 6,
              power: 0.15,
              cooldownTurns: 4,
            ),
          ),
          Equipment(
            name: 'シャドウリングLv.LR',
            slot: EquipmentSlot.accessory,
            rarity: EquipmentRarity.LR,
            activeSkill: Skill(
              name: '深淵の零撃',
              type: SkillType.attack,
              description: 'このターン正解ダメージ +150%（2.5倍）\n追加固定ダメージ 60\n（深淵そのものの一撃。存在が視認できない速度の斬撃）',
              staminaCost: 8,
              power: 2.5,
              cooldownTurns: 5,
              fixedDamage: 60,
            ),
          ),
        ];
    }
  }


  /// 新ドロップ判定。nullなら何も落ちない。装備/アイテムはDropResultで返す。
  static DropResult? rollDrop(int stage) {
    // 50%: 何も落ちない
    if (_rand.nextDouble() < 0.5) return null;
    // 50%: 装備 or アイテム
    final isEquip = _rand.nextBool();
    if (isEquip) {
      // 装備抽選
      final rarityRoll = _rand.nextDouble();
      EquipmentRarity rarity;
      if (rarityRoll < 0.01) {
        rarity = EquipmentRarity.LR;
      } else if (rarityRoll < 0.05) {
        rarity = EquipmentRarity.SSR;
      } else if (rarityRoll < 0.20) {
        rarity = EquipmentRarity.SR;
      } else if (rarityRoll < 0.50) {
        rarity = EquipmentRarity.R;
      } else {
        rarity = EquipmentRarity.N;
      }
      // フォールバック処理
      final type = stage <= 10 ? _stageToType(stage) : MonsterType.icuShadow;
      final candidates = EquipmentDropTable._candidatesForMonster(type, levelForIcuShadow: stage);
      Equipment? equip = EquipmentDropTable._pickEquipmentWithFallback(candidates, rarity);
      if (equip != null) {
        return DropResult(equipment: equip);
      } else {
        // どのレア度もなければ何も落ちない
        return null;
      }
    } else {
      // アイテム抽選
      final items = EquipmentDropTable.itemsForStage(stage);
      if (items.isEmpty) return null;
      final item = items[EquipmentDropTable._rand.nextInt(items.length)];
      return DropResult(item: item);
    }
  }

  /// 指定レア度の装備がなければ下位レア度へフォールバック
  static Equipment? _pickEquipmentWithFallback(List<Equipment> list, EquipmentRarity rarity) {
    final order = [EquipmentRarity.LR, EquipmentRarity.SSR, EquipmentRarity.SR, EquipmentRarity.R, EquipmentRarity.N];
    int start = order.indexOf(rarity);
    for (int i = start; i < order.length; i++) {
      final filtered = list.where((e) => e.rarity == order[i]).toList();
      if (filtered.isNotEmpty) {
        return filtered[EquipmentDropTable._rand.nextInt(filtered.length)];
      }
    }
    return null;
  }

  /// ドロップ結果（装備 or アイテム）
  static MonsterType _stageToType(int stage) {
    if (stage <= 10) {
      return [
        MonsterType.dialysisSlime,
        MonsterType.iabpGolem,
        MonsterType.ecmoDragon,
        MonsterType.ventCerberus,
        MonsterType.pcpsLeviathan,
        MonsterType.bloodPuriPhoenix,
        MonsterType.pacemakerKing,
        MonsterType.defibDemon,
        MonsterType.anesthesiaTitan,
        MonsterType.meEmperor,
      ][stage - 1];
    }
    return MonsterType.icuShadow;
  }
}

class DropResult {
  final Equipment? equipment;
  final Item? item;
  DropResult({this.equipment, this.item});
}
