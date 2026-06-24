import 'package:flutter/services.dart';

/// ブランド共通のハプティクス語彙(DESIGN.md §5.4 / §10.1)。
///
/// 「どの作品も同じ手応え」を単一の出所から保つ。各作は `HapticFeedback` を直接
/// 呼ばず、ここを通す。`on`(= 設定の hapticsEnabled)で一括 off できる。
/// Web 等で未対応でも例外を握りつぶす(§0 必ず起動)。
///
/// 語彙(§5.4):
///   tap    主操作(置く/開く/タップ)          = light tick
///   select 選択・トグル・無効操作の小反応       = selectionClick
///   impact 副操作(捕獲/裏返し/マージ/壁当て)  = medium
///   win    勝利                              = heavy
class Haptics {
  const Haptics._();

  static void _safe(void Function() f, bool on) {
    if (!on) return;
    try {
      f();
    } catch (_) {
      // 未対応プラットフォームでは無視。
    }
  }

  /// 主操作: 置く / 開く / タップ。軽い tick。
  static void tap(bool on) => _safe(HapticFeedback.lightImpact, on);

  /// 選択・トグル・無効操作。最も軽い反応。
  static void select(bool on) => _safe(HapticFeedback.selectionClick, on);

  /// 副操作: 捕獲 / 裏返し / マージ / 強い接触。中。
  static void impact(bool on) => _safe(HapticFeedback.mediumImpact, on);

  /// 勝利・確定的な大きな出来事。強め。
  static void win(bool on) => _safe(HapticFeedback.heavyImpact, on);
}
