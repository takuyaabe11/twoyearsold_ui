import 'package:flutter/material.dart';

/// 難易度・強さを ★1〜★N で選ぶ共通セレクタ(TWOYEARSOLD 全ゲーム共通デザイン)。
///
/// タップでも横ドラッグでも★の数を決められる(ドラッグ&ドロップの操作感)。
/// 文字の難易度名に代えて、星の数だけで強さを示す。テーマ実装に依存しないよう、
/// 色は明示的に受け取る(各ゲームが自分のテーマ色を渡す)。仕様は DESIGN.md §10。
class StarPicker extends StatelessWidget {
  /// 選択中の★数(1..count)。
  final int value;

  /// 表示する★枠の総数(既定 5)。
  final int count;

  /// 選べる上限(既定 = count)。これを超える枠は淡く描き、選べない。
  final int max;

  /// 塗り(選択中)の色。通常はアクセント(朱)。
  final Color filledColor;

  /// 空き枠(選択可能だが未選択)の色。範囲外の枠はこの色をさらに淡くする。
  final Color emptyColor;

  /// 右に添える任意のラベル(難易度名など)。null で非表示=★だけ。
  final String? label;

  /// ラベル色(省略時は filledColor)。
  final Color? labelColor;

  /// ★数(1..max)が変わったとき呼ばれる。
  final ValueChanged<int> onChanged;

  const StarPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.filledColor,
    required this.emptyColor,
    this.count = 5,
    int? max,
    this.label,
    this.labelColor,
  }) : max = max ?? count;

  /// 1枠あたりの当たり判定幅(タップ/ドラッグの座標→星数換算に使う)。
  static const double _slot = 44;
  static const double _starSize = 32;

  @override
  Widget build(BuildContext context) {
    void selectAt(double dx) {
      final i = (dx / _slot).floor().clamp(0, count - 1) + 1;
      final capped = i.clamp(1, max);
      if (capped != value) onChanged(capped);
    }

    final stars = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => selectAt(d.localPosition.dx),
      onHorizontalDragStart: (d) => selectAt(d.localPosition.dx),
      onHorizontalDragUpdate: (d) => selectAt(d.localPosition.dx),
      child: SizedBox(
        width: _slot * count,
        height: _slot,
        child: Row(
          children: [
            for (var i = 1; i <= count; i++)
              SizedBox(
                width: _slot,
                height: _slot,
                child: Center(
                  child: Icon(
                    i <= value
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: _starSize,
                    color: i <= value
                        ? filledColor
                        : emptyColor
                            .withValues(alpha: i <= max ? _emptyAlpha : 0.28),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (label == null) return stars;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        stars,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: labelColor ?? filledColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  /// 範囲内の空き枠の不透明度(emptyColor 自体が淡い場合もあるので軽め)。
  double get _emptyAlpha => (emptyColor.a == 1.0) ? 0.5 : 1.0;
}
