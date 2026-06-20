import 'package:flutter/material.dart';

/// 言語を選ぶプルダウン(テーマ・i18n 非依存)。
///
/// 色・文言・候補・選択ハンドラを引数で受けるので、`AppTheme` 系の各ゲームでも
/// `SudokuTheme` の NumberPlace でも同一コードを共有できる(DESIGN.md §10.2)。
///
/// 罫で囲った 1 行の「フィールド」をタップすると、対応言語のメニューがその直下に開く。
/// 先頭は常に「端末に従う」で、`null`(端末追従)のときは解決先の言語名を併記する。
class LanguagePulldown extends StatelessWidget {
  /// 選択中の言語コード(null = 端末に従う)。
  final String? selectedCode;

  /// 候補言語(コード, 自国語表記)。
  final List<({String code, String name})> languages;

  /// 「端末に従う」のラベル(例: 端末に従う / System)。
  final String systemLabel;

  /// 端末追従時に実際へ解決される言語の表示名(ヒント用, 例: 日本語)。
  final String deviceLanguageName;

  /// 選択時のコールバック。null = 端末に従う。
  final ValueChanged<String?> onChanged;

  // 役割トークン(呼び出し側のテーマから渡す)。
  final Color textPrimary;
  final Color textSecondary;
  final Color surface;
  final Color line;
  final Color accent;

  const LanguagePulldown({
    super.key,
    required this.selectedCode,
    required this.languages,
    required this.systemLabel,
    required this.deviceLanguageName,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.line,
    required this.accent,
  });

  /// 「端末に従う」を表すメニューの値(実在の言語コードと衝突しない番兵)。
  static const _systemValue = '__system__';

  String get _systemRowLabel => '$systemLabel  ·  $deviceLanguageName';

  @override
  Widget build(BuildContext context) {
    // 明示選択された言語(null のときは端末名をヒント表示するため引かない)。
    final picked = selectedCode == null
        ? null
        : languages.firstWhere(
            (l) => l.code == selectedCode,
            orElse: () => languages.first,
          );

    return InkWell(
      onTap: () => _openMenu(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: line),
            bottom: BorderSide(color: line),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                picked == null ? _systemRowLabel : picked.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 22, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    // フィールド直下にメニューを開くためのアンカー位置を算出。
    final field = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        field.localToGlobal(field.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        field.localToGlobal(field.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final chosen = await showMenu<String>(
      context: context,
      position: position,
      color: surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: line),
        borderRadius: BorderRadius.circular(4),
      ),
      items: [
        // 先頭は「端末に従う」。解決先の言語名を添える。
        _menuItem(_systemValue, _systemRowLabel, selectedCode == null),
        for (final lang in languages)
          _menuItem(lang.code, lang.name, selectedCode == lang.code),
      ],
    );

    if (chosen != null) {
      onChanged(chosen == _systemValue ? null : chosen);
    }
  }

  PopupMenuItem<String> _menuItem(String value, String label, bool selected) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? textPrimary : textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: accent),
          ],
        ),
      );
}
