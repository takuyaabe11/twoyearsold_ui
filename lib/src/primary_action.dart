import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 主要アクション行 — DESIGN.md §6 / §4。`[ Start .......... → ]`。
/// 塗らない。24 / w700 / accent ラベル + 末尾に accent の `arrow_forward`。
///
/// [expand]=true で左にラベル・右に矢印を広げる(メニュー的)。false で内容幅に縮め中央寄せ。
class PrimaryAction extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final VoidCallback onTap;
  final bool expand;
  final double fontSize;

  const PrimaryAction({
    super.key,
    required this.theme,
    required this.label,
    required this.onTap,
    this.expand = true,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: theme.accent,
        letterSpacing: 0.3,
      ),
    );
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (expand) Expanded(child: text) else text,
        SizedBox(width: expand ? 0 : 8),
        Icon(Icons.arrow_forward, size: fontSize - 2, color: theme.accent),
      ],
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: row,
      ),
    );
  }
}
