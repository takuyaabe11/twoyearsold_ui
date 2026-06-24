import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

/// 全アプリ共通の起動シーケンス(DESIGN.md §2.1 / §9)。各 `main()` はこれを呼ぶだけ。
///
/// - 本文/CJK フォントを先読みして初回描画時の □(notdef)フラッシュを防ぐ(§2.1)。
/// - SharedPreferences 初期化に失敗してもアプリは必ず起動する(モックで継続・§9)。
/// - `sharedPreferencesProvider` を注入した `ProviderScope` で [app] を起動。
///
/// [fonts] は同梱フォントのアセット名(既定: Arimo, NotoSansJP)。
Future<void> bootstrap(
  Widget Function() app, {
  List<String> fonts = const ['Arimo', 'NotoSansJP'],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  for (final f in fonts) {
    try {
      await (FontLoader(f)..addFont(rootBundle.load('assets/fonts/$f.ttf')))
          .load();
    } catch (_) {
      // 先読み失敗は致命ではない。
    }
  }
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // ストレージ初期化に失敗してもアプリは必ず起動する。— §9。
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(const {});
    prefs = await SharedPreferences.getInstance();
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: app(),
    ),
  );
}
