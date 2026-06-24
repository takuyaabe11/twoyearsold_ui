import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 画面左上の戻るボタン(DESIGN.md §6「戻る」/ §10.1 戻る=左上 arrow_back)。
///
/// `IconButton(arrow_back, onSurface, padding 0, 左寄せ)` を各画面で手書きする
/// (~11箇所)代わりに使う単一の出所。既定で `Navigator.maybePop()`。
class EditorialBackButton extends StatelessWidget {
  final AppTheme theme;

  /// 既定は `Navigator.of(context).maybePop()`。
  final VoidCallback? onPressed;

  const EditorialBackButton({super.key, required this.theme, this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        icon: Icon(Icons.arrow_back, color: theme.onSurface),
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      );
}
