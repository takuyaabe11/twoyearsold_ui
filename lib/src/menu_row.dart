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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.thinLine)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Expanded(
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
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(fontSize: 13, color: theme.textMuted),
              ),
              const SizedBox(width: 12),
            ],
            Icon(Icons.arrow_forward, size: 18, color: theme.accent),
          ],
        ),
      ),
    );
  }
}
