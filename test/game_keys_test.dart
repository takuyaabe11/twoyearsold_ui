import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  testWidgets('each key calls its action; unbound keys fall through',
      (tester) async {
    final log = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: GameKeys(
        onBack: () => log.add('back'),
        onRestart: () => log.add('restart'),
        onUndo: () => log.add('undo'),
        onHint: () => log.add('hint'),
        onMove: (d) => log.add(d.name),
        onConfirm: () => log.add('confirm'),
        onDigit: (n) => log.add('digit$n'),
        onDelete: () => log.add('delete'),
        child: const SizedBox.expand(),
      ),
    ));
    for (final k in [
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.keyH,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.backspace,
    ]) {
      await tester.sendKeyEvent(k);
    }
    expect(log, [
      'back', 'restart', 'undo', 'hint', 'left', 'up', 'confirm', //
      'digit7', 'digit3', 'delete',
    ]);
    // redo は渡していない → 何も起きず、処理済みにもならない。
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyY), isFalse);
  });

  testWidgets('a shortcut with Ctrl / Cmd is left to the browser',
      (tester) async {
    var restarts = 0;
    await tester.pumpWidget(MaterialApp(
      home: GameKeys(
          onRestart: () => restarts++, child: const SizedBox.expand()),
    ));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(restarts, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    expect(restarts, 1);
  });

  testWidgets('Esc goes back by default', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  const GameKeys(child: Scaffold(body: Text('inner'))))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsNothing);
  });

  test('the grid cursor appears on first move, then walks and stops at edges',
      () {
    final c = GridCursor(cols: 8, rows: 8);
    expect(c.index, isNull);
    c.move(AxisDirection.right);
    expect(c.index, 4 * 8 + 3); // 最初の一押しは現れるだけ(中央)
    c.move(AxisDirection.right);
    expect(c.index, 4 * 8 + 4);
    for (var i = 0; i < 20; i++) {
      c.move(AxisDirection.up);
    }
    expect(c.index, 4); // 上端で止まる
    c.hide();
    expect(c.index, isNull);
  });

  testWidgets('a game can add its own keys, which win over the shared ones',
      (tester) async {
    final log = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: GameKeys(
        onHint: () => log.add('hint'),
        extra: {
          LogicalKeyboardKey.keyF: () => log.add('flag'),
          LogicalKeyboardKey.keyH: () => log.add('own-h'),
        },
        child: const SizedBox.expand(),
      ),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    expect(log, ['flag', 'own-h']);
  });
}
