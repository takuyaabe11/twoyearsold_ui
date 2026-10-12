# coding: utf-8
"""品質ガード — シリーズ横断の「穴」を機械で数え、これ以上広がらないようにする。

i18n_guard.py が文言を守るのと同じ形で、所作・アクセシビリティ・Web の殻などを守る。
検査はどれもソースを読むだけ(flutter を起動しない)なので push のたびに回せる。

穴は一度に全部は塞げないので「ラチェット」にしている:
  - quality_baseline.json に、いま開いている穴(作 × 検査)を書いておく。
  - そこに無い穴が新しく開いたら失敗(後戻りを止める)。
  - 穴を塞いだら baseline から消すまで失敗(塞いだ状態を固定する)。
  - baseline に載っていない作(= 新作)は、全検査を最初から満たす必要がある。

使い方:
  python3 twoyearsold_ui/tool/quality_guard.py <AppName>|all   # ガード(違反で exit 1)
  python3 twoyearsold_ui/tool/quality_guard.py --table         # 横並びのスペック表(Markdown)
  python3 twoyearsold_ui/tool/quality_guard.py --tighten       # 塞いだ穴を baseline から消す
  python3 twoyearsold_ui/tool/quality_guard.py --list <AppName> [検査名]   # 規範違反の一覧
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sync_web_shell as sws  # noqa: E402  Web の殻の生成ロジック(一致検査に使う)
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
BASELINE = os.path.join(HERE, 'quality_baseline.json')


def games():
    """ゲーム = monorepo 直下で lib/main.dart と web/ を持つディレクトリ(共有パッケージは除く)。"""
    out = []
    for name in sorted(os.listdir(ROOT)):
        d = os.path.join(ROOT, name)
        # 隠しディレクトリ(作業用の写しなど)と共有パッケージはゲームではない。
        if name.startswith('.') or name == 'twoyearsold_ui' or not os.path.isdir(d):
            continue
        if os.path.exists(os.path.join(d, 'lib/main.dart')) and os.path.isdir(os.path.join(d, 'web')):
            out.append(name)
    return out


def _read(path):
    try:
        return open(path, encoding='utf-8').read()
    except (OSError, UnicodeDecodeError):
        return ''


def _dart(game, sub):
    """(相対パス, 中身) を返す。生成物(l10n の自動生成)は数えない。"""
    base = os.path.join(ROOT, game, sub)
    for dp, _, fns in os.walk(base):
        for fn in fns:
            if not fn.endswith('.dart') or fn.endswith('.g.dart'):
                continue
            if re.fullmatch(r'app_localizations(_\w+)?\.dart', fn):
                continue
            path = os.path.join(dp, fn)
            yield os.path.relpath(path, os.path.join(ROOT, game)), _read(path)


def _lib_has(game, pattern):
    rx = re.compile(pattern)
    return any(rx.search(src) for _, src in _dart(game, 'lib'))


# ---- 検査。True = 満たしている。名前は baseline のキーになるので変えない。 ----

def semantics(game):
    """読み上げ: 画面に Semantics がある(盤が CustomPaint だけだと何も読まれない)。"""
    return _lib_has(game, r'\bSemantics\(|SemanticsService\.')


def motion(game):
    """演出 off: 設定と OS の両方を見る共有 motionEnabled を参照している。"""
    return _lib_has(game, r'\bmotionEnabled\b')


def text_scale(game):
    """文字拡大: 倍率の上限がある(共有の TwoyearsoldApp が全画面に掛ける。独自の App は自前で)
    うえで、文字拡大時の画面をゴールデンで固定している。"""
    clamped = _lib_has(game, r'\bTwoyearsoldApp\(|withClampedTextScaling|textScalerOf')
    rx = re.compile(r'textScale:')
    return clamped and any(rx.search(src) for _, src in _dart(game, 'test'))


def keyboard(game):
    """キーボード: Web / デスクトップ向けのキー操作がある(共有の GameKeys か、自前の処理)。"""
    return _lib_has(game, r'\bGameKeys\(|onKeyEvent|CallbackShortcuts|\bShortcuts\(|KeyboardListener')


def shared_sound(game):
    """音: プレイヤーの扱いは共有(SoundService / SoundBank)に任せ、audioplayers を直接使わない
    (各作で書き直すと Web の自動再生対策 unlock() が抜ける)。語彙は各作に置いてよい。"""
    return not _lib_has(game, r"package:audioplayers/")


def shared_game_over(game):
    """終了画面: 共有 GameOverOverlay を使う。"""
    return _lib_has(game, r'\bGameOverOverlay\(')


def golden(game):
    """見た目の固定: ゴールデンテストがある。"""
    rx = re.compile(r'matchesGoldenFile|\bexpectGolden\(')  # 後者は共有ハーネス
    return any(rx.search(src) for _, src in _dart(game, 'test'))


def tap_targets(game):
    """タップ領域: 操作要素の当たり判定が 44px 以上であることをテストで測っている(§9)。
    共有ハーネスの expectTapTargets(ホーム・プレイ・終了)と expectTapTargetsOneLevelDeep
    (ホームから 1 操作で開く画面の巡回)。"""
    src = '\n'.join(t for _, t in _dart(game, 'test'))
    return 'expectTapTargets(' in src and 'expectTapTargetsOneLevelDeep(' in src


def web_meta(game):
    """Web の体裁: リンク展開(OG)と theme-color がある。"""
    html = _read(os.path.join(ROOT, game, 'web/index.html'))
    return 'og:title' in html and 'theme-color' in html


def web_splash(game):
    """Web の起動画面: 最初のフレームまでの白フラッシュを防ぐ。"""
    return 'flutter-first-frame' in _read(os.path.join(ROOT, game, 'web/index.html')) and \
        'id="loading"' in _read(os.path.join(ROOT, game, 'web/index.html'))


def offline(game):
    """オフライン: 自前 service worker と先取り一覧の後処理がある。"""
    d = os.path.join(ROOT, game)
    return (os.path.exists(os.path.join(d, 'web/app_sw.js'))
            and os.path.exists(os.path.join(d, 'pwa_postbuild.sh'))
            and 'app_sw.js' in _read(os.path.join(d, 'web/index.html'))
            and 'pwa_postbuild.sh' in _read(os.path.join(d, 'vercel_build.sh')))


def web_shell(game):
    """Web の殻: game.json を持ち、共有の雛形(web_shell/)から生成した内容と一致する。"""
    return game in sws.games() and not sws.stale(game)


def readme(game):
    """README: Flutter の雛形のままでない。"""
    return 'starting point for a Flutter application' not in _read(
        os.path.join(ROOT, game, 'README.md'))


CHECKS = [
    ('semantics', '読み上げ(Semantics)', semantics),
    ('motion', '演出 off', motion),
    ('text_scale', '文字拡大', text_scale),
    ('keyboard', 'キーボード', keyboard),
    ('shared_sound', '共有の音の基盤', shared_sound),
    ('shared_game_over', '共有の終了画面', shared_game_over),
    ('golden', 'ゴールデン', golden),
    ('tap_targets', 'タップ領域の計測', tap_targets),
    ('web_meta', 'Web の体裁(OG)', web_meta),
    ('web_splash', 'Web の起動画面', web_splash),
    ('offline', 'オフライン', offline),
    ('web_shell', 'Web の殻が共有と一致', web_shell),
    ('readme', 'README', readme),
]


def failing(game):
    return [key for key, _, fn in CHECKS if not fn(game)]


# ---- 規範違反の件数(増えたら止める) ----
#
# DESIGN.md の掟のうち、ソースから機械的に数えられるもの。上の「ある / ない」の検査と違い、
# 違反は作によって何十件もあり、一度には直せない。そこで件数を quality_counts.json に記録し、
#   - 件数が増えたら失敗(新しい違反を入れさせない)
#   - 減ったら --tighten で記録を下げるまで失敗(直した分を固定する)
# とする。規範が認める例外(§10.5 の立体表現など)は、その行に理由つきの印を書いて数えない:
#   canvas.drawShadow(...); // design-ok: 高さを伝える機能的な影(§10.5)
# 印は「// design-ok: 」の後に理由が必須。理由のない印は数える。

COUNTS = os.path.join(HERE, 'quality_counts.json')
_OK = re.compile(r'//\s*design-ok:\s*\S')


def _violations(game, pattern, skip_file=None):
    """lib/ で [pattern] に当たる行(コメント行と design-ok の行を除く)を "path:行: 内容" で返す。"""
    rx = re.compile(pattern)
    out = []
    for rel, src in _dart(game, 'lib'):
        if skip_file and skip_file(rel):
            continue
        for n, line in enumerate(src.splitlines(), 1):
            code = line.strip()
            if not code or code.startswith('//'):
                continue
            # 行末コメントの中身は検査しない(コードの部分だけ見る)。
            head = re.split(r'\s//', line, maxsplit=1)[0]
            if rx.search(head) and not _OK.search(line):
                out.append(f'{rel}:{n}: {code[:90]}')
    return out


def rounded(game):
    """角丸(§4「角丸は使わない」)。チップ・カード・ピル型を作らない。"""
    return _violations(
        game, r'BorderRadius\.(?!zero)|Radius\.(circular|elliptical)\(|StadiumBorder\(|\bRRect\.')


def shadows(game):
    """影・elevation(§1.4 / §4「影で階層を作らない」)。"""
    return _violations(
        game, r'BoxShadow\(|\belevation:\s*[1-9]|MaskFilter\.blur|drawShadow\(|\bShadow\(')


def raw_colors(game):
    """色の直書き(§1「色は役割トークン経由」)。テーマ定義ファイルは対象外。"""
    return _violations(
        game,
        # 数値リテラルで書いた色だけを数える(既存の色を計算で濃淡させる補助は対象外)。
        r'Color\(0x[0-9A-Fa-f]{6,8}\)|Color\.from(ARGB|RGBO)\(\s*(0x|\d)|\bColors\.(?!transparent\b)\w+',
        skip_file=lambda rel: re.search(r'(^|/)(\w*theme\w*|stones|palette)\.dart$', rel) is not None)


def canvas_fonts(game):
    """Canvas へ直接描く文字の書体指定漏れ(§2.1)。TextPainter に渡す TextStyle はテーマの書体を
    継がないので、fontFamily が無いと端末既定(Web では CDN の Roboto)で描かれる。"""
    out = []
    for rel, src in _dart(game, 'lib'):
        if 'TextPainter(' not in src:
            continue
        for m in re.finditer(r'TextStyle\(', src):
            i = m.end()
            depth, j = 1, i
            while depth and j < len(src):
                depth += src[j] == '('
                depth -= src[j] == ')'
                j += 1
            if re.search(r'\bfontFamily\s*:', src[i:j]):
                continue
            # Text ウィジェットの TextStyle は DefaultTextStyle から書体を継ぐので対象外。
            # TextSpan / TextPainter の近くにあるものだけを見る。
            near = src[max(0, m.start() - 240):m.start()]
            if 'TextSpan(' not in near and 'TextPainter(' not in near:
                continue
            n = src.count('\n', 0, m.start()) + 1
            line = src.splitlines()[n - 1]
            if not _OK.search(line):
                out.append(f'{rel}:{n}: {line.strip()[:90]}')
    return out


COUNTED = [
    ('rounded', '角丸', rounded),
    ('shadows', '影', shadows),
    ('raw_colors', '色の直書き', raw_colors),
    ('canvas_fonts', 'Canvas 文字の書体漏れ', canvas_fonts),
]


def load_counts():
    if not os.path.exists(COUNTS):
        return {}
    return json.load(open(COUNTS, encoding='utf-8'))


def save_counts(c):
    with open(COUNTS, 'w', encoding='utf-8') as f:
        json.dump({g: c[g] for g in sorted(c)}, f, ensure_ascii=False, indent=2)
        f.write('\n')


# ---- 規模の指標(表にだけ出す。合否は付けない) ----

def _count_lines(game, sub):
    return sum(src.count('\n') for rel, src in _dart(game, sub) if '/l10n/' not in rel)


def _count_tests(game):
    rx = re.compile(r'^\s*(?:test|testWidgets)\(', re.M)
    return sum(len(rx.findall(src)) for _, src in _dart(game, 'test'))


def table():
    gs = games()
    rows = [('lib 行数', [f'{_count_lines(g, "lib"):,}' for g in gs]),
            ('テスト数', [str(_count_tests(g)) for g in gs])]
    for key, label, fn in CHECKS:
        rows.append((label, ['○' if fn(g) else '×' for g in gs]))
    rows.append(('開いている穴', [str(len(failing(g))) for g in gs]))
    for key, label, fn in COUNTED:
        rows.append((f'{label}(件)', [str(len(fn(g))) for g in gs]))
    out = ['| | ' + ' | '.join(gs) + ' |', '|---|' + '---|' * len(gs)]
    out += [f'| {label} | ' + ' | '.join(cells) + ' |' for label, cells in rows]
    return '\n'.join(out)


# ---- ガード ----

def load_baseline():
    if not os.path.exists(BASELINE):
        return {}
    return json.load(open(BASELINE, encoding='utf-8'))


def save_baseline(b):
    with open(BASELINE, 'w', encoding='utf-8') as f:
        json.dump({g: b[g] for g in sorted(b) if b[g]}, f, ensure_ascii=False, indent=2)
        f.write('\n')


def run_one(game, baseline):
    labels = {key: label for key, label, _ in CHECKS}
    docs = {key: fn.__doc__ for key, _, fn in CHECKS}
    now = set(failing(game))
    known = set(baseline.get(game, []))
    opened = sorted(now - known)
    closed = sorted(known - now)
    print(f'=== quality guard: {game} ===')
    for key in opened:
        print(f'✗ 新しい穴: {labels[key]} — {docs[key]}')
    for key in closed:
        print(f'✗ 塞いだ穴が baseline に残っている: {labels[key]}'
              f' → quality_guard.py --tighten で固定する')
    if not opened and not closed:
        debt = f'(既知の穴 {len(known)} 件: {", ".join(labels[k] for k in sorted(known))})' if known else ''
        print(f'✓ 後戻りなし {debt}')
    # 規範違反の件数。記録が無い作(新作)は 0 件が基準。
    bad = 0
    recorded = load_counts().get(game, {})
    for key, label, fn in COUNTED:
        found = fn(game)
        limit = recorded.get(key, 0)
        if len(found) > limit:
            bad += 1
            print(f'✗ {label}が増えた: {limit} → {len(found)} 件 — {fn.__doc__.splitlines()[0]}')
            print(f'   一覧: quality_guard.py --list {game} {key}'
                  f' / 規範が認める例外なら行末に「// design-ok: 理由」')
        elif len(found) < limit:
            bad += 1
            print(f'✗ {label}が減った({limit} → {len(found)} 件)。'
                  f'quality_guard.py --tighten で記録を下げて固定する')
    if not bad:
        left = ', '.join(f'{label} {recorded.get(key, 0)}'
                         for key, label, _ in COUNTED if recorded.get(key, 0))
        print(f'✓ 規範違反は増えていない' + (f'(残り: {left})' if left else ''))
    return len(opened) + len(closed) + bad


def main():
    args = sys.argv[1:]
    if not args:
        print('usage: quality_guard.py <AppName>|all | --table | --tighten')
        sys.exit(2)
    if args[0] == '--table':
        print(table())
        return
    if args[0] == '--list':
        # 規範違反の一覧: --list <AppName> [検査名]
        for key, label, fn in COUNTED:
            if len(args) > 2 and args[2] != key:
                continue
            found = fn(args[1])
            print(f'## {label}({key}): {len(found)} 件')
            for v in found:
                print(f'  {v}')
        return
    baseline = load_baseline()
    if args[0] == '--tighten':
        # 塞いだ穴を消すだけ。新しい穴を baseline へ足すことはしない(緩める方向には動かさない)。
        for g in games():
            now = set(failing(g))
            kept = [k for k in baseline.get(g, []) if k in now]
            for k in sorted(set(baseline.get(g, [])) - now):
                print(f'{g}: {k} を baseline から削除(塞がった)')
            baseline[g] = kept
        save_baseline(baseline)
        # 規範違反の件数は、下がった分だけ記録を下げる(上げない)。
        counts = load_counts()
        for g in games():
            rec = counts.setdefault(g, {})
            for key, label, fn in COUNTED:
                n = len(fn(g))
                if n < rec.get(key, 0):
                    print(f'{g}: {label} {rec[key]} → {n} 件')
                    rec[key] = n
            counts[g] = {k: v for k, v in rec.items() if v}
        save_counts(counts)
        return
    targets = games() if args[0] == 'all' else [args[0]]
    for g in targets:
        if g not in games():
            print(f'unknown game {g}; known: {games()}')
            sys.exit(2)
    total = sum(run_one(g, baseline) for g in targets)
    if total:
        print(f'\nFAILED: {total} 件。穴は塞ぐ(baseline へ足して通すことはしない)。')
    sys.exit(1 if total else 0)


if __name__ == '__main__':
    main()
