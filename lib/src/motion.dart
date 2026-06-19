import 'package:flutter/material.dart';

/// フェード + わずかな上スライド(2%)のミニマルな画面遷移。
/// [enabled] が false、または reduced-motion 時は遷移なし(child をそのまま)。— DESIGN.md §5。
class MinimalPageTransitionsBuilder extends PageTransitionsBuilder {
  final bool enabled;
  const MinimalPageTransitionsBuilder({this.enabled = true});

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!enabled || MediaQuery.of(context).disableAnimations) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
