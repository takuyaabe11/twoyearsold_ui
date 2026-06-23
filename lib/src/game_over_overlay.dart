import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'l10n.dart';
import 'primary_action.dart';

/// 勝敗オーバーレイ — DESIGN.md §10.1。全作共通の定型:
/// 「**薄い**スクリム + 大見出し + `New Game`(朱 + `→`) + `Home`」。
///
/// 各作が勝敗画面を独自実装すると、スクリム濃度・余白・朱の使い方がドリフトする
/// (監査で Minesweeper/Gobblet/2048 のスクリムが濃すぎた)。ここを単一の出所にする。
/// [title] は勝敗文(`l10n.victory`/`defeat`/`draw` 等)を呼び出し側が渡す。
/// [accent]=true で見出しを朱に(勝ち等)。[detail] にスコアやレビューを差し込める。
class GameOverOverlay extends StatelessWidget {
  final AppTheme theme;
  final L10n l10n;
  final String title;
  final bool accent;
  final Widget? detail;
  final VoidCallback onNewGame;
  final VoidCallback onHome;

  const GameOverOverlay({
    super.key,
    required this.theme,
    required this.l10n,
    required this.title,
    required this.onNewGame,
    required this.onHome,
    this.accent = false,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 薄いスクリム(盤が透けて残る)。§10.1「薄い」。
      color: theme.background.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: theme.displayFontFamily,
              fontFamilyFallback: theme.fontFamilyFallback,
              fontSize: 44,
              height: 1.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
              color: accent ? theme.accent : theme.textPrimary,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 16),
            detail!,
          ],
          const SizedBox(height: 28),
          PrimaryAction(
            theme: theme,
            label: l10n.newGame,
            onTap: onNewGame,
            expand: false,
          ),
          const SizedBox(height: 4),
          // 副アクション: Home(塗らない・textMuted のテキスト)。
          GestureDetector(
            onTap: onHome,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                l10n.home,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: theme.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
