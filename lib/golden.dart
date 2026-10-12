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
      // 既定書体(Helvetica Neue)と代替列の Helvetica / Arial は端末のフォントで、テストには
      // 無い。Web / Android で実際に使われる Arimo を、それらの名でも登録する。登録しないと
      // テスト既定の箱フォントが先に拾われ、ラテン文字と一部の漢字(一 二 三 など)が箱になる。
      if (family == 'Arimo') {
        for (final alias in {
          AppTheme.editorialDark.fontFamily,
          AppTheme.editorialDark.displayFontFamily,
          'Helvetica',
          'Arial',
        }) {
          await (FontLoader(alias)
                ..addFont(Future.value(ByteData.sublistView(bytes))))
              .load();
        }
      }
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
  BrandFooter.debugYear = 2026; // フッターの年を固定(年越しで画像が変わらないように)。
  addTearDown(() => BrandFooter.debugYear = null);
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

/// いま画面にある操作要素のうち、当たり判定が [min] px 未満のものを列挙する(§9 タップ領域は
/// 最低 44px)。見た目の大きさではなく、指が反応する範囲(ウィジェットの箱)を測る。
///
/// 盤のマスは対象外: 同じ大きさの操作要素が 16 個以上並んでいれば格子とみなす。マスの
/// 大きさは盤の升目数と画面幅で決まり、余白を足して広げられる類のものではない。
///
/// 測れるのは GestureDetector / InkWell / ボタン類。Listener で直接ポインタを受ける盤
/// (3D の盤など)は対象外。
List<String> smallTapTargets(WidgetTester tester, {double min = 44}) {
  final found = _tappables(tester);
  // 格子(盤のマス)を除く。
  final bySize = <String, int>{};
  String key(Rect r) => '${r.width.round()}x${r.height.round()}';
  for (final f in found) {
    bySize[key(f.rect)] = (bySize[key(f.rect)] ?? 0) + 1;
  }
  final small = <String>{};
  for (final f in found) {
    if ((bySize[key(f.rect)] ?? 0) >= 16) continue;
    if (f.rect.width + 0.5 >= min && f.rect.height + 0.5 >= min) continue;
    small.add('${f.what}: ${f.rect.width.round()}×${f.rect.height.round()}'
        ' @(${f.rect.left.round()},${f.rect.top.round()})');
  }
  return small.toList()..sort();
}

/// いま画面にある操作要素(当たり判定の矩形と呼び名)。
List<({Rect rect, String what})> _tappables(WidgetTester tester) {
  final screen =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  final found = <({Rect rect, String what})>[];
  for (final e in tester.allElements) {
    final w = e.widget;
    final tappable = switch (w) {
      GestureDetector g => g.onTap != null ||
          g.onTapDown != null ||
          g.onTapUp != null ||
          g.onLongPress != null ||
          g.onDoubleTap != null,
      InkResponse i => i.onTap != null || i.onLongPress != null,
      ButtonStyleButton b => b.onPressed != null,
      _ => false,
    };
    if (!tappable) continue;
    // ボタン類は内側の見た目(40px)ではなく、外側の当たり判定(48px に広げてある)で反応する。
    // 外側は ButtonStyleButton として別に測るので、その内側にあるインクや、ツールチップが
    // 長押し用に挟む GestureDetector は数えない。
    if (w is! ButtonStyleButton) {
      var inButton = false;
      e.visitAncestorElements((a) {
        // 文字入力のカーソル・選択ハンドルは OS 標準の部品で、アプリの操作要素ではない。
        if (a.widget is ButtonStyleButton ||
            '${a.widget.runtimeType}'.contains('SelectionHandle')) {
          inButton = true;
        }
        return !inButton;
      });
      if (inButton) continue;
    }
    final box = e.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.isEmpty || !screen.overlaps(rect)) continue;
    found.add((rect: rect, what: _describe(e)));
  }
  return found;
}

/// ホームから 1 回の操作で開く画面(設定・統計・遊び方・対戦設定・プレイなど)をひととおり
/// 開き、それぞれで [smallTapTargets] を測る。ホームを立てた直後に呼ぶ。
///
/// ホームの操作要素を上から順に押し、開いた画面を測って戻る、を繰り返す。常時動く画面
/// (リアルタイム系のプレイ画面)でも止まらないよう、落ち着くのを待たず一定時間だけ進める。
Future<void> expectTapTargetsOneLevelDeep(WidgetTester tester,
    {double min = 44}) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  List<({Rect rect, String what})> entries() {
    final seen = <String>{};
    return [
      for (final t in _tappables(tester))
        if (seen.add('${t.rect}')) t
    ]..sort((a, b) => a.rect.top != b.rect.top
        ? a.rect.top.compareTo(b.rect.top)
        : a.rect.left.compareTo(b.rect.left));
  }

  Future<void> advance() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  final problems = <String>[];
  final count = entries().length;
  for (var i = 0; i < count; i++) {
    final list = entries();
    if (i >= list.length) break;
    final entry = list[i];
    await tester.tapAt(entry.rect.center);
    await advance();
    expect(tester.takeException(), isNull, reason: '${entry.what} を開いて例外');
    for (final s in smallTapTargets(tester, min: min)) {
      problems.add('${entry.what} → $s');
    }
    while (nav.canPop()) {
      nav.pop();
      await advance();
    }
  }
  expect(problems.toSet().toList()..sort(), isEmpty,
      reason: '当たり判定が $min px 未満の操作要素(§9)。「開いた入口 → 要素: 幅×高さ @位置」:\n  '
          '${(problems.toSet().toList()..sort()).join('\n  ')}');
}

/// 操作要素の当たり判定がすべて [min] px 以上であること。
void expectTapTargets(WidgetTester tester, {double min = 44}) {
  final small = smallTapTargets(tester, min: min);
  expect(small, isEmpty,
      reason: '当たり判定が $min px 未満の操作要素(§9)。見た目は変えず、余白か最小寸法で'
          '反応する範囲を広げる:\n  ${small.join('\n  ')}');
}

/// 操作要素の呼び名(中の文字・ツールチップ・アイコン・型のどれか)。
String _describe(Element e) {
  String? text;
  void visit(Element c) {
    if (text != null) return;
    final w = c.widget;
    if (w is Text && (w.data ?? '').trim().isNotEmpty) {
      text = '「${w.data!.trim()}」';
    } else if (w is RichText) {
      final t = w.text.toPlainText().trim();
      if (t.isNotEmpty) text = '「$t」';
    } else if (w is Tooltip && (w.message ?? '').isNotEmpty) {
      text = '「${w.message}」';
    } else if (w is Icon) {
      text = 'アイコン ${w.icon?.codePoint.toRadixString(16)}';
    } else {
      c.visitChildElements(visit);
    }
  }

  e.visitChildElements(visit);
  return text ?? e.widget.runtimeType.toString();
}

