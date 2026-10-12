import 'package:audioplayers/audioplayers.dart';

/// 効果音の再生基盤。プレイヤーの確保・事前読み込み・即時発火・ループ・Web の解錠を受け持つ。
///
/// 語彙(どの出来事でどの音を、どの強さで鳴らすか)は持たない。共有の 7 語で足りる作は
/// [SoundService] を使う。固有の音響を持つリアルタイム系(§10.5 の個性)は、語彙だけを
/// 各作に置き、再生はここへ任せる — プレイヤーの扱いを各作で書き直さない(§10.4)。
///
/// 再生は常に安全(例外を投げない)。読み込めなかった音は鳴らないだけ。
class SoundBank {
  /// [playerFactory] はテスト用の差し替え口。
  SoundBank({AudioPlayer Function(String id)? playerFactory})
      : _newPlayer = playerFactory ?? ((id) => AudioPlayer(playerId: id));

  final AudioPlayer Function(String id) _newPlayer;
  final Map<String, AudioPlayer> _players = {};
  final Set<String> _loops = {};
  bool _ready = false;
  bool _unlocked = false;

  bool has(String id) => _players.containsKey(id);

  /// 他アプリの音と混ぜ、消音スイッチに従う。最初の [load] の前に一度だけ効く。
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
  }

  /// [asset](`sounds/xxx.wav`)を [id] の名で事前読み込みする。
  /// 単発の音は低遅延モード。[loop] は環境音用で、音量 0 のまま待機する([resume] で鳴らす)。
  Future<void> load(String id, String asset, {bool loop = false}) async {
    await init();
    try {
      final p = _newPlayer(id);
      if (loop) {
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setSource(AssetSource(asset));
        await p.setVolume(0);
        _loops.add(id);
      } else {
        // 低遅延モード(web では WebAudio 経路)で遅延を抑える。失敗しても続行。
        try {
          await p.setPlayerMode(PlayerMode.lowLatency);
        } catch (_) {}
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(asset));
      }
      _players[id] = p;
    } catch (_) {
      // 個別の読み込み失敗は無視(その音は鳴らないだけ)。
    }
  }

  /// 単発の音を即時に鳴らす(頭出ししてから再生。往復待ちをしない = 低遅延優先)。
  /// [rate] はピッチ、[volume] は音量。省くと前回の値のまま。
  void fire(String id, {double? rate, double? volume}) {
    final p = _players[id];
    if (p == null) return;
    if (rate != null) _quiet(p.setPlaybackRate(rate));
    if (volume != null) _quiet(p.setVolume(volume));
    _quiet(p.seek(Duration.zero));
    _quiet(p.resume());
  }

  void setVolume(String id, double volume) {
    final p = _players[id];
    if (p != null) _quiet(p.setVolume(volume));
  }

  /// ループ音を鳴らし始める / 続きから鳴らす。
  void resume(String id) {
    final p = _players[id];
    if (p != null) _quiet(p.resume());
  }

  void pause(String id) {
    final p = _players[id];
    if (p != null) _quiet(p.pause());
  }

  /// Web の自動再生ポリシー対策。最初のユーザー操作(タップ/スワイプ/キー)で一度だけ呼ぶと、
  /// 音量0のプレイヤーを resume して AudioContext を「解錠」する(無音)。以後の効果音が
  /// 初回から確実に鳴る。トランジェント活性化の窓内で呼ぶこと。安全(例外を投げない)。
  Future<void> unlock() async {
    if (_unlocked) return;
    final id = _players.keys.where((k) => !_loops.contains(k)).firstOrNull;
    if (id == null) return; // まだ何も読み込めていない。次の操作でやり直す。
    _unlocked = true;
    final p = _players[id]!;
    try {
      await p.setVolume(0);
      await p.resume();
      await p.stop();
      await p.setVolume(1);
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
    _loops.clear();
  }

  static void _quiet(Future<void> f) {
    f.catchError((_) {});
  }
}
