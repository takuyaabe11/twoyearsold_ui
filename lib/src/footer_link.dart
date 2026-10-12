import 'package:flutter/material.dart';

import 'app_theme.dart';

/// フッターの小さなテキストリンク(DESIGN.md §6「フッターリンク」)。
///
/// `Statistics · Achievements · Settings` のように中黒で並べる 13px/textMuted。
/// 各作で `_FooterLink` を個別実装してドリフトする(§9 のタップ領域を入れ忘れる等)
/// のを防ぐ単一の出所。**44px のタップ領域を内蔵**(13px の文字に縦と横の余白)。
///
/// 横の余白 [hitPad] は見た目の間隔を兼ねる([FooterDot] は余白を持たない)。先頭のリンクは
/// 余白のぶん右へずれるので、並べる側が [hitPad] だけ左へ寄せて文字の左端を揃える。
class FooterLink extends StatelessWidget {
  /// 文字の左右に取る当たり判定の余白。2 文字のラベル(約 27px)でも幅 44px を超える。
  static const double hitPad = 9;

  final String label;
  final AppTheme theme;
  final VoidCallback onTap;
  const FooterLink(this.label, this.theme, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          // §9: 最低 44px。縦だけでなく横も(短いラベルは文字幅だけでは 44px に届かない)。
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: hitPad),
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
  Widget build(BuildContext context) =>
      // 左右の間隔は隣の FooterLink の余白が担う(当たり判定を間隔いっぱいまで広げるため)。
      Text('·', style: TextStyle(color: theme.textMuted));
}
