import 'dart:async';

/// 1秒刻みの経過時間カウンタ。各作の GameController が `Timer.periodic(1s)` を
/// 手書きしていた(=ドリフト)のを単一の出所に。
///
/// 停止/再開はメソッドで(一時停止は [stop]、再開は [start])。毎秒 [onTick] に
/// 現在の経過秒を渡す。アプリ側で notifyListeners や自動保存を行う。
class GameClock {
  final void Function(int elapsed) onTick;
  Timer? _timer;
  int _elapsed = 0;

  GameClock(this.onTick);

  int get elapsed => _elapsed;
  bool get running => _timer != null;

  /// 動かす(既に動いていれば何もしない)。
  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      onTick(_elapsed);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 経過を0に戻す(新規ゲーム時など)。
  void reset() => _elapsed = 0;

  /// 復元時など、経過秒を直接設定する。
  void set(int seconds) => _elapsed = seconds;

  void dispose() => stop();
}
