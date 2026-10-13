import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 極細罫で区切るメニュー行: [ ラベル ...... (trailing) → ]。— DESIGN.md §6。
class MenuRow extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const MenuRow({
    super.key,
    required this.theme,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  static const double _arrow = 18;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.thinLine)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        // ラベルを先に(折り返さない幅で)置き、残りを補足へ渡す。補足が長いときに削られるのは
        // 補足の側(末尾を省略)。ラベルが行より長いときだけ、ラベルを折り返す。
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth - _arrow - _gap,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                    color: theme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Expanded(
                child: trailing == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(start: _gap),
                        child: Text(
                          trailing!,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textMuted,
                          ),
                        ),
                      ),
              ),
              if (trailing != null) const SizedBox(width: _gap),
              Icon(Icons.arrow_forward, size: _arrow, color: theme.accent),
            ],
          ),
        ),
      ),
    );
  }
}
