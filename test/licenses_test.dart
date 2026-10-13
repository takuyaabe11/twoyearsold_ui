import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twoyearsold_ui/twoyearsold_ui.dart';

void main() {
  test('every bundled font has a copyright line and the full OFL text', () {
    expect(kFontCopyrights.keys,
        containsAll(['Arimo', 'NotoSansJP', 'NotoSansArabic', 'Inter']));
    for (final c in kFontCopyrights.values) {
      expect(c, isNotEmpty);
    }
    expect(kOflText, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(kOflText, contains('PERMISSION & CONDITIONS'));
    expect(kOflText, contains('TERMINATION'));
  });

  testWidgets('the list opens the full text of a license', (tester) async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(
          ['A Test Font'], 'Copyright Someone\n\nFull license text here.');
    });
    await tester.pumpWidget(const MaterialApp(
      home: LicensesScreen(theme: AppTheme.editorialDark, title: 'Licenses'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Licenses'), findsOneWidget);
    await tester.tap(find.text('A Test Font'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Full license text here.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the heading exists in every language', () {
    final seen = <String>{};
    for (final l in L10n.supported) {
      final word = L10n(l.code).licenses;
      expect(word, isNotEmpty, reason: l.code);
      seen.add(word);
    }
    // 英語へのフォールバックで埋まっていない(言語ごとに訳がある)。
    expect(seen.length, greaterThan(25));
  });
}
