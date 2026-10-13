import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester,
      {required String label, String? trailing, double scale = 1}) {
    return tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 326,
              child: MenuRow(
                theme: AppTheme.editorialDark,
                label: label,
                trailing: trailing,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ));
  }

  double lineHeight(WidgetTester tester, String text) =>
      tester.getSize(find.text(text)).height;

  testWidgets('a long trailing note never wraps the label', (tester) async {
    // 実機(Android・文字 1.3 倍)で「つづきから」が 2 行に折れた組み合わせ。
    await pump(tester, label: 'Continue', scale: 1.3);
    final oneLine = lineHeight(tester, 'Continue');
    await pump(tester,
        label: 'Continue',
        trailing: '16 × 16 · Classic · 10/13 10:57',
        scale: 1.3);
    expect(lineHeight(tester, 'Continue'), oneLine);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the trailing note stays right next to the arrow', (tester) async {
    await pump(tester, label: 'Continue', trailing: '9 × 9');
    final note = tester.getRect(find.text('9 × 9'));
    final arrow = tester.getRect(find.byIcon(Icons.arrow_forward));
    expect(arrow.left - note.right, 12);
  });

  testWidgets('a label wider than the row wraps instead of overflowing',
      (tester) async {
    await pump(tester,
        label: 'Herausforderung des Tages fortsetzen und weiterspielen',
        trailing: '3',
        scale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
