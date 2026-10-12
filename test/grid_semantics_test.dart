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

  testWidgets('cells without an action are still announced one by one',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 200,
          height: 100,
          // 盤はたいていジェスチャを受けるウィジェットの中にある。その親ノードへ、
          // 操作を持たないマスのラベルが吸い込まれていた。
          child: GestureDetector(
            onTap: () {},
            child: GridSemantics(
              cols: 2,
              rows: 1,
              label: (i) => 'cell $i',
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ),
      ),
    ));
    // 操作が無くても、マスごとに別々のノードとして読まれる(1 つに連結されない)。
    expect(tester.getSemantics(find.bySemanticsLabel('cell 0')).label, 'cell 0');
    expect(tester.getSemantics(find.bySemanticsLabel('cell 1')).label, 'cell 1');
    handle.dispose();
  });
}
