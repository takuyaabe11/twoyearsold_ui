/// 各作のテストから使う補助(本番コードからは import しない)。
library;

import 'package:audioplayers/audioplayers.dart';

import 'src/sound_bank.dart';

/// 音を鳴らさず、プレイヤーへの操作を `id.操作(引数)` の形で [log] へ順に記録する [SoundBank]。
/// 「どの出来事でどの音が、どのピッチ・音量で鳴るか」をテストで固定するために使う。
/// [missing] に入れた id は読み込みに失敗する(その音が欠けた端末の再現)。
SoundBank recordingSoundBank(List<String> log, {Set<String> missing = const {}}) =>
    SoundBank(
      playerFactory: (id) =>
          _RecordingPlayer(id, log, broken: missing.contains(id)),
    );

class _RecordingPlayer implements AudioPlayer {
  _RecordingPlayer(this.id, this.log, {this.broken = false});
  final String id;
  final List<String> log;
  final bool broken;

  @override
  dynamic noSuchMethod(Invocation i) {
    final name = i.memberName.toString().split('"')[1];
    if (broken && name == 'setSource') throw StateError('no such asset');
    final arg = i.positionalArguments.isEmpty ? '' : i.positionalArguments.first;
    final shown = switch (arg) {
      AssetSource a => a.path,
      Duration d => '${d.inMilliseconds}ms',
      Enum e => e.name,
      _ => '$arg',
    };
    log.add('$id.$name($shown)');
    return Future<void>.value();
  }
}
