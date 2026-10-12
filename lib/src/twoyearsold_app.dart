import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'brand_footer.dart';
import 'l10n.dart';
import 'motion.dart';
import 'settings_controller.dart';

/// OS の文字サイズ設定をどこまで反映するか(倍率の上限)。これを超える設定は上限で描く。
const double kMaxTextScale = 1.3;

/// 全アプリ共通の `MaterialApp` シェル(DESIGN.md §10)。各 `App` ウィジェットの代わりに使う。
///
/// 単一の出所として以下を一元化する(各 main.dart で再実装しない):
/// - 表示言語に応じたフォントフォールバック並べ替え(Han unification 回避・§2.1)
/// - ミニマルなページ遷移(フェード + 2%スライド・全プラットフォーム・§5.5)
/// - ブランドフッター枠(§8) / 多言語 delegates・supportedLocales(§10.2)
/// - 文字拡大の上限([kMaxTextScale]・§9)
///
/// 共有 `settingsProvider`(AppTheme)を使うアプリ向け。独自テーマ体系(例: NumberPlace の
/// SudokuTheme)は専用の App を持つ。
class TwoyearsoldApp extends ConsumerWidget {
  final String title;
  final Widget home;

  /// gen-l10n 等の追加 localizationsDelegates(任意)。
  final List<LocalizationsDelegate<dynamic>> extraDelegates;

  const TwoyearsoldApp({
    super.key,
    required this.title,
    required this.home,
    this.extraDelegates = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final localeCode = L10n.resolve(settings.localeCode).code;
    final theme =
        settings.theme.withFontFallback(AppTheme.fallbackForLocale(localeCode));
    final transitions =
        MinimalPageTransitionsBuilder(enabled: settings.animationsEnabled);
    final pageTransitions = PageTransitionsTheme(builders: {
      for (final p in TargetPlatform.values) p: transitions,
    });
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      locale: L10n.localeFromCode(settings.localeCode),
      supportedLocales: L10n.locales,
      localizationsDelegates: [
        ...extraDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme.toThemeData().copyWith(pageTransitionsTheme: pageTransitions),
      // 文字拡大は受け止めるが、盤と HUD が崩れない範囲に抑える(全画面・全作で同じ上限)。
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: kMaxTextScale,
        child: Column(
          children: [
            Expanded(child: child ?? const SizedBox.shrink()),
            BrandFooter(theme: theme),
          ],
        ),
      ),
      home: home,
    );
  }
}
