// lib/widgets/battle_background.dart
//
// ステージごとの背景を、グラデーション + 簡単な図形だけで描画するウィジェット
// 画像ファイルは使わず、BoxDecoration と Positioned で表現

import 'package:flutter/material.dart';

class BattleBackground extends StatelessWidget {
  final int stage;
  final Widget child;

  const BattleBackground({
    super.key,
    required this.stage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _backgroundForStage(stage);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: decoration,
      child: Stack(
        children: [
          // 装飾用の図形をステージごとに追加
          ..._buildDecorations(stage),
          child,
        ],
      ),
    );
  }

  // ステージごとの背景グラデーション
  BoxDecoration _backgroundForStage(int stage) {
    switch (stage) {
      case 1: // 透析スライム
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 2: // IABPゴーレム（明るめのブルーグレーに変更）
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A5A8C), Color(0xFF5A7FB8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 3: // ECMOドラゴン
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF0F766E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 4: // 人工呼吸ケルベロス
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF34D399)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 5: // PCPSリヴァイアサン
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 6: // 血液浄化フェニックス
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F1D1D), Color(0xFFF97316)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        );
      case 7: // ペースメーカーキング
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF4C1D95)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 8: // 除細動デーモン
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF7F1D1D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 9: // 麻酔器タイタン
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF022C22), Color(0xFF0F766E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 10: // ME機器エンペラー
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      default: // Stage 11以降：ICUシャドウ
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
    }
  }

  // ステージごとの装飾図形を生成
  List<Widget> _buildDecorations(int stage) {
    switch (stage) {
      case 1:
        return _stage1Decorations();
      case 2:
        return _stage2Decorations();
      case 3:
        return _stage3Decorations();
      case 4:
        return _stage4Decorations();
      case 5:
        return _stage5Decorations();
      case 6:
        return _stage6Decorations();
      case 7:
        return _stage7Decorations();
      case 8:
        return _stage8Decorations();
      case 9:
        return _stage9Decorations();
      case 10:
        return _stage10Decorations();
      default:
        return _stage11Decorations();
    }
  }

  // Stage 1: 透析スライム - 右下に円、左上に横線
  List<Widget> _stage1Decorations() {
    return [
      Positioned(
        right: 40,
        bottom: 60,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyan.withOpacity(0.2),
          ),
        ),
      ),
      Positioned(
        right: 20,
        bottom: 40,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyan.withOpacity(0.15),
          ),
        ),
      ),
      Positioned(
        left: 20,
        top: 30,
        child: Container(width: 80, height: 2, color: Colors.cyan.withOpacity(0.4)),
      ),
      Positioned(
        left: 20,
        top: 50,
        child: Container(width: 80, height: 2, color: Colors.cyan.withOpacity(0.3)),
      ),
      Positioned(
        left: 20,
        top: 70,
        child: Container(width: 80, height: 2, color: Colors.cyan.withOpacity(0.3)),
      ),
    ];
  }

  // Stage 2: IABPゴーレム - 左上にスポットライト、中央に水平ライン
  List<Widget> _stage2Decorations() {
    return [
      Positioned(
        left: -50,
        top: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 200,
        child: Container(height: 2, color: Colors.cyan.withOpacity(0.5)),
      ),
    ];
  }

  // Stage 3: ECMOドラゴン - 斜めライン、右側にリング
  List<Widget> _stage3Decorations() {
    return [
      Positioned(
        left: 100,
        top: 100,
        child: Transform.rotate(
          angle: -0.5,
          child: Container(width: 200, height: 2, color: Colors.teal.withOpacity(0.4)),
        ),
      ),
      Positioned(
        right: 150,
        top: 300,
        child: Transform.rotate(
          angle: 0.3,
          child: Container(width: 180, height: 2, color: Colors.teal.withOpacity(0.4)),
        ),
      ),
      Positioned(
        right: 80,
        top: 250,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.tealAccent.withOpacity(0.5), width: 3),
          ),
        ),
      ),
    ];
  }

  // Stage 4: 人工呼吸ケルベロス - サインカーブ風の斜めカーブ、左下に点
  List<Widget> _stage4Decorations() {
    return [
      Positioned(
        left: 50,
        top: 200,
        child: Transform.rotate(
          angle: 0.2,
          child: Container(width: 300, height: 3, color: Colors.greenAccent.withOpacity(0.4)),
        ),
      ),
      Positioned(
        left: 100,
        top: 350,
        child: Transform.rotate(
          angle: -0.15,
          child: Container(width: 250, height: 2, color: Colors.greenAccent.withOpacity(0.3)),
        ),
      ),
      Positioned(
        left: 20,
        bottom: 40,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
      Positioned(
        left: 35,
        bottom: 35,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
      Positioned(
        left: 48,
        bottom: 42,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    ];
  }

  // Stage 5: PCPSリヴァイアサン - 円弧、右上にジグザグ風ライン
  List<Widget> _stage5Decorations() {
    return [
      Positioned(
        left: -100,
        top: 200,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purple.withOpacity(0.4), width: 4),
          ),
        ),
      ),
      Positioned(
        left: -80,
        top: 220,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purple.withOpacity(0.3), width: 3),
          ),
        ),
      ),
      Positioned(
        right: 50,
        top: 80,
        child: Transform.rotate(
          angle: 0.3,
          child: Container(width: 100, height: 2, color: Colors.redAccent.withOpacity(0.4)),
        ),
      ),
      Positioned(
        right: 30,
        top: 100,
        child: Transform.rotate(
          angle: -0.3,
          child: Container(width: 80, height: 2, color: Colors.redAccent.withOpacity(0.4)),
        ),
      ),
    ];
  }

  // Stage 6: 血液浄化フェニックス - 上向きに明るくなる円、炎風三角形
  List<Widget> _stage6Decorations() {
    return [
      Positioned(
        left: 150,
        top: 50,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.3),
          ),
        ),
      ),
      Positioned(
        right: 100,
        top: 80,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.25),
          ),
        ),
      ),
      Positioned(
        left: 250,
        top: 150,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepOrange.withOpacity(0.2),
          ),
        ),
      ),
      // 炎っぽい三角形（斜めの長方形で代用）
      Positioned(
        left: 200,
        bottom: 0,
        child: Transform.rotate(
          angle: -0.2,
          child: Container(
            width: 80,
            height: 200,
            color: Colors.orange.withOpacity(0.2),
          ),
        ),
      ),
    ];
  }

  // Stage 7: ペースメーカーキング - 中央に太いライン、光点
  List<Widget> _stage7Decorations() {
    return [
      Positioned(
        left: 0,
        right: 0,
        top: 250,
        child: Container(height: 4, color: Colors.cyanAccent.withOpacity(0.6)),
      ),
      Positioned(
        left: 150,
        top: 245,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellowAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 350,
        top: 245,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellowAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 200,
        top: 245,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellowAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Stage 8: 除細動デーモン - ジグザグの雷、赤い帯
  List<Widget> _stage8Decorations() {
    return [
      Positioned(
        left: 100,
        top: 50,
        child: Transform.rotate(
          angle: 0.3,
          child: Container(width: 150, height: 3, color: Colors.yellow.withOpacity(0.6)),
        ),
      ),
      Positioned(
        left: 200,
        top: 150,
        child: Transform.rotate(
          angle: -0.4,
          child: Container(width: 120, height: 3, color: Colors.yellow.withOpacity(0.5)),
        ),
      ),
      Positioned(
        right: 150,
        top: 100,
        child: Transform.rotate(
          angle: 0.5,
          child: Container(width: 130, height: 3, color: Colors.yellow.withOpacity(0.6)),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 80,
        child: Container(height: 40, color: Colors.red.withOpacity(0.3)),
      ),
    ];
  }

  // Stage 9: 麻酔器タイタン - 左右に縦長方形、上部にリング
  List<Widget> _stage9Decorations() {
    return [
      Positioned(
        left: 30,
        top: 100,
        child: Container(
          width: 50,
          height: 300,
          color: Colors.teal.withOpacity(0.2),
        ),
      ),
      Positioned(
        right: 30,
        top: 100,
        child: Container(
          width: 50,
          height: 300,
          color: Colors.teal.withOpacity(0.2),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 50,
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 4),
            ),
          ),
        ),
      ),
    ];
  }

  // Stage 10: ME機器エンペラー - 基板パターン風、中央スポットライト
  List<Widget> _stage10Decorations() {
    return [
      // 基板パターン風の四角と線
      Positioned(
        left: 50,
        top: 100,
        child: Container(width: 80, height: 80, color: Colors.blueGrey.withOpacity(0.3)),
      ),
      Positioned(
        right: 80,
        top: 150,
        child: Container(width: 60, height: 60, color: Colors.blueGrey.withOpacity(0.25)),
      ),
      Positioned(
        left: 150,
        bottom: 120,
        child: Container(width: 70, height: 70, color: Colors.blueGrey.withOpacity(0.2)),
      ),
      Positioned(
        left: 100,
        top: 120,
        child: Container(width: 2, height: 200, color: Colors.cyan.withOpacity(0.4)),
      ),
      Positioned(
        right: 120,
        top: 180,
        child: Container(width: 150, height: 2, color: Colors.cyan.withOpacity(0.4)),
      ),
      // 中央スポットライト
      Positioned(
        left: 0,
        right: 0,
        top: 200,
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  // Stage 11以降: ICUシャドウ - 薄い四角枠、霧っぽい円
  List<Widget> _stage11Decorations() {
    return [
      Positioned(
        left: 80,
        top: 80,
        child: Container(
          width: 150,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
          ),
        ),
      ),
      Positioned(
        right: 100,
        top: 150,
        child: Container(
          width: 120,
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
          ),
        ),
      ),
      Positioned(
        left: 150,
        bottom: 100,
        child: Container(
          width: 140,
          height: 110,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 150,
        child: Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ),
    ];
  }
}
