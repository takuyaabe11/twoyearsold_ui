import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 小さく字間を広げた控えめなセクション見出し(大文字)。— DESIGN.md §2 / §6。
class SectionLabel extends StatelessWidget {
  final String text;
  final AppTheme theme;
  const SectionLabel(this.text, this.theme, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 2),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            color: theme.textMuted,
            letterSpacing: 2.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
