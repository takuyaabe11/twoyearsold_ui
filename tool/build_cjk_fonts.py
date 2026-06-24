#!/usr/bin/env python3
"""各ゲームの非ラテン系フォントを、実際に使う文字だけ正しい地域字形で生成する。

背景(なぜ必要か):
  共有していた NotoSansJP.ttf は極端なサブセット(漢字342字・Thin)で、UI で使う
  漢字を取りこぼし、未収録字は CanvasKit の自動フォールバック(CJK 既定=簡体字
  Noto Sans SC)で描画されていた。結果として「日本語の漢字が簡体字字形で出る」
  化けが発生。さらに簡体/繁体/韓国語/アラビア/デーヴァナーガリー/タイには専用
  フォントが無く、繁体字も簡体字字形に化けていた(Han unification)。

方針:
  - ロケール単位で実際に使う文字を集める(ja と zh は同じ漢字コードポイントを
    共有するため、スクリプト一括ではなくロケール単位で振り分ける)。
  - 各ロケールを「正しい地域フォント」(JP/SC/TC/KR/Arabic/Devanagari/Thai)の
    Regular で、その文字だけサブセット生成する(数 KB)。
  - ラテン/キリルは Arimo が完全カバー済みのため対象外。

使い方:
  python3 tool/build_cjk_fonts.py            # 全ゲーム再生成
  python3 tool/build_cjk_fonts.py Reversi    # 指定ゲームのみ

文言を増やしたら本ツールを再実行する(= フォントは常に文言と同期)。— DESIGN.md §2.1。
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

from fontTools.ttLib import TTFont

# このスクリプトは twoyearsold_ui リポジトリ内にあるが、対象は monorepo ルート
# (twoyearsold/) 配下の各ゲーム。ROOT はファイル位置の3階層上(tool->twoyearsold_ui->root)。
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36")

# ロケール -> (Google Fonts ファミリ, Flutter アセットファミリ名)。
# ラテン/キリル(en de fr es it pt pt_BR ru id nl pl tr vi)は Arimo がカバー -> 対象外。
SCRIPT_FONTS = {
    'ja':      ('Noto Sans JP',          'NotoSansJP'),
    'zh':      ('Noto Sans SC',          'NotoSansSC'),
    'zh_Hant': ('Noto Sans TC',          'NotoSansTC'),
    'ko':      ('Noto Sans KR',          'NotoSansKR'),
    'ar':      ('Noto Sans Arabic',      'NotoSansArabic'),
    'hi':      ('Noto Sans Devanagari',  'NotoSansDevanagari'),
    'th':      ('Noto Sans Thai',        'NotoSansThai'),
    # 追加スクリプト(2026-06)。ペルシャ(fa)はアラビア文字 -> 既存 NotoSansArabic を
    # 共有(ar と文字集合を union する。build_game の by_family 参照)。ウルドゥーは Nastaliq。
    'fa':      ('Noto Sans Arabic',      'NotoSansArabic'),
    'ur':      ('Noto Nastaliq Urdu',    'NotoNastaliqUrdu'),
    'bn':      ('Noto Sans Bengali',     'NotoSansBengali'),
    'he':      ('Noto Sans Hebrew',      'NotoSansHebrew'),
    'ta':      ('Noto Sans Tamil',       'NotoSansTamil'),
    'te':      ('Noto Sans Telugu',      'NotoSansTelugu'),
}

# コード内リテラルで描画する記号(★☆ 等)は L10n 文字列に現れず corpus に入らないため、
# 放置すると盤面/統計の星が豆腐化する(Arimo に無く、地域フォントにフォールバックして初めて出る)。
# NotoSansJP は fallbackForLocale() で全ロケールのフォールバック列に常在するので、ここに同梱すれば
# 言語に依らず描画できる。— DESIGN.md §2.1 / AppTheme.fallbackForLocale。
SYMBOLS_ALWAYS = set('★☆')

# 各ゲームの文言ソース。dart=共通形式の _data マップ, arb=NumberPlace 形式。
SHARED_L10N = os.path.join(ROOT, 'twoyearsold_ui/lib/src/l10n.dart')
GAMES = {
    'Reversi':     {'dart': ['lib/l10n/rv_l10n.dart'], 'shared': True},
    '2048':        {'dart': ['lib/l10n/tf_l10n.dart'], 'shared': True},
    'Gobblet':     {'dart': ['lib/l10n/gb_l10n.dart'], 'shared': True},
    'AirHockey':   {'dart': ['lib/l10n/ah_l10n.dart'], 'shared': True},
    'Minesweeper': {'dart': ['lib/l10n/ms_l10n.dart'], 'shared': True},
    'NumberPlace': {'arb': 'lib/l10n', 'shared': False},
}


def _string_literals(blob):
    """Dart/JSON 文字列リテラルの中身を全て返す(' と " の両対応, \\' を考慮)。"""
    out = []
    for m in re.finditer(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"", blob):
        out.append(m.group(1) if m.group(1) is not None else m.group(2))
    return out


def collect_dart(path):
    """共通形式 `static const ... _data = { 'loc': { ... }, ... }` を
    {locale: set(chars)} で返す。波括弧をカウントして locale ブロックを切り出す。"""
    src = open(path, encoding='utf-8').read()
    res = {}
    for m in re.finditer(r"'([a-zA-Z_]+)'\s*:\s*\{", src):
        loc = m.group(1)
        if loc not in SCRIPT_FONTS:
            continue
        # 対応する閉じ波括弧まで(ネスト対応)
        i = m.end() - 1
        depth = 0
        while i < len(src):
            if src[i] == '{':
                depth += 1
            elif src[i] == '}':
                depth -= 1
                if depth == 0:
                    break
            i += 1
        block = src[m.end():i]
        chars = set()
        for v in _string_literals(block):
            chars |= set(v)
        res.setdefault(loc, set()).update(chars)
    return res


def collect_arb(arb_dir):
    """NumberPlace: app_<locale>.arb(JSON, 1ファイル1ロケール)を集約。"""
    res = {}
    for fn in os.listdir(arb_dir):
        m = re.fullmatch(r'app_([a-zA-Z_]+)\.arb', fn)
        if not m:
            continue
        loc = m.group(1)
        if loc not in SCRIPT_FONTS:
            continue
        data = json.load(open(os.path.join(arb_dir, fn), encoding='utf-8'))
        chars = set()
        for k, v in data.items():
            if k.startswith('@'):       # メタデータは除外
                continue
            if isinstance(v, str):
                chars |= set(v)
        res.setdefault(loc, set()).update(chars)
    return res


def merge(*maps):
    out = {}
    for mp in maps:
        for loc, cs in mp.items():
            out.setdefault(loc, set()).update(cs)
    return out


def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    return urllib.request.urlopen(req, timeout=40).read()


def build_subset(gf_family, chars):
    """Google Fonts text= API で必要文字だけの Regular サブセットを取得し ttf 化。"""
    # 非 ASCII のみ要求(ASCII は Arimo がカバー)。安定のためソートして決定的に。
    wanted = ''.join(sorted(c for c in chars if ord(c) > 0x7F and c not in '\n\r\t'))
    if not wanted:
        return None, 0
    fam = gf_family.replace(' ', '+')
    url = (f'https://fonts.googleapis.com/css2?family={fam}:wght@400'
           f'&text={urllib.parse.quote(wanted)}')
    css = fetch(url).decode()
    m = re.search(r"src:\s*url\((https://[^)]+)\)\s*format\('woff2'\)", css)
    if not m:
        raise RuntimeError(f'woff2 URL not found for {gf_family}\n{css[:300]}')
    woff2 = fetch(m.group(1))
    tmp = f'/tmp/_subset_{gf_family.replace(" ", "")}.woff2'
    open(tmp, 'wb').write(woff2)
    f = TTFont(tmp)
    f.flavor = None  # woff2 -> 素の ttf
    return f, len(wanted)


def build_game(game, cfg):
    print(f'\n=== {game} ===')
    src_dir = os.path.join(ROOT, game)
    per_locale = {}
    if cfg.get('shared'):
        per_locale = merge(per_locale, collect_dart(SHARED_L10N))
    for rel in cfg.get('dart', []):
        per_locale = merge(per_locale, collect_dart(os.path.join(src_dir, rel)))
    if 'arb' in cfg:
        per_locale = merge(per_locale, collect_arb(os.path.join(src_dir, cfg['arb'])))

    # コードリテラル記号(★☆)を NotoSansJP(全ロケールの fallback に常在)へ同梱。
    per_locale.setdefault('ja', set()).update(SYMBOLS_ALWAYS)

    fonts_dir = os.path.join(src_dir, 'assets/fonts')
    os.makedirs(fonts_dir, exist_ok=True)
    # 同じ出力ファミリ(asset_family)に複数ロケールが割り当たる場合(例: ar と fa は
    # どちらも NotoSansArabic)、文字集合を union してから1ファイルに焼く。
    by_family = {}
    for loc, (gf_family, asset_family) in SCRIPT_FONTS.items():
        chars = per_locale.get(loc, set())
        if not chars:
            continue
        entry = by_family.setdefault(asset_family, [gf_family, set()])
        entry[1] |= chars
    built = []
    for asset_family, (gf_family, chars) in by_family.items():
        f, n = build_subset(gf_family, chars)
        if f is None:
            print(f'  {asset_family:18} -> (no chars, skip)')
            continue
        out = os.path.join(fonts_dir, f'{asset_family}.ttf')
        f.save(out)
        size = os.path.getsize(out)
        # 収録確認
        cov = set()
        for t in f['cmap'].tables:
            cov |= set(t.cmap.keys())
        miss = [c for c in chars if ord(c) > 0x7F and ord(c) not in cov]
        flag = '' if not miss else f'  !! MISSING {miss}'
        print(f'  {asset_family:18} {n:4} chars  {size:6}B{flag}')
        built.append(asset_family)
    return built


def main():
    targets = sys.argv[1:] or list(GAMES)
    for game in targets:
        build_game(game, GAMES[game])


if __name__ == '__main__':
    main()
