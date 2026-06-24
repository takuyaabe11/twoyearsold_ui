import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// 横並びの選択肢グループ(DESIGN.md §6 / §4)。
///
/// ラジオ/チップ/塗りピル/下線を**使わない**。選択は**テキストの濃淡だけ**で示す:
/// 選択 = textPrimary・w700 / 非選択 = textMuted・w400 / 無効 = muted@0.4。
/// 各作が個別に同等実装(_Choice 等)してドリフトする(サイズ18・朱下線 等)のを防ぐ
/// 単一の出所。サイズは §6 の選択肢=22。
class ChoiceRow<T> extends StatelessWidget {
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
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
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
    final text = Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        color: color,
        letterSpacing: 0.2,
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
