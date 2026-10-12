import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// 横並びの選択肢グループ(DESIGN.md §6 / §4)。
///
/// ラジオ/チップ/塗りピル/下線を**使わない**。選択は**テキストの濃淡だけ**で示す:
/// 選択 = textPrimary・w700 / 非選択 = textMuted・w400 / 無効 = muted@0.4。
/// 各作が個別に同等実装(_Choice 等)してドリフトする(サイズ18・朱下線 等)のを防ぐ
/// 単一の出所。サイズは §6 の選択肢=22。
///
/// 各選択肢は文字の周りに当たり判定の余白を持つ(§9: 44px 以上。文字だけでは高さ約 31px、
/// 短いラベルは幅も足りない)。横の余白は選択肢どうしの間隔の一部として数え、全体を余白の
/// ぶん寄せるので、文字の位置と横の間隔は余白なしのときと同じ。縦は行ごとに少し広くなる。
class ChoiceRow<T> extends StatelessWidget {
  /// 文字の左右・上下に取る当たり判定の余白。
  static const double hitPadX = 6;
  static const double hitPadY = 7;

  final AppTheme theme;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  /// 選べない選択肢(淡色・タップ不可)。
  final List<T> disabled;

  final double spacing;
  final double runSpacing;
  final double fontSize;

  const ChoiceRow({
    super.key,
    required this.theme,
    required this.value,
    required this.options,
    required this.onChanged,
    this.disabled = const [],
    this.spacing = 24,
    this.runSpacing = 8,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.translate(
      // 先頭の選択肢の文字を、余白なしのときと同じ左端(右から左の言語では右端)に揃える。
      offset: Offset(rtl ? hitPadX : -hitPadX, 0),
      child: Wrap(
      spacing: (spacing - hitPadX * 2).clamp(0.0, double.infinity),
      runSpacing: (runSpacing - hitPadY * 2).clamp(0.0, double.infinity),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (v, label) in options)
          _ChoiceItem(
            label: label,
            selected: v == value,
            disabled: disabled.contains(v),
            fontSize: fontSize,
            theme: theme,
            onTap: () => onChanged(v),
          ),
      ],
      ),
    );
  }
}

class _ChoiceItem extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final double fontSize;
  final AppTheme theme;
  final VoidCallback onTap;
  const _ChoiceItem({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.fontSize,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? theme.textMuted.withValues(alpha: 0.4)
        : (selected ? theme.textPrimary : theme.textMuted);
    final text = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: ChoiceRow.hitPadX, vertical: ChoiceRow.hitPadY),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
    if (disabled) return text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: text,
    );
  }
}
