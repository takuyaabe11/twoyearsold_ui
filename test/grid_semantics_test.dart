import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  testWidgets('each cell is announced and can be activated; touch still reaches the board',
      (tester) async {
    final handle = tester.ensureSemantics();
    final semanticTaps = <int>[];
    var boardTaps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          height: 200,
          child: GridSemantics(
            cols: 3,
            rows: 2,
            label: (i) => 'cell $i',
            onTap: semanticTaps.add,
            isButton: (i) => i.isEven,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => boardTaps++,
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ),
      ),
    ));

    for (var i = 0; i < 6; i++) {
      expect(find.bySemanticsLabel('cell $i'), findsOneWidget);
    }
    // マスは等分の格子に並ぶ(4 番 = 2 行目の中央)。
    expect(tester.getRect(find.bySemanticsLabel('cell 4')).size, const Size(100, 100));
    expect(tester.getSemantics(find.bySemanticsLabel('cell 4')),
        matchesSemantics(label: 'cell 4', isButton: true, hasTapAction: true));
    expect(tester.getSemantics(find.bySemanticsLabel('cell 1')),
        matchesSemantics(label: 'cell 1', hasTapAction: true));

    // 読み上げの操作はそのマスの番号で届く。
    tester.semantics.tap(find.semantics.byLabel('cell 4'));
    expect(semanticTaps, [4]);

    // 指のタップは読み上げ層を素通りして盤へ届く。
    await tester.tapAt(tester.getCenter(find.bySemanticsLabel('cell 1')));
    expect(boardTaps, 1);
    handle.dispose();
  });
}
