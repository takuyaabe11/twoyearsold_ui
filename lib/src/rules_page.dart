import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'back_button.dart';
import 'editorial_scaffold.dart';
import 'headings.dart';
import 'section_label.dart';

/// 「遊び方」ルール一覧ページ(DESIGN.md §6/§7)。各作で同型に手書きしていた
/// チュートリアルの単一の出所。[rules] は (見出し, 本文) の並び(各作の xxL10n.howTo)。
class RulesPage extends StatelessWidget {
  final AppTheme theme;

  /// 画面タイトル(例: l10n.howToPlay)。
  final String title;

  /// (セクション見出し, 本文) の並び。
  final List<(String, String)> rules;

  final double bodyFontSize;
  final double bodyHeight;

  const RulesPage({
    super.key,
    required this.theme,
    required this.title,
    required this.rules,
    this.bodyFontSize = 13,
    this.bodyHeight = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return EditorialScaffold(
      theme: theme,
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorialBackButton(theme: theme),
          const SizedBox(height: 24),
          ScreenTitle(theme: theme, text: title),
          const SizedBox(height: 40),
          for (final (heading, body) in rules) ...[
            SectionLabel(heading, theme),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 2),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: bodyFontSize,
                  height: bodyHeight,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
