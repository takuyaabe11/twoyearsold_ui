import 'package:flutter/foundation.dart';

/// dispose 後に `notifyListeners` を呼んでも安全な `ChangeNotifier`。
///
/// 非同期処理(compute / Timer / AI 探索)のコールバックが、画面を離れた後に
/// `notifyListeners` を呼ぶと例外になる。各作の GameController がこのガードを
/// 個別実装(し忘れる=Minesweeper の潜在バグ)していたのを単一の出所に。
class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
