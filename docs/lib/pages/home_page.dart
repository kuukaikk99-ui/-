import 'package:flutter/material.dart';
import 'year_mode_page.dart';
import 'history_page.dart';
import 'original_mode_page.dart';
import 'stage_select_page.dart';
import 'range_mode_page.dart';
import '../models/battle_models.dart';

// モード選択・履歴カード共通ウィジェット

// モード選択・履歴カード共通ウィジェット
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverScaleCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ホバー・クリック時のスケールアニメーション
class _HoverScaleCard extends StatefulWidget {
  final Widget child;
  const _HoverScaleCard({required this.child});

  @override
  State<_HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<_HoverScaleCard> {
  double _scale = 1.0;
  bool _hovering = false;
  bool _pressed = false;

  void _onEnter(PointerEvent e) {
    setState(() {
      _hovering = true;
      if (!_pressed) _scale = 1.05;
    });
  }

  void _onExit(PointerEvent e) {
    setState(() {
      _hovering = false;
      if (!_pressed) _scale = 1.0;
    });
  }

  void _onTapDown(TapDownDetails d) {
    setState(() {
      _pressed = true;
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails d) {
    setState(() {
      _pressed = false;
      _scale = _hovering ? 1.05 : 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _pressed = false;
      _scale = _hovering ? 1.05 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 仮の初期プレイヤー（本来はProviderや永続化から取得）
    final player = BattlePlayer(
      level: 1,
      exp: 0,
      expToNext: 100,
      maxHp: 100,
      hp: 100,
      maxStamina: 40,
      stamina: 40,
      attackPower: 10,
      defensePower: 5,
      items: [],
      skills: [],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('くーの臨床工学技士国家試験対策'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: const Color(0xFFF5F7FB),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // ① 上部タイトルバー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF32C5A5), Color(0xFF27B48A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '問題回答',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ② 4つのモードカードグリッド
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardSize = constraints.maxWidth < 400 ? 140.0 : 160.0;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _ModeCard(
                          title: '年度別モード',
                          subtitle: '年度・午前/午後を選択',
                          icon: Icons.calendar_month,
                          color: const Color(0xFF4FC3F7),
                          size: cardSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const YearModePage(),
                              ),
                            );
                          },
                        ),
                        _ModeCard(
                          title: 'ランダムモード',
                          subtitle: 'ランダム出題',
                          icon: Icons.shuffle,
                          color: const Color(0xFFFFCA28),
                          size: cardSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RangeModePage(),
                              ),
                            );
                          },
                        ),
                        _ModeCard(
                          title: 'バトルモード',
                          subtitle: 'モンスターと戦う',
                          icon: Icons.flash_on,
                          color: const Color(0xFFFF7043),
                          size: cardSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StageSelectPage(),
                              ),
                            );
                          },
                        ),
                        _ModeCard(
                          title: 'オリジナル問題',
                          subtitle: '自作問題で演習',
                          icon: Icons.lightbulb,
                          color: const Color(0xFF81C784),
                          size: cardSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OriginalModePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // ③ 履歴カード（ModeCardデザインで統一）
            SafeArea(
              child: Center(
                child: _ModeCard(
                  title: '履歴を見る',
                  subtitle: '過去の解答履歴',
                  icon: Icons.history,
                  color: const Color(0xFF32C5A5),
                  size: 160,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
