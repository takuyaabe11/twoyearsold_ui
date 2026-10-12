import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/testing.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
