import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// JSON 1スロットの永続化(SharedPreferences)。中断ゲームの保存・復元の単一の出所。
///
/// 各作が `SaveRepository`(同一キー `current_game_v1` / 壊れた JSON は読み捨てて削除)を
/// コピー実装していたのを汎用化。ペイロード型 T(各作の SavedGame)とその codec は各作が渡す。
class JsonSlotRepository<T> {
  final SharedPreferences prefs;
  final String key;
  final String atKey;
  final Map<String, dynamic> Function(T value) encode;
  final T Function(Map<String, dynamic> json) decode;

  JsonSlotRepository(
    this.prefs, {
    required this.encode,
    required this.decode,
    this.key = 'current_game_v1',
    this.atKey = 'current_game_at_v1',
  });

  bool get hasSaved => prefs.containsKey(key);

  DateTime? get savedAt {
    final ms = prefs.getInt(atKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> save(T value) async {
    try {
      await prefs.setString(key, jsonEncode(encode(value)));
      await prefs.setInt(atKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  T? load() {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      unawaited(prefs.remove(key).catchError((_) => false));
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await prefs.remove(key);
      await prefs.remove(atKey);
    } catch (_) {}
  }
}
