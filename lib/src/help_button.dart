import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 右上の「?」ヘルプ釦 — DESIGN.md §6。遊び方(How to Play)への共通の入口。
///
/// 全作で「遊び方=右上の help_outline」に統一するための単一の出所
/// (メニュー行と二重に置かない/各作で大きさ・色がドリフトしないように)。
/// アイコンは細めアウトライン・小さめ(§6: 18前後)・補助色 textMuted。
class HelpButton extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onTap;
  final String? tooltip;

  const HelpButton({
    super.key,
    required this.theme,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: theme.textMuted, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}
