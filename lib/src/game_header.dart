import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ゲーム画面の共通ヘッダ — DESIGN.md §6 / §10.1。
/// 戻る=左上 `arrow_back`(onSurface)、やり直し=右上 `refresh`(accent/朱)。
/// 中央に任意の控えめな情報([center])を置ける(例: ラリー数)。
/// 各作がヘッダを独自実装して padding/色/配置がドリフトするのを防ぐ単一の出所。
class GameHeader extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onBack;

  /// やり直し(右上 refresh)。null なら表示しない。
  final VoidCallback? onRestart;
  final String? restartTooltip;

  /// 中央の控えめな表示(任意)。
  final Widget? center;

  /// やり直し(右上 refresh)の左に並べる固有の追加アクション(ヒント/アンドゥ等)。
  final List<Widget> trailing;

  const GameHeader({
    super.key,
    required this.theme,
    required this.onBack,
    this.onRestart,
    this.restartTooltip,
    this.center,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.onSurface),
            onPressed: onBack,
          ),
          const Spacer(),
          if (center != null) center!,
          const Spacer(),
          ...trailing,
          // 右上を戻ると対称に保つため、refresh が無くても同幅を確保。
          if (onRestart != null)
            IconButton(
              icon: Icon(Icons.refresh, color: theme.accent),
              tooltip: restartTooltip,
              onPressed: onRestart,
            )
          else if (trailing.isEmpty)
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
