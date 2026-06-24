import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// キー別の集計戦績(難易度別・レベル別)を SharedPreferences に1キーで永続化する
/// 汎用リポジトリ(DESIGN.md §10.4 / §10.7)。
///
/// 各作が `Map<String,葉> + forKey/forLevel + load()(try/catch 空) +
/// record()(= load → 葉を更新 → save) + toJson/fromJson` の骨格をコピー実装して
/// いた(=ドリフトの温床)のを単一の出所に。
///
/// 葉型 L(各作の DifficultyStats / LevelStats 等の immutable 値)とその codec・空値を
/// 注入する。葉の更新ロジックはゲーム固有なので [record] に `update` 関数で渡す。
///
/// 例:
/// ```dart
/// final repo = KeyedStatsRepository<DifficultyStats>(
///   prefs,
///   empty: const DifficultyStats(),
///   encodeLeaf: (s) => s.toJson(),
///   decodeLeaf: DifficultyStats.fromJson,
/// );
/// await repo.record(d.name, (cur) => cur.recordResult(won: won, seconds: s));
/// final stats = repo.load(); // Map<String, DifficultyStats>
/// ```
class KeyedStatsRepository<L> {
  final SharedPreferences prefs;
  final String key;
  final L empty;
  final Map<String, dynamic> Function(L leaf) encodeLeaf;
  final L Function(Map<String, dynamic> json) decodeLeaf;

  KeyedStatsRepository(
    this.prefs, {
    required this.empty,
    required this.encodeLeaf,
    required this.decodeLeaf,
    this.key = 'stats_v1',
  });

  /// 全キーの戦績を読む(壊れた JSON は空として読み捨て)。
  Map<String, L> load() {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in j.entries)
          e.key: decodeLeaf(e.value as Map<String, dynamic>),
      };
    } catch (_) {
      return {};
    }
  }

  /// 単一キーの戦績(無ければ [empty])。
  L forKey(String k) => load()[k] ?? empty;

  /// [k] の葉を [update] で更新して保存し、更新後の全戦績を返す。
  Future<Map<String, L>> record(String k, L Function(L current) update) async {
    final current = load();
    final next = {...current, k: update(current[k] ?? empty)};
    try {
      await prefs.setString(
        key,
        jsonEncode({for (final e in next.entries) e.key: encodeLeaf(e.value)}),
      );
    } catch (_) {}
    return next;
  }
}
