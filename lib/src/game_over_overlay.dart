import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'primary_action.dart';

/// 勝敗オーバーレイ — DESIGN.md §10.1。全作共通の定型:
/// 「**薄い**スクリム + 大見出し + 主要アクション(朱 + `→`) + `Home`」。
///
/// 各作が勝敗画面を独自実装すると、スクリム濃度・余白・朱の使い方がドリフトする
/// (監査で Minesweeper/Gobblet/2048 のスクリムが濃すぎた)。ここを単一の出所にする。
/// 文言は L10n クラスに縛られないよう文字列で受け取る(独自 l10n の作でも使える)。
///
/// [primaryLabel]/[onPrimary] が主要アクション(朱+→)。多くの作では「New Game」だが、
/// 2048 の勝利時のように「Keep Going」を主にしたい場合もあるため汎用名にしてある。
/// [secondaryLabel]/[onSecondary] は任意の副テキストアクション(例: 勝利時の New Game)。
/// [homeLabel]/[onHome] は Home。[detail] にスコアやレビューを差し込める。
class GameOverOverlay extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final bool accent;
  final Widget? detail;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String homeLabel;
  final VoidCallback onHome;

  const GameOverOverlay({
    super.key,
    required this.theme,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    required this.homeLabel,
    required this.onHome,
    this.accent = false,
    this.detail,
    this.secondaryLabel,
    this.onSecondary,
  });

  Widget _textAction(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.textMuted,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );

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
            label: primaryLabel,
            onTap: onPrimary,
            expand: false,
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 2),
            _textAction(secondaryLabel!, onSecondary!),
          ],
          const SizedBox(height: 2),
          _textAction(homeLabel, onHome),
        ],
      ),
    );
  }
}
