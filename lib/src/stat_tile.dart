import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// 統計・スコアの「数値ディスプレイ」(DESIGN.md §2.2 数値段の単一の出所)。
///
/// 各作が `fontSize: 26/28/30…` を個別に発明してドリフトするのを防ぐため、
/// 数値表示はこの部品を通す。値=ディスプレイ書体・大・負トラッキング、
/// ラベル=セクションラベル(11 / 大文字 / 字間2.6 / muted)。
///
/// §2.2 数値スケール:
///   大(スコア/勝率/タイム) size 28 / w700 / ls -0.5
///   中(統計セル)          size 22 / w700 / ls -0.5
class StatTile extends StatelessWidget {
  final AppTheme theme;
  final String value;
  final String label;

  /// 大きい表示(28) か 中(22) か。
  final bool large;

  /// 値を accent 色にする(勝率など主役の1点)。既定は textPrimary。
  final bool emphasize;

  /// 横並びで等幅に詰めるとき true(`Expanded` でラップ)。
  final bool expand;

  final CrossAxisAlignment align;

  const StatTile({
    super.key,
    required this.theme,
    required this.value,
    required this.label,
    this.large = true,
    this.emphasize = false,
    this.expand = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final col = Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: theme.displayFontFamily,
            fontFamilyFallback: theme.fontFamilyFallback,
            fontSize: large ? 28 : 22,
            height: 1.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: emphasize ? theme.accent : theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.6,
            color: theme.textMuted,
          ),
        ),
      ],
    );
    return expand ? Expanded(child: col) : col;
  }
}
