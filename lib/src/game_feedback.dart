import 'haptics.dart';
import 'sound_service.dart';

/// 効果音と触覚をまとめた「所作」の単一の発火口(DESIGN.md §5.4 / §10.1)。
///
/// 各作の GameController が `final SoundService sound;` `final bool Function() soundOn;`
/// `final bool Function() hapticsOn;` の3フィールドと `void _sfx(Sfx){ if(soundOn()) ... }`
/// ヘルパを個別にコピー実装していた(=設定ゲートの分散・ドリフトの温床)のを束ねる。
///
/// 設定の ON/OFF 判定はここで一括して行う。各作は `feedback.sfx(Sfx.place)` /
/// `feedback.impact()` のように所作名で呼ぶだけでよい。
///
/// 注: リアルタイム音響を持つ作(AirHockey の専用 SoundService 等)は対象外。
/// 共有 [SoundService] の語彙(place/note/erase…)に乗る作のための束ね口。
class GameFeedback {
  GameFeedback({
    required this.sound,
    required this.soundOn,
    required this.hapticsOn,
  });

  final SoundService sound;
  final bool Function() soundOn;
  final bool Function() hapticsOn;

  /// 効果音(設定 OFF なら無音)。[rate] は再生速度(音程変調)。
  void sfx(Sfx s, {double rate = 1.0}) {
    if (soundOn()) sound.play(s, rate: rate);
  }

  /// 触覚のみ(設定 OFF なら無振動)。§5.4 の語彙に対応する薄いラッパ。
  void tap() => Haptics.tap(hapticsOn());
  void select() => Haptics.select(hapticsOn());
  void impact() => Haptics.impact(hapticsOn());
  void win() => Haptics.win(hapticsOn());
}
