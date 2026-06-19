import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';

/// 軽量 i18n。全ゲーム共通の文言を `{言語: {キー: 文言}}` で持つ。
/// 言語追加 = [_data] に1言語足すだけ(コード生成なし)。— DESIGN.md §10.2。
///
/// ゲーム固有の文言は各ゲーム側で同じ要領で持つ(共通文言はここから取得)。
class L10n {
  final String code;
  const L10n(this.code);

  /// 対応言語(コード, 母語表記)。ここに足すと言語ピッカーに自動で並ぶ。
  static const supported = <({String code, String name})>[
    (code: 'en', name: 'English'),
    (code: 'ja', name: '日本語'),
  ];

  static List<Locale> get locales =>
      [for (final l in supported) Locale(l.code)];

  static bool isSupported(String code) =>
      supported.any((l) => l.code == code);

  /// 明示コード(null=端末言語)から L10n を解決。未対応は en にフォールバック。
  static L10n resolve(String? code) {
    if (code != null && isSupported(code)) return L10n(code);
    try {
      final dev = ui.PlatformDispatcher.instance.locale.languageCode;
      if (isSupported(dev)) return L10n(dev);
    } catch (_) {}
    return const L10n('en');
  }

  String _get(String key) =>
      _data[code]?[key] ?? _data['en']?[key] ?? key;

  // ── 共通文言 ──
  String get settings => _get('settings');
  String get game => _get('game');
  String get theme => _get('theme');
  String get sound => _get('sound');
  String get animations => _get('animations');
  String get language => _get('language');
  String get languageSystem => _get('languageSystem');
  String get newGame => _get('newGame');
  String get howToPlay => _get('howToPlay');
  String get statistics => _get('statistics');
  String get continueLabel => _get('continueLabel');
  String get start => _get('start');
  String get home => _get('home');
  String get difficulty => _get('difficulty');
  String get easy => _get('easy');
  String get medium => _get('medium');
  String get hard => _get('hard');
  String get opponent => _get('opponent');
  String get computer => _get('computer');
  String get passAndPlay => _get('passAndPlay');
  String get firstMove => _get('firstMove');
  String get yourTurn => _get('yourTurn');
  String get victory => _get('victory');
  String get defeat => _get('defeat');
  String get draw => _get('draw');

  static const Map<String, Map<String, String>> _data = {
    'en': {
      'settings': 'Settings',
      'game': 'Game',
      'theme': 'Theme',
      'sound': 'Sound',
      'animations': 'Animations',
      'language': 'Language',
      'languageSystem': 'System',
      'newGame': 'New Game',
      'howToPlay': 'How to Play',
      'statistics': 'Statistics',
      'continueLabel': 'Continue',
      'start': 'Start',
      'home': 'Home',
      'difficulty': 'Difficulty',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'opponent': 'Opponent',
      'computer': 'Computer',
      'passAndPlay': 'Pass & Play',
      'firstMove': 'First move',
      'yourTurn': 'Your turn',
      'victory': 'Victory',
      'defeat': 'Defeat',
      'draw': 'Draw',
    },
    'ja': {
      'settings': '設定',
      'game': 'ゲーム',
      'theme': 'テーマ',
      'sound': '効果音',
      'animations': 'アニメーション',
      'language': '言語',
      'languageSystem': '端末に従う',
      'newGame': '新しいゲーム',
      'howToPlay': '遊び方',
      'statistics': '統計',
      'continueLabel': 'つづきから',
      'start': '開始',
      'home': 'ホーム',
      'difficulty': '難易度',
      'easy': 'やさしい',
      'medium': 'ふつう',
      'hard': 'むずかしい',
      'opponent': '対戦相手',
      'computer': 'コンピュータ',
      'passAndPlay': '交互プレイ',
      'firstMove': '先手',
      'yourTurn': 'あなたの番',
      'victory': '勝ち',
      'defeat': '負け',
      'draw': '引き分け',
    },
  };
}

/// 現在の言語に対応する L10n(設定の localeCode から解決)。
final l10nProvider = Provider<L10n>(
  (ref) => L10n.resolve(ref.watch(settingsProvider).localeCode),
);
