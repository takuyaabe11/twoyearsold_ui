import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'providers.dart';

/// ユーザー設定(表示・言語・効果音・演出)。shared_preferences に永続化。
class SettingsState {
  final String themeId;

  /// 表示言語コード(null = 端末の言語に従う)。例: 'en' / 'ja' / 'zh_Hant'。
  final String? localeCode;

  final bool soundEnabled;
  final bool animationsEnabled;

  const SettingsState({
    this.themeId = 'editorial_dark',
    this.localeCode,
    this.soundEnabled = true,
    this.animationsEnabled = true,
  });

  AppTheme get theme => AppTheme.byId(themeId);

  SettingsState copyWith({
    String? themeId,
    String? localeCode,
    bool clearLocale = false,
    bool? soundEnabled,
    bool? animationsEnabled,
  }) =>
      SettingsState(
        themeId: themeId ?? this.themeId,
        localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
        soundEnabled: soundEnabled ?? this.soundEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'theme': themeId,
        if (localeCode != null) 'locale': localeCode,
        'sound': soundEnabled,
        'animations': animationsEnabled,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
        themeId: json['theme'] as String? ?? 'editorial_dark',
        localeCode: json['locale'] as String?,
        soundEnabled: json['sound'] as bool? ?? true,
        animationsEnabled: json['animations'] as bool? ?? true,
      );
}

class SettingsController extends Notifier<SettingsState> {
  static const _key = 'settings_v1';

  @override
  SettingsState build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const SettingsState();
    try {
      return SettingsState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const SettingsState();
    }
  }

  void setTheme(String id) => _update(state.copyWith(themeId: id));
  void setSound(bool v) => _update(state.copyWith(soundEnabled: v));
  void setAnimations(bool v) => _update(state.copyWith(animationsEnabled: v));

  /// null で「端末の言語に従う」。
  void setLocale(String? code) => _update(
        code == null
            ? state.copyWith(clearLocale: true)
            : state.copyWith(localeCode: code),
      );

  void _update(SettingsState next) {
    state = next;
    try {
      ref
          .read(sharedPreferencesProvider)
          .setString(_key, jsonEncode(next.toJson()));
    } catch (_) {
      // 保存失敗は致命ではない。
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
