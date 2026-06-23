import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 全画面共通の定型骨格 — DESIGN.md §7。
///
/// `Scaffold(bg) → SafeArea → LayoutBuilder → SingleChildScrollView →
///  ConstrainedBox(minHeight) → Center → ConstrainedBox(maxWidth:460) → Padding(32)`。
/// 縦が余れば中央寄せ、足りなければスクロール、を全画面で守るための単一の出所。
/// 各作がこの骨格を手書きするとドリフトするため、ここに一元化する。
class EditorialScaffold extends StatelessWidget {
  final AppTheme theme;

  /// 中身。通常は `Column(crossAxisAlignment: start)`。
  final Widget child;

  /// コンテンツ最大幅(§3)。既定 460。
  final double maxWidth;

  /// 水平パディング(§3)。既定 32。上下は控えめに。
  final EdgeInsets padding;

  const EditorialScaffold({
    super.key,
    required this.theme,
    required this.child,
    this.maxWidth = 460,
    this.padding = const EdgeInsets.fromLTRB(32, 24, 32, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
