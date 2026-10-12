import 'package:flutter/material.dart';

/// Canvas で描いた盤(`CustomPaint`)に、マスごとの読み上げを重ねる。
///
/// `CustomPaint` だけの盤は、スクリーンリーダーからは何も無い 1 枚の絵に見える。これで各マスに
/// ラベル(座標と状態)と操作(ダブルタップ = [onTap])を与える。見た目とタッチ操作には
/// 影響しない(描画なし・ポインタは下の盤へ素通し)。
class GridSemantics extends StatelessWidget {
  const GridSemantics({
    super.key,
    required this.cols,
    required this.rows,
    required this.label,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isButton,
    this.isSelected,
    this.cellRect,
  });

  final int cols;
  final int rows;

  /// マス [index] の読み上げ文。等分の格子では行優先で左上が 0。[cellRect] を渡す盤では、
  /// index と位置の対応は呼び出し側が決める。例: 「c4、黒」「3 行 5 列、旗」。
  final String Function(int index) label;

  /// 読み上げの操作(ダブルタップ)。null なら操作なしのラベルだけ。
  final void Function(int index)? onTap;

  /// 読み上げの長押し操作(例: 旗を立てる)。
  final void Function(int index)? onLongPress;

  /// そのマスがいま操作できるか(ボタンとして読み上げる)。null なら [onTap] があれば全マス。
  final bool Function(int index)? isButton;

  /// そのマスが選択中か(選択中のマス・キーボードカーソルの位置を「選択済み」と読ませる)。
  final bool Function(int index)? isSelected;

  /// マスの位置(盤の大きさ [size] の中での矩形)。null なら等分の格子。
  /// 透視のかかった盤は、投影したマスを囲む矩形を返す。
  final Rect Function(int index, Size size)? cellRect;

  /// 盤(描画とタッチ操作を持つ本体)。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 盤そのものは読み上げ対象から外す(マスのラベルと二重にしない)。
        ExcludeSemantics(child: child),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = box.biggest;
              final w = size.width / cols, h = size.height / rows;
              return Stack(
                children: [
                  for (var i = 0; i < cols * rows; i++)
                    Positioned.fromRect(
                      rect: cellRect?.call(i, size) ??
                          Rect.fromLTWH((i % cols) * w, (i ~/ cols) * h, w, h),
                      child: Semantics(
                        // マスごとに独立したノードにする。無いと、操作を持たないマスの
                        // ラベルが親の 1 ノードへ連結されて、盤全体が 1 つの長い文になる。
                        container: true,
                        label: label(i),
                        button: isButton?.call(i) ?? onTap != null,
                        selected: isSelected?.call(i),
                        onTap: onTap == null ? null : () => onTap!(i),
                        onLongPress:
                            onLongPress == null ? null : () => onLongPress!(i),
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
