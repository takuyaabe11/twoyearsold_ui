/// ゴールデンテスト(見た目の固定)の共通ハーネス。各作の test/ からだけ使う。
///
/// 本物のアプリ殻([TwoyearsoldApp])・本物の同梱フォント・固定の画面寸法で画面を立てるので、
/// 配置・配色・余白に加えて、字の欠け(豆腐)・右から左の言語・文字拡大での崩れまで捕まえる。
/// 各作 6 枚が基準: ホーム / プレイ / 終了(日本語・暗)、プレイの文字拡大、アラビア語のホーム、
/// 明るいテーマのプレイ。更新は `flutter test --update-goldens`。
library;

// flutter_test は各作の dev_dependency から解決される(このライブラリはテスト専用)。
// ignore_for_file: depend_on_referenced_packages, invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'twoyearsold_ui.dart';

/// 基準の画面寸法(論理ピクセル)。iPhone 相当の縦長。
const goldenSize = Size(390, 844);

bool _fontsLoaded = false;

/// 作の `assets/fonts/*.ttf` と Material Icons を読み込む(テスト既定の箱文字で描かせない)。
Future<void> loadGoldenFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final dir = Directory('assets/fonts');
  if (dir.existsSync()) {
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      if (!f.path.endsWith('.ttf')) continue;
      final family = f.uri.pathSegments.last.replaceAll('.ttf', '');
      final bytes = f.readAsBytesSync();
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')
            ..addFont(
                Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
          .load();
    }
  }
}

/// [home] を、設定つきのアプリ殻で立てる。演出・音・触覚は止める(静止画として比べるため)。
///
/// - [locale] / [themeId]: 表示言語とテーマ(共有設定として保存済みの状態を再現する)。
/// - [textScale]: OS の文字サイズ設定。アプリ側の上限([kMaxTextScale])もそのまま効く。
/// - [prefs]: 作ごとの保存データ(進行中の盤など)。
/// - [overrides]: 作ごとの差し替え(音のプロバイダなど)。
/// - [settle]: 常時動く画面(リアルタイム系)は false にして、[tester.pump] で時刻を決める。
/// - [app]: 共有の殻を使わない作(独自の MaterialApp)はここで自分の App を返す。
Future<void> pumpGolden(
  WidgetTester tester,
  Widget home, {
  String locale = 'ja',
  String themeId = 'editorial_dark',
  double textScale = 1.0,
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
  Size size = goldenSize,
  bool settle = true,
  Widget Function(Widget home)? app,
}) async {
  await loadGoldenFonts();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  SharedPreferences.setMockInitialValues({
    'settings_v1': jsonEncode({
      'theme': themeId,
      'locale': locale,
      'sound': false,
      'animations': false,
      'haptics': false,
    }),
    ...prefs,
  });
  final store = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(store),
      ...overrides,
    ],
    child: app?.call(home) ?? TwoyearsoldApp(title: 'golden', home: home),
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// いま立っている画面を `goldens/<name>.png` と比べる。描画中の例外(はみ出し等)も失敗にする。
Future<void> expectGolden(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: '$name の描画で例外');
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}
