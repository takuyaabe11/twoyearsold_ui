import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'providers.dart';

/// ユーザー設定(表示・効果音・演出)。shared_preferences に永続化。
class SettingsState {
  final String themeId;
  final bool soundEnabled;
  final bool animationsEnabled;

  const SettingsState({
    this.themeId = 'editorial_dark',
    this.soundEnabled = true,
    this.animationsEnabled = true,
  });

  AppTheme get theme => AppTheme.byId(themeId);

  SettingsState copyWith({
    String? themeId,
    bool? soundEnabled,
    bool? animationsEnabled,
  }) =>
      SettingsState(
        themeId: themeId ?? this.themeId,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'theme': themeId,
        'sound': soundEnabled,
        'animations': animationsEnabled,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
        themeId: json['theme'] as String? ?? 'editorial_dark',
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
