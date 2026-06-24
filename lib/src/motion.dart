import 'package:flutter/material.dart';

/// 演出(アニメーション)を出すべきかを返す単一の判定(DESIGN.md §5 / §9 / §10.4)。
///
/// 「設定の演出 ON」かつ「OS の reduced-motion でない」の AND。各作の play_screen が
/// `settings.animationsEnabled && !MediaQuery.of(context).disableAnimations` を
/// 個別にインライン展開していた(=ドリフト)のを束ねる。[settingEnabled] には
/// 各作の設定値(settingsProvider の animationsEnabled)を渡す。
bool motionEnabled(BuildContext context, {required bool settingEnabled}) =>
    settingEnabled && !MediaQuery.of(context).disableAnimations;

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
