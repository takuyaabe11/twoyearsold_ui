import 'package:flutter/material.dart';

/// TWOYEARSOLD デザイン憲法(../DESIGN.md)に準拠したテーマ。
///
/// 役割(セマンティック)トークンで色を持つ。生 hex は画面に直書きせず、
/// 必ずこのトークン経由で使う。書体はテーマ間で固定(色だけが変わる)。
class AppTheme {
  final String id;
  final Brightness brightness;

  /// UI・本文・数字に使う書体(Helvetica 系)。
  final String fontFamily;

  /// ロゴ / 大見出しのディスプレイ書体。
  final String displayFontFamily;

  /// [fontFamily] が無い環境での代替(Helvetica Neue → Arimo → 日本語 NotoSansJP)。
  final List<String> fontFamilyFallback;

  /// 地(上→下のごく僅かなグラデに使う2色)。
  final Color background;
  final Color backgroundAlt;

  /// パネルとその上の文字。
  final Color surface;
  final Color onSurface;

  /// 細罫(UIの主役)/ 構造境界(やや太)。
  final Color thinLine;
  final Color boxLine;

  /// 主役 / 副次 / 補足の文字。
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// アクセント(画面に1色だけ)。
  final Color accent;

  /// エラー(抑えた朱)。多用しない。
  final Color errorText;
  final Color errorFill;

  /// 選択・関連の面ハイライト。
  final Color selectionFill;

  const AppTheme({
    required this.id,
    required this.brightness,
    this.fontFamily = 'Helvetica Neue',
    this.displayFontFamily = 'Helvetica Neue',
    this.fontFamilyFallback = const ['Helvetica', 'Arimo', 'Arial', 'NotoSansJP'],
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.onSurface,
    required this.thinLine,
    required this.boxLine,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.errorText,
    required this.errorFill,
    required this.selectionFill,
  });

  /// エディトリアル・ダーク(全アプリの第一既定。黒地 × オフホワイト × 朱)。
  static const editorialDark = AppTheme(
    id: 'editorial_dark',
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0B),
    backgroundAlt: Color(0xFF101012),
    surface: Color(0xFF131316),
    onSurface: Color(0xFFF4F4F2),
    thinLine: Color(0xFF242427),
    boxLine: Color(0xFF55555A),
    textPrimary: Color(0xFFF4F4F2),
    textSecondary: Color(0xFF9A9A98),
    textMuted: Color(0xFF5C5C5E),
    accent: Color(0xFFE2563C),
    errorText: Color(0xFFE2563C),
    errorFill: Color(0xFF2A1613),
    selectionFill: Color(0xFF1E1E22),
  );

  /// エディトリアル・ライト(白地版)。
  static const editorialLight = AppTheme(
    id: 'editorial_light',
    brightness: Brightness.light,
    background: Color(0xFFFAFAF8),
    backgroundAlt: Color(0xFFF1F1EE),
    surface: Color(0xFFEFEFEB),
    onSurface: Color(0xFF111110),
    thinLine: Color(0xFFE3E3DE),
    boxLine: Color(0xFF1A1A18),
    textPrimary: Color(0xFF111110),
    textSecondary: Color(0xFF6A6A66),
    textMuted: Color(0xFFA0A09A),
    accent: Color(0xFFC8412C),
    errorText: Color(0xFFC8412C),
    errorFill: Color(0xFFF3DCD6),
    selectionFill: Color(0xFFEAEAE5),
  );

  /// 温白クリーム(紙)。accent は墨(モノクロ)。— DESIGN.md §1.3。
  static const warmCream = AppTheme(
    id: 'warm_cream',
    brightness: Brightness.light,
    background: Color(0xFFFBF6EA),
    backgroundAlt: Color(0xFFF5EEDC),
    surface: Color(0xFFF3ECDB),
    onSurface: Color(0xFF2B2620),
    thinLine: Color(0xFFD8CCB0),
    boxLine: Color(0xFF7E725A),
    textPrimary: Color(0xFF2B2620),
    textSecondary: Color(0xFF6B5E48),
    textMuted: Color(0xFF9A8E76),
    accent: Color(0xFF2B2620),
    errorText: Color(0xFFB0473A),
    errorFill: Color(0xFFF0D9D2),
    selectionFill: Color(0xFFE9DCBE),
  );

  /// セピア / 羊皮紙。
  static const sepia = AppTheme(
    id: 'sepia',
    brightness: Brightness.light,
    background: Color(0xFFEFE3CA),
    backgroundAlt: Color(0xFFE7D8B8),
    surface: Color(0xFFE9DABB),
    onSurface: Color(0xFF3A2E1E),
    thinLine: Color(0xFFC9B68F),
    boxLine: Color(0xFF7A6A4C),
    textPrimary: Color(0xFF3A2E1E),
    textSecondary: Color(0xFF6E5A3E),
    textMuted: Color(0xFF9C8862),
    accent: Color(0xFF3A2E1E),
    errorText: Color(0xFFA84634),
    errorFill: Color(0xFFE4C8BC),
    selectionFill: Color(0xFFDFCDA6),
  );

  /// クール白磁。
  static const cool = AppTheme(
    id: 'cool',
    brightness: Brightness.light,
    background: Color(0xFFFAFBFC),
    backgroundAlt: Color(0xFFF1F4F6),
    surface: Color(0xFFEFF2F4),
    onSurface: Color(0xFF1F2933),
    thinLine: Color(0xFFD7DDE2),
    boxLine: Color(0xFF7A858E),
    textPrimary: Color(0xFF1F2933),
    textSecondary: Color(0xFF52606B),
    textMuted: Color(0xFF93A0AA),
    accent: Color(0xFF1F2933),
    errorText: Color(0xFFB0473A),
    errorFill: Color(0xFFF0DAD5),
    selectionFill: Color(0xFFE2E8EC),
  );

  /// ダークインク。
  static const darkInk = AppTheme(
    id: 'dark_ink',
    brightness: Brightness.dark,
    background: Color(0xFF1E1B16),
    backgroundAlt: Color(0xFF24201A),
    surface: Color(0xFF26221B),
    onSurface: Color(0xFFEDE6D6),
    thinLine: Color(0xFF3A352B),
    boxLine: Color(0xFF8A7F66),
    textPrimary: Color(0xFFEDE6D6),
    textSecondary: Color(0xFFB9AE97),
    textMuted: Color(0xFF7E7460),
    accent: Color(0xFFEDE6D6),
    errorText: Color(0xFFD9776A),
    errorFill: Color(0xFF3A2A26),
    selectionFill: Color(0xFF3A3428),
  );

  static const all = [
    editorialDark,
    editorialLight,
    warmCream,
    sepia,
    cool,
    darkInk,
  ];

  static AppTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => editorialDark);

  /// Material ウィジェット用の ThemeData。
  ThemeData toThemeData() {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: accent,
        surface: surface,
        onSurface: onSurface,
        error: errorText,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
