# coding: utf-8
"""Web の殻の単一の出所 — 各ゲームの web/ とビルド後処理を、共有の雛形から生成する。

各ゲームが自分で書くのは game.json(名前・説明・URL・ワードマーク・向き)だけ。
index.html(OG・起動画面・service worker の登録)、manifest.json、app_sw.js、
pwa_postbuild.sh、vercel_build.sh は twoyearsold_ui/web_shell/ から作る。殻を直すときは
ここを直して同期すれば全作へ行き渡る(作ごとに手で直すと、直し漏れた作だけ古いまま残る)。

使い方:
  python3 twoyearsold_ui/tool/sync_web_shell.py            # 全ゲームへ書き出す
  python3 twoyearsold_ui/tool/sync_web_shell.py Reversi    # 指定ゲームのみ
  python3 twoyearsold_ui/tool/sync_web_shell.py --check    # 生成物と一致するか検査(書かない)
"""
import html
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
SHELL = os.path.join(os.path.dirname(HERE), 'web_shell')

# アプリ既定テーマ(Editorial Dark)の地色。起動画面・タイトルバーをアプリの地と揃える。
BACKGROUND = '#0A0A0B'

# そのまま配る(作ごとの差なし)。
COPIED = {
    'app_sw.js': 'web/app_sw.js',
    'pwa_postbuild.sh': 'pwa_postbuild.sh',
    'vercel_build.sh': 'vercel_build.sh',
}


def games():
    out = []
    for name in sorted(os.listdir(ROOT)):
        if not name.startswith('.') and os.path.exists(os.path.join(ROOT, name, 'game.json')):
            out.append(name)
    return out


def _read(path):
    return open(path, encoding='utf-8').read()


def render(game):
    """{ゲーム内の相対パス: 中身} を返す。"""
    g = json.loads(_read(os.path.join(ROOT, game, 'game.json')))
    esc = lambda s: html.escape(s, quote=True)
    index = _read(os.path.join(SHELL, 'index.html.tmpl'))
    for key, value in {
        'title': esc(g['title']),
        'description': esc(g['description']),
        'url': esc(g['url'].rstrip('/')),
        # ワードマークはホームと同じ行割りで積む。
        'wordmark': '<br>'.join(esc(line) for line in g['wordmark']),
    }.items():
        index = index.replace('{{' + key + '}}', value)

    manifest = {
        'name': g['title'],
        'short_name': g['title'],
        'id': '/',
        'scope': '.',
        'lang': 'en',
        'categories': ['games'],
        'start_url': '.',
        'display': 'standalone',
        'display_override': ['standalone'],
        'background_color': BACKGROUND,
        'theme_color': BACKGROUND,
        'description': g['description'],
        'orientation': g.get('orientation', 'portrait-primary'),
        'prefer_related_applications': False,
    }
    if g.get('screenshots'):
        manifest['screenshots'] = g['screenshots']
    manifest['icons'] = [
        {'src': 'icons/Icon-192.png', 'sizes': '192x192', 'type': 'image/png'},
        {'src': 'icons/Icon-512.png', 'sizes': '512x512', 'type': 'image/png'},
        {'src': 'icons/Icon-maskable-192.png', 'sizes': '192x192', 'type': 'image/png',
         'purpose': 'maskable'},
        {'src': 'icons/Icon-maskable-512.png', 'sizes': '512x512', 'type': 'image/png',
         'purpose': 'maskable'},
    ]
    out = {
        'web/index.html': index,
        'web/manifest.json': json.dumps(manifest, indent=4, ensure_ascii=False) + '\n',
    }
    for src, dst in COPIED.items():
        out[dst] = _read(os.path.join(SHELL, src))
    return out


def stale(game):
    """生成物と食い違うファイル(相対パス)の一覧。空 = 同期済み。"""
    out = []
    for rel, want in render(game).items():
        path = os.path.join(ROOT, game, rel)
        if not os.path.exists(path) or _read(path) != want:
            out.append(rel)
    return out


def main():
    args = [a for a in sys.argv[1:] if a != '--check']
    targets = args or games()
    if '--check' in sys.argv[1:]:
        bad = False
        for game in targets:
            for rel in stale(game):
                bad = True
                print(f'✗ {game}: {rel} が共有の殻と食い違う → sync_web_shell.py {game}')
        if not bad:
            print(f'✓ Web の殻は同期済み({len(targets)} 作)')
        sys.exit(1 if bad else 0)
    for game in targets:
        for rel, want in render(game).items():
            with open(os.path.join(ROOT, game, rel), 'w', encoding='utf-8') as f:
                f.write(want)
        print(f'{game}: 同期')


if __name__ == '__main__':
    main()
