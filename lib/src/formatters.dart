/// 全作共通の表示フォーマッタ。各作で `mm:ss` や勝率% を手書き(=ドリフト)しない。

/// 秒数を `mm:ss` に。各作の統計/ゲーム中タイマー表示の単一の出所。
String formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// 勝率等(0.0–1.0)を整数% に。[noData] は分母0などデータ無しのときの表示(既定 '—')。
String formatPercent(double? ratio, {String noData = '—'}) {
  if (ratio == null) return noData;
  return '${(ratio * 100).round()}%';
}

/// 保存日時を `M/D HH:MM` に(「つづきから」の補足表示)。
String formatSavedAt(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.month}/${at.day} ${two(at.hour)}:${two(at.minute)}';
}
