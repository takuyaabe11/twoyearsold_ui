# 物差し(NumberPlace で縦に通す) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 品質の第 1 層の入口と第 3 層(市場との比較)の物差しを作り、NumberPlace を測って、オーナーに網羅の線を引いてもらい、欠けを台帳に積む。

**Architecture:** 共有の道具を `twoyearsold_ui/tool/` に置く。入口 `gate.py`、権利の語の検査 `rights_guard.py`(辞書 `rights_terms.json`)、第 3 層の記録の形の検査 `market_check.py`、まとめ `market_report.py`、性能の道具 `perf/`(`common.py`・`start_time.py`・`frames.py`・`new_game.py`)。記録そのものは NumberPlace の `quality/market/` に置く。担当が作るコードの Task と、統括が見張りのある作業として行う Task(測定・調査・オーナーの番)が並ぶ。仕様 10 節に従い、未検証の前提を確かめる Task を、それに頼るコードの Task より前に置く。

**Tech Stack:** Python 3.9(`/usr/bin/python3`、標準ライブラリだけ)、unittest、外部の命令 `flutter`・`adb`・`ffmpeg`/`ffprobe`(9.0、`/opt/homebrew/bin`)・`sips`、Android エミュレータ(android-35)。

**Spec:** `twoyearsold_ui/docs/superpowers/specs/2026-10-14-numberplace-yardstick-design.md`

## 計画の前に確かめたこと(2026-10-14、既存の AVD `np` で)

性能の道具の作りは、次の実測に合わせてある。Task 5 と Task 12 で、測定用のエミュレータでも確かめ直す。

1. 画面の録画(`screenrecord`)は、画面が変わったときだけコマを出す。止まっている間は 1〜2 秒コマが無い。→ 「コマが無い間は変わっていない」とみなし、録画が続いた長さは「押してから止めるまでの秒数」で知る(`frames.detect` の `observe_s`)。
2. adb から送った押下(`input tap`)では、端末の「タップを表示」(`show_touches`)の丸が描かれない。→ 押した瞬間の印には使えない。
3. 端末の「ポインタの位置」(`pointer_location`)は、adb から送った押下でも、画面の上端の帯をシステムが書き換える。帯を 160×8 の灰色に縮めた、1 画素あたりの平均の差は、押した瞬間で 12〜15、時計の分の変化で 0.2。→ しきい値を 4 にする。ただし、前に押した跡が残っていると、次の押下で帯の形が変わらない。そこで、最後の押下の直前に点け直して、帯を「P: 0 / 0」に戻す。帯はシステムが描くので、アプリが固まっていても押した瞬間に変わる。
4. `monkey` では設定アプリが起動しなかった。→ 起動は、`cmd package resolve-activity` で引いた画面を `am start -W -n` で開く(起動の速さの測り方と同じ)。
5. 下書きの道具で、設定アプリの画面の切り替わりを 3 回測れた(684 / 695 / 834ms)。確かめ用の画像を目で見て、押した瞬間のコマと落ち着いたコマが正しいことを確かめた。起動の速さは 11 回を 4.9 秒で測れた(中央値 367ms)。
6. この計画に載せたコードとテスト(58 件)は、下書きの場で Python 3.9.6 で走らせ、すべて通ることを確かめてから載せた。

## Global Constraints

- 道具は `twoyearsold_ui/tool/` に置き、Python 3.9(`/usr/bin/python3`)の標準ライブラリだけで書く。外部の命令は `flutter`・`adb`・`ffmpeg`・`ffprobe`・`sips` だけ。
- テストは `twoyearsold_ui/tool/tests/` に置き、`cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v` で走らせる。
- コメントと文面は日本語、識別子は英語。先頭の docstring に使い方を書く(今の `quality_guard.py` と同じ)。
- 入口の結果の `status` は `pass` / `fail` / `unmeasured`。測定値の `status` は `ok` / `unmeasured`。黙って合格にしない。道具が見つからないときは `fail`。
- 権利の語の検査は、利用者に見える所だけ(`lib/l10n/*.arb`、`store/` の下の文字のファイル、`web/*.html`、`web/manifest.json`、`game.json`)。コードの中の名前は対象外。
- 第 3 層の記録は NumberPlace の `quality/market/`(`competitors.json`・`features.json`・`perf.json`・`README.md`・`evidence/`・`scripts/`)。根拠の画面の写しは縮小して保存し、非公開のリポジトリの外に出さない。
- 起動の速さは 11 回測り、最初の 1 回を捨てた 10 回の中央値。出題の時間は 5 回の中央値(捨てる回は無い)。中央値は `round(statistics.median(runs))`。出題の条件は「Classic・9×9・中くらいの難しさ」。競合の広告による遅れも含める。
- 測定用のエミュレータは `yardstick_play_35`(イメージ `system-images;android-35;google_apis_playstore;arm64-v8a`、機種 `pixel_7`)。
- Claude はパスワードを入力しない。Google へのログインと競合のインストールはオーナーが行う。有料の競合は買わない。新しい規約への同意が求められたら、オーナーに伺う。
- 測定のために端末の設定(`pointer_location` など)を変えたら、終わったら元に戻す(もともと無ければ消す)。
- アプリのコードは、入口が見つけた不合格を直すときだけ変える。利用者に見える見た目や文言を変える直しは、オーナーに伺ってから。
- push: `twoyearsold_ui` と `twoyearsold-ops` は承認済み。NumberPlace の push は Web 版の公開(Vercel)を走らせるので、その都度オーナーに確かめる。
- 統括の Task の命令にある `$SCRATCH` は、そのセッションの scratchpad のディレクトリ。

## Review Focus

1. 全角や大文字の混じった語(`ＳＵＤＯＫＵ`、`Sudoku's`)や、ほかの文字で書いた語: 権利の語の検査が見つける。→ Task 1
2. `flutter` が無い、またはテストが時間内に終わらない: 入口はその検査を理由つきの `fail` にし、ほかの検査を続けて JSON も書く(偽の `flutter` を PATH に置いても確かめる)。→ Task 3
3. `features.json` で「ある」と書いたのに根拠が無い、根拠のファイルが無い、「note:」しか無い: 形の検査が不合格にする。→ Task 2
4. 録画に押した瞬間が映らない、盤が落ち着かない、少しずつ動き続ける、録画の終わりまでに落ち着かない: その測定は理由つきの未計測になり、全体は止まらない。→ Task 9、Task 10
5. エミュレータが動いていない: 起動の速さと出題の時間の道具は、端末に何もせず、すぐに理由つきの `unmeasured` を返す。→ Task 8、Task 10

---

### Task 1: 権利の語の検査

**Files:**
- Create: `twoyearsold_ui/tool/rights_terms.json`
- Create: `twoyearsold_ui/tool/rights_guard.py`
- Test: `twoyearsold_ui/tool/tests/test_rights_guard.py`

**Interfaces:**
- Produces:
  - `rights_guard.load_terms(path=TERMS) -> list[tuple[str, str]]`(語と、正規化した書き方の組)
  - `rights_guard.scan(app_dir: str, terms) -> list[str]`(`"相対パス:行  語(書き方)"` の並び。読めないファイルは `"相対パス  読めない(UTF-8 のテキストではない)"`)
  - `rights_guard.main(argv=None, root=ROOT, terms_path=TERMS) -> int`(0 / 1 / 2)

辞書の書き方は、Wikipedia の言語間リンク(2026-10-14 に取得)で、アプリの 37 言語(ar bn cs da de el en es fa fi fil fr he hi hu id it ja ko ms nb nl pl pt pt_BR ro ru sv ta te th tr uk ur vi zh zh_Hant)の項目名を引いて作った。カタカナの揺れも足してある。アラビア語の「عطيل」(戯曲のオセロ)は入れない。「تعطيل」(無効にする)の一部として、表示文言に普通に出てくるため。

- [ ] **Step 1: 失敗するテストを書く**

```python
import contextlib
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import rights_guard  # noqa: E402


class RightsGuardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        os.makedirs(self.app)
        self.terms_path = os.path.join(self.tmp, 'terms.json')
        with open(self.terms_path, 'w', encoding='utf-8') as f:
            json.dump({'terms': [{'term': 'Sudoku', 'reason': 'x', 'forms': ['sudoku', '数独', '스도쿠']}]}, f)
        self.terms = rights_guard.load_terms(self.terms_path)

    def write(self, rel, text):
        path = os.path.join(self.app, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)

    def test_finds_terms_in_user_visible_files_ignoring_width_and_case(self):
        self.write('lib/l10n/app_ja.arb', '{"appTitle": "ナンプレ",\n"x": "数独"}')
        self.write('store/play/listing/en-US/full.txt', "A quiet game.\nNot a ＳＵＤＯＫＵ clone. Sudoku's fans\n")
        self.write('web/index.html', '<title>스도쿠</title>')
        found = rights_guard.scan(self.app, self.terms)
        self.assertEqual(len(found), 3, found)
        self.assertTrue(any(f.startswith('lib/l10n/app_ja.arb:2') for f in found))
        self.assertTrue(any(f.startswith('store/play/listing/en-US/full.txt:2') for f in found))

    def test_code_identifiers_and_binary_files_are_not_scanned(self):
        self.write('lib/domain/sudoku_variant.dart', 'enum SudokuVariant { classic }\n')
        os.makedirs(os.path.join(self.app, 'store/play'), exist_ok=True)
        with open(os.path.join(self.app, 'store/play/icon.png'), 'wb') as f:
            f.write(b'\x89PNG sudoku')
        self.assertEqual(rights_guard.scan(self.app, self.terms), [])

    def test_one_report_per_term_per_line(self):
        self.write('store/a.txt', 'sudoku sudokus 数独\n')
        self.assertEqual(len(rights_guard.scan(self.app, self.terms)), 1)

    def test_files_directly_under_store_and_game_json_are_scanned(self):
        self.write('store/notes.md', 'sudoku\n')
        self.write('game.json', '{"name": "Sudoku"}\n')
        self.assertEqual(len(rights_guard.scan(self.app, self.terms)), 2)

    def test_main_exit_codes(self):
        self.write('store/a.txt', 'calm\n')
        with contextlib.redirect_stdout(io.StringIO()):
            self.check_exit_codes()

    def check_exit_codes(self):
        self.assertEqual(rights_guard.main(['Demo'], root=self.tmp, terms_path=self.terms_path), 0)
        self.write('store/b.txt', 'sudoku\n')
        self.assertEqual(rights_guard.main(['Demo'], root=self.tmp, terms_path=self.terms_path), 1)
        self.assertEqual(rights_guard.main(['Nope'], root=self.tmp, terms_path=self.terms_path), 2)
        self.assertEqual(rights_guard.main([], root=self.tmp, terms_path=self.terms_path), 2)

    def test_repository_terms_file_lists_the_four_terms_in_many_scripts(self):
        terms = rights_guard.load_terms()
        self.assertTrue({'Sudoku', 'Othello', 'Gobblet', 'Tetris'} <= {term for term, _ in terms})
        sudoku = {form for term, form in terms if term == 'Sudoku'}
        for form in ('sudoku', '数独', '數獨', '스도쿠', 'судоку', 'σουντόκου', 'سودوكو', 'סודוקו', 'सुडोकू', 'ซูโดกุ'):
            self.assertIn(form, sudoku)


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'rights_guard'`)

- [ ] **Step 3: 実装する**

`twoyearsold_ui/tool/rights_terms.json`:

```json
{
  "terms": [
    {"term": "Sudoku",
     "reason": "「数独」は日本で株式会社ニコリの登録商標。名前にも文面にも、全言語で使わない(オーナーの方針)",
     "forms": ["sudoku", "su doku", "su-doku", "szúdoku", "szudoku", "数独", "數獨", "スドク", "スードク", "スウドク",
               "스도쿠", "судоку", "σουντόκου", "σουντοκου", "سودوكو", "سودوکو", "سوڈوکو", "סודוקו",
               "सुडोकू", "सुडोकु", "सु डोकु", "সুডোকু", "சுடோகு", "சுடோக்கு", "సుడోకు", "ซูโดกุ"]},
    {"term": "Othello",
     "reason": "オセロ(Othello)は他社の登録商標。リバーシの作でも使わない(オーナーの方針)",
     "forms": ["othello", "otello", "otelo", "オセロ", "오셀로", "오델로", "отелло", "οθέλλο", "奥赛罗", "奧賽羅",
               "أوثيلو", "اتلو", "اوتھیلو", "אותלו", "ओथेलो", "ওথেলো", "ஒத்தெல்லோ", "ఒథెల్లో", "โอเทลโล"]},
    {"term": "Gobblet",
     "reason": "Gobblet は他社のゲームの名前(商標)。Cover Three の名前と文面に使わない(オーナーの方針)",
     "forms": ["gobblet", "гобблет", "ゴブレット", "고블렛"]},
    {"term": "Tetris",
     "reason": "Tetris は他社の登録商標",
     "forms": ["tetris", "テトリス", "테트리스", "тетрис", "тетріс", "τέτρις", "俄罗斯方块", "俄羅斯方塊", "تتريس", "تتریس",
               "טטריס", "टेट्रिस", "টেট্রিস", "டெட்ரிஸ்", "టెట్రిస్", "เตตริส", "ٹیٹرس"]}
  ]
}
```

`twoyearsold_ui/tool/rights_guard.py`:

```python
# coding: utf-8
"""権利の語の検査 — 利用者に見える文面に、使ってはいけない語(他社の商標など)が無いかを見る。

語の一覧と理由は rights_terms.json(各語の 37 言語での書き方を forms に持つ)。
調べるのは利用者に見える所だけ: 表示文言(lib/l10n/*.arb)、ストアの文面(store/ の下の文字のファイル)、
Web の文面(web/*.html、web/manifest.json)、game.json。コードの中の名前は利用者に見せないので対象外。
大文字小文字と全角半角を区別せず(NFKC で正規化して casefold)、語の一部として含まれる場合も見つける。

使い方:
  python3 twoyearsold_ui/tool/rights_guard.py <AppName>   # 見つかれば一覧を出して exit 1
"""
import glob
import json
import os
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
TERMS = os.path.join(HERE, 'rights_terms.json')

PATTERNS = ('lib/l10n/*.arb', 'store/**/*', 'web/*.html', 'web/manifest.json', 'game.json')
TEXT_SUFFIXES = ('.arb', '.txt', '.md', '.json', '.html', '.yaml', '.yml', '.csv', '.xml')


def norm(text):
    return unicodedata.normalize('NFKC', text).casefold()


def load_terms(path=TERMS):
    """[(語, 正規化した書き方)] を返す。"""
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    out = []
    for t in data['terms']:
        forms = {norm(t['term'])} | {norm(form) for form in t.get('forms', [])}
        for form in sorted(forms):
            out.append((t['term'], form))
    return out


def target_files(app_dir):
    seen = set()
    for pattern in PATTERNS:
        for path in glob.glob(os.path.join(app_dir, pattern), recursive=True):
            if os.path.isfile(path) and path.lower().endswith(TEXT_SUFFIXES):
                seen.add(path)
    return sorted(seen)


def scan(app_dir, terms):
    """見つかった所を「相対パス:行  語(書き方)」の並びで返す。1 行につき 1 つの語は 1 回だけ数える。"""
    found = []
    for path in target_files(app_dir):
        rel = os.path.relpath(path, app_dir)
        try:
            with open(path, encoding='utf-8') as f:
                text = f.read()
        except (OSError, UnicodeDecodeError):
            found.append(f'{rel}  読めない(UTF-8 のテキストではない)')
            continue
        for ln, line in enumerate(text.splitlines(), 1):
            low = norm(line)
            hit = set()
            for term, form in terms:
                if term not in hit and form in low:
                    hit.add(term)
                    found.append(f'{rel}:{ln}  {term}({form})')
    return found


def main(argv=None, root=ROOT, terms_path=TERMS):
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print('usage: rights_guard.py <AppName>')
        return 2
    app_dir = os.path.join(root, args[0])
    if not os.path.isdir(app_dir):
        print(f'アプリが見つかりません: {app_dir}')
        return 2
    found = scan(app_dir, load_terms(terms_path))
    print(f'=== rights guard: {args[0]} ===')
    for item in found:
        print(f'✗ {item}')
    if not found:
        print('✓ 使ってはいけない語は見つかりませんでした')
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(6 件)

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/rights_terms.json tool/rights_guard.py tool/tests/test_rights_guard.py
git commit -m "feat: 権利の語の検査(利用者に見える文面の他社の商標)"
```

---

### Task 2: 第 3 層の記録の形の検査

**Files:**
- Create: `twoyearsold_ui/tool/market_check.py`
- Test: `twoyearsold_ui/tool/tests/test_market_check.py`

**Interfaces:**
- Produces:
  - 定数 `market_check.MARKET`(`'quality/market'`)
  - `market_check.check_competitors(data) -> tuple[list[str], list[str]]`(競合の id の並び、問題の並び)
  - `market_check.check_features(data, ids: list[str], market_dir: str) -> list[str]`
  - `market_check.check_perf(data, ids: list[str]) -> list[str]`
  - `market_check.check_market(app_dir: str) -> tuple[str, list[str]]`(`'pass'` / `'fail'` / `'unmeasured'` と、理由の並び)
  - `market_check.main(argv=None, root=ROOT) -> int`(0 / 1 / 2)

升の根拠の決まり: `evidence/` の下のファイル(あること)か、`quote: ` で始まる掲載文などの引用。「無い」の升に限って、`note: ` で始まる確かめ方の記録も根拠にできる(無いものは写せないため)。

- [ ] **Step 1: 失敗するテストを書く**

```python
import contextlib
import copy
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import market_check  # noqa: E402

COMPETITORS = {
    'chosen_on': '2026-10-15',
    'criteria': '日米の上位',
    'apps': [
        {'id': 'c01', 'name': 'A', 'play': 'com.a', 'app_store': None, 'price_model': 'free_with_ads',
         'rating': 4.7, 'ratings_count': 1000, 'why': 'JP 1 位', 'on_android': True},
        {'id': 'c02', 'name': 'B', 'play': None, 'app_store': 'id1', 'price_model': 'paid',
         'rating': None, 'ratings_count': None, 'why': 'US 3 位', 'on_android': False},
    ],
}
FEATURES = {
    'features': [
        {'id': 'notes', 'name': 'メモ', 'kind': 'feature',
         'has': {'self': {'value': 'yes', 'evidence': 'evidence/self/notes.png'},
                 'c01': {'value': 'yes', 'evidence': 'quote: Notes mode'},
                 'c02': {'value': 'unknown', 'evidence': None}},
         'proposal': {'decision': 'cover', 'reason': '基本', 'exclude_category': None},
         'owner': {'decision': None, 'date': None, 'note': ''}},
    ],
}
PERF = {
    'device': {'avd': 'yardstick_play_35', 'image': 'android-35', 'host': 'M5'},
    'measured_on': '2026-10-15',
    'conditions': {'new_game': 'Classic・9×9・中くらいの難しさ'},
    'apps': {
        'self': {'cold_start_ms': {'runs': [400, 410, 420], 'median': 410, 'status': 'ok', 'reason': ''},
                 'new_game_ms': {'runs': [], 'median': None, 'status': 'unmeasured', 'reason': '台本が壊れた'}},
        'c01': {'cold_start_ms': {'runs': [500, 600], 'median': 550, 'status': 'ok', 'reason': ''},
                'new_game_ms': {'runs': [100], 'median': 100, 'status': 'ok', 'reason': ''}},
    },
}


class MarketCheckTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.market = os.path.join(self.app, 'quality', 'market')
        os.makedirs(os.path.join(self.market, 'evidence', 'self'))
        with open(os.path.join(self.market, 'evidence', 'self', 'notes.png'), 'wb') as f:
            f.write(b'png')

    def put(self, name, data):
        with open(os.path.join(self.market, name), 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False)

    def put_all(self, competitors=COMPETITORS, features=FEATURES, perf=PERF):
        self.put('competitors.json', competitors)
        self.put('features.json', features)
        self.put('perf.json', perf)

    def with_cell(self, value, evidence):
        features = copy.deepcopy(FEATURES)
        features['features'][0]['has']['self'] = {'value': value, 'evidence': evidence}
        return features

    def test_complete_valid_records_pass(self):
        self.put_all()
        self.assertEqual(market_check.check_market(self.app), ('pass', []))

    def test_missing_directory_is_unmeasured(self):
        shutil.rmtree(os.path.join(self.app, 'quality'))
        status, reasons = market_check.check_market(self.app)
        self.assertEqual(status, 'unmeasured')
        self.assertTrue(reasons)

    def test_partial_records_are_unmeasured(self):
        self.put('competitors.json', COMPETITORS)
        status, reasons = market_check.check_market(self.app)
        self.assertEqual(status, 'unmeasured')
        self.assertIn('features.json がまだ無い', reasons)

    def test_yes_without_evidence_or_with_missing_file_fails(self):  # Review Focus 3
        for evidence in (None, '', 'evidence/self/missing.png', 'see the store', 'note: 設定で見た'):
            self.put_all(features=self.with_cell('yes', evidence))
            status, _ = market_check.check_market(self.app)
            self.assertEqual(status, 'fail', evidence)

    def test_no_may_be_backed_by_a_note_of_how_it_was_checked(self):
        self.put_all(features=self.with_cell('no', 'note: 設定とメニューをすべて開いたが無い'))
        self.assertEqual(market_check.check_market(self.app)[0], 'pass')

    def test_exclude_needs_a_category_and_owner_decision_needs_a_date(self):
        features = copy.deepcopy(FEATURES)
        features['features'][0]['proposal'] = {'decision': 'exclude', 'reason': '広告', 'exclude_category': None}
        self.put_all(features=features)
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')
        features = copy.deepcopy(FEATURES)
        features['features'][0]['owner'] = {'decision': 'cover', 'date': None, 'note': ''}
        self.put_all(features=features)
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')

    def test_feature_rows_must_cover_every_competitor(self):
        features = copy.deepcopy(FEATURES)
        del features['features'][0]['has']['c02']
        self.put_all(features=features)
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')

    def test_perf_median_must_match_runs_and_ids_must_be_known(self):
        perf = copy.deepcopy(PERF)
        perf['apps']['self']['cold_start_ms']['median'] = 999
        self.put_all(perf=perf)
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')
        perf = copy.deepcopy(PERF)
        perf['apps']['c99'] = perf['apps']['c01']
        self.put_all(perf=perf)
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')

    def test_on_android_must_follow_play(self):
        competitors = copy.deepcopy(COMPETITORS)
        competitors['apps'][1]['on_android'] = True
        self.put_all(competitors=competitors)
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')

    def test_broken_json_fails(self):
        self.put_all()
        with open(os.path.join(self.market, 'perf.json'), 'w', encoding='utf-8') as f:
            f.write('{broken')
        self.assertEqual(market_check.check_market(self.app)[0], 'fail')

    def test_main_exit_codes(self):
        self.put_all()
        with contextlib.redirect_stdout(io.StringIO()):
            self.check_exit_codes()

    def check_exit_codes(self):
        self.assertEqual(market_check.main(['Demo'], root=self.tmp), 0)
        self.put('perf.json', {'apps': {}})
        self.assertEqual(market_check.main(['Demo'], root=self.tmp), 1)
        self.assertEqual(market_check.main(['Nope'], root=self.tmp), 2)


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'market_check'`)

- [ ] **Step 3: 実装する**

```python
# coding: utf-8
"""第 3 層(市場との比較)の記録の形の検査。

アプリの quality/market/ にある competitors.json・features.json・perf.json が、決めた形どおりかを見る。
記録がまだ無い(ディレクトリが無い、またはファイルが揃っていない)アプリは「未計測」。
升の根拠(evidence)は、evidence/ の下のファイル(あること)か、「quote: 」で始まる掲載文などの引用。
「無い」の升に限り、「note: 」で始まる確かめ方の記録も根拠にできる(無いものは写せないため)。

使い方:
  python3 twoyearsold_ui/tool/market_check.py <AppName>   # 形が違えば一覧を出して exit 1
"""
import json
import os
import re
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
MARKET = os.path.join('quality', 'market')

DATE = re.compile(r'^\d{4}-\d{2}-\d{2}$')
CID = re.compile(r'^c\d{2}$')
FID = re.compile(r'^[a-z0-9_]+$')
PRICE_MODELS = {'free', 'free_with_ads', 'freemium', 'paid', 'subscription'}
KINDS = {'feature', 'mode', 'variant', 'setting'}
VALUES = {'yes', 'no', 'unknown'}
PROPOSALS = {'cover', 'exclude', 'ask'}
CATEGORIES = {'ads', 'iap', 'online', 'trademark', 'philosophy'}
OWNER = {None, 'cover', 'exclude'}
METRICS = ('cold_start_ms', 'new_game_ms')


def _text(value):
    return isinstance(value, str) and value.strip() != ''


def _number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def check_competitors(data):
    """(競合の id の並び, 問題の並び) を返す。"""
    if not isinstance(data, dict):
        return [], ['competitors.json: 中身がオブジェクトではない']
    errors = []
    if not (isinstance(data.get('chosen_on'), str) and DATE.match(data['chosen_on'])):
        errors.append('competitors.json: chosen_on は YYYY-MM-DD')
    if not _text(data.get('criteria')):
        errors.append('competitors.json: criteria が空')
    apps = data.get('apps')
    if not isinstance(apps, list) or not apps:
        return [], errors + ['competitors.json: apps が空']
    ids = []
    for i, app in enumerate(apps):
        where = f'competitors.json: apps[{i}]'
        if not isinstance(app, dict):
            errors.append(f'{where}: オブジェクトではない')
            continue
        cid = app.get('id')
        if not (isinstance(cid, str) and CID.match(cid)):
            errors.append(f'{where}: id は c01 の形')
        elif cid in ids:
            errors.append(f'{where}: id {cid} が重複')
        else:
            ids.append(cid)
        if not _text(app.get('name')):
            errors.append(f'{where}: name が空')
        play, store = app.get('play'), app.get('app_store')
        for key, value in (('play', play), ('app_store', store)):
            if value is not None and not _text(value):
                errors.append(f'{where}: {key} は文字列か null')
        if play is None and store is None:
            errors.append(f'{where}: play か app_store のどちらかが要る')
        if app.get('price_model') not in PRICE_MODELS:
            errors.append(f'{where}: price_model は {"・".join(sorted(PRICE_MODELS))} のどれか')
        rating = app.get('rating')
        if rating is not None and not (_number(rating) and 0 <= rating <= 5):
            errors.append(f'{where}: rating は 0〜5 の数か null')
        count = app.get('ratings_count')
        if count is not None and not (isinstance(count, int) and not isinstance(count, bool) and count >= 0):
            errors.append(f'{where}: ratings_count は 0 以上の整数か null')
        if not _text(app.get('why')):
            errors.append(f'{where}: why が空')
        if app.get('on_android') is not (play is not None):
            errors.append(f'{where}: on_android は play があるときだけ true')
    return ids, errors


def _check_cell(where, col, cell, market_dir):
    if not isinstance(cell, dict):
        return [f'{where}: has.{col} が無い']
    value, evidence = cell.get('value'), cell.get('evidence')
    if value not in VALUES:
        return [f'{where}: has.{col}.value は yes・no・unknown のどれか']
    if value == 'unknown':
        return []
    if not _text(evidence):
        return [f'{where}: has.{col} は根拠(evidence)が要る']
    if evidence.startswith('evidence/'):
        if not os.path.isfile(os.path.join(market_dir, evidence)):
            return [f'{where}: has.{col} の根拠のファイルが無い({evidence})']
        return []
    if evidence.startswith('quote: ') or (value == 'no' and evidence.startswith('note: ')):
        return []
    return [f'{where}: has.{col} の根拠は evidence/ のファイルか「quote: 」の引用(「無い」なら「note: 」も可)']


def check_features(data, ids, market_dir):
    feats = data.get('features') if isinstance(data, dict) else None
    if not isinstance(feats, list) or not feats:
        return ['features.json: features が空']
    errors = []
    seen = set()
    cols = ['self'] + list(ids)
    for i, feat in enumerate(feats):
        where = f'features.json: features[{i}]'
        if not isinstance(feat, dict):
            errors.append(f'{where}: オブジェクトではない')
            continue
        fid = feat.get('id')
        if not (isinstance(fid, str) and FID.match(fid)):
            errors.append(f'{where}: id は英小文字・数字・_')
        elif fid in seen:
            errors.append(f'{where}: id {fid} が重複')
        else:
            seen.add(fid)
            where = f'features.json: {fid}'
        if not _text(feat.get('name')):
            errors.append(f'{where}: name が空')
        if feat.get('kind') not in KINDS:
            errors.append(f'{where}: kind は {"・".join(sorted(KINDS))} のどれか')
        has = feat.get('has')
        if not isinstance(has, dict):
            errors.append(f'{where}: has が無い')
        else:
            for col in cols:
                errors += _check_cell(where, col, has.get(col), market_dir)
            extra = sorted(set(has) - set(cols))
            if extra:
                errors.append(f'{where}: has に知らない列({", ".join(extra)})')
        proposal = feat.get('proposal')
        if not isinstance(proposal, dict) or proposal.get('decision') not in PROPOSALS:
            errors.append(f'{where}: proposal.decision は cover・exclude・ask のどれか')
        else:
            if not _text(proposal.get('reason')):
                errors.append(f'{where}: proposal.reason が空')
            category = proposal.get('exclude_category')
            if proposal['decision'] == 'exclude' and category not in CATEGORIES:
                errors.append(f'{where}: 外すときは exclude_category が要る({"・".join(sorted(CATEGORIES))})')
            if proposal['decision'] != 'exclude' and category is not None:
                errors.append(f'{where}: exclude_category は外すときだけ')
        owner = feat.get('owner')
        if not isinstance(owner, dict) or owner.get('decision') not in OWNER:
            errors.append(f'{where}: owner.decision は null・cover・exclude のどれか')
        else:
            date = owner.get('date')
            if owner['decision'] is None and date is not None:
                errors.append(f'{where}: owner.date は線を引いたときだけ')
            if owner['decision'] is not None and not (isinstance(date, str) and DATE.match(date)):
                errors.append(f'{where}: owner.date は YYYY-MM-DD')
            if not isinstance(owner.get('note', ''), str):
                errors.append(f'{where}: owner.note は文字列')
    return errors


def check_perf(data, ids):
    if not isinstance(data, dict):
        return ['perf.json: 中身がオブジェクトではない']
    errors = []
    device = data.get('device')
    if not isinstance(device, dict) or not all(_text(device.get(k)) for k in ('avd', 'image', 'host')):
        errors.append('perf.json: device に avd・image・host が要る')
    if not (isinstance(data.get('measured_on'), str) and DATE.match(data['measured_on'])):
        errors.append('perf.json: measured_on は YYYY-MM-DD')
    conditions = data.get('conditions')
    if not isinstance(conditions, dict) or not _text(conditions.get('new_game')):
        errors.append('perf.json: conditions.new_game が要る')
    apps = data.get('apps')
    if not isinstance(apps, dict) or 'self' not in apps:
        return errors + ['perf.json: apps に self が要る']
    for key, metrics in apps.items():
        where = f'perf.json: apps.{key}'
        if key != 'self' and key not in ids:
            errors.append(f'{where}: competitors.json に無い id')
        if not isinstance(metrics, dict):
            errors.append(f'{where}: オブジェクトではない')
            continue
        for name in METRICS:
            m = metrics.get(name)
            w = f'{where}.{name}'
            if not isinstance(m, dict):
                errors.append(f'{w} が無い')
                continue
            status, runs = m.get('status'), m.get('runs')
            if status not in ('ok', 'unmeasured'):
                errors.append(f'{w}: status は ok・unmeasured のどれか')
            elif status == 'ok':
                if (not isinstance(runs, list) or not runs
                        or any(isinstance(r, bool) or not isinstance(r, int) or r <= 0 for r in runs)):
                    errors.append(f'{w}: runs は正の整数の並び')
                elif m.get('median') != round(statistics.median(runs)):
                    errors.append(f'{w}: median が runs の中央値と違う')
            elif not _text(m.get('reason')):
                errors.append(f'{w}: 未計測の理由が要る')
    return errors


def check_market(app_dir):
    """('pass' | 'fail' | 'unmeasured', 理由の並び) を返す。"""
    market_dir = os.path.join(app_dir, MARKET)
    if not os.path.isdir(market_dir):
        return 'unmeasured', ['quality/market がまだ無い']
    errors, missing = [], []

    def load(name):
        path = os.path.join(market_dir, name)
        if not os.path.exists(path):
            missing.append(name)
            return None
        try:
            with open(path, encoding='utf-8') as f:
                return json.load(f)
        except (OSError, ValueError) as e:
            errors.append(f'{name}: 読めない({e})')
            return None

    competitors, features, perf = load('competitors.json'), load('features.json'), load('perf.json')
    ids = []
    if competitors is not None:
        ids, problems = check_competitors(competitors)
        errors += problems
    for name, data, check in (('features.json', features, lambda d: check_features(d, ids, market_dir)),
                              ('perf.json', perf, lambda d: check_perf(d, ids))):
        if data is None:
            continue
        if competitors is None:
            errors.append(f'{name}: competitors.json が要る')
        else:
            errors += check(data)
    if errors:
        return 'fail', errors
    if missing:
        return 'unmeasured', [f'{name} がまだ無い' for name in missing]
    return 'pass', []


def main(argv=None, root=ROOT):
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print('usage: market_check.py <AppName>')
        return 2
    app_dir = os.path.join(root, args[0])
    if not os.path.isdir(app_dir):
        print(f'アプリが見つかりません: {app_dir}')
        return 2
    status, reasons = check_market(app_dir)
    print(f'=== market check: {args[0]} ({status}) ===')
    for reason in reasons:
        print(f'{"✗" if status == "fail" else "・"} {reason}')
    return 1 if status == 'fail' else 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(合わせて 17 件)

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/market_check.py tool/tests/test_market_check.py
git commit -m "feat: 第 3 層の記録の形の検査"
```

---

### Task 3: 第 1 層の入口 `gate.py`

**Files:**
- Create: `twoyearsold_ui/tool/gate.py`
- Test: `twoyearsold_ui/tool/tests/test_gate.py`

**Interfaces:**
- Consumes: `rights_guard.scan`、`rights_guard.load_terms`(Task 1)、`market_check.check_market`(Task 2)
- Produces:
  - `gate.run_command(args: list[str], cwd: str, timeout: float) -> tuple[int, str]`(終了コードと出力の末尾。命令が無ければ `FileNotFoundError`、時間切れは `subprocess.TimeoutExpired`)
  - `gate.check_licenses(app_dir: str) -> tuple[str, str]`
  - `gate.run_gate(app: str, root=ROOT, run=run_command, python=sys.executable) -> dict`(仕様 4.1 の JSON の形。検査の名前は `analyze`・`test`・`quality`・`i18n`・`rights`・`licenses`・`market` の順)
  - `gate.render(report: dict) -> str`(人が読む表)
  - `gate.main(argv=None, root=ROOT, run=run_command) -> int`(0 / 1 / 2)

ライセンス表示の確認は、仕様 4.1 のとおり「アプリのコードに `LicensesScreen(` の呼び出しがあるか」を見る。注釈の中で名前に触れただけでは合格にしない。

- [ ] **Step 1: 失敗するテストを書く**

```python
import contextlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import gate  # noqa: E402


class GateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.write('lib/presentation/settings/settings_screen.dart',
                   "onTap: () => Navigator.push(context, MaterialPageRoute(\n"
                   "    builder: (_) => LicensesScreen(theme: theme, title: title)));\n")
        self.write('store/play/listing/en-US/full.txt', 'A calm number puzzle.\n')
        self.calls = []

    def write(self, rel, text):
        path = os.path.join(self.app, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)

    def fake_run(self, results):
        def run(args, cwd, timeout):
            self.calls.append((args, cwd, timeout))
            key = 'flutter ' + args[1] if args[0] == 'flutter' else os.path.basename(args[1])
            outcome = results.get(key, (0, ''))
            if isinstance(outcome, BaseException):
                raise outcome
            return outcome
        return run

    def fake_command(self, bin_dir, name, body):
        path = os.path.join(bin_dir, name)
        with open(path, 'w', encoding='utf-8') as f:
            f.write('#!/bin/sh\n' + body + '\n')
        os.chmod(path, 0o755)
        return path

    def with_path(self, path):
        old = os.environ.get('PATH', '')
        os.environ['PATH'] = path
        self.addCleanup(os.environ.__setitem__, 'PATH', old)

    def statuses(self, report):
        return {c['name']: c['status'] for c in report['checks']}

    def test_all_checks_run_in_order_and_pass(self):
        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
        self.assertEqual([c['name'] for c in report['checks']],
                         ['analyze', 'test', 'quality', 'i18n', 'rights', 'licenses', 'market'])
        self.assertTrue(report['ok'])
        self.assertEqual(self.statuses(report)['market'], 'unmeasured')
        self.assertEqual(report['app'], 'Demo')
        self.assertEqual([c[1] for c in self.calls], [self.app] * 4)

    def test_missing_flutter_and_timeouts_fail_with_reasons_and_continue(self):  # Review Focus 2
        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({
            'flutter analyze': FileNotFoundError('flutter'),
            'flutter test': subprocess.TimeoutExpired(['flutter', 'test'], 5),
        }))
        checks = {c['name']: c for c in report['checks']}
        self.assertEqual(checks['analyze']['status'], 'fail')
        self.assertIn('flutter が見つからない', checks['analyze']['detail'])
        self.assertEqual(checks['test']['status'], 'fail')
        self.assertIn('秒で終わらなかった', checks['test']['detail'])
        self.assertEqual(checks['rights']['status'], 'pass')
        self.assertFalse(report['ok'])

    def test_failing_guard_reports_the_tail_of_its_output(self):
        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({
            'i18n_guard.py': (1, 'line1\n✗ 完全性: 3 件\nFAILED: 3 件の違反\n'),
        }))
        checks = {c['name']: c for c in report['checks']}
        self.assertEqual(checks['i18n']['status'], 'fail')
        self.assertIn('終了コード 1', checks['i18n']['detail'])
        self.assertIn('FAILED: 3 件の違反', checks['i18n']['detail'])

    def test_rights_and_licenses_are_checked_in_process(self):
        self.write('store/play/listing/ja-JP/full.txt', '静かな数独\n')
        self.write('lib/presentation/settings/settings_screen.dart', '// LicensesScreen はまだ\n')
        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
        self.assertEqual(self.statuses(report)['rights'], 'fail')
        self.assertEqual(self.statuses(report)['licenses'], 'fail')

    def test_real_commands_with_fake_flutter_on_path(self):
        bin_dir = os.path.join(self.tmp, 'bin')
        os.makedirs(bin_dir)
        self.fake_command(bin_dir, 'flutter',
                          'if [ "$1" = test ]; then echo "Some tests failed."; exit 1; fi\necho "No issues found!"')
        python = self.fake_command(bin_dir, 'python', 'exit 0')
        self.with_path(bin_dir + os.pathsep + os.environ.get('PATH', ''))
        report = gate.run_gate('Demo', root=self.tmp, python=python)
        checks = {c['name']: c for c in report['checks']}
        self.assertEqual(checks['analyze']['status'], 'pass')
        self.assertEqual(checks['test']['status'], 'fail')
        self.assertIn('Some tests failed.', checks['test']['detail'])
        self.assertEqual(checks['quality']['status'], 'pass')

    def test_real_missing_flutter_fails_with_a_reason(self):  # Review Focus 2
        bin_dir = os.path.join(self.tmp, 'bin')
        os.makedirs(bin_dir)
        python = self.fake_command(bin_dir, 'python', 'exit 0')
        self.with_path(bin_dir)
        report = gate.run_gate('Demo', root=self.tmp, python=python)
        checks = {c['name']: c for c in report['checks']}
        self.assertEqual(checks['analyze']['status'], 'fail')
        self.assertIn('flutter が見つからない', checks['analyze']['detail'])
        self.assertEqual(checks['i18n']['status'], 'pass')

    def test_main_writes_json_and_sets_exit_code(self):
        out = os.path.join(self.tmp, 'gate.json')
        with contextlib.redirect_stdout(io.StringIO()):
            code = gate.main(['Demo', '--json', out], root=self.tmp, run=self.fake_run({}))
            self.assertEqual(code, 0)
            with open(out, encoding='utf-8') as f:
                data = json.load(f)
            self.assertEqual(data['app'], 'Demo')
            self.assertIn('checked_at', data)
            code = gate.main(['Demo'], root=self.tmp, run=self.fake_run({'flutter test': (1, 'Some tests failed.')}))
            self.assertEqual(code, 1)
            self.assertEqual(gate.main(['Nope'], root=self.tmp, run=self.fake_run({})), 2)

    def test_render_lists_every_check(self):
        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
        text = gate.render(report)
        for name in ('analyze', 'test', 'quality', 'i18n', 'rights', 'licenses', 'market'):
            self.assertIn(name, text)


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'gate'`)

- [ ] **Step 3: 実装する**

```python
# coding: utf-8
"""第 1 層の入口 — 1 つのアプリについて、機械で確かめられる品質をまとめて確かめる。

順に走らせる: flutter analyze / 全テスト(ゴールデンとタップ領域の巡回を含む)/ 横断ガード / 翻訳ガード /
権利の語の検査 / ライセンス表示の確認 / 第 3 層の記録の形の検査。
人が読む表を標準出力に出し、--json を渡すとそこへ機械が読める JSON を書く。
1 つでも不合格(fail)なら exit 1。未計測(unmeasured、理由つき)は不合格にしない。

使い方:
  python3 twoyearsold_ui/tool/gate.py <AppName> [--json <書き出し先>]
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
sys.path.insert(0, HERE)
import market_check  # noqa: E402
import rights_guard  # noqa: E402

ANALYZE_TIMEOUT_S = 900
TEST_TIMEOUT_S = 3600
GUARD_TIMEOUT_S = 300
DETAIL_LIMIT = 10


def run_command(args, cwd, timeout):
    """(終了コード, 出力の末尾) を返す。命令が無ければ FileNotFoundError、時間切れは TimeoutExpired。"""
    done = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    return done.returncode, ((done.stdout or '') + (done.stderr or ''))[-4000:]


def _command_check(args, cwd, timeout, run):
    try:
        code, out = run(args, cwd, timeout)
    except FileNotFoundError:
        return 'fail', f'{os.path.basename(args[0])} が見つからない'
    except subprocess.TimeoutExpired:
        return 'fail', f'{timeout} 秒で終わらなかった'
    if code == 0:
        return 'pass', ''
    tail = ' / '.join(line.strip() for line in out.strip().splitlines()[-5:])
    return 'fail', f'終了コード {code}: {tail}'


def check_licenses(app_dir):
    """アプリのコードに、共有の LicensesScreen を開く入口(LicensesScreen( の呼び出し)があるか。"""
    for path in sorted(glob.glob(os.path.join(app_dir, 'lib', '**', '*.dart'), recursive=True)):
        try:
            with open(path, encoding='utf-8') as f:
                text = f.read()
        except (OSError, UnicodeDecodeError):
            continue
        if re.search(r'\bLicensesScreen\s*\(', text):
            return 'pass', ''
    return 'fail', 'ライセンスの画面を開く入口(LicensesScreen( の呼び出し)が lib/ に見つからない'


def _joined(items):
    head = '; '.join(items[:DETAIL_LIMIT])
    return head + (f' ほか {len(items) - DETAIL_LIMIT} 件' if len(items) > DETAIL_LIMIT else '')


def run_gate(app, root=ROOT, run=run_command, python=sys.executable):
    app_dir = os.path.join(root, app)
    checks = []

    def add(name, status, detail, started):
        checks.append({'name': name, 'status': status, 'detail': detail,
                       'seconds': round(time.monotonic() - started, 1)})

    commands = [
        ('analyze', ['flutter', 'analyze'], ANALYZE_TIMEOUT_S),
        ('test', ['flutter', 'test'], TEST_TIMEOUT_S),
        ('quality', [python, os.path.join(HERE, 'quality_guard.py'), app], GUARD_TIMEOUT_S),
        ('i18n', [python, os.path.join(HERE, 'i18n_guard.py'), app], GUARD_TIMEOUT_S),
    ]
    for name, args, timeout in commands:
        started = time.monotonic()
        status, detail = _command_check(args, app_dir, timeout, run)
        add(name, status, detail, started)

    started = time.monotonic()
    found = rights_guard.scan(app_dir, rights_guard.load_terms())
    add('rights', 'fail' if found else 'pass', _joined(found), started)

    started = time.monotonic()
    status, detail = check_licenses(app_dir)
    add('licenses', status, detail, started)

    started = time.monotonic()
    status, reasons = market_check.check_market(app_dir)
    add('market', status, _joined(reasons), started)

    return {
        'app': app,
        'ok': all(c['status'] != 'fail' for c in checks),
        'checked_at': dt.datetime.now().astimezone().isoformat(timespec='seconds'),
        'checks': checks,
    }


MARKS = {'pass': '○', 'fail': '✗', 'unmeasured': '−'}


def render(report):
    lines = [f"=== gate: {report['app']} ({'合格' if report['ok'] else '不合格'}) ===",
             '| 検査 | 結果 | 秒 | 内容 |', '|---|---|---|---|']
    for c in report['checks']:
        detail = c['detail'].replace('|', '/')
        lines.append(f"| {c['name']} | {MARKS[c['status']]} {c['status']} | {c['seconds']} | {detail} |")
    return '\n'.join(lines)


def main(argv=None, root=ROOT, run=run_command):
    parser = argparse.ArgumentParser(description='第 1 層の入口')
    parser.add_argument('app')
    parser.add_argument('--json', help='機械が読める結果の書き出し先')
    args = parser.parse_args(argv)
    if not os.path.isdir(os.path.join(root, args.app)):
        print(f'アプリが見つかりません: {os.path.join(root, args.app)}')
        return 2
    report = run_gate(args.app, root=root, run=run)
    print(render(report))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
            f.write('\n')
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(合わせて 25 件)

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/gate.py tool/tests/test_gate.py
git commit -m "feat: 第 1 層の入口(1 つのアプリの機械検査をまとめて走らせる)"
```

---

### Task 4: NumberPlace で入口を走らせて直す(統括)

この Task から先の「(統括)」の Task は、統括が見張りのある作業として自分で行う。担当には渡さない。直しのコードが要るときは、直しごとに小さな作業(テストを先に書く)として担当に渡し、確認役を通す。

- [ ] **Step 1: 入口を走らせ、結果を残す**

```bash
cd /Users/abe/dev/twoyearsold && mkdir -p NumberPlace/quality
/usr/bin/python3 -B twoyearsold_ui/tool/gate.py NumberPlace --json NumberPlace/quality/gate.json; echo "exit=$?"
```

Expected: `market` は `unmeasured`(記録がまだ無い)。`rights` は少なくとも `store/play/README.md:40` で `fail` になる見込み(方針の注記の中に、語そのものを書いているため)。

- [ ] **Step 2: 不合格を仕分けて直す**

- `store/play/README.md:40` は利用者に見えない内部の注記。語を書かずに辞書を指す形へ、次の 1 行に書き換える(ほかの文意は残す):
  `- 他社の商標の名前は使わない(全言語・全箇所。語と理由の一覧は twoyearsold_ui/tool/rights_terms.json で、入口 gate.py が毎回確かめる)。とくに、このパズルの日本での元の名前は株式会社ニコリの登録商標で、同社は無断使用に注意を出している。呼び名は「ナンプレ」「number-placement puzzle / number puzzle」。変種名の「Killer」は単体で使う。`
- 利用者に見えない直し(テストの失敗、解析の警告など): 直しごとに担当に渡し、確認役を通す。
- 利用者に見える文言や見た目を変える直し(表示文言や掲載文に権利の語がある、など): 何をどう変えるかを AskUserQuestion でオーナーに伺ってから直す。
- 直したら Step 1 をもう一度走らせる。`market` 以外がすべて `pass` になるまで繰り返す。

- [ ] **Step 3: 結果を commit する(NumberPlace はローカルだけ)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace && git add quality/gate.json store/play/README.md && git commit -m "chore: 第 1 層の入口の結果と、方針の注記から権利の語を外す"
```

直せずに残った不合格があれば、運用リポジトリの `ledger/NumberPlace.md` の「課題」に `- [gate] <検査の名前> が不合格: <内容>(根拠: NumberPlace/quality/gate.json)` の形で 1 件ずつ書き、運用リポジトリを commit して push する。

---

### Task 5: 測定用のエミュレータを作り、自作を入れて録画の前提を確かめ直す(統括)

- [ ] **Step 1: Play ストア入りのイメージを入れ、エミュレータを作って起動する**

```bash
SDK=~/Library/Android/sdk; BIN=$(ls -d $SDK/cmdline-tools/*/bin | head -1); ADB=$SDK/platform-tools/adb
$BIN/sdkmanager --install "system-images;android-35;google_apis_playstore;arm64-v8a" < /dev/null
echo no | $BIN/avdmanager create avd -n yardstick_play_35 -k "system-images;android-35;google_apis_playstore;arm64-v8a" -d pixel_7
nohup $SDK/emulator/emulator -avd yardstick_play_35 -no-audio > "$SCRATCH/yardstick-emulator.log" 2>&1 &
$ADB wait-for-device; until [ "$($ADB shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 5; done; $ADB shell wm size
```

Expected: `Physical size: 1080x2400`(上書きの行が無い)。`sdkmanager` が新しい規約への同意を求めて止まったら(標準入力を閉じているので、断って終わる)、規約の名前を添えて AskUserQuestion でオーナーに伺う。エミュレータは画面ありで起動する(Task 7 でオーナーがログインするため)。

- [ ] **Step 2: 自作の release を作って入れる**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace && flutter build apk --release && ~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

署名は `~/keystores/key.properties` があればアップロード鍵、無ければ debug の鍵になる(どちらでも測定には差し支えない)。パスワードを入力する場面は無い。

- [ ] **Step 3: 録画の前提を、この機種で確かめ直す**

```bash
ADB=~/Library/Android/sdk/platform-tools/adb; PKG=net.twoyearsold.numberplace
COMP=$($ADB shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER $PKG | tail -1 | tr -d '\r')
BEFORE=$($ADB shell settings get system pointer_location | tr -d '\r')
$ADB shell am force-stop $PKG; $ADB shell am start -W -n $COMP | grep TotalTime; sleep 3
$ADB shell settings put system pointer_location 0; $ADB shell settings put system pointer_location 1; sleep 1
$ADB shell screenrecord --verbose --size 720x1600 /sdcard/probe.mp4 > "$SCRATCH/probe-rec.log" 2>&1 &
sleep 2; $ADB shell input tap 540 1200; sleep 3; $ADB shell pkill -INT screenrecord; sleep 2
grep -E "Content|recorded" "$SCRATCH/probe-rec.log"; $ADB pull /sdcard/probe.mp4 "$SCRATCH/probe.mp4"; $ADB shell rm -f /sdcard/probe.mp4
if [ "$BEFORE" = null ]; then $ADB shell settings delete system pointer_location; else $ADB shell settings put system pointer_location "$BEFORE"; fi
ffprobe -v error -select_streams v:0 -show_entries frame=pts_time -of csv=p=0 "$SCRATCH/probe.mp4" | tr '\n' ' '; echo
ffmpeg -v error -i "$SCRATCH/probe.mp4" -fps_mode passthrough -vf "crop=720:40:0:0,scale=160:8,format=gray" -f rawvideo - > "$SCRATCH/strip.raw"
/usr/bin/python3 -I -c "
import sys; d=open(sys.argv[1],'rb').read(); n=160*8; f=[d[i:i+n] for i in range(0,len(d),n)]
print([round(sum(abs(a-b) for a,b in zip(f[i],f[i-1]))/n,2) for i in range(1,len(f))])" "$SCRATCH/strip.raw"
```

Expected: `Content area is 720x1600 at offset x=0 y=0`。コマの時刻は、押すまで間が空く(画面が止まっている間はコマが無い)。帯の差の並びに 4 を大きく超える値が 1 つあり(押した瞬間)、それより前の値は 4 未満。違う結果なら、Task 9・10 に入る前に、しきい値や帯の高さを Ruling で決め直し、その値を担当への依頼に添える。

- [ ] **Step 4: 前提の記録を作る**

`twoyearsold_ui/tool/perf/README.md` を作る。中身は次のとおり。「測定用」の列は、Step 1〜3 で見た値で埋める。

```markdown
# 性能の道具

NumberPlace で作った第 3 層の物差しのうち、性能を測る道具。他の 8 作でも使う。

- 起動の速さ: `python3 twoyearsold_ui/tool/perf/start_time.py <package> [--record <perf.json> --id <self|c01…>]`
- 出題の時間: `python3 twoyearsold_ui/tool/perf/new_game.py <台本> [--keep <dir>] [--record <perf.json>] [--note <条件の違い>]`
- 確かめ用の画像を 1 枚にまとめる: `ffmpeg -v error -y -i "<dir>/<id>-%d.png" -vf tile=1x5 -frames:v 1 "<dir>/<id>-check.png"`
  (各行が 1 回の測定。左から、押す前・押した瞬間・盤が落ち着いたコマ)

## 確かめた前提

| 前提(仕様 10 節) | np(2026-10-14) | 測定用 yardstick_play_35 |
|---|---|---|
| 3. 録画のコマから前後 1 コマで割り出せる | 画面が変わるときだけコマが出る(変化中は約 16ms 間隔)。押した瞬間は「ポインタの位置」の帯で分かる(差 12〜15、時計の変化 0.2)。「タップを表示」は adb の押下では描かれない | |
| 録画の大きさ | 1080x1920 のまま録れた。道具は画面の 2/3(16 の倍数)で録る | |
| 起動の画面の引き方 | monkey では起動しないアプリがある。resolve-activity と am start -W -n を使う | |
| 1. ログインと競合のインストール | − | (Task 7) |
| 2. am start -W の時間を同じ意味で比べられる | − | (Task 7) |
| 4. 広告の揺れが中央値で吸収できる | − | (Task 12) |
| 5. 測定が現実的な時間で終わる | 起動の速さ 11 回で 4.9 秒、出題の時間 1 回で約 15 秒 | (Task 12) |
```

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui && git add tool/perf/README.md && git commit -m "docs: 性能の道具の前提の記録(np と測定用のエミュレータ)"
```

---

### Task 6: 競合の候補を選ぶ(統括)

- [ ] **Step 1: 上位を調べる**

日本と米国の Google Play と App Store で、「ナンプレ」「数独」「sudoku」の検索の上位と、パズルのランキングを Web で調べる。ストアの公開のページを読むだけで、ログインや購入はしない。

- [ ] **Step 2: 10 本を選ぶ**

両国の上位の重なりを優先し、無料(広告つき)・有料・サブスクリプションの形が偏らないようにする。Android にあるものを 7 本以上にする(出題の時間を 7 本以上で測るため)。1 本ごとに、選んだ理由(どの国のどの一覧で何位か)を書く。

- [ ] **Step 3: 記録して形を確かめる**

`NumberPlace/quality/market/competitors.json` を書く(仕様 4.3 の形。`chosen_on` は選んだ日、`criteria` は選び方、`price_model` は `free`・`free_with_ads`・`freemium`・`paid`・`subscription` のどれか、`on_android` は `play` があるときだけ true)。

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/market_check.py NumberPlace; echo "exit=$?"
```

Expected: `unmeasured`(features.json と perf.json がまだ無い)で、exit 0。

- [ ] **Step 4: Commit(NumberPlace はローカルだけ)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace && git add quality/market/competitors.json && git commit -m "docs: 第 3 層の競合の候補"
```

---

### Task 7: ★ログインと競合のインストール、起動の速さの意味の確かめ(統括 + オーナー)

- [ ] **Step 1: ★オーナーに頼む(AskUserQuestion。終わったら知らせてもらう)**

- 候補の一覧(`competitors.json` の `on_android` が true のもの。名前・価格の形・選んだ理由)を見せ、入れ替えたいものがあれば聞く。
- エミュレータの画面で Play ストアを開き、Google アカウントでログインしてもらう(Claude はパスワードを扱わない)。
- 無料の競合を Play から入れてもらう。有料のものは入れない(機能は掲載情報から比べる)。

- [ ] **Step 2: 前提 1 を確かめる**

```bash
~/Library/Android/sdk/platform-tools/adb shell pm list packages | sort
```

入らなかった競合があれば、選び方を保ったまま次の候補と入れ替えてよいかをオーナーに伺い、`competitors.json` を直す(入れ替えの理由は `why` に書く)。結果を `twoyearsold_ui/tool/perf/README.md` の前提 1 の行に書く。

- [ ] **Step 3: 前提 2 を確かめる(自作と、起動の画面の作りが違いそうな競合 2 本)**

アプリごとに、起動を録画しながら `am start -W` の時間を取り、録画で「最初の操作できる画面が落ち着くまで」と比べる。

```bash
ADB=~/Library/Android/sdk/platform-tools/adb; PKG=<package>; ID=<self か cNN>
COMP=$($ADB shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER $PKG | tail -1 | tr -d '\r')
$ADB shell am force-stop $PKG; $ADB shell input keyevent KEYCODE_HOME; sleep 2
$ADB shell screenrecord --size 720x1600 /sdcard/launch.mp4 &
sleep 2; $ADB shell am start -W -n $COMP | grep TotalTime
sleep 8; $ADB shell pkill -INT screenrecord; sleep 2; $ADB pull /sdcard/launch.mp4 "$SCRATCH/launch-$ID.mp4"; $ADB shell rm -f /sdcard/launch.mp4
ffprobe -v error -select_streams v:0 -show_entries frame=pts_time -of csv=p=0 "$SCRATCH/launch-$ID.mp4" | tr '\n' ' '; echo
ffmpeg -v error -y -i "$SCRATCH/launch-$ID.mp4" -vf "fps=10,scale=120:-2,tile=10x3" -frames:v 1 "$SCRATCH/launch-$ID.png"
```

`launch-$ID.png`(0.1 秒ごとのコマ)を見て、ホーム画面から変わり始めたコマから、最初の操作できる画面が落ち着くまでの時間を読む。どのアプリでも、その時間と TotalTime の差が 300ms 以内なら、`am start -W` のままでよい。どれかで差が 300ms を超えたら(起動の後に読み込みの画面を挟むなど)、Ruling として、Task 10 の後に「ホーム画面のアイコンを押して起動を測る」作業を足す。`new_game.py` の台本に `"from_home": true` を足し、そのときは起動の代わりにホームへ戻ってアイコンを押し、盤の場所の代わりに最初の画面の場所が落ち着くまでを測る。結果を README の前提 2 の行に書き、commit する。

---

### Task 8: 性能の道具の共通部品と、起動の速さ

**Files:**
- Create: `twoyearsold_ui/tool/perf/common.py`
- Create: `twoyearsold_ui/tool/perf/start_time.py`
- Test: `twoyearsold_ui/tool/tests/test_start_time.py`

**Interfaces:**
- Produces:
  - `common.ADB: str`(環境変数 `ADB`、無ければ `~/Library/Android/sdk/platform-tools/adb`)
  - `common.MeasureError(Exception)`
  - `common.run(args: list[str], timeout: float = 60) -> tuple[int, str, str]`
  - `common.adb(*args: str, run=run, timeout: float = 60) -> tuple[int, str, str]`
  - `common.median_ms(runs: list[int]) -> int`
  - `common.metric(runs: list[int], reason: str = '') -> dict`(perf.json の 1 つの測定値の形)
  - `common.device_ready(run=run) -> Optional[str]`(つながっていれば None、なければ理由)
  - `common.launcher_component(package: str, run=run) -> str`(`package/activity`。見つからなければ `MeasureError`)
  - `common.record(path: str, app_id: str, name: str, value: dict) -> None`(perf.json の 1 つの測定値だけを書き換える)
  - `start_time.cold_start_once(package: str, component: str, run=run) -> int`
  - `start_time.measure(package: str, runs: int = 11, run=run) -> dict`
  - `start_time.main(argv=None, run=run) -> int`

- [ ] **Step 1: 失敗するテストを書く**

```python
import contextlib
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'perf'))
import common  # noqa: E402
import start_time  # noqa: E402


class FakeAdb:
    def __init__(self, state='device', totals=None, resolve='com.x/.Main', total_text='TotalTime: {}'):
        self.state = state
        self.totals = list(totals or [])
        self.resolve = resolve
        self.total_text = total_text
        self.calls = []

    def __call__(self, args, timeout=60):
        rest = args[1:]
        self.calls.append(rest)
        if rest == ['get-state']:
            return (0, self.state + '\n', '') if self.state else (1, '', 'error: no devices')
        if rest[:3] == ['shell', 'cmd', 'package']:
            return 0, f'priority=0 preferredOrder=0\n{self.resolve}\n', ''
        if rest[:3] == ['shell', 'am', 'force-stop']:
            return 0, '', ''
        if rest[:3] == ['shell', 'am', 'start']:
            value = self.totals.pop(0)
            return 0, 'Starting: Intent\nStatus: ok\n' + self.total_text.format(value) + '\nComplete\n', ''
        raise AssertionError(f'unexpected adb call {rest}')


class StartTimeTest(unittest.TestCase):
    def test_drops_the_first_run_and_takes_the_median(self):
        fake = FakeAdb(totals=[900] + [400, 410, 420, 430, 440, 450, 460, 470, 480, 490])
        result = start_time.measure('com.x', runs=11, run=fake)
        self.assertEqual(result['status'], 'ok')
        self.assertEqual(result['runs'], [400, 410, 420, 430, 440, 450, 460, 470, 480, 490])
        self.assertEqual(result['median'], 445)
        starts = [c for c in fake.calls if c[:3] == ['shell', 'am', 'start']]
        self.assertEqual(starts[0], ['shell', 'am', 'start', '-W', '-n', 'com.x/.Main'])
        self.assertEqual(len([c for c in fake.calls if c[:3] == ['shell', 'am', 'force-stop']]), 11)

    def test_no_device_is_unmeasured_without_launching(self):  # Review Focus 5
        fake = FakeAdb(state='')
        result = start_time.measure('com.x', run=fake)
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('エミュレータが動いていない', result['reason'])
        self.assertEqual(fake.calls, [['get-state']])

    def test_missing_launcher_or_total_time_is_unmeasured(self):
        result = start_time.measure('com.x', run=FakeAdb(resolve='No activity found'))
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('起動の画面が見つからない', result['reason'])
        result = start_time.measure('com.x', run=FakeAdb(totals=[1] * 11, total_text='WaitTime: {}'))
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('起動の時間を読めない', result['reason'])

    def test_missing_adb_is_unmeasured(self):
        def missing(args, timeout=60):
            raise FileNotFoundError(args[0])
        result = start_time.measure('com.x', run=missing)
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('adb を使えない', result['reason'])

    def test_metric_shape(self):
        self.assertEqual(common.metric([3, 1, 2]), {'runs': [3, 1, 2], 'median': 2, 'status': 'ok', 'reason': ''})
        self.assertEqual(common.metric([], '理由'),
                         {'runs': [], 'median': None, 'status': 'unmeasured', 'reason': '理由'})

    def test_record_updates_one_metric_and_keeps_the_rest(self):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, ignore_errors=True)
        path = os.path.join(tmp, 'perf.json')
        with open(path, 'w', encoding='utf-8') as f:
            json.dump({'measured_on': '2026-10-15', 'apps': {'self': {'new_game_ms': common.metric([1])}}}, f)
        with contextlib.redirect_stdout(io.StringIO()):
            start_time.main(['com.x', '--runs', '3', '--record', path, '--id', 'self'],
                            run=FakeAdb(totals=[9, 5, 7]))
        common.record(path, 'c01', 'cold_start_ms', common.metric([], '広告'))
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
        self.assertEqual(data['measured_on'], '2026-10-15')
        self.assertEqual(data['apps']['self']['new_game_ms']['median'], 1)
        self.assertEqual(data['apps']['self']['cold_start_ms']['median'], 6)
        self.assertEqual(data['apps']['c01']['cold_start_ms']['status'], 'unmeasured')


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'common'`)

- [ ] **Step 3: 実装する**

`twoyearsold_ui/tool/perf/common.py`:

```python
# coding: utf-8
"""性能の道具の共通部品: adb の場所、命令の実行、測定値のまとめ方、perf.json への書き込み。"""
import json
import os
import statistics
import subprocess

ADB = os.environ.get('ADB') or os.path.expanduser('~/Library/Android/sdk/platform-tools/adb')


class MeasureError(Exception):
    """1 回の測定ができなかった(理由を文面に持つ)。"""


def run(args, timeout=60):
    """命令を走らせ、(終了コード, 標準出力, 標準エラー) を返す。"""
    done = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    return done.returncode, done.stdout, done.stderr


def adb(*args, run=run, timeout=60):
    return run([ADB, *args], timeout=timeout)


def median_ms(runs):
    return round(statistics.median(runs))


def metric(runs, reason=''):
    """perf.json の 1 つの測定値の形にする。runs が空なら未計測。"""
    if runs:
        return {'runs': list(runs), 'median': median_ms(runs), 'status': 'ok', 'reason': reason}
    return {'runs': [], 'median': None, 'status': 'unmeasured', 'reason': reason or '測れなかった'}


def device_ready(run=run):
    """エミュレータ(端末)がつながっていれば None、なければ理由を返す。"""
    try:
        code, out, _ = adb('get-state', run=run, timeout=10)
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        return f'adb を使えない({e})'
    if code != 0 or out.strip() != 'device':
        return 'エミュレータが動いていない(adb get-state が device ではない)'
    return None


def launcher_component(package, run=run):
    """ホーム画面から開いたときに起動する画面(package/activity)を引く。"""
    code, out, _ = adb('shell', 'cmd', 'package', 'resolve-activity', '--brief',
                       '-c', 'android.intent.category.LAUNCHER', package, run=run)
    lines = [line.strip() for line in out.splitlines() if line.strip()]
    if code != 0 or not lines or '/' not in lines[-1]:
        raise MeasureError(f'起動の画面が見つからない({package})')
    return lines[-1]


def record(path, app_id, name, value):
    """perf.json の apps.<app_id>.<name> を value にする。ほかの項目はそのまま残す。"""
    data = {}
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
    data.setdefault('apps', {}).setdefault(app_id, {})[name] = value
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
```

`twoyearsold_ui/tool/perf/start_time.py`:

```python
# coding: utf-8
"""起動の速さ — アプリを止めてから起動し、最初の画面が出るまでの時間(am start -W の TotalTime)を測る。

11 回測り、最初の 1 回を捨てた 10 回の中央値をとる(初回だけの準備の時間を除くため)。
結果は perf.json の 1 つの測定値の形(JSON)で標準出力に出す。--record を渡すと perf.json にも書く。

使い方:
  python3 twoyearsold_ui/tool/perf/start_time.py <package> [--runs 11] [--record <perf.json> --id <self|c01…>]
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import MeasureError, adb, device_ready, launcher_component, metric, record, run  # noqa: E402

TOTAL = re.compile(r'^TotalTime:\s*(\d+)\s*$', re.M)


def cold_start_once(package, component, run=run):
    adb('shell', 'am', 'force-stop', package, run=run)
    code, out, err = adb('shell', 'am', 'start', '-W', '-n', component, run=run, timeout=120)
    found = TOTAL.search(out)
    if code != 0 or not found:
        raise MeasureError(f'起動の時間を読めない({(out + err).strip()[-200:]})')
    return int(found.group(1))


def measure(package, runs=11, run=run):
    reason = device_ready(run=run)
    if reason:
        return metric([], reason)
    try:
        component = launcher_component(package, run=run)
        times = [cold_start_once(package, component, run=run) for _ in range(runs)]
    except MeasureError as e:
        return metric([], str(e))
    except subprocess.TimeoutExpired as e:
        return metric([], f'adb が時間内に答えなかった({e})')
    return metric(times[1:])


def main(argv=None, run=run):
    parser = argparse.ArgumentParser(description='起動の速さ')
    parser.add_argument('package')
    parser.add_argument('--runs', type=int, default=11)
    parser.add_argument('--record', help='結果を書き込む perf.json')
    parser.add_argument('--id', help='perf.json の中のアプリの id(self か c01 など)')
    args = parser.parse_args(argv)
    if args.runs < 2:
        parser.error('--runs は 2 以上(最初の 1 回を捨てるため)')
    if args.record and not args.id:
        parser.error('--record には --id が要る')
    result = measure(args.package, args.runs, run=run)
    if args.record:
        record(args.record, args.id, 'cold_start_ms', result)
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(合わせて 31 件)

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/perf/common.py tool/perf/start_time.py tool/tests/test_start_time.py
git commit -m "feat: 性能の道具(起動の速さ)"
```

---

### Task 9: 録画のコマから出題の時間を割り出す計算

**Files:**
- Create: `twoyearsold_ui/tool/perf/frames.py`
- Test: `twoyearsold_ui/tool/tests/test_frames.py`

**Interfaces:**
- Produces:
  - `frames.FrameError(Exception)`
  - `frames.mean_abs_diff(a: bytes, b: bytes) -> float`
  - `frames.tap_index(frames) -> int`
  - `frames.board_index(frames, tap: int, end: Optional[float] = None) -> int`
  - `frames.detect(frames, observe_s: Optional[float] = None) -> tuple[int, int]`(押したコマの番号と、盤が出たコマの番号)
  - `frames.new_game_ms(frames, observe_s: Optional[float] = None) -> int`
  - 定数 `TAP_THRESHOLD = 4.0`、`CHANGE_THRESHOLD = 8.0`、`STABLE_THRESHOLD = 2.0`、`STABLE_SECONDS = 0.3`

コマは `(時刻[秒], 盤の場所の画素, 印の帯の画素)` の並び。画素は同じ大きさの灰色の `bytes`(0〜255)。

- [ ] **Step 1: 失敗するテストを書く**

```python
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'perf'))
import frames  # noqa: E402

FPS = 60


def gray(value, size=100):
    return bytes([value]) * size


def make(tap_at=None, board=None, total=60):
    """tap_at: 印の帯が変わるコマの番号(その後は変わったまま)。board: {コマの番号: 盤の明るさ} の変わり目。"""
    out = []
    level = 0
    for i in range(total):
        if board and i in board:
            level = board[i]
        mark = 255 if tap_at is not None and i >= tap_at else 0
        out.append((i / FPS, gray(level), gray(mark, 16)))
    return out


class FramesTest(unittest.TestCase):
    def test_measures_from_tap_to_the_first_settled_board_frame(self):
        seq = make(tap_at=5, board={9: 128})
        self.assertEqual(frames.tap_index(seq), 5)
        self.assertEqual(frames.board_index(seq, 5), 9)
        self.assertEqual(frames.new_game_ms(seq), round(4 / FPS * 1000))

    def test_a_fade_in_ends_where_the_board_settles(self):
        seq = make(tap_at=5, board={9: 40, 10: 80, 11: 128})
        self.assertEqual(frames.board_index(seq, 5), 11)

    def test_no_tap_is_an_error(self):  # Review Focus 4
        with self.assertRaises(frames.FrameError):
            frames.new_game_ms(make(board={9: 128}))

    def test_a_board_that_never_settles_is_an_error(self):  # Review Focus 4
        seq = make(tap_at=5)
        seq = [(t, gray(0 if i < 8 else (60 if i % 2 else 200)), mark) for i, (t, _, mark) in enumerate(seq)]
        with self.assertRaises(frames.FrameError):
            frames.new_game_ms(seq)

    def test_a_slow_drift_is_not_settled(self):
        seq = make(tap_at=5)
        seq = [(t, gray(0 if i < 9 else min(255, 100 + (i - 9))), mark) for i, (t, _, mark) in enumerate(seq)]
        with self.assertRaises(frames.FrameError):
            frames.new_game_ms(seq)

    def test_a_recording_that_ends_before_the_board_settles_is_an_error(self):
        with self.assertRaises(frames.FrameError):
            frames.new_game_ms(make(tap_at=5, board={58: 128}, total=60))

    def test_small_noise_does_not_count_as_a_tap_or_a_board(self):
        noisy = []
        for i, (t, board, mark) in enumerate(make(tap_at=20, board={30: 128})):
            bump = i % 2
            noisy.append((t, bytes(min(255, x + bump) for x in board), bytes(min(255, x + 3 * bump) for x in mark)))
        self.assertEqual(frames.tap_index(noisy), 20)
        self.assertEqual(frames.board_index(noisy, 20), 30)

    def test_a_still_screen_without_frames_counts_as_settled_when_the_recording_went_on(self):
        # 画面の録画は、画面が止まるとコマを出さない。盤が出たコマが最後のコマになる。
        seq = [(0.0, gray(0), gray(0, 16)), (0.5, gray(0), gray(255, 16)), (0.62, gray(128), gray(255, 16))]
        with self.assertRaises(frames.FrameError):
            frames.new_game_ms(seq)
        self.assertEqual(frames.detect(seq, observe_s=4.0), (1, 2))
        self.assertEqual(frames.new_game_ms(seq, observe_s=4.0), 120)

    def test_mismatched_sizes_are_an_error(self):
        with self.assertRaises(frames.FrameError):
            frames.mean_abs_diff(b'\x00\x00', b'\x00')


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'frames'`)

- [ ] **Step 3: 実装する**

```python
# coding: utf-8
"""録画のコマから、出題の時間を割り出す(純粋な計算。adb や ffmpeg は使わない)。

コマは (時刻[秒], 盤の場所の画素, 印の帯の画素) の並び。画素は同じ大きさの灰色の bytes(0〜255)。
- 押した瞬間: 印の帯(画面の上端。端末の「ポインタの位置」が、押されるたびに書き換える帯)が、
  前のコマから大きく変わった最初のコマ。帯はシステムが描くので、アプリが固まっていても押した瞬間に変わる。
- 盤が出た瞬間: 押した後で、盤の場所が押す前と大きく違い、その後 STABLE_SECONDS の間ほぼ同じままの最初のコマ。
画面の録画は、画面が変わらない間はコマを出さない。コマが無い間は「変わっていない」とみなす。
"""
TAP_THRESHOLD = 4.0       # 印の帯の、1 画素あたりの平均の差。実測(2026-10-14): 押した瞬間 12〜15、時計の変化 0.2
CHANGE_THRESHOLD = 8.0    # 盤の場所が押す前と違うとみなす差
STABLE_THRESHOLD = 2.0    # 盤の場所が落ち着いているとみなす差
STABLE_SECONDS = 0.3


class FrameError(Exception):
    """録画から測れなかった(理由を文面に持つ)。"""


def mean_abs_diff(a, b):
    if len(a) != len(b) or not a:
        raise FrameError('画素の大きさが違う')
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


def tap_index(frames):
    for i in range(1, len(frames)):
        if mean_abs_diff(frames[i][2], frames[i - 1][2]) > TAP_THRESHOLD:
            return i
    raise FrameError('押した瞬間が録画に見つからない')


def _settled_from(frames, j, end):
    """j のコマから STABLE_SECONDS の間、盤の場所が j のコマとほぼ同じか。録画がそこまで続いていなければ偽。"""
    until = frames[j][0] + STABLE_SECONDS
    if end < until:
        return False
    k = j + 1
    while k < len(frames) and frames[k][0] <= until:
        if mean_abs_diff(frames[k][1], frames[j][1]) > STABLE_THRESHOLD:
            return False
        k += 1
    return True


def board_index(frames, tap, end=None):
    """盤が出て落ち着いた最初のコマの番号。end は録画が続いたと分かっている時刻(既定は最後のコマの時刻)。"""
    end = frames[-1][0] if end is None else end
    before = frames[tap - 1][1]
    for j in range(tap, len(frames)):
        if mean_abs_diff(frames[j][1], before) <= CHANGE_THRESHOLD:
            continue
        if _settled_from(frames, j, end):
            return j
    raise FrameError('盤が現れない(または落ち着かない)')


def detect(frames, observe_s=None):
    """(押したコマの番号, 盤が出たコマの番号) を返す。
    observe_s は、押した後に録画が続いたと分かっている秒数(画面が止まるとコマが出ないため、最後のコマでは分からない)。"""
    if len(frames) < 2:
        raise FrameError('コマが足りない')
    tap = tap_index(frames)
    end = frames[-1][0]
    if observe_s is not None:
        end = max(end, frames[tap][0] + observe_s)
    return tap, board_index(frames, tap, end)


def new_game_ms(frames, observe_s=None):
    tap, board = detect(frames, observe_s)
    return round((frames[board][0] - frames[tap][0]) * 1000)
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(合わせて 40 件)

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/perf/frames.py tool/tests/test_frames.py
git commit -m "feat: 録画のコマから出題の時間を割り出す計算"
```

---

### Task 10: 出題の時間の測定(台本・録画・コマの取り出し)

**Files:**
- Create: `twoyearsold_ui/tool/perf/new_game.py`
- Test: `twoyearsold_ui/tool/tests/test_new_game.py`

**Interfaces:**
- Consumes: `common.ADB`、`common.MeasureError`、`common.adb`、`common.device_ready`、`common.launcher_component`、`common.metric`、`common.record`、`common.run`(Task 8)、`frames.detect`、`frames.FrameError`(Task 9)
- Produces:
  - `new_game.load_script(path: str) -> dict`(仕様 4.4 の台本。`settle_s` の既定は 1.5。形が違えば `MeasureError`)
  - `new_game.screen_size(run=run) -> tuple[int, int]`(上書きがあればそちら)
  - `new_game.record_size(screen: tuple[int, int]) -> tuple[int, int]`(画面の 2/3 を 16 の倍数に丸めた大きさ)
  - `new_game.find_text(xml_text: str, text: str) -> tuple[int, int]`
  - `new_game.to_video(region: dict, screen: tuple[int, int], content: tuple[int, int, int, int]) -> dict`
  - `new_game.read_frames(video: str, board_region: dict, screen, content, run_bytes=run_bytes) -> list[tuple[float, bytes, bytes]]`
  - `new_game.check_image(video: str, indexes, out: str, run_bytes=run_bytes) -> None`
  - `new_game.measure(script_path: str, runs: int = 5, keep_dir=None, run=run, run_bytes=run_bytes, popen=subprocess.Popen, sleep=time.sleep) -> dict`
  - `new_game.main(argv=None, **deps) -> int`
  - 定数 `BOARD_SIZE = 64`、`MARK_W, MARK_H = 160, 8`、`REMOTE_UI`、`REMOTE_VIDEO`

- [ ] **Step 1: 失敗するテストを書く**

```python
import contextlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'perf'))
import new_game  # noqa: E402

UI_XML = """<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="" content-desc="" bounds="[0,0][1080,2400]">
    <node text="New Game" content-desc="" bounds="[100,2000][500,2100]" />
    <node text="" content-desc="Medium" bounds="[600,1000][1000,1100]" />
    <node text="" content-desc="Hard&#10;4 stars" bounds="[600,1200][1000,1300]" />
  </node>
</hierarchy>"""


class ScriptTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)

    def write(self, data):
        path = os.path.join(self.tmp, 's.json')
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f)
        return path

    def test_valid_script_loads_with_default_settle(self):
        script = new_game.load_script(self.write({
            'app': 'self', 'package': 'net.x', 'steps': [{'tap': {'text': 'New Game'}}, {'tap': {'x': 5, 'y': 6}}],
            'board_region': {'x': 1, 'y': 2, 'w': 3, 'h': 4}}))
        self.assertEqual(script['settle_s'], 1.5)

    def test_broken_scripts_are_rejected(self):
        region = {'x': 1, 'y': 1, 'w': 1, 'h': 1}
        for bad in ({}, {'app': 'a', 'package': 'p', 'steps': [], 'board_region': region},
                    {'app': 'a', 'package': 'p', 'steps': [{'tap': {}}], 'board_region': region},
                    {'app': 'a', 'package': 'p', 'steps': [{'tap': {'x': 1, 'y': 1}}], 'board_region': {'x': 1}}):
            with self.assertRaises(new_game.MeasureError, msg=str(bad)):
                new_game.load_script(self.write(bad))

    def test_find_text_uses_text_content_desc_and_its_lines(self):
        self.assertEqual(new_game.find_text(UI_XML, 'New Game'), (300, 2050))
        self.assertEqual(new_game.find_text(UI_XML, 'Medium'), (800, 1050))
        self.assertEqual(new_game.find_text(UI_XML, 'Hard'), (800, 1250))
        with self.assertRaises(new_game.MeasureError):
            new_game.find_text(UI_XML, 'Expert')

    def test_screen_and_recording_sizes(self):
        def wm(out):
            return lambda args, timeout=60: (0, out, '')
        self.assertEqual(new_game.screen_size(run=wm('Physical size: 1080x2400\n')), (1080, 2400))
        self.assertEqual(new_game.screen_size(run=wm('Physical size: 1080x2400\nOverride size: 1080x1920\n')),
                         (1080, 1920))
        with self.assertRaises(new_game.MeasureError):
            new_game.screen_size(run=wm('error\n'))
        self.assertEqual(new_game.record_size((1080, 2400)), (720, 1600))
        self.assertEqual(new_game.record_size((1080, 1920)), (720, 1280))

    def test_to_video_maps_screen_pixels_into_the_recording(self):
        self.assertEqual(new_game.to_video({'x': 60, 'y': 600, 'w': 960, 'h': 960}, (1080, 2400), (0, 0, 720, 1600)),
                         {'x': 40, 'y': 400, 'w': 640, 'h': 640})
        self.assertEqual(new_game.to_video({'x': 0, 'y': 0, 'w': 100, 'h': 100}, (100, 200), (10, 0, 50, 100)),
                         {'x': 10, 'y': 0, 'w': 50, 'h': 50})


@unittest.skipUnless(shutil.which('ffmpeg') and shutil.which('ffprobe'), 'ffmpeg が無い')
class VideoTest(unittest.TestCase):
    """人工の動画(上端の帯が 1.0 秒に変わり、盤の場所が 1.5 秒から明るくなる。30 コマ/秒)で、取り出しと計算をまとめて確かめる。"""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp()
        cls.video = os.path.join(cls.tmp, 'v.mp4')
        subprocess.run([
            'ffmpeg', '-v', 'error', '-f', 'lavfi', '-i', 'color=c=black:s=320x640:r=30:d=3',
            '-vf', "drawbox=x=0:y=0:w=320:h=16:color=white:t=fill:enable='gte(t,1.0)',"
                   "drawbox=x=40:y=100:w=240:h=240:color=gray:t=fill:enable='gte(t,1.5)'",
            '-pix_fmt', 'yuv420p', cls.video], check=True)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def test_measures_a_synthetic_video_within_one_frame(self):
        seq = new_game.read_frames(self.video, {'x': 40, 'y': 100, 'w': 240, 'h': 240}, (320, 640), (0, 0, 320, 640))
        self.assertGreater(len(seq), 80)
        self.assertLessEqual(abs(new_game.fr.new_game_ms(seq) - 500), 34)

    def test_screen_coordinates_are_scaled_to_the_recording(self):
        seq = new_game.read_frames(self.video, {'x': 80, 'y': 200, 'w': 480, 'h': 480}, (640, 1280), (0, 0, 320, 640))
        self.assertLessEqual(abs(new_game.fr.new_game_ms(seq) - 500), 34)

    def test_check_image_is_written(self):
        out = os.path.join(self.tmp, 'check.png')
        new_game.check_image(self.video, (29, 30, 45), out)
        self.assertGreater(os.path.getsize(out), 0)


class Proc:
    """screenrecord を走らせる adb の代わり。"""

    def communicate(self, timeout=None):
        return 'Content area is 720x1600 at offset x=0 y=0\n', None

    def kill(self):
        pass


def video_bytes(args, timeout=120):
    """押した瞬間が 0.5 秒、盤が 0.62 秒に出る 3 コマの録画の代わり(画面が止まるとコマが出ない)。"""
    if args[0] == 'ffprobe':
        return 0, b'0.000000\n0.500000\n0.620000\n', b''
    vf = args[args.index('-vf') + 1]
    if 'select=' in vf:
        with open(args[-1], 'wb') as f:
            f.write(b'png')
        return 0, b'', b''
    if f'scale={new_game.BOARD_SIZE}:{new_game.BOARD_SIZE}' in vf:
        size = new_game.BOARD_SIZE * new_game.BOARD_SIZE
        return 0, bytes(size) * 2 + bytes([128]) * size, b''
    size = new_game.MARK_W * new_game.MARK_H
    return 0, bytes(size) + bytes([255]) * size * 2, b''


def still_bytes(args, timeout=120):
    """押した瞬間が映っていない録画の代わり。"""
    if args[0] == 'ffprobe':
        return 0, b'0.0\n0.033\n', b''
    vf = args[args.index('-vf') + 1]
    w, h = (new_game.BOARD_SIZE,) * 2 if f'scale={new_game.BOARD_SIZE}:' in vf else (new_game.MARK_W, new_game.MARK_H)
    return 0, bytes(w * h * 2), b''


class FakeDevice:
    """adb の呼び出しを記録し、決まった答えを返す。"""

    def __init__(self, state='device', pointer='0'):
        self.state = state
        self.pointer = pointer
        self.calls = []

    def __call__(self, args, timeout=60):
        rest = args[1:]
        self.calls.append(rest)
        if rest == ['get-state']:
            return (0, self.state + '\n', '') if self.state else (1, '', 'no devices')
        if rest == ['shell', 'wm', 'size']:
            return 0, 'Physical size: 1080x2400\n', ''
        if rest[:3] == ['shell', 'cmd', 'package']:
            return 0, 'priority=0\ncom.c/.Main\n', ''
        if rest == ['shell', 'settings', 'get', 'system', 'pointer_location']:
            return 0, self.pointer + '\n', ''
        if rest[:2] == ['shell', 'cat']:
            return 0, UI_XML, ''
        if rest[0] == 'pull':
            with open(rest[2], 'wb') as f:
                f.write(b'mp4')
        return 0, '', ''


class MeasureTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.script = self.write_script([{'tap': {'text': 'New Game'}}, {'tap': {'text': 'Medium'}}])

    def write_script(self, steps):
        path = os.path.join(self.tmp, 's.json')
        with open(path, 'w', encoding='utf-8') as f:
            json.dump({'app': 'c01', 'package': 'com.c', 'steps': steps,
                       'board_region': {'x': 60, 'y': 600, 'w': 960, 'h': 960}}, f)
        return path

    def measure(self, fake, run_bytes=video_bytes, **kwargs):
        return new_game.measure(self.script, run=fake, run_bytes=run_bytes, popen=lambda *a, **k: Proc(),
                                sleep=lambda s: None, **kwargs)

    def test_no_device_is_unmeasured_and_settings_are_untouched(self):  # Review Focus 5
        fake = FakeDevice(state='')
        result = self.measure(fake)
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('エミュレータが動いていない', result['reason'])
        self.assertEqual(fake.calls, [['get-state']])

    def test_missing_text_is_unmeasured_and_pointer_location_is_restored(self):
        self.script = self.write_script([{'tap': {'text': 'Nope'}}])
        fake = FakeDevice(pointer='0')
        result = self.measure(fake)
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('「Nope」が画面に無い', result['reason'])
        self.assertEqual(fake.calls[-1], ['shell', 'settings', 'put', 'system', 'pointer_location', '0'])

    def test_a_setting_that_did_not_exist_is_deleted_again(self):
        fake = FakeDevice(pointer='null')
        self.measure(fake, runs=1)
        self.assertEqual(fake.calls[-1], ['shell', 'settings', 'delete', 'system', 'pointer_location'])

    def test_a_recording_without_the_tap_makes_the_metric_unmeasured(self):  # Review Focus 4
        result = self.measure(FakeDevice(), run_bytes=still_bytes, runs=1)
        self.assertEqual(result['status'], 'unmeasured')
        self.assertIn('録画から測れない', result['reason'])

    def test_successful_runs_are_measured_and_kept(self):
        fake = FakeDevice()
        keep = os.path.join(self.tmp, 'keep')
        result = self.measure(fake, runs=2, keep_dir=keep)
        self.assertEqual(result, {'runs': [120, 120], 'median': 120, 'status': 'ok', 'reason': ''})
        for name in ('c01-1.mp4', 'c01-1.png', 'c01-2.json'):
            self.assertTrue(os.path.exists(os.path.join(keep, name)), name)
        with open(os.path.join(keep, 'c01-2.json'), encoding='utf-8') as f:
            self.assertEqual(json.load(f), {'tap_s': 0.5, 'board_s': 0.62, 'ms': 120, 'tap_frame': 1, 'board_frame': 2})
        taps = [c for c in fake.calls if c[:3] == ['shell', 'input', 'tap']]
        self.assertEqual(taps[-1], ['shell', 'input', 'tap', '800', '1050'])
        resets = [i for i, c in enumerate(fake.calls) if c == ['shell', 'settings', 'put', 'system', 'pointer_location', '1']]
        records = [i for i, c in enumerate(fake.calls) if c[:3] == ['shell', 'rm', '-f']]
        self.assertTrue(resets and records and resets[0] < records[0])

    def test_main_records_the_result_with_the_note(self):
        perf = os.path.join(self.tmp, 'perf.json')
        with contextlib.redirect_stdout(io.StringIO()):
            code = new_game.main([self.script, '--runs', '1', '--record', perf, '--note', 'Classic・ふつう'],
                                 run=FakeDevice(), run_bytes=video_bytes, popen=lambda *a, **k: Proc(),
                                 sleep=lambda s: None)
        self.assertEqual(code, 0)
        with open(perf, encoding='utf-8') as f:
            data = json.load(f)
        self.assertEqual(data['apps']['c01']['new_game_ms'],
                         {'runs': [120], 'median': 120, 'status': 'ok', 'reason': 'Classic・ふつう'})


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'new_game'`)

- [ ] **Step 3: 実装する**

```python
# coding: utf-8
"""出題の時間 — 台本どおりに押し、最後に押した瞬間から盤が出て落ち着くまでを、録画のコマから測る。

台本(quality/market/scripts/<id>.json):
  {"app": "c01", "package": "com.example", "steps": [{"tap": {"text": "New Game"}}, {"tap": {"x": 540, "y": 1200}}],
   "board_region": {"x": 40, "y": 600, "w": 1000, "h": 1000}, "settle_s": 1.5}
座標は端末の画面の画素(uiautomator dump の bounds と同じ)。settle_s は押した後に画面が落ち着くまで待つ秒数(既定 1.5)。
最後の 1 つの手前までを押して待ち、録画を始めてから最後の 1 つを押す。
押した瞬間は、端末の「ポインタの位置」(押されるたびに、画面の上端の帯をシステムが書き換える)で見分ける。
adb から送った押下では「タップを表示」の丸が描かれないため(2026-10-14 に確かめた)。
測るあいだだけ「ポインタの位置」を点け、終わったら元に戻す。
5 回測って中央値をとる。台本が壊れた・録画から測れない回があれば、その測定は未計測(理由つき)。

使い方:
  python3 twoyearsold_ui/tool/perf/new_game.py <台本> [--runs 5] [--keep <dir>] [--record <perf.json>] [--note <条件の違い>]
  --keep: 各回の録画(<app>-<n>.mp4)、割り出した時刻(<app>-<n>.json)、確かめ用の画像(<app>-<n>.png。
          押す前・押した・盤が出たの 3 コマを横に並べたもの)を残す。
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frames as fr  # noqa: E402
from common import ADB, MeasureError, adb, device_ready, launcher_component, metric, record, run  # noqa: E402

REMOTE_UI = '/sdcard/yardstick_ui.xml'
REMOTE_VIDEO = '/sdcard/yardstick_new_game.mp4'
RECORD_LEAD_S = 2.0      # 録画を始めてから最後に押すまで(録画の立ち上がりを待つ)
RECORD_TAIL_S = 6.0      # 最後に押してから録画を止めるまで(広告などの遅れも入るように長めに)
OBSERVE_S = RECORD_TAIL_S - 0.5  # 押した後に録画が続いたと言える秒数(止める命令の遅れの分を引く)
BOARD_SIZE = 64          # 盤の場所を縮める一辺(画素)
MARK_W, MARK_H = 160, 8  # 印の帯を縮める大きさ
MARK_RATIO = 40          # 印の帯の高さ = 画面の高さ / 40(「ポインタの位置」の帯が収まる)
CHECK_WIDTH = 160        # 確かめ用の画像の、1 コマの幅
BOUNDS = re.compile(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
SIZE = re.compile(r'(Physical|Override) size: (\d+)x(\d+)')
CONTENT = re.compile(r'Content area is (\d+)x(\d+) at offset x=(\d+) y=(\d+)')


def run_bytes(args, timeout=120):
    done = subprocess.run(args, capture_output=True, timeout=timeout)
    return done.returncode, done.stdout, done.stderr


def load_script(path):
    try:
        with open(path, encoding='utf-8') as f:
            script = json.load(f)
    except (OSError, ValueError) as e:
        raise MeasureError(f'台本を読めない({e})')
    ok = (isinstance(script, dict) and isinstance(script.get('app'), str) and isinstance(script.get('package'), str)
          and isinstance(script.get('steps'), list) and script['steps']
          and isinstance(script.get('board_region'), dict)
          and all(isinstance(script['board_region'].get(k), int) for k in ('x', 'y', 'w', 'h')))
    if ok:
        for step in script['steps']:
            tap = step.get('tap') if isinstance(step, dict) else None
            if not isinstance(tap, dict) or not (isinstance(tap.get('text'), str)
                                                 or (isinstance(tap.get('x'), int) and isinstance(tap.get('y'), int))):
                ok = False
    if not ok:
        raise MeasureError(f'台本の形が違う({path})')
    script.setdefault('settle_s', 1.5)
    return script


def screen_size(run=run):
    """端末の画面の大きさ。上書き(Override)があればそちら(uiautomator の座標と同じ)。"""
    _, out, _ = adb('shell', 'wm', 'size', run=run)
    sizes = {kind: (int(w), int(h)) for kind, w, h in SIZE.findall(out)}
    size = sizes.get('Override') or sizes.get('Physical')
    if not size:
        raise MeasureError(f'画面の大きさを読めない({out.strip()[-200:]})')
    return size


def record_size(screen):
    """録画の大きさ: 画面の 2/3 を 16 の倍数に丸める(画面の大きさのままでは、端末の符号化器が受け付けないことがある)。"""
    return screen[0] * 2 // 3 // 16 * 16, screen[1] * 2 // 3 // 16 * 16


def find_text(xml_text, text):
    try:
        tree = ET.fromstring(xml_text)
    except ET.ParseError as e:
        raise MeasureError(f'画面の構成を読めない({e})')
    for node in tree.iter('node'):
        labels = (node.get('text') or '', node.get('content-desc') or '')
        if any(text == label or text in label.splitlines() for label in labels):
            found = BOUNDS.match(node.get('bounds', ''))
            if found:
                x1, y1, x2, y2 = map(int, found.groups())
                return (x1 + x2) // 2, (y1 + y2) // 2
    raise MeasureError(f'「{text}」が画面に無い')


def tap_point(step, run=run):
    tap = step['tap']
    if 'text' in tap:
        adb('shell', 'uiautomator', 'dump', REMOTE_UI, run=run, timeout=30)
        _, xml_text, _ = adb('shell', 'cat', REMOTE_UI, run=run)
        return find_text(xml_text, tap['text'])
    return tap['x'], tap['y']


def get_setting(namespace, key, run=run):
    _, out, _ = adb('shell', 'settings', 'get', namespace, key, run=run)
    return out.strip()


def restore_setting(namespace, key, value, run=run):
    """元の値に戻す。もともと無かった(null)なら消す。"""
    if value in ('', 'null'):
        adb('shell', 'settings', 'delete', namespace, key, run=run)
    else:
        adb('shell', 'settings', 'put', namespace, key, value, run=run)


def frame_times(video, run_bytes=run_bytes):
    code, out, err = run_bytes(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                                '-show_entries', 'frame=pts_time', '-of', 'csv=p=0', video])
    if code != 0:
        raise MeasureError(f'録画のコマの時刻を読めない({err.decode(errors="replace").strip()[-200:]})')
    times = []
    for line in out.decode().splitlines():
        field = line.strip().split(',')[0]
        if not field:
            continue
        try:
            times.append(float(field))
        except ValueError:
            raise MeasureError(f'録画のコマの時刻を読めない({field})')
    return times


def crop_frames(video, region, size, run_bytes=run_bytes):
    """録画の region({x, y, w, h}、録画の画素)を切り出し、size(幅, 高さ)に縮めた灰色の画素を、コマごとに返す。"""
    w, h = size
    crop = f"crop={region['w']}:{region['h']}:{region['x']}:{region['y']},scale={w}:{h},format=gray"
    code, out, err = run_bytes(['ffmpeg', '-v', 'error', '-i', video, '-fps_mode', 'passthrough',
                                '-vf', crop, '-f', 'rawvideo', '-'])
    if code != 0:
        raise MeasureError(f'録画のコマを取り出せない({err.decode(errors="replace").strip()[-200:]})')
    step = w * h
    return [out[i:i + step] for i in range(0, len(out) - step + 1, step)]


def to_video(region, screen, content):
    """画面の画素の場所を、録画の画素の場所に直す。content は録画の中の画面の場所 (x, y, w, h)。"""
    sx, sy = content[2] / screen[0], content[3] / screen[1]
    return {'x': content[0] + round(region['x'] * sx), 'y': content[1] + round(region['y'] * sy),
            'w': max(1, round(region['w'] * sx)), 'h': max(1, round(region['h'] * sy))}


def read_frames(video, board_region, screen, content, run_bytes=run_bytes):
    """録画から (時刻, 盤の場所の画素, 印の帯の画素) の並びを作る。board_region と screen は画面の画素。"""
    times = frame_times(video, run_bytes=run_bytes)
    mark = {'x': 0, 'y': 0, 'w': screen[0], 'h': max(1, screen[1] // MARK_RATIO)}
    boards = crop_frames(video, to_video(board_region, screen, content), (BOARD_SIZE, BOARD_SIZE), run_bytes=run_bytes)
    marks = crop_frames(video, to_video(mark, screen, content), (MARK_W, MARK_H), run_bytes=run_bytes)
    if not (len(times) == len(boards) == len(marks)):
        raise MeasureError(f'録画のコマの数が合わない(時刻 {len(times)}、盤 {len(boards)}、帯 {len(marks)})')
    return list(zip(times, boards, marks))


def check_image(video, indexes, out, run_bytes=run_bytes):
    """確かめ用に、録画のコマ(番号)を横に並べた画像を作る。"""
    picks = sorted(set(indexes))
    select = '+'.join(f'eq(n\\,{i})' for i in picks)
    code, _, err = run_bytes(['ffmpeg', '-v', 'error', '-y', '-i', video, '-fps_mode', 'passthrough', '-vf',
                              f"select='{select}',scale={CHECK_WIDTH}:-2,tile={len(picks)}x1",
                              '-frames:v', '1', out])
    if code != 0:
        raise MeasureError(f'確かめ用の画像を作れない({err.decode(errors="replace").strip()[-200:]})')


def _record_last_tap(xy, size, local, run, popen, sleep):
    """録画を回しながら最後の 1 つを押し、録画を local に取り出す。録画の中の画面の場所 (x, y, w, h) を返す。"""
    adb('shell', 'rm', '-f', REMOTE_VIDEO, run=run)
    proc = popen([ADB, 'shell', 'screenrecord', '--verbose', '--size', f'{size[0]}x{size[1]}',
                  '--bit-rate', '8000000', REMOTE_VIDEO],
                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    sleep(RECORD_LEAD_S)
    adb('shell', 'input', 'tap', str(xy[0]), str(xy[1]), run=run)
    sleep(RECORD_TAIL_S)
    adb('shell', 'pkill', '-INT', 'screenrecord', run=run)
    try:
        log, _ = proc.communicate(timeout=15)
    except subprocess.TimeoutExpired:
        proc.kill()
        raise MeasureError('録画が止まらない')
    found = CONTENT.search(log or '')
    if not found:
        raise MeasureError(f'録画の中の画面の場所を読めない({(log or "").strip()[-200:]})')
    code, _, err = adb('pull', REMOTE_VIDEO, local, run=run, timeout=120)
    if code != 0:
        raise MeasureError(f'録画を取り出せない({err.strip()[-200:]})')
    w, h, x, y = map(int, found.groups())
    return x, y, w, h


def measure_once(script, n, workdir, screen, component, keep_dir=None, run=run, run_bytes=run_bytes,
                 popen=subprocess.Popen, sleep=time.sleep):
    adb('shell', 'am', 'force-stop', script['package'], run=run)
    adb('shell', 'am', 'start', '-W', '-n', component, run=run, timeout=120)
    sleep(script['settle_s'] + 2.0)
    for step in script['steps'][:-1]:
        x, y = tap_point(step, run=run)
        adb('shell', 'input', 'tap', str(x), str(y), run=run)
        sleep(script['settle_s'])
    last = tap_point(script['steps'][-1], run=run)
    # 「ポインタの位置」を点け直し、上端の帯を押す前の形(P: 0 / 0)に戻す。前に押した跡が残ると、最後の押下で帯が変わらない。
    adb('shell', 'settings', 'put', 'system', 'pointer_location', '0', run=run)
    adb('shell', 'settings', 'put', 'system', 'pointer_location', '1', run=run)
    sleep(1.0)
    local = os.path.join(workdir, f'{n}.mp4')
    content = _record_last_tap(last, record_size(screen), local, run, popen, sleep)
    name = f"{script['app']}-{n}"
    if keep_dir:
        shutil.copyfile(local, os.path.join(keep_dir, name + '.mp4'))
    frames_list = read_frames(local, script['board_region'], screen, content, run_bytes=run_bytes)
    try:
        tap, board = fr.detect(frames_list, observe_s=OBSERVE_S)
    except fr.FrameError as e:
        raise MeasureError(f'録画から測れない({n} 回目: {e})')
    ms = round((frames_list[board][0] - frames_list[tap][0]) * 1000)
    if keep_dir:
        with open(os.path.join(keep_dir, name + '.json'), 'w', encoding='utf-8') as f:
            json.dump({'tap_s': frames_list[tap][0], 'board_s': frames_list[board][0], 'ms': ms,
                       'tap_frame': tap, 'board_frame': board}, f)
        check_image(local, (tap - 1, tap, board), os.path.join(keep_dir, name + '.png'), run_bytes=run_bytes)
    return ms


def measure(script_path, runs=5, keep_dir=None, run=run, run_bytes=run_bytes, popen=subprocess.Popen, sleep=time.sleep):
    reason = device_ready(run=run)
    if reason:
        return metric([], reason)
    try:
        script = load_script(script_path)
        screen = screen_size(run=run)
        component = launcher_component(script['package'], run=run)
    except MeasureError as e:
        return metric([], str(e))
    if keep_dir:
        os.makedirs(keep_dir, exist_ok=True)
    before = get_setting('system', 'pointer_location', run=run)
    times = []
    try:
        with tempfile.TemporaryDirectory() as workdir:
            for n in range(1, runs + 1):
                times.append(measure_once(script, n, workdir, screen, component, keep_dir, run=run,
                                          run_bytes=run_bytes, popen=popen, sleep=sleep))
    except MeasureError as e:
        return metric([], str(e))
    except subprocess.TimeoutExpired as e:
        return metric([], f'adb か ffmpeg が時間内に答えなかった({e})')
    finally:
        restore_setting('system', 'pointer_location', before, run=run)
    return metric(times)


def main(argv=None, **deps):
    parser = argparse.ArgumentParser(description='出題の時間')
    parser.add_argument('script')
    parser.add_argument('--runs', type=int, default=5)
    parser.add_argument('--keep', help='各回の録画と確かめ用の画像を残すディレクトリ')
    parser.add_argument('--record', help='結果を書き込む perf.json(台本の app を id に使う)')
    parser.add_argument('--note', default='', help='測れたときに理由欄へ書く、条件の違い')
    args = parser.parse_args(argv)
    result = measure(args.script, args.runs, keep_dir=args.keep, **deps)
    if result['status'] == 'ok' and args.note:
        result['reason'] = args.note
    if args.record:
        try:
            app_id = load_script(args.script)['app']
        except MeasureError as e:
            print(f'perf.json に書けない: {e}')
            return 2
        record(args.record, app_id, 'new_game_ms', result)
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(合わせて 54 件)。人工の動画のテスト(VideoTest)が飛ばされず(`skipped` が出ない)、前後 1 コマ(30 コマ/秒で 34ms)以内で通ること。

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/perf/new_game.py tool/tests/test_new_game.py
git commit -m "feat: 性能の道具(出題の時間。台本・録画・コマの取り出し)"
```

---

### Task 11: 第 3 層のまとめと、台帳に書く欠けの行

**Files:**
- Create: `twoyearsold_ui/tool/market_report.py`
- Test: `twoyearsold_ui/tool/tests/test_market_report.py`

**Interfaces:**
- Consumes: `market_check.MARKET`(Task 2)
- Produces:
  - `market_report.load(app_dir: str) -> tuple[dict, dict, Optional[dict]]`
  - `market_report.covered(feature: dict, owner_only: bool) -> bool`
  - `market_report.feature_gaps(features: dict, ids: list[str], owner_only: bool = True) -> list[tuple[dict, int, int]]`
  - `market_report.perf_gaps(perf: Optional[dict]) -> list[str]`
  - `market_report.gap_lines(competitors, features, perf) -> list[str]`(仕様 4.6 の形。オーナーの線の内側だけ)
  - `market_report.render(app: str, competitors, features, perf) -> str`(README.md の中身。線がまだの行は「仕分けどおりなら欠け」として別に見せる)
  - `market_report.main(argv=None, root=ROOT) -> int`

- [ ] **Step 1: 失敗するテストを書く**

```python
import contextlib
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import market_report  # noqa: E402

COMPETITORS = {'chosen_on': '2026-10-15', 'criteria': 'x', 'apps': [
    {'id': 'c01', 'name': 'A', 'play': 'com.a', 'app_store': None, 'price_model': 'free_with_ads',
     'rating': 4.7, 'ratings_count': 10, 'why': 'JP 1 位', 'on_android': True},
    {'id': 'c02', 'name': 'B', 'play': 'com.b', 'app_store': None, 'price_model': 'paid',
     'rating': 4.1, 'ratings_count': 5, 'why': 'US 2 位', 'on_android': True}]}


def feature(fid, self_value, c01, c02, proposal, owner):
    return {'id': fid, 'name': fid.upper(), 'kind': 'feature',
            'has': {'self': {'value': self_value, 'evidence': 'quote: x'},
                    'c01': {'value': c01, 'evidence': 'quote: x'},
                    'c02': {'value': c02, 'evidence': 'quote: x'}},
            'proposal': {'decision': proposal, 'reason': 'r',
                         'exclude_category': 'ads' if proposal == 'exclude' else None},
            'owner': {'decision': owner, 'date': '2026-10-16' if owner else None, 'note': ''}}


FEATURES = {'features': [
    feature('daily', 'no', 'yes', 'no', 'cover', 'cover'),
    feature('ads_free', 'no', 'yes', 'yes', 'exclude', 'exclude'),
    feature('themes', 'no', 'yes', 'yes', 'cover', None),
    feature('notes', 'yes', 'yes', 'yes', 'cover', 'cover'),
]}


def ok(*runs):
    return {'runs': list(runs), 'median': sorted(runs)[len(runs) // 2], 'status': 'ok', 'reason': ''}


def unmeasured(reason):
    return {'runs': [], 'median': None, 'status': 'unmeasured', 'reason': reason}


PERF = {'device': {'avd': 'a', 'image': 'i', 'host': 'h'}, 'measured_on': '2026-10-15',
        'conditions': {'new_game': 'Classic・9×9・中くらいの難しさ'},
        'apps': {'self': {'cold_start_ms': ok(300), 'new_game_ms': ok(50)},
                 'c01': {'cold_start_ms': ok(200), 'new_game_ms': ok(80)},
                 'c02': {'cold_start_ms': unmeasured('広告で止まる'), 'new_game_ms': unmeasured('台本が壊れた')}}}


class MarketReportTest(unittest.TestCase):
    def test_gap_lines_follow_the_owner_line_and_the_spec_format(self):
        lines = market_report.gap_lines(COMPETITORS, FEATURES, PERF)
        self.assertIn('- [market] 競合 1/2 が持つ「DAILY」が無い(根拠: quality/market/features.json の daily)', lines)
        self.assertFalse(any('ADS_FREE' in line or 'THEMES' in line or 'NOTES' in line for line in lines))
        self.assertIn('- [perf] 起動の速さが競合の最良値(c01 の 200ms)を上回っていない(自作 300ms)'
                      '(根拠: quality/market/perf.json)', lines)
        self.assertFalse(any('出題の時間' in line for line in lines))

    def test_unmeasured_self_is_a_perf_gap(self):
        perf = json.loads(json.dumps(PERF))
        perf['apps']['self']['new_game_ms'] = unmeasured('x')
        lines = market_report.perf_gaps(perf)
        self.assertTrue(any('出題の時間' in line and '自作が未計測' in line for line in lines))

    def test_readme_shows_tables_marks_and_rows_still_waiting_for_the_owner(self):
        text = market_report.render('NumberPlace', COMPETITORS, FEATURES, PERF)
        for part in ('# NumberPlace の市場との比較', '| c01 | A |', '| DAILY |', '○', '×',
                     '起動の速さ', '未計測(広告で止まる)'):
            self.assertIn(part, text)
        gaps = text.split('## 欠け')[1]
        self.assertIn('DAILY', gaps)
        self.assertIn('THEMES', gaps.split('オーナーの線がまだの行')[1])
        self.assertNotIn('ADS_FREE', gaps)

    def test_main_writes_readme_and_prints_gaps(self):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, ignore_errors=True)
        market = os.path.join(tmp, 'Demo', 'quality', 'market')
        os.makedirs(market)
        for name, data in (('competitors.json', COMPETITORS), ('features.json', FEATURES), ('perf.json', PERF)):
            with open(os.path.join(market, name), 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(market_report.main(['Demo', '--write'], root=tmp), 0)
            self.assertEqual(market_report.main(['Demo', '--gaps'], root=tmp), 0)
            self.assertEqual(market_report.main(['Nope', '--gaps'], root=tmp), 2)
        self.assertTrue(os.path.exists(os.path.join(market, 'README.md')))
        self.assertIn('- [market] 競合 1/2 が持つ「DAILY」が無い', out.getvalue())


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: FAIL(`No module named 'market_report'`)

- [ ] **Step 3: 実装する**

```python
# coding: utf-8
"""第 3 層のまとめ — quality/market の記録から、人が読むまとめ(README.md)と、台帳に書く欠けの行を作る。

使い方:
  python3 twoyearsold_ui/tool/market_report.py <AppName> --write   # quality/market/README.md を書く
  python3 twoyearsold_ui/tool/market_report.py <AppName> --gaps    # 台帳の「課題」に書く行を出す(オーナーの線の内側だけ)
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
sys.path.insert(0, HERE)
from market_check import MARKET  # noqa: E402

MARK = {'yes': '○', 'no': '×', 'unknown': '?'}
METRIC_NAMES = {'cold_start_ms': '起動の速さ', 'new_game_ms': '出題の時間'}
DECISIONS = {'cover': '網羅する', 'exclude': '外す', 'ask': '伺う', None: '未'}


def load(app_dir):
    """(competitors, features, perf) を返す。perf は無ければ None。"""
    market = os.path.join(app_dir, MARKET)

    def read(name, required=True):
        path = os.path.join(market, name)
        if not os.path.exists(path):
            if required:
                raise FileNotFoundError(path)
            return None
        with open(path, encoding='utf-8') as f:
            return json.load(f)

    return read('competitors.json'), read('features.json'), read('perf.json', required=False)


def covered(feature, owner_only):
    """線の内側(網羅する)か。owner_only なら、オーナーの決定だけを見る。"""
    decision = feature['owner']['decision']
    if decision is not None:
        return decision == 'cover'
    return not owner_only and feature['proposal']['decision'] == 'cover'


def feature_gaps(features, ids, owner_only=True):
    """[(機能, 持っている競合の数, 競合の数)] — 線の内側で、自作が持っていないもの。"""
    out = []
    for f in features['features']:
        if covered(f, owner_only) and f['has']['self']['value'] != 'yes':
            have = sum(1 for cid in ids if f['has'][cid]['value'] == 'yes')
            out.append((f, have, len(ids)))
    return out


def perf_gaps(perf):
    """性能の各項目で、自作が競合の最良値を上回っていなければ、台帳の行を返す。"""
    if not perf:
        return []
    lines = []
    apps = perf['apps']
    for metric, name in METRIC_NAMES.items():
        rivals = [(cid, m[metric]['median']) for cid, m in apps.items()
                  if cid != 'self' and m[metric]['status'] == 'ok']
        if not rivals:
            continue
        best_id, best = min(rivals, key=lambda r: r[1])
        mine = apps['self'][metric]
        if mine['status'] != 'ok':
            lines.append(f'- [perf] {name}は自作が未計測({mine["reason"]})(根拠: quality/market/perf.json)')
        elif mine['median'] >= best:
            lines.append(f'- [perf] {name}が競合の最良値({best_id} の {best}ms)を上回っていない'
                         f'(自作 {mine["median"]}ms)(根拠: quality/market/perf.json)')
    return lines


def gap_lines(competitors, features, perf):
    ids = [a['id'] for a in competitors['apps']]
    lines = [f'- [market] 競合 {have}/{total} が持つ「{f["name"]}」が無い(根拠: quality/market/features.json の {f["id"]})'
             for f, have, total in feature_gaps(features, ids, owner_only=True)]
    return lines + perf_gaps(perf)


def _cell(metric):
    if metric['status'] == 'ok':
        return f'{metric["median"]}ms' + (f'({metric["reason"]})' if metric['reason'] else '')
    return f'未計測({metric["reason"]})'


def render(app, competitors, features, perf):
    ids = [a['id'] for a in competitors['apps']]
    out = [f'# {app} の市場との比較', '',
           f'競合は {competitors["chosen_on"]} に選んだ({competitors["criteria"]})。'
           'このファイルは `twoyearsold_ui/tool/market_report.py --write` で作る(手で直さない)。', '',
           '## 競合', '', '| id | 名前 | ストア | 価格の形 | 評価 | 選んだ理由 |', '|---|---|---|---|---|---|']
    for a in competitors['apps']:
        stores = [s for s in (a['play'] and f'Play {a["play"]}', a['app_store'] and f'App Store {a["app_store"]}') if s]
        rating = a['rating'] if a['rating'] is not None else '−'
        out.append(f'| {a["id"]} | {a["name"]} | {" / ".join(stores)} | {a["price_model"]} | {rating} | {a["why"]} |')
    out += ['', '## 機能とモード', '',
            '| 機能 | 種類 | 自作 | ' + ' | '.join(ids) + ' | 仕分け | 理由 | オーナー |',
            '|---|---|---|' + '---|' * len(ids) + '---|---|---|']
    for f in features['features']:
        cells = ' | '.join(MARK[f['has'][cid]['value']] for cid in ids)
        out.append(f'| {f["name"]} | {f["kind"]} | {MARK[f["has"]["self"]["value"]]} | {cells} | '
                   f'{DECISIONS[f["proposal"]["decision"]]} | {f["proposal"]["reason"]} | {DECISIONS[f["owner"]["decision"]]} |')
    if perf:
        out += ['', '## 性能', '',
                f'条件: {perf["conditions"]["new_game"]}。機種: {perf["device"]["avd"]}({perf["device"]["image"]})。'
                f'測った日: {perf["measured_on"]}。値は中央値。', '',
                '| アプリ | 起動の速さ | 出題の時間 |', '|---|---|---|']
        for key, m in perf['apps'].items():
            out.append(f'| {key} | {_cell(m["cold_start_ms"])} | {_cell(m["new_game_ms"])} |')
    gaps = feature_gaps(features, ids, owner_only=True)
    slow = perf_gaps(perf)
    pending = [g for g in feature_gaps(features, ids, owner_only=False) if g[0]['owner']['decision'] is None]
    out += ['', '## 欠け', '']
    for f, have, total in gaps:
        out.append(f'- {f["name"]}(競合 {have}/{total} が持つ)')
    for line in slow:
        out.append(line.replace('- [perf] ', '- '))
    if not gaps and not slow:
        out.append('オーナーの線の内側に、欠けはありません。')
    if pending:
        out += ['', 'オーナーの線がまだの行のうち、Claude の仕分けどおりなら欠けになるもの:', '']
        for f, have, total in pending:
            out.append(f'- {f["name"]}(競合 {have}/{total} が持つ。仕分け: {DECISIONS[f["proposal"]["decision"]]})')
    return '\n'.join(out) + '\n'


def main(argv=None, root=ROOT):
    parser = argparse.ArgumentParser(description='第 3 層のまとめ')
    parser.add_argument('app')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--write', action='store_true')
    group.add_argument('--gaps', action='store_true')
    args = parser.parse_args(argv)
    app_dir = os.path.join(root, args.app)
    try:
        competitors, features, perf = load(app_dir)
    except FileNotFoundError as e:
        print(f'記録が見つかりません: {e}')
        return 2
    if args.write:
        path = os.path.join(app_dir, MARKET, 'README.md')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(render(args.app, competitors, features, perf))
        print(f'書いた: {path}')
    else:
        for line in gap_lines(competitors, features, perf):
            print(line)
    return 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 通ることを確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -v`
Expected: `OK`(合わせて 58 件)

- [ ] **Step 5: Commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/market_report.py tool/tests/test_market_report.py
git commit -m "feat: 第 3 層のまとめと、台帳に書く欠けの行"
```

---

### Task 12: 機能の洗い出しと性能の測定(統括)

- [ ] **Step 1: 自作で道具を通す(前提 3 の最終確認)**

自作の台本 `NumberPlace/quality/market/scripts/self.json` を作る。ホームから「Classic・9×9・中くらいの難しさ(Medium、★3)」の新しい問題を始める押下の並びにする。押す場所は `adb shell uiautomator dump` で見て、文字(`text`)で引けなければ座標で書く。`board_region` は盤の場所(端末の画素)。

```bash
cd /Users/abe/dev/twoyearsold; M=NumberPlace/quality/market; KEEP="$SCRATCH/keep"
/usr/bin/python3 -B twoyearsold_ui/tool/perf/start_time.py net.twoyearsold.numberplace --record $M/perf.json --id self
/usr/bin/python3 -B twoyearsold_ui/tool/perf/new_game.py $M/scripts/self.json --keep "$KEEP" --record $M/perf.json
ffmpeg -v error -y -i "$KEEP/self-%d.png" -vf tile=1x5 -frames:v 1 "$KEEP/self-check.png"
```

`self-check.png` を Read で見る。各行の左から、押す前・押した瞬間(上端の帯が変わったコマ)・盤が落ち着いたコマになっていること。ずれていれば、台本(`board_region`、`settle_s`)を直して測り直す。道具の側の直しが要るなら、Ruling を書いて担当に渡す。

- [ ] **Step 2: 競合を 1 本ずつ触って、機能とモードを洗い出す**

1 本ずつエミュレータで開き、メニュー・設定・遊び方・変種を見て回る。根拠の画面の写しは縮小して保存する。

```bash
OUT=NumberPlace/quality/market/evidence/c01; mkdir -p $OUT
~/Library/Android/sdk/platform-tools/adb exec-out screencap -p > $OUT/settings.png && sips -Z 720 $OUT/settings.png >/dev/null
```

自作も同じように洗い出す(`evidence/self/`)。`features.json` に行(機能・モード・変種・設定)と升を書く。升の根拠は、写し(`evidence/…`)か、掲載文の引用(`quote: …`。App Store にしか無い競合や有料の競合)。「無い」は、確かめ方の記録(`note: …`)でもよい。根拠の無い升は `unknown`。

自作の掲載文(`store/play/listing/*/full.txt`・`short.txt`、`store/play/testers.md`)がうたう機能が、本当にアプリにあるかも確かめる(たとえば「デイリーチャレンジ」)。無いものは、`features.json` の行(自作は `no`)にし、言い過ぎの一覧として Task 13 でオーナーに伺う。

- [ ] **Step 3: 競合ごとの台本を作り、性能を測る(前提 4・5)**

Android にある競合ごとに、`scripts/<id>.json` を作り、Step 1 と同じ命令で測る(`--id <id>`)。条件(Classic・9×9・中くらい)にそろえられない競合は、近い条件で測り、`--note "<実際の条件>"` を付ける。アプリごとに `<id>-check.png` を作って目で確かめ、押した瞬間や盤のコマが違う回(広告の画面を盤と取り違えた、など)があれば、台本を直して測り直す。直せないときは、その測定を理由つきの `unmeasured` にする(`perf.json` を直接直し、`runs` を空・`median` を null・`reason` に理由)。

広告の揺れ(前提 4: 5 回の値のばらつきと、広告が出た回の数)と、かかった時間(前提 5)を `twoyearsold_ui/tool/perf/README.md` に書く。

- [ ] **Step 4: 測定の条件を書く**

`perf.json` の先頭に、測った条件を書き足す(`apps` はそのまま)。

```json
"device": {"avd": "yardstick_play_35", "image": "android-35 google_apis_playstore arm64-v8a", "host": "MacBook Pro M5 Pro / 24GB"},
"measured_on": "<測った日 YYYY-MM-DD>",
"conditions": {"new_game": "Classic・9×9・中くらいの難しさ"}
```

- [ ] **Step 5: 仕分けを書く**

`features.json` の各行に `proposal`(`cover` 網羅する / `exclude` 外す / `ask` 伺う)と理由を書く。外す行は `exclude_category`(`ads`・`iap`・`online`・`trademark`・`philosophy`)を付ける。見た目や遊び方が変わる行は `ask` にする。

- [ ] **Step 6: 形を確かめ、まとめを作り、終わりの条件を確かめる**

```bash
cd /Users/abe/dev/twoyearsold
/usr/bin/python3 -B twoyearsold_ui/tool/market_check.py NumberPlace; echo "exit=$?"
/usr/bin/python3 -B twoyearsold_ui/tool/market_report.py NumberPlace --write
/usr/bin/python3 -I -c "
import json; m='NumberPlace/quality/market/'
apps=json.load(open(m+'perf.json'))['apps']; comp=json.load(open(m+'competitors.json'))['apps']
android=[a['id'] for a in comp if a['on_android']]
print('起動の速さが測れていない Android の競合:', [i for i in android if apps.get(i,{}).get('cold_start_ms',{}).get('status')!='ok'])
print('出題の時間を測れた競合の数:', sum(1 for i in android if apps.get(i,{}).get('new_game_ms',{}).get('status')=='ok'))
print('自作:', apps['self']['cold_start_ms']['status'], apps['self']['new_game_ms']['status'])"
```

Expected: `pass` で exit 0。README.md ができる。起動の速さが測れていない Android の競合は `[]`、出題の時間を測れた競合は 7 以上、自作は `ok ok`(仕様 8 節)。満たさなければ、台本を直して測り直す。

- [ ] **Step 7: Commit(NumberPlace はローカルだけ)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace && git add quality/market && git commit -m "docs: 第 3 層の機能の一覧と性能の記録"
cd /Users/abe/dev/twoyearsold/twoyearsold_ui && git add tool/perf/README.md && git commit -m "docs: 性能の道具の前提の記録(広告の揺れと時間)"
```

---

### Task 13: ★オーナーの線と、欠けを台帳へ(統括 + オーナー)

- [ ] **Step 1: ★線を引いてもらう**

README.md の一覧の要点(行ごとの、競合の何本が持つか、仕分け、理由)を見せる。AskUserQuestion で、`ask` の行と、`cover` / `exclude` の仕分けを変えたい行を伺う(行が多ければ、まとまりごとに数回に分ける)。掲載文の言い過ぎ(Task 12 Step 2)は、掲載文を直すか、機能を足す欠けとして積むかを伺う。答えを `features.json` の `owner` に書く(すべての行に、決定と日付)。

- [ ] **Step 2: 欠けを台帳へ**

```bash
cd /Users/abe/dev/twoyearsold
/usr/bin/python3 -B twoyearsold_ui/tool/market_report.py NumberPlace --write
/usr/bin/python3 -B twoyearsold_ui/tool/market_report.py NumberPlace --gaps
```

出た行と、掲載文の言い過ぎ(`- [store] 掲載文が「…」をうたうが、アプリに無い(根拠: store/play/listing/<言語>/full.txt:<行>)`)を、運用リポジトリの `ledger/NumberPlace.md` の「課題」に足す。運用リポジトリを commit して push する。

- [ ] **Step 3: 入口がすべて合格であることを確かめる**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/gate.py NumberPlace --json NumberPlace/quality/gate.json; echo "exit=$?"
cd NumberPlace && git add quality && git commit -m "docs: オーナーの線と、入口の結果"
```

Expected: `market` が `pass`、exit 0。

- [ ] **Step 4: push を確かめる**

`twoyearsold_ui` を push する(承認済み)。NumberPlace の commit(`quality/`、`store/play/README.md`)は Web 版の公開を走らせるので、push してよいかをオーナーに伺ってから push する。

- [ ] **Step 5: 報告**

オーナーに、欠けの一覧と、次に立てる改良の計画のまとまり(例: 足りない機能、出題の速さ、掲載文)を報告する。測定用のエミュレータは、次の測り直しのために残す(消すかはオーナーに伺う)。
