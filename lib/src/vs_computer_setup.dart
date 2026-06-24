import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'back_button.dart';
import 'choice_row.dart';
import 'editorial_scaffold.dart';
import 'headings.dart';
import 'l10n.dart';
import 'primary_action.dart';
import 'section_label.dart';
import 'star_picker.dart';

/// 「対コンピュータ / 2人対戦」の対戦設定画面の単一の出所(DESIGN.md §7 / §10.7)。
///
/// Gobblet と Reversi の NewGameScreen がほぼ完全な双子(相手選択・★難易度・先手選択・
/// 開始・タグライン)だったのを束ねる。アプリ固有型(GameMode / AiLevel)に依存しないよう、
/// 状態はプリミティブ(`vsComputer` / `stars` / `youFirst`)で持ち、[onStart] でまとめて
/// 返す。各作はラッパで自分の型(GameMode・AiLevel.fromStars)へ写して PlayScreen を開く。
///
/// 先手選択の文言は作で異なる(Gobblet「あなた / コンピュータ」、Reversi「黒(先手) /
/// 白(後手)」)ため [firstMoveLabel] / [youLabel] / [opponentLabel] で注入する。
class VsComputerSetup extends StatefulWidget {
  const VsComputerSetup({
    super.key,
    required this.theme,
    required this.l10n,
    required this.firstMoveLabel,
    required this.youLabel,
    required this.opponentLabel,
    required this.tagline,
    required this.onStart,
    this.initialStars = 3,
  });

  final AppTheme theme;
  final L10n l10n;

  /// 先手選択セクションの見出し(例: l10n.firstMove / 「あなたの石」)。
  final String firstMoveLabel;

  /// 先手選択の選択肢ラベル(自分 / 相手)。
  final String youLabel;
  final String opponentLabel;

  /// 開始ボタン下の小さな説明文。
  final String tagline;

  /// 開始時のコールバック。[vsComputer] false は2人対戦、[stars] は★1〜5、
  /// [youFirst] は自分が先手か。
  final void Function({
    required bool vsComputer,
    required int stars,
    required bool youFirst,
  }) onStart;

  final int initialStars;

  @override
  State<VsComputerSetup> createState() => _VsComputerSetupState();
}

class _VsComputerSetupState extends State<VsComputerSetup> {
  late bool _vsComputer = true;
  late int _stars = widget.initialStars;
  bool _youFirst = true;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.l10n;
    return EditorialScaffold(
      theme: theme,
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorialBackButton(theme: theme),
          const SizedBox(height: 24),
          ScreenTitle(theme: theme, text: l10n.newGame),
          const SizedBox(height: 40),
          SectionLabel(l10n.opponent, theme),
          ChoiceRow<bool>(
            theme: theme,
            value: _vsComputer,
            options: [
              (true, l10n.computer),
              (false, l10n.passAndPlay),
            ],
            onChanged: (v) => setState(() => _vsComputer = v),
          ),
          const SizedBox(height: 28),
          if (_vsComputer) ...[
            SectionLabel(l10n.difficulty, theme),
            const SizedBox(height: 12),
            StarPicker(
              value: _stars,
              filledColor: theme.accent,
              emptyColor: theme.textMuted,
              onChanged: (s) => setState(() => _stars = s),
            ),
            const SizedBox(height: 28),
            SectionLabel(widget.firstMoveLabel, theme),
            ChoiceRow<bool>(
              theme: theme,
              value: _youFirst,
              options: [
                (true, widget.youLabel),
                (false, widget.opponentLabel),
              ],
              onChanged: (v) => setState(() => _youFirst = v),
            ),
            const SizedBox(height: 28),
          ],
          PrimaryAction(theme: theme, label: l10n.start, onTap: _start),
          const SizedBox(height: 16),
          Text(
            widget.tagline,
            style: TextStyle(fontSize: 13, height: 1.4, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  void _start() => widget.onStart(
        vsComputer: _vsComputer,
        stars: _stars,
        youFirst: _youFirst,
      );
}
