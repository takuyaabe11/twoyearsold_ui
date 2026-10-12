import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// キーボード操作の共通語彙(Web / デスクトップ)。どの作でも同じキーが同じ意味になる:
///
///   Esc 戻る / R・N やり直し(新しいゲーム) / U・Z 待った / Y やり直し(redo) / H ヒント /
///   矢印・WASD 移動 / Enter・Space 決定 / 数字 入力 / Backspace・Delete 消去
///
/// 渡したコールバックのキーだけが効く(null のキーは素通し)。画面を開いたらすぐ効くよう
/// 自動でフォーカスを取る。各作でキー判定を書き直さない(§10.4)。
class GameKeys extends StatefulWidget {
  const GameKeys({
    super.key,
    required this.child,
    this.onBack,
    this.onRestart,
    this.onUndo,
    this.onRedo,
    this.onHint,
    this.onMove,
    this.onConfirm,
    this.onDigit,
    this.onDelete,
    this.onAnyKey,
    this.wasd = true,
  });

  final Widget child;

  /// Esc。null なら前の画面へ戻る(`Navigator.maybePop`)。
  final VoidCallback? onBack;
  final VoidCallback? onRestart;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onHint;

  /// 矢印(と WASD)。押しっぱなしで繰り返す。
  final ValueChanged<AxisDirection>? onMove;

  /// Enter / Space。
  final VoidCallback? onConfirm;

  /// 数字キー 0〜9(テンキー含む)。
  final ValueChanged<int>? onDigit;
  final VoidCallback? onDelete;

  /// どのキーでも最初に呼ぶ(Web の効果音の解錠など)。
  final VoidCallback? onAnyKey;

  /// WASD を矢印として扱うか。文字キーを別の意味で使う作は false。
  final bool wasd;

  @override
  State<GameKeys> createState() => _GameKeysState();
}

class _GameKeysState extends State<GameKeys> {
  final FocusNode _focus = FocusNode(debugLabel: 'GameKeys');

  static final _arrows = <LogicalKeyboardKey, AxisDirection>{
    LogicalKeyboardKey.arrowUp: AxisDirection.up,
    LogicalKeyboardKey.arrowDown: AxisDirection.down,
    LogicalKeyboardKey.arrowLeft: AxisDirection.left,
    LogicalKeyboardKey.arrowRight: AxisDirection.right,
  };
  static final _wasd = <LogicalKeyboardKey, AxisDirection>{
    LogicalKeyboardKey.keyW: AxisDirection.up,
    LogicalKeyboardKey.keyS: AxisDirection.down,
    LogicalKeyboardKey.keyA: AxisDirection.left,
    LogicalKeyboardKey.keyD: AxisDirection.right,
  };
  static final _digits = <LogicalKeyboardKey, int>{
    for (final (i, k) in [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ].indexed)
      k: i,
    for (final (i, k) in [
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ].indexed)
      k: i,
  };

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _run(VoidCallback? f) {
    if (f == null) return KeyEventResult.ignored;
    f();
    return KeyEventResult.handled;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final down = event is KeyDownEvent;
    if (!down && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    // 修飾キーつき(Ctrl+R の再読み込みなど)はブラウザ・OS に渡す。
    final hw = HardwareKeyboard.instance;
    if (hw.isControlPressed || hw.isMetaPressed || hw.isAltPressed) {
      return KeyEventResult.ignored;
    }
    widget.onAnyKey?.call();
    final k = event.logicalKey;

    final dir = _arrows[k] ?? (widget.wasd ? _wasd[k] : null);
    if (dir != null) {
      if (widget.onMove == null) return KeyEventResult.ignored;
      widget.onMove!(dir);
      return KeyEventResult.handled;
    }
    if (!down) return KeyEventResult.ignored; // 移動以外は押しっぱなしで繰り返さない。

    if (k == LogicalKeyboardKey.escape) {
      return _run(widget.onBack ?? () => Navigator.of(context).maybePop());
    }
    if (k == LogicalKeyboardKey.keyR || k == LogicalKeyboardKey.keyN) {
      return _run(widget.onRestart);
    }
    if (k == LogicalKeyboardKey.keyU || k == LogicalKeyboardKey.keyZ) {
      return _run(widget.onUndo);
    }
    if (k == LogicalKeyboardKey.keyY) return _run(widget.onRedo);
    if (k == LogicalKeyboardKey.keyH) return _run(widget.onHint);
    if (k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.space) {
      return _run(widget.onConfirm);
    }
    if (k == LogicalKeyboardKey.backspace || k == LogicalKeyboardKey.delete) {
      return _run(widget.onDelete);
    }
    final digit = _digits[k];
    if (digit != null && widget.onDigit != null) {
      widget.onDigit!(digit);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: widget.child,
      );
}

/// 格子盤のキーボードカーソル。矢印で動かし、決定キーでそのマスを操作する。
///
/// キーボードを使うまでは出さない([index] が null)。タッチ・マウスで操作したら [hide] で
/// 消す(指で遊ぶ人の盤に余計な印を残さない)。
class GridCursor extends ChangeNotifier {
  GridCursor({required this.cols, required this.rows, this.start});

  int cols;
  int rows;

  /// 最初に矢印を押したとき現れるマス。null なら盤の中央。
  final int? start;

  int? _index;
  int? get index => _index;

  void move(AxisDirection dir) {
    final i = _index;
    if (i == null) {
      _index = start ?? (rows ~/ 2) * cols + (cols - 1) ~/ 2;
      notifyListeners();
      return;
    }
    var c = i % cols, r = i ~/ cols;
    switch (dir) {
      case AxisDirection.up:
        r = r > 0 ? r - 1 : r;
      case AxisDirection.down:
        r = r < rows - 1 ? r + 1 : r;
      case AxisDirection.left:
        c = c > 0 ? c - 1 : c;
      case AxisDirection.right:
        c = c < cols - 1 ? c + 1 : c;
    }
    final next = r * cols + c;
    if (next == i) return;
    _index = next;
    notifyListeners();
  }

  void moveTo(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }

  void hide() {
    if (_index == null) return;
    _index = null;
    notifyListeners();
  }
}

/// 選択表現を持たない盤(Reversi / Minesweeper など)のカーソル。色を足さず、罫線と同じ
/// 語彙の細い枠で示す(§4 罫線で階層 / §1 アクセントは少量)。選択表現がある作はそちらを使う。
class CursorFrame extends StatelessWidget {
  const CursorFrame({super.key, required this.theme, this.inset = 2});

  final AppTheme theme;
  final double inset;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: 0.85),
                width: 1.5,
              ),
            ),
          ),
        ),
      );
}
