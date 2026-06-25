import 'package:audioplayers/audioplayers.dart';

/// TWOYEARSOLD 共通の効果音語彙(DESIGN.md §10.1)。「どの作品も同じ間」。
///
/// 役割で名付ける(各作のイベントをこの語彙に写像する):
///   place    主操作(置く/開く/打つ)
///   note     副操作・印
///   erase    取り消し/裏返し/マージ/捕獲
///   mistake  誤り
///   hint     ヒント提示
///   complete 完成・勝ち
///   gameOver 失敗・負け
///
/// アセットは各作が `assets/sounds/<name>.wav` を同梱する(7音は全作 byte 同一)。
/// 使わない音は同梱不要(その音の play は安全に無視される)。リアルタイム系(AirHockey 等)は
/// 固有の音響を §10.5 の個性として各作で持ってよい。
enum Sfx { place, note, erase, mistake, hint, complete, gameOver }

/// 合成したミニマルな効果音を再生する。各音に専用プレイヤーを持ち、事前読み込みして
/// `stop()+resume()` で低遅延に再生する(Web でも確実)。再生は常に安全(例外を投げない)。
/// — これが効果音の単一の出所(§10.4)。各作で再実装しない。
class SoundService {
  static const _files = {
    Sfx.place: 'sounds/place.wav',
    Sfx.note: 'sounds/note.wav',
    Sfx.erase: 'sounds/erase.wav',
    Sfx.mistake: 'sounds/mistake.wav',
    Sfx.hint: 'sounds/hint.wav',
    Sfx.complete: 'sounds/complete.wav',
    Sfx.gameOver: 'sounds/gameover.wav',
  };

  /// 同梱する音だけを読み込む(未同梱は静かにスキップ)。null=全7音。
  final Set<Sfx>? only;

  SoundService({this.only});

  final Map<Sfx, AudioPlayer> _players = {};
  bool _ready = false;
  bool _unlocked = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build(),
      );
    } catch (_) {
      // コンテキスト設定に失敗しても再生自体は試みる。
    }
    for (final entry in _files.entries) {
      if (only != null && !only!.contains(entry.key)) continue;
      try {
        final p = AudioPlayer(playerId: 'sfx_${entry.key.name}');
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(entry.value));
        _players[entry.key] = p;
      } catch (_) {
        // 個別の読み込み失敗は無視(その音は鳴らないだけ)。
      }
    }
  }

  /// Web の自動再生ポリシー対策。最初のユーザー操作(タップ/スワイプ/キー)で一度だけ呼ぶと、
  /// 音量0のプレイヤーを resume して AudioContext を「解錠」する(無音)。以後の効果音が
  /// 初回から確実に鳴る。トランジェント活性化の窓内で呼ぶこと。安全(例外を投げない)。
  Future<void> unlock() async {
    if (_unlocked || _players.isEmpty) return;
    _unlocked = true;
    final p = _players.values.first;
    try {
      await p.setVolume(0);
      await p.resume();
      await p.stop();
      await p.setVolume(1);
    } catch (_) {}
  }

  /// [rate] で再生ピッチ/速度を微調整できる(裏返しの揺らぎ・アクセント用)。
  /// 対応しない環境では無視される(安全)。
  void play(Sfx sfx, {double rate = 1.0}) {
    final p = _players[sfx];
    if (p == null) return;
    p.stop().then((_) async {
      if (rate != 1.0) {
        try {
          await p.setPlaybackRate(rate);
        } catch (_) {}
      }
      await p.resume();
    }).catchError((_) {});
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}
