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
    ('web_meta', 'Web の体裁(OG)', web_meta),
    ('web_splash', 'Web の起動画面', web_splash),
    ('offline', 'オフライン', offline),
    ('web_shell', 'Web の殻が共有と一致', web_shell),
    ('readme', 'README', readme),
]


def failing(game):
    return [key for key, _, fn in CHECKS if not fn(game)]


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
    return len(opened) + len(closed)


def main():
    args = sys.argv[1:]
    if not args:
        print('usage: quality_guard.py <AppName>|all | --table | --tighten')
        sys.exit(2)
    if args[0] == '--table':
        print(table())
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
