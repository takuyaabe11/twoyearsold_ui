# coding: utf-8
"""i18n ガード — TWOYEARSOLD の各アプリが満たすべき「作成時の必要条件」を検査する。
ビルド前(vercel_build.sh)やコミット前に実行し、違反があれば exit 1 で止める。

3つの検査(いずれも違反でビルドを止める):
  1. 完全性   : 全 supported ロケールが存在し、全キーが非空(英語フォールバック禁止)。
  2. フォント : corpus(全ロケール文字 + 登録した画面内マップ) ⊆ 同梱フォント cmap。豆腐防止。
  3. 直書き   : ユーザー可視のリテラルが L10n を経由していない疑い。`// i18n-ok` で明示免除。

使い方: python3 twoyearsold_ui/tool/i18n_guard.py <AppName>
  例:   python3 twoyearsold_ui/tool/i18n_guard.py Reversi
"""
import os, re, sys, importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/

# build_cjk_fonts の設定・収集ロジックを再利用(corpus とフォント対応の単一の出所)。
_spec = importlib.util.spec_from_file_location('bf', os.path.join(HERE, 'build_cjk_fonts.py'))
bf = importlib.util.module_from_spec(_spec)
try:
    _spec.loader.exec_module(bf)
except SystemExit:
    pass
from fontTools.ttLib import TTFont

SHARED_L10N = bf.SHARED_L10N
GAMES = bf.GAMES
SCRIPT_FONTS = bf.SCRIPT_FONTS

def supported_locales():
    s = open(SHARED_L10N, encoding='utf-8').read()
    return re.findall(r"code:\s*'([^']+)'", s)

# ---- 値の抽出(Dart locale ブロック / ARB) ----
def _read_dq(s, i):
    i += 1; buf = []
    while i < len(s):
        c = s[i]
        if c == '\\':
            nx = s[i+1] if i+1 < len(s) else ''
            buf.append({'n':'\n','t':'\t','\\':'\\',"'":"'",'$':'$','"':'"'}.get(nx, nx)); i += 2; continue
        if c == "'":
            return ''.join(buf), i+1
        buf.append(c); i += 1
    return ''.join(buf), i

def _block_pairs(src, loc):
    for m in re.finditer(r"'" + re.escape(loc) + r"'\s*:\s*\{", src):
        i = m.end() - 1; depth = 0
        while i < len(src):
            if src[i] == '{': depth += 1
            elif src[i] == '}':
                depth -= 1
                if depth == 0: break
            i += 1
        body = src[m.end():i]
        out = {}; j = 0; n = len(body)
        while j < n:
            if body[j] == "'":
                k, e = _read_dq(body, j)
                t = e
                while t < n and body[t] in ' \t\n\r': t += 1
                if t < n and body[t] == ':':
                    t += 1
                    while t < n and body[t] in ' \t\n\r': t += 1
                    if t < n and body[t] == "'":
                        v, e2 = _read_dq(body, t); out[k] = v; j = e2; continue
                j = e; continue
            j += 1
        return out
    return None

def collect_app_locale_values(game, cfg):
    """{source: {locale: {key: val}}} を返す(完全性検査用)。"""
    import json
    res = {}
    srcs = [('shared', SHARED_L10N)]
    for rel in cfg.get('dart', []):
        srcs.append((rel, os.path.join(ROOT, game, rel)))
    for src_name, path in srcs:
        s = open(path, encoding='utf-8').read()
        res[src_name] = {}
        for loc in supported_locales():
            pairs = _block_pairs(s, loc)
            if pairs is not None:
                res[src_name][loc] = pairs
    if 'arb' in cfg:
        d = os.path.join(ROOT, game, cfg['arb'])
        res['arb'] = {}
        for loc in supported_locales():
            p = os.path.join(d, f'app_{loc}.arb')
            if os.path.exists(p):
                data = json.load(open(p, encoding='utf-8'))
                res['arb'][loc] = {k: v for k, v in data.items() if not k.startswith('@') and isinstance(v, str)}
    return res

# ---- 検査1: 完全性 ----
def check_completeness(game, cfg):
    fails = []
    locs = supported_locales()
    data = collect_app_locale_values(game, cfg)
    for src, perloc in data.items():
        en = perloc.get('en')
        if en is None:
            continue
        enk = set(en)
        for loc in locs:
            d = perloc.get(loc)
            if d is None:
                fails.append(f'[{src}] ロケール {loc} のブロック/ファイルが無い')
                continue
            miss = enk - set(d)
            if miss:
                fails.append(f'[{src}] {loc}: キー欠落 {sorted(miss)[:5]}{"…" if len(miss)>5 else ""} ({len(miss)}件)')
            empt = [k for k in enk if k in d and not str(d[k]).strip()]
            if empt:
                fails.append(f'[{src}] {loc}: 空値 {empt[:5]}{"…" if len(empt)>5 else ""} ({len(empt)}件)')
    return fails

# ---- 検査2: フォント被覆 ----
def check_fonts(game, cfg):
    fails = []
    per_locale = {}
    if cfg.get('shared'):
        per_locale = bf.merge(per_locale, bf.collect_dart(SHARED_L10N))
    for rel in cfg.get('dart', []):
        per_locale = bf.merge(per_locale, bf.collect_dart(os.path.join(ROOT, game, rel)))
    if 'arb' in cfg:
        per_locale = bf.merge(per_locale, bf.collect_arb(os.path.join(ROOT, game, cfg['arb'])))
    fonts_dir = os.path.join(ROOT, game, 'assets/fonts')
    by_family = {}
    for loc, (gf, asset) in SCRIPT_FONTS.items():
        ch = {c for c in per_locale.get(loc, set()) if ord(c) > 0x7F and c not in '\n\r\t'}
        by_family.setdefault(asset, set()).update(ch)
    for asset, chars in by_family.items():
        if not chars: continue
        fp = os.path.join(fonts_dir, asset + '.ttf')
        if not os.path.exists(fp):
            fails.append(f'フォント {asset}.ttf が無い({len(chars)}字必要) → build_cjk_fonts.py 実行')
            continue
        cm = set(TTFont(fp).getBestCmap().keys())
        miss = sorted(c for c in chars if ord(c) not in cm)
        if miss:
            fails.append(f'{asset}: 未収録 {"".join(miss[:20])} ({len(miss)}字) → build_cjk_fonts.py 実行')
    return fails

# ---- 検査3: 直書き(L10n非経由の疑い) ----
SCAN_PATTERNS = [
    r"Text\(\s*(['\"])(?P<v>(?:(?!\1).)+)\1",
    r"TextSpan\(\s*text:\s*(['\"])(?P<v>(?:(?!\1).)+)\1",
    r"(?:tooltip|semanticLabel|hintText|labelText|label)\s*:\s*(['\"])(?P<v>(?:(?!\1).)+)\1",
    r"(?:=>|return)\s*(['\"])(?P<v>[A-Z][^'\"]*)\1\s*;",
]
def _looks_uifacing(v):
    if not v.strip(): return False
    # 補間(${...} / $ident)を除去した「素のテキスト」で判定する。
    residual = re.sub(r'\$\{[^}]*\}', '', v)
    residual = re.sub(r'\$\w+', '', residual)
    words = re.findall(r'[A-Za-z]{2,}', residual)
    if not words: return False                          # 純補間/数値/記号(例 '$done / $total')
    if re.search(r'[()=;]', residual): return False     # toString/デバッグ様(例 'Cage(sum=$sum)')
    # CamelCase の単一識別子(空白なし・小文字→大文字遷移)は識別子/クラス名扱い
    rs = residual.strip()
    if ' ' not in rs and re.fullmatch(r'[A-Za-z]+', rs) and re.search(r'[a-z][A-Z]', rs):
        return False
    return True

def check_hardcoded(game):
    fails = []
    libdir = os.path.join(ROOT, game, 'lib')
    for dp, _, files in os.walk(libdir):
        if '/l10n' in dp.replace('\\','/'): continue
        for fn in files:
            if not fn.endswith('.dart') or fn.endswith('.g.dart') or 'app_localizations' in fn:
                continue
            path = os.path.join(dp, fn)
            lines = open(path, encoding='utf-8').read().splitlines()
            for ln, line in enumerate(lines, 1):
                if 'i18n-ok' in line:        # 明示免除
                    continue
                for pat in SCAN_PATTERNS:
                    for m in re.finditer(pat, line):
                        v = m.group('v')
                        if _looks_uifacing(v):
                            rel = os.path.relpath(path, os.path.join(ROOT, game))
                            fails.append(f'{rel}:{ln}  直書き疑い {v!r}  (L10n化 or `// i18n-ok`)')
    return fails

def run_one(game):
    cfg = GAMES[game]
    print(f'=== i18n guard: {game} ===')
    c = check_completeness(game, cfg)
    f = check_fonts(game, cfg)
    h = check_hardcoded(game)
    for title, items in [('完全性', c), ('フォント被覆', f), ('直書き(L10n非経由)', h)]:
        if items:
            print(f'\n✗ {title}: {len(items)} 件')
            for it in items[:50]:
                print(f'   {it}')
        else:
            print(f'✓ {title}: OK')
    total = len(c) + len(f) + len(h)
    if total:
        print(f'\nFAILED: {total} 件の違反。修正するか(直書きは `// i18n-ok` で免除)。')
    else:
        print('\nPASSED: i18n 要件をすべて満たしています。')
    return total

def main():
    if len(sys.argv) < 2:
        print('usage: i18n_guard.py <AppName>|all'); sys.exit(2)
    arg = sys.argv[1]
    games = list(GAMES) if arg == 'all' else [arg]
    for g in games:
        if g not in GAMES:
            print(f'unknown game {g}; known: {list(GAMES)}'); sys.exit(2)
    total = 0
    for g in games:
        total += run_one(g)
        if arg == 'all': print()
    sys.exit(1 if total else 0)

if __name__ == '__main__':
    main()
