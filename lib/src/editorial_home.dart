import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editorial_scaffold.dart';
import 'footer_link.dart';
import 'headings.dart';
import 'help_button.dart';

/// トップ画面の「殻(chrome)」の単一の出所(DESIGN.md §7)。
///
/// 全作の home_screen が `Stack[ EditorialScaffold[Column[Wordmark, …本体…,
/// フッターリンク]] + Positioned 右上 HelpButton ]` を個別にコピー実装していた
/// (=ドリフトの温床: HelpButton の位置・SafeArea・余白がずれる)のを束ねる。
///
/// 可変部はワードマーク・本体([body]: メニュー行や「つづきから」カード等)・フッター
/// リンク・ヘルプ遷移のみ。本体の中身はゲームごとに異なる(§10.5)ので [body] スロット
/// で受ける。ナビゲーションと効果音の先読みは各作の Stateful ラッパが持つ(遷移先が固有
/// のため)。
class EditorialHome extends StatelessWidget {
  const EditorialHome({
    super.key,
    required this.theme,
    required this.wordmark,
    required this.body,
    required this.footer,
    required this.onHelp,
    this.helpTooltip,
    this.wordmarkFontSize = 60,
    this.gapAfterWordmark = 56,
    this.gapBeforeFooter = 36,
  });

  final AppTheme theme;

  /// ワードマーク(1〜2行)。例: `['Number', 'Place']`。
  final List<String> wordmark;
  final double wordmarkFontSize;

  /// ワードマークとフッターの間の本体(メニュー行・カード等)。
  final Widget body;

  /// フッターのテキストリンク。複数なら間に中黒(`·`)を自動で挟む。
  final List<({String label, VoidCallback onTap})> footer;

  final VoidCallback onHelp;
  final String? helpTooltip;

  final double gapAfterWordmark;
  final double gapBeforeFooter;

  @override
  Widget build(BuildContext context) {
    final footerRow = <Widget>[];
    for (var i = 0; i < footer.length; i++) {
      if (i > 0) footerRow.add(FooterDot(theme));
      footerRow.add(FooterLink(footer[i].label, theme, footer[i].onTap));
    }
    return Stack(
      children: [
        EditorialScaffold(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wordmark(
                theme: theme,
                lines: wordmark,
                fontSize: wordmarkFontSize,
              ),
              SizedBox(height: gapAfterWordmark),
              body,
              SizedBox(height: gapBeforeFooter),
              Row(mainAxisSize: MainAxisSize.min, children: footerRow),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: SafeArea(
            child: HelpButton(
              color: theme.textMuted,
              onTap: onHelp,
              tooltip: helpTooltip,
            ),
          ),
        ),
      ],
    );
  }
}

/// メニュー行(MenuRow)を極細罫の上線で囲むトップ画面の定番ブロック。
/// `Container(border: top thinLine)[Column[…rows]]` を単一の出所に。
class MenuBlock extends StatelessWidget {
  const MenuBlock({super.key, required this.theme, required this.rows});

  final AppTheme theme;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.thinLine)),
        ),
        child: Column(children: rows),
      );
}
