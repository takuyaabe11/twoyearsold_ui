import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<(int, String)> options) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: ChoiceRow<int>(
            theme: AppTheme.editorialDark,
            value: options.first.$1,
            options: options,
            onChanged: (_) {},
          ),
        ),
      ),
    ));
  }

  testWidgets('a one-glyph label still gets a 44px wide tap area',
      (tester) async {
    await pump(tester, [(1, '♠'), (2, '♠♥'), (4, '♠♥♦♣')]);
    for (final label in ['♠', '♠♥', '♠♥♦♣']) {
      final size = tester.getSize(find
          .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
          .first);
      expect(size.width, greaterThanOrEqualTo(44), reason: label);
      expect(size.height, greaterThanOrEqualTo(44), reason: label);
    }
  });

  testWidgets('options that fit stay on one line', (tester) async {
    // 最小幅を入れるときに行いっぱいへ広げてしまうと、選択肢が 1 行に 1 つずつ並ぶ。
    await pump(tester, [(1, 'Klondike'), (2, 'FreeCell'), (3, 'Spider')]);
    final a = tester.getTopLeft(find.text('Klondike'));
    final b = tester.getTopLeft(find.text('FreeCell'));
    final c = tester.getTopLeft(find.text('Spider'));
    expect(b.dy, a.dy);
    expect(c.dy, a.dy);
    expect(b.dx, greaterThan(a.dx));
    expect(c.dx, greaterThan(b.dx));
  });
}
