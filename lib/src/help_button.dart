import 'package:flutter/material.dart';

/// 右上の「?」ヘルプ釦 — DESIGN.md §6。遊び方(How to Play)への共通の入口。
///
/// 全作で「遊び方=右上の help_outline」に統一するための単一の出所
/// (メニュー行と二重に置かない/各作で大きさ・色がドリフトしないように)。
/// アイコンは細めアウトライン・小さめ(§6: 18前後)・補助色。テーマ実装に依存しない
/// よう色は明示的に受け取る(独自テーマの作でも使える。StarPicker と同方針)。
class HelpButton extends StatelessWidget {
  /// アイコン色(通常は補助色 textMuted / noteText)。
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  const HelpButton({
    super.key,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: color, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}
