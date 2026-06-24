import 'l10n.dart';

/// テーマ id → 表示名(L10n 経由。37言語対応)。
String themeName(L10n l10n, String id) => switch (id) {
      'editorial_dark' => l10n.themeEditorialDark,
      'editorial_light' => l10n.themeEditorialLight,
      'warm_cream' => l10n.themeWarmCream,
      'sepia' => l10n.themeSepia,
      'cool' => l10n.themeCool,
      'dark_ink' => l10n.themeDarkInk,
      _ => id,
    };
