import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ヒーローのワードマーク — DESIGN.md §2.2(60 / w700 / ls −1.5 / height 1.0 / textPrimary)。
///
/// 複数行に積める(`height: 1.0` で詰める)。負トラッキングはサイズに比例させ、
/// 大きくしても「塊感」を保つ(既定 −fontSize×0.025 = 60 で −1.5)。書体はディスプレイ固定。
class Wordmark extends StatelessWidget {
  final AppTheme theme;
  final List<String> lines;
  final double fontSize;
  final double? letterSpacing;
  final Color? color;

  const Wordmark({
    super.key,
    required this.theme,
    required this.lines,
    this.fontSize = 60,
    this.letterSpacing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ls = letterSpacing ?? -fontSize * 0.025;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Text(
            line,
            style: TextStyle(
              fontFamily: theme.displayFontFamily,
              fontFamilyFallback: theme.fontFamilyFallback,
              fontSize: fontSize,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: color ?? theme.textPrimary,
              letterSpacing: ls,
            ),
          ),
      ],
    );
  }
}

/// 画面タイトル — DESIGN.md §2.2(44 / w700 / ls −1.2 / height 1.0 / textPrimary)。
class ScreenTitle extends StatelessWidget {
  final AppTheme theme;
  final String text;
  final double fontSize;
  final double letterSpacing;

  const ScreenTitle({
    super.key,
    required this.theme,
    required this.text,
    this.fontSize = 44,
    this.letterSpacing = -1.2,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: theme.displayFontFamily,
        fontFamilyFallback: theme.fontFamilyFallback,
        fontSize: fontSize,
        height: 1.0,
        fontWeight: FontWeight.w700,
        color: theme.textPrimary,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
