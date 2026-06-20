import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';
import 'app_theme.dart';
import 'l10n.dart';
import 'language_pulldown.dart';
import 'theme_name.dart';
import 'section_label.dart';

/// 設定: テーマ・言語・効果音・演出。エディトリアル。全文言は共有 i18n から。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final l10n = ref.watch(l10nProvider);
    final theme = settings.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: Icon(Icons.arrow_back, color: theme.onSurface),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.settings,
                      style: TextStyle(
                        fontFamily: theme.displayFontFamily,
                        fontFamilyFallback: theme.fontFamilyFallback,
                        fontSize: 44,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    SectionLabel(l10n.theme, theme),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: theme.thinLine)),
                      ),
                      child: Column(
                        children: [
                          for (final t in AppTheme.all)
                            _ThemeRow(
                              theme: theme,
                              id: t.id,
                              selected: t.id == settings.themeId,
                              onTap: () => ctrl.setTheme(t.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    SectionLabel(l10n.language, theme),
                    LanguagePulldown(
                      selectedCode: settings.localeCode,
                      languages: L10n.supported,
                      systemLabel: l10n.languageSystem,
                      deviceLanguageName: L10n.supported
                          .firstWhere(
                            (l) => l.code == L10n.resolve(null).code,
                            orElse: () => L10n.supported.first,
                          )
                          .name,
                      onChanged: ctrl.setLocale,
                      textPrimary: theme.textPrimary,
                      textSecondary: theme.textSecondary,
                      surface: theme.surface,
                      line: theme.thinLine,
                      accent: theme.accent,
                    ),
                    const SizedBox(height: 36),

                    SectionLabel(l10n.game, theme),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: theme.thinLine)),
                      ),
                      child: Column(
                        children: [
                          _ToggleRow(
                            theme: theme,
                            label: l10n.sound,
                            value: settings.soundEnabled,
                            onChanged: ctrl.setSound,
                          ),
                          _ToggleRow(
                            theme: theme,
                            label: l10n.animations,
                            value: settings.animationsEnabled,
                            onChanged: ctrl.setAnimations,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final AppTheme theme;
  final String id;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeRow({
    required this.theme,
    required this.id,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = AppTheme.byId(id);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.thinLine)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            // 小さな見本(地 + アクセント)。
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: swatch.background,
                border: Border.all(color: theme.thinLine),
              ),
              child: Center(
                child: Container(
                  width: 9,
                  height: 9,
                  color: swatch.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                themeName(id),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? theme.textPrimary : theme.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: theme.accent),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.thinLine)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: theme.onSurface,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.accent,
          ),
        ],
      ),
    );
  }
}
