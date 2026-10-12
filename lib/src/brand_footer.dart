import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 全画面共通の最下部ブランド表記(小さく控えめに)。— DESIGN.md §6 / §8。
class BrandFooter extends StatelessWidget {
  final AppTheme theme;
  const BrandFooter({super.key, required this.theme});

  /// 表記の年を固定する(テスト用)。ゴールデンが年越しで一斉に落ちないようにする。
  @visibleForTesting
  static int? debugYear;

  @override
  Widget build(BuildContext context) {
    // MaterialApp.builder の Column 直下(Navigator の兄弟)に置かれるため、
    // Material 祖先が無いと Text に黄色い二重下線が描かれる。Material で包んで防ぐ。
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        color: theme.background,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 3),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '© ${debugYear ?? DateTime.now().year} TWOYEARSOLD',
              textAlign: TextAlign.center,
              // ブランド表記はラテン文字の固定句。右から左の言語でも語順を入れ替えない
              // (入れ替わると「TWOYEARSOLD 2026 ©」になる)。
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.6,
                color: theme.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
