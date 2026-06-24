import 'package:flutter/material.dart';

import 'app_theme.dart';

/// フッターの小さなテキストリンク(DESIGN.md §6「フッターリンク」)。
///
/// `Statistics · Achievements · Settings` のように中黒で並べる 13px/textMuted。
/// 各作で `_FooterLink` を個別実装してドリフトする(§9 のタップ領域を入れ忘れる等)
/// のを防ぐ単一の出所。**44px のタップ領域を内蔵**(13px の文字に縦余白)。
class FooterLink extends StatelessWidget {
  final String label;
  final AppTheme theme;
  final VoidCallback onTap;
  const FooterLink(this.label, this.theme, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14), // §9: 最低44px。
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
}

/// フッターリンクの中黒区切り `·`(textMuted)。FooterLink の間に置く。
class FooterDot extends StatelessWidget {
  final AppTheme theme;
  const FooterDot(this.theme, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('·', style: TextStyle(color: theme.textMuted)),
      );
}
