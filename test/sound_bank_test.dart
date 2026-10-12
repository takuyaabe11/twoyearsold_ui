import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/testing.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  firstSoundSurvivesUnlock();

  late List<String> log;
  late SoundBank bank;
  setUp(() {
    log = [];
    bank = recordingSoundBank(log);
  });

  test('a one-shot sound is preloaded in low-latency mode', () async {
    await bank.load('hit', 'sounds/place.wav');
    expect(log, [
      'hit.setPlayerMode(lowLatency)',
      'hit.setReleaseMode(stop)',
      'hit.setSource(sounds/place.wav)',
    ]);
  });

  test('fire rewinds and plays at once, applying pitch and volume first', () {
    return bank.load('hit', 'sounds/place.wav').then((_) {
      log.clear();
      bank.fire('hit', rate: 0.9, volume: 0.5);
      expect(log, [
        'hit.setPlaybackRate(0.9)',
        'hit.setVolume(0.5)',
        'hit.seek(0ms)',
        'hit.resume()',
      ]);
    });
  });

  test('fire without pitch or volume leaves them as they were', () async {
    await bank.load('goal', 'sounds/erase.wav');
    log.clear();
    bank.fire('goal');
    expect(log, ['goal.seek(0ms)', 'goal.resume()']);
  });

  test('a loop waits silent until resumed', () async {
    await bank.load('blower', 'sounds/blower.wav', loop: true);
    expect(log, [
      'blower.setReleaseMode(loop)',
      'blower.setSource(sounds/blower.wav)',
      'blower.setVolume(0.0)',
    ]);
    log.clear();
    bank
      ..setVolume('blower', 0.18)
      ..resume('blower')
      ..pause('blower');
    expect(log,
        ['blower.setVolume(0.18)', 'blower.resume()', 'blower.pause()']);
  });

  test('a sound that failed to load is skipped without throwing', () async {
    final b = recordingSoundBank(log, missing: {'bad'});
    await b.load('bad', 'sounds/missing.wav');
    await b.load('ok', 'sounds/place.wav');
    expect(b.has('bad'), isFalse);
    expect(b.has('ok'), isTrue);
    log.clear();
    b.fire('bad');
    b.setVolume('bad', 1);
    expect(log, isEmpty);
  });

  test('unlock plays one silent one-shot once, never a loop', () async {
    await bank.load('blower', 'sounds/blower.wav', loop: true);
    await bank.load('hit', 'sounds/place.wav');
    log.clear();
    await bank.unlock();
    await bank.unlock();
    expect(log, [
      'hit.setVolume(0.0)',
      'hit.resume()',
      'hit.stop()',
      'hit.setVolume(1.0)',
    ]);
  });

  test('unlock before anything is loaded retries on the next call', () async {
    await bank.unlock();
    await bank.load('hit', 'sounds/place.wav');
    log.clear();
    await bank.unlock();
    expect(log, isNotEmpty);
  });
}

// 解錠は最初の単発プレイヤーを無音で一度鳴らす。同じ操作でその音を鳴らすと(例: 最初の
// 一投の放球音)、無音のまま鳴って stop で切られていた。解錠が済んでから鳴らす。
void firstSoundSurvivesUnlock() {
  test('a sound fired while it is being used to unlock plays after, audibly',
      () async {
    final log = <String>[];
    final bank = recordingSoundBank(log);
    await bank.load('shoot', 'sounds/place.wav');
    await bank.load('rim', 'sounds/rim0.wav');
    log.clear();

    final unlocking = bank.unlock(); // 操作の入口
    bank.fire('shoot'); // 同じ操作で鳴る音
    bank.fire('rim', volume: 0.9); // 別のプレイヤーは待たせない
    await unlocking;
    await Future<void>.delayed(Duration.zero);

    final restored = log.indexOf('shoot.setVolume(1.0)');
    final played = log.lastIndexOf('shoot.resume()');
    expect(restored, greaterThan(-1));
    expect(played, greaterThan(restored),
        reason: '音量を戻した後に鳴らす: $log');
    expect(log.where((e) => e == 'shoot.resume()'), hasLength(2)); // 無音の解錠 + 本番
    expect(log.indexOf('rim.resume()'), lessThan(restored));
  });
}
