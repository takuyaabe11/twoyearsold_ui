# 愛の地図(NumberPlace) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ナンプレを愛する人たちが愛しているものを観点の地図にまとめ、NumberPlace を観点ごとに評価し、オーナーに線を引いてもらい、追う観点を gate の love 検査で毎回確かめられるようにする。

**Architecture:** 共有の道具を `twoyearsold_ui/tool/` に置く。記録の形の検査と強さの計算は `love_schema.py`(JSON だけを見る)、今のコードの判定・追う観点の確かめ・gate の入口は `love_check.py`、文書の生成は `love_report.py`、遅い測定は `love_measure.py`。gate の `market` を `love` に替える。記録は NumberPlace の `quality/love/` に置き、`findings.json` と `love.json` を単一の出所にして、`map.md` と `assessment.md` を生成する。担当が作るコードの Task(3〜10)と、統括が見張りながら行う Task(1・2・11〜18。片付け・前提・調べる・まとめる・評価する・オーナーの番)が並ぶ。

**Tech Stack:** Python 3.9(`/usr/bin/python3`、標準ライブラリだけ)、unittest、git、Flutter(`flutter test`・`flutter build apk`)、adb、Android エミュレータ `yardstick_play_35`。

**Spec:** `twoyearsold_ui/docs/superpowers/specs/2026-10-15-numberplace-love-map-design.md`

## 計画の前に確かめたこと(2026-10-15)

1. 自作の台本 `NumberPlace/quality/market/scripts/self.json` には、起動の速さを測るための `ready_region` がある(仕様 12 章の 5 は満たしている)。見本は `scripts/refs/self-new_game.json`。
2. 性能の道具(`perf/launch_time.py`・`perf/new_game.py`)は、結果を標準出力の最後の行に JSON(`runs`・`median`・`status`・`reason`)で出して exit 0 で終わる。端末とのつながりの失敗は exit 3 で、JSON を出さない。`--record` は旧形式(`perf.json`)なので使わない。
3. release ビルドの署名は、`~/keystores/key.properties` があればアップロード鍵、無ければ debug 鍵(`NumberPlace/android/app/build.gradle.kts` の 9〜51 行)。前に入れた自作と鍵が違うと、`adb install -r` は署名の違いで失敗する。
4. NumberPlace は共有パッケージを git の版(`pubspec.lock` の `resolved-ref`)で参照していて、`pubspec_overrides.yaml` は無い。
5. 「今のコード」の判定(Task 6 のコード)を、実際の NumberPlace のリポジトリで読み取りだけ試した。HEAD は今のコードと出て、`lib/` を最後に変えた commit の 1 つ前は「アプリのコードが、記録の commit の後に変わった」と出た。
6. 前回の試しの測定には、負荷と値の対応の記録が残っていない。負荷の上限は Task 2 で測って決める。
7. twoyearsold_ui は公開、NumberPlace と twoyearsold-ops は非公開のリポジトリ。NumberPlace の `quality/market/` は、`competitors.json` が commit 済みで、`scripts/` と `evidence/` は commit していない(4.2MB)。機能表の下書きは作業場の `market/` にあり、作業場はセッションが変わると消えうる。
8. NumberPlace のパッケージ名は `number_place`。答えがひとつかは `SudokuSolver(dim).hasUniqueSolution(givens)`、出題は `PuzzleGenerator(dim).generate(difficulty: ..., rng: ...)`(`lib/domain/solver.dart`・`lib/domain/generator.dart`)。`test/` に `flutter_test_config.dart` は無い。
9. この計画に載せたコードとテスト(新しく 85 件。market のテスト 18 件を外して、合わせて 157 件)は、下書きの場で Python 3.9.6 を使い Task ごとに組み立てて走らせた。各 Task のテストが実装の前に Expected の理由で落ち、実装の後に通ること、警告が出ないことを確かめてから載せた。

## 計画で決めたこと(仕様の細部)

- 仕様 11.1 の `love_check.py` の役割を、2 つのファイルに分ける。形の検査と層・強さの計算は `love_schema.py`(JSON だけを見る)、今のコードの判定・追う観点の確かめ・gate の入口は `love_check.py`。役割そのものは仕様のまま。
- 測定の条件(エミュレータの名前・負荷の上限・回数)は、コードの定数にせず `NumberPlace/quality/love/measure/conditions.json` に置く。値は Task 2 で測って決める。
- `fix_order` に必ず入れるのは、追う観点のうち最終の段が `lacks` か `violates` のもの(直す所があるもの)。応えている追う観点は入れなくてよい。
- `love_check.check` は、形の理由と観点ごとの結果を分けて返す。gate の `detail` には、`love_check.failures` で両方を並べる。
- 所見の id の範囲を、調べる係ごとに分ける。毎日解く人は `f001`〜`f199`、解き筋を極める愛好家は `f201`〜`f399`、変種を楽しむ人は `f401`〜`f599`、アプリと問題集の声は `f601`〜`f799`。
- 評価の根拠の画面の写しは、`quality/love/evidence/a/` と `evidence/b/` に、幅 720 に縮めて `<観点の id>-<番号>.png` の名前で置く。
- A の評価は、B が終わるまで作業場に置き、リポジトリに入れない。B が見て偏らないようにするため。

## Global Constraints

- 道具は `twoyearsold_ui/tool/` に置き、Python 3.9(`/usr/bin/python3`)の標準ライブラリだけで書く。外部の命令は `git`・`flutter`・`adb` と、性能の道具(`tool/perf/`)。
- テストは `twoyearsold_ui/tool/tests/` に置き、`cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests` で走らせる。1 つのファイルだけなら、末尾に `-p <ファイル名>` を足す。
- コメントと文面は日本語、識別子は英語。先頭の docstring に使い方を書く。
- 公開のリポジトリ(twoyearsold_ui)には、他社の作品名と商標の語(`tool/rights_terms.json` の語)を書かない。テストの見本の値にも使わない。商標の語は、非公開の `NumberPlace/quality/love/` の中だけに置く。
- 生成物(`map.md`・`assessment.md`)は、表を使わず見出しと箇条書きで書く。手で直さない。
- 記録の形は仕様 10 章のとおり。値の集まりは次のとおり。
  - `layer`: daily・expert・variant・any
  - `channel`: words・reviews
  - `kind`: love・harm
  - `grade`: meets・lacks・violates・unverified
  - `effort`: small・medium・large
  - `decision`: pursue・skip・hold
  - `verify`: machine・human・both
  - `check.kind`: command・measure
  - `tool`: launch_time・new_game
  - 人の確かめの `result`: pass・fail
- 観点は 10〜20。各観点の根拠は 2 つ以上で、発信者が 2 つ以上別。強さは、3 層か発信者 5 以上で strong、2 層か発信者 3 以上で medium、ほかは weak。
- 引用は 15 語未満かつ 60 字未満、1 つの所見に 1 つまで。
- アプリのコードの範囲は `lib/`・`assets/`・`android/`・`ios/`・`web/`・`pubspec.yaml`・`pubspec.lock`。
- gate の検査は analyze・test・quality・i18n・rights・licenses・love の 7 つ。`love.json` が無いアプリは unmeasured。
- 調べるときは、reddit・ログインが要る所・紙の本の中身を使わない。
- 人の確かめは、オーナー(か、オーナーが頼んだ人)が行う。Claude がエミュレータで代わりに見たものは数えない。
- Claude はパスワードを入力も表示もしない。鍵は `~/keystores/` に置いたまま扱う。アカウントの作成・ログイン・購入はしない。広告は押さない。
- 消すのは、git の履歴に残るもの(`git rm`)と、この計画で作った一時のファイルだけ。測定用のエミュレータからアプリを消す(`adb uninstall`)ときは、先にオーナーに確かめる。
- push: 仕様 9.4 のとおり、twoyearsold_ui の旧計画の commit とこの計画の commit、NumberPlace の commit は、Task 18 でまとめてオーナーに確かめる。twoyearsold-ops への push は承認済み。
- PK は別のセッションが作業中なので触らない。Mac で動いている別のセッションの処理を止めない。
- 係(subagent)への依頼文は日本語で書く。調べる係と評価の係は、最も能力の高いモデルで立てる。
- 統括の Task の `$SCRATCH` は `/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad`(この計画を書いたセッションの作業場。機能表の下書きがある)。
- commit のメッセージは日本語で書き(型 `feat:` などは原文)、末尾に `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` を付ける。

## Review Focus

1. love.json や findings.json の値の型が違う(文字列の所に配列、根拠が文字列 1 つ、owner が文字列): 形の検査は例外で落ちず、broken の理由を出す。→ Task 3 `test_wrong_types_do_not_raise`、Task 4 `test_wrong_types_do_not_raise_and_are_broken`
2. 評価の根拠が、決まったフォルダやアプリの外を指す(`evidence/../love.json`、外へのリンク、`code: ../Other/...`、`code: lib/a.dart:0`、行数を超える行): broken にする。→ Task 4 `test_evidence_strings_need_a_known_prefix_and_an_existing_target`、Task 5 の `test_evidence_and_measure_refs_must_exist_inside_their_folders` ほか 2 件
3. 記録の commit が、短い sha・存在しない sha・枝の名前・オプションに見える文字列である、または git が無い・止まる: 今のコードの判定は例外で落ちず、理由を出す。→ Task 6 `test_short_shas_and_names_resolve_and_unknown_ones_do_not`、`test_a_missing_or_hanging_git_is_reported`
4. 速い確かめの命令が、大量に出力する・時間切れになる・見つからない: その観点だけを fail にし(理由は短く)、ほかの観点の確かめは続ける。→ Task 7 `test_a_failing_command_fails_only_its_aspect`、`test_a_hanging_command_is_cut_off`
5. 生成の書きかけと、所見だけの段階: `map.md` と `assessment.md` は一時ファイルから置き換え、前のものを壊さない。`love.json` が無くても `map.md` は作れる。→ Task 9 `test_a_failed_write_keeps_the_previous_document`、`test_findings_alone_write_only_the_map`

---

### Task 1: 旧方針の片付け(統括)

**Files:**
- Create: `NumberPlace/quality/market/features.json`(作業場の機能表の下書きから作る)
- Move: `NumberPlace/quality/market/scripts/self.json` → `NumberPlace/quality/love/measure/scripts/self.json`
- Move: `NumberPlace/quality/market/scripts/refs/self-new_game.json` → `NumberPlace/quality/love/measure/scripts/refs/self-new_game.json`
- Remove(履歴に残したうえで): `NumberPlace/quality/market/`
- Modify: `twoyearsold_ui/docs/superpowers/specs/2026-10-14-numberplace-yardstick-design.md`(1 行目の次)
- Modify: `twoyearsold_ui/docs/superpowers/plans/2026-10-14-numberplace-yardstick.md`(1 行目の次)
- Modify: `twoyearsold_ui/docs/superpowers/specs/2026-10-14-ecosystem-design.md`(113 行目「### 4.3 第 3 層: 市場との比較(新設)」の次)
- Modify(git の外): `twoyearsold_ui/.superpowers/sdd/2026-10-14-numberplace-yardstick/progress.md`

**Interfaces:**
- Produces: 機能表の下書きの commit(Task 12 の `coverage_check.checklist_commit` に使う。台帳に `Task 1: checklist_commit = <hash>` と書く)。自作の台本 `NumberPlace/quality/love/measure/scripts/self.json`(Task 2・10・16 が使う)。

- [ ] **Step 1: 機能表の下書きを、旧方針の記録の場所に置く**

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
cd $SCRATCH/market && /usr/bin/python3 -B features_build.py /Users/abe/dev/twoyearsold/NumberPlace/quality/market/features.json
```

Expected: `rows 44`。作業場の `market/` が消えていたら、代わりの元は無いので、止まってオーナーに伝える。

- [ ] **Step 2: 中身を確かめる**

Run: `/usr/bin/python3 -c "import json; d=json.load(open('/Users/abe/dev/twoyearsold/NumberPlace/quality/market/features.json')); print(len(d['features']), d['features'][0]['id'])"`
Expected: `44 classic_9x9`

- [ ] **Step 3: 旧方針の記録を、まだ commit していない分も含めて履歴に残す**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
git add quality/market
git commit -m "docs: 旧方針(市場の上位との比較)の記録 — 台本・見本・画面の写し・機能表の下書き" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git rev-parse --short HEAD
```

Expected: commit に `quality/market/scripts/`・`quality/market/evidence/`・`quality/market/features.json` が入る(`git show --stat HEAD` で確かめる)。表示された hash を台帳に `Task 1: checklist_commit = <hash>` と書く。

- [ ] **Step 4: 自作の台本を移し、旧方針の記録を作業のファイルから外す**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
mkdir -p quality/love/measure/scripts/refs
git mv quality/market/scripts/self.json quality/love/measure/scripts/self.json
git mv quality/market/scripts/refs/self-new_game.json quality/love/measure/scripts/refs/self-new_game.json
git rm -r -q quality/market
git commit -m "chore: 旧方針の記録を作業のファイルから外し、自作の台本を quality/love/measure/ に移す" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git ls-files quality/market | wc -l; ls quality/love/measure/scripts quality/love/measure/scripts/refs
```

Expected: `0`、`refs  self.json`、`self-new_game.json`

- [ ] **Step 5: 旧仕様・旧計画・全体の設計に、置き換えたことを 1 行ずつ足す**

旧仕様 `twoyearsold_ui/docs/superpowers/specs/2026-10-14-numberplace-yardstick-design.md` の 1 行目(見出し)の次に、空行とこの行を入れる:

```markdown
> 2026-10-15: この仕様は [愛の地図(NumberPlace)の設計](2026-10-15-numberplace-love-map-design.md) に置き換えた。市場の上位が品質の手本にならなかったため。
```

旧計画 `twoyearsold_ui/docs/superpowers/plans/2026-10-14-numberplace-yardstick.md` の 1 行目(見出し)の次に、空行とこの行を入れる:

```markdown
> 2026-10-15: この計画は、Task 12 の途中でオーナーの決定により中止した。後継は [愛の地図(NumberPlace)の計画](2026-10-15-numberplace-love-map.md)。
```

全体の設計 `twoyearsold_ui/docs/superpowers/specs/2026-10-14-ecosystem-design.md` の「### 4.3 第 3 層: 市場との比較(新設)」の次に、空行とこの行を入れる:

```markdown
> 2026-10-15: 3 層目の考え方は [愛の地図(NumberPlace)の設計](2026-10-15-numberplace-love-map-design.md) で置き換えた。市場の上位と比べるのではなく、ナンプレを愛する人が愛しているものに応えているかを確かめる。
```

- [ ] **Step 6: 旧計画の台帳に、中止の行を足す(git の外)**

`twoyearsold_ui/.superpowers/sdd/2026-10-14-numberplace-yardstick/progress.md` の末尾に:

```
Final: 中止 — 2026-10-15 オーナーの決定(上位の競合は品質の手本にならない)。後継の仕様は docs/superpowers/specs/2026-10-15-numberplace-love-map-design.md、計画は docs/superpowers/plans/2026-10-15-numberplace-love-map.md。git stash@{0}(待ってから押す・文字を待つテスト 3 件)は使わず、消さずに置く。
```

- [ ] **Step 7: commit(twoyearsold_ui)**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add docs/superpowers/specs/2026-10-14-numberplace-yardstick-design.md docs/superpowers/plans/2026-10-14-numberplace-yardstick.md docs/superpowers/specs/2026-10-14-ecosystem-design.md
git commit -m "docs: 旧仕様・旧計画・全体の設計に、愛の地図への置き換えを書く" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
grep -c '2026-10-15-numberplace-love-map' docs/superpowers/specs/2026-10-14-numberplace-yardstick-design.md docs/superpowers/plans/2026-10-14-numberplace-yardstick.md docs/superpowers/specs/2026-10-14-ecosystem-design.md
```

Expected: 3 つのファイルとも `1`。

### Task 2: 前提の確かめと測定の条件(統括)

仕様 12 章の 4・6・7 を確かめ、測定の条件を決める。

**Files:**
- Create: `NumberPlace/quality/love/measure/conditions.json`

**Interfaces:**
- Consumes: `NumberPlace/quality/love/measure/scripts/self.json`(Task 1)
- Produces: `conditions.json` の形 `{"avd": str, "image": str, "load_limit_1m": number, "runs": {"launch_time": int, "new_game": int}, "decided_on": "YYYY-MM-DD", "basis": str}`(Task 10 の `love_measure.py` が読む)。測定用のエミュレータに、今のコードの release ビルドが入った状態(Task 13・14 が使う)。

- [ ] **Step 1: 鍵の有無だけを確かめる(中身は読まない・表示しない)**

Run: `test -f ~/keystores/key.properties && echo ある || echo 無い`
Expected: `ある` か `無い`。台帳に `Task 2: Ruling: release の署名は <アップロード鍵|debug 鍵>` と書く。

- [ ] **Step 2: 測定用のエミュレータを動かす**

Run: `~/Library/Android/sdk/platform-tools/adb devices`
Expected: `emulator-5554	device` の行がある。無ければ `~/Library/Android/sdk/emulator/emulator -avd yardstick_play_35 -no-snapshot-save` を裏で走らせ、`adb wait-for-device` のあと `adb shell getprop sys.boot_completed` が `1` になるまで待つ。
Run: `~/Library/Android/sdk/platform-tools/adb emu avd name`
Expected: 1 行目が `yardstick_play_35`

- [ ] **Step 3: 今のコードを release でビルドして入れる(仕様 12 章の 6)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
flutter build apk --release
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Expected: `Built build/app/outputs/flutter-apk/app-release.apk`、`Success`。
`INSTALL_FAILED_UPDATE_INCOMPATIBLE` で失敗したら、前に入れた自作と署名が違う。オーナーに「測定用のエミュレータの NumberPlace を入れ直すため、そのアプリのデータ(これまでの測定で作ったものだけ)を消してよいか」を確かめ、許可があれば `adb uninstall net.twoyearsold.numberplace` のあとに入れ直す。台帳に Ruling を書く。

- [ ] **Step 4: 負荷を記録しながら、自作の起動と出題を 5 セット測る(仕様 12 章の 4)**

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
mkdir -p $SCRATCH/love_cond && cd /Users/abe/dev/twoyearsold
for i in 1 2 3 4 5; do
  before=$(sysctl -n vm.loadavg | awk '{print $2}')
  /usr/bin/python3 -B twoyearsold_ui/tool/perf/launch_time.py NumberPlace/quality/love/measure/scripts/self.json --runs 11 > $SCRATCH/love_cond/launch-$i.txt
  /usr/bin/python3 -B twoyearsold_ui/tool/perf/new_game.py NumberPlace/quality/love/measure/scripts/self.json --runs 5 > $SCRATCH/love_cond/new_game-$i.txt
  after=$(sysctl -n vm.loadavg | awk '{print $2}')
  echo "$i $before $after" >> $SCRATCH/love_cond/load.txt
done
```

Expected: 各ファイルの最後の行が `"status": "ok"` の JSON。20〜40 分かかるので、裏で走らせて終わりを待つ。出題が `unmeasured` で理由が見本の食い違いなら、自作の「新しいゲーム」の画面を出してから `python3 twoyearsold_ui/tool/perf/new_game.py NumberPlace/quality/love/measure/scripts/self.json --make-ref new_game` で見本を作り直し、測り直す。

- [ ] **Step 5: 揺れを見て、負荷の上限を決める**

規則: セットの負荷を「前後の大きい方」とする。負荷が L 以下のセットを集めたとき、起動と出題それぞれで、セットごとの中央値の(最大 − 最小)が、それらの中央値の中央値の 10% 以内に収まる。この条件を満たす L のうち、最も大きいものを上限にする。満たすセットが 3 未満なら、負荷が下がった時間にさらに 5 セットまで測る。それでも足りなければ、得られた中で最も揺れの小さい範囲の上端を上限にし、台帳に Ruling として書く。

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
/usr/bin/python3 - <<EOF
import json, statistics
rows = []
for line in open('$SCRATCH/love_cond/load.txt'):
    i, before, after = line.split()
    get = lambda name: json.loads([l for l in open(f'$SCRATCH/love_cond/{name}-{i}.txt') if l.startswith('{')][-1])['median']
    rows.append((max(float(before), float(after)), get('launch'), get('new_game')))
rows.sort()
for k in range(1, len(rows) + 1):
    part = rows[:k]
    for col, name in ((1, 'launch'), (2, 'new_game')):
        vals = [r[col] for r in part if r[col] is not None]
        if vals:
            spread = (max(vals) - min(vals)) / statistics.median(vals)
            print(f'L={part[-1][0]:.1f} sets={len(vals)} {name} medians={vals} spread={spread:.1%}')
EOF
```

Expected: 負荷ごとの揺れの一覧。規則で選んだ L と、そのときの揺れを台帳に書く。

- [ ] **Step 6: 測定の条件を書く**

`NumberPlace/quality/love/measure/conditions.json`(L と根拠は Step 5 の結果):

```json
{
  "avd": "yardstick_play_35",
  "image": "android-35 google_apis_playstore arm64-v8a",
  "load_limit_1m": 6.0,
  "runs": {"launch_time": 11, "new_game": 5},
  "decided_on": "2026-10-16",
  "basis": "負荷 3.1〜5.8 の 4 セットで、起動の中央値 1180〜1260ms(揺れ 6.6%)、出題 480〜515ms(揺れ 7.0%)"
}
```

上の `load_limit_1m`・`decided_on`・`basis` の値は形の例。Step 5 で決めた値に置き換える。

- [ ] **Step 7: `test/` の外のテストが動くかを試す(仕様 12 章の 7)**

`NumberPlace/love_test/probe_test.dart` を一時に作る:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:number_place/domain/board_dimensions.dart';
import 'package:number_place/domain/solver.dart';

void main() {
  test('love_test から lib の型を使える', () {
    expect(SudokuSolver(BoardDimensions.nine).hasUniqueSolution(List.filled(81, 0)), isFalse);
  });
}
```

Run: `cd /Users/abe/dev/twoyearsold/NumberPlace && flutter test love_test/probe_test.dart && flutter analyze love_test`
Expected: `All tests passed!`、`No issues found!`。確かめたら `rm love_test/probe_test.dart && rmdir love_test`(この Step で作ったものだけ)。動かなければ、理由と代わりの置き場所を台帳に Ruling で書き、Task 16 の置き場所をそれに合わせる。

- [ ] **Step 8: commit(NumberPlace)と台帳**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
git add quality/love/measure/conditions.json
git commit -m "chore: 遅い測定の条件(エミュレータ・負荷の上限・回数)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

台帳に、Step 1・3・5・7 の結果を `Task 2: Ruling: ...` の行で書く。

### Task 3: 所見の形の検査

**Files:**
- Create: `twoyearsold_ui/tool/love_schema.py`
- Create: `twoyearsold_ui/tool/tests/love_fixtures.py`
- Test: `twoyearsold_ui/tool/tests/test_love_schema_findings.py`

**Interfaces:**
- Produces:
  - `love_schema.LOVE`(`'quality/love'`)、値の集まり `LAYERS`・`COUNTED_LAYERS`・`CHANNELS`・`KINDS`・`GRADES`・`EFFORTS`・`DECISIONS`・`VERIFY`・`CHECK_KINDS`・`TOOLS`・`RESULTS`、数 `MIN_ASPECTS`・`MAX_ASPECTS`・`MIN_EVIDENCE`・`MIN_SOURCES`・`DEFAULT_TIMEOUT_S`、正規表現 `DATE`
  - `love_schema.Problems`(`bad(text)`・`todo(text)`・`pair() -> (broken, incomplete)`)
  - `love_schema.check_findings(data) -> tuple[list[str], list[str]]`(broken, incomplete)
  - `love_schema.findings_by_id(data) -> dict[str, dict]`
  - `love_schema.layer_counts(data) -> dict[str, int]`
  - 同じファイルの中で Task 4・5 が使う小道具 `_text`・`_one_of`・`_number`・`_str_list`
  - `love_fixtures.finding(fid, layer='daily', kind='love', source=None, **extra) -> dict`

- [ ] **Step 1: テストの見本と、落ちるテストを書く**

`twoyearsold_ui/tool/tests/love_fixtures.py`:

```python
"""愛の地図のテストの見本(所見と観点)。テストだけが使う。"""
import json
import os


def finding(fid, layer='daily', kind='love', source=None, **extra):
    """形の正しい所見 1 つ。発信者は既定で id ごとに別。"""
    f = {'id': fid, 'layer': layer, 'channel': 'words', 'kind': kind,
         'source': source or f'発信者 {fid}', 'title': f'題 {fid}', 'url': f'https://example.com/{fid}',
         'read_on': '2026-10-16', 'summary': f'要約 {fid}', 'quote': '', 'reading': ''}
    f.update(extra)
    return f
```

`twoyearsold_ui/tool/tests/test_love_schema_findings.py`:

```python
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import love_schema  # noqa: E402
from love_fixtures import finding  # noqa: E402


class FindingsTest(unittest.TestCase):
    def check(self, items):
        return love_schema.check_findings({'findings': items})

    def test_well_formed_findings_have_no_problems(self):
        self.assertEqual(self.check([finding('f001'), finding('f002', layer='any', kind='harm')]), ([], []))

    def test_no_findings_yet_is_incomplete_not_broken(self):
        self.assertEqual(self.check([]), ([], ['findings.json: 所見がまだ無い']))

    def test_values_outside_the_sets_are_broken(self):
        broken, _ = self.check([finding('f001', layer='casual', channel='forum', kind='like')])
        self.assertEqual(len(broken), 3)
        self.assertIn('layer は daily・expert・variant・any のどれか', broken[0])

    def test_ids_must_be_f_and_three_digits_and_unique(self):
        broken, _ = self.check([finding('f1'), finding('f001'), finding('f001')])
        self.assertIn('findings.json: findings[0]: id は f001 の形', broken)
        self.assertIn('findings.json: findings[2]: id f001 が重複', broken)

    def test_source_summary_url_and_date_are_required(self):
        broken, _ = self.check([finding('f001', source=' ', summary='', url='ftp://x', read_on='10/16')])
        self.assertEqual(sorted(broken), sorted([
            'findings.json: f001: source が空', 'findings.json: f001: summary が空',
            'findings.json: f001: url は http:// か https:// で始まる', 'findings.json: f001: read_on は YYYY-MM-DD']))

    def test_title_may_be_empty_but_must_be_text(self):
        self.assertEqual(self.check([finding('f001', title='')]), ([], []))
        self.assertEqual(self.check([finding('f001', title=None)])[0], ['findings.json: f001: title は文字列'])

    def test_quote_must_be_short(self):
        self.assertEqual(self.check([finding('f001', quote='短い 引用')]), ([], []))
        long_words = ' '.join(['word'] * 15)
        long_chars = 'あ' * 60
        for quote in (long_words, long_chars):
            broken, _ = self.check([finding('f001', quote=quote)])
            self.assertEqual(broken, ['findings.json: f001: quote が長い(15 語未満かつ 60 字未満にする)'])

    def test_wrong_types_do_not_raise(self):  # Review Focus 1
        for data in (None, [], {'findings': 'f001'}, {'findings': [1, None, 'x']},
                     {'findings': [finding('f001', layer=['daily'], quote=['a'], url=None)]}):
            broken, _ = love_schema.check_findings(data)
            self.assertTrue(broken, data)

    def test_findings_by_id_and_layer_counts_skip_malformed_entries(self):
        data = {'findings': [finding('f001', layer='expert'), 'x', {'id': 'bad'}, finding('f001', layer='daily'),
                             finding('f002', layer='any')]}
        by_id = love_schema.findings_by_id(data)
        self.assertEqual(sorted(by_id), ['f001', 'f002'])
        self.assertEqual(by_id['f001']['layer'], 'expert')
        self.assertEqual(love_schema.layer_counts(data), {'daily': 0, 'expert': 1, 'variant': 0, 'any': 1})


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_schema_findings.py`
Expected: `FAILED (errors=1)`。理由は `ModuleNotFoundError: No module named 'love_schema'`

- [ ] **Step 3: 実装を書く**

`twoyearsold_ui/tool/love_schema.py`:

```python
# coding: utf-8
"""愛の地図の記録の形の検査と、層・強さの計算。

アプリの quality/love/ にある所見(findings.json)と観点(love.json)が、決めた形どおりかを見る。
理由は 2 種類に分けて返す。
  broken      決まった値の外・参照先が無い・型が違う。生成物(map.md・assessment.md)は作らない。
  incomplete  生成物は作れるが、終わりの条件をまだ満たしていない(評価や決定がまだ、など)。
gate の love 検査(love_check.py)と、生成(love_report.py)から使う。
"""
import json
import os
import re

LOVE = os.path.join('quality', 'love')

LAYERS = ('daily', 'expert', 'variant', 'any')
COUNTED_LAYERS = ('daily', 'expert', 'variant')  # any(層を決められない)は層の数に数えない
CHANNELS = ('words', 'reviews')
KINDS = ('love', 'harm')
GRADES = ('meets', 'lacks', 'violates', 'unverified')
EFFORTS = ('small', 'medium', 'large')
DECISIONS = ('pursue', 'skip', 'hold')
VERIFY = ('machine', 'human', 'both')
CHECK_KINDS = ('command', 'measure')
TOOLS = ('launch_time', 'new_game')
RESULTS = ('pass', 'fail')
MIN_ASPECTS, MAX_ASPECTS = 10, 20
MIN_EVIDENCE, MIN_SOURCES = 2, 2
QUOTE_MAX_WORDS, QUOTE_MAX_CHARS = 15, 60  # 引用は 15 語未満かつ 60 字未満
DEFAULT_TIMEOUT_S = 600

FINDING_ID = re.compile(r'^f\d{3,}$')
ASPECT_ID = re.compile(r'^[a-z0-9_]+$')
DATE = re.compile(r'^\d{4}-\d{2}-\d{2}$')
URL = re.compile(r'^https?://\S+$')


def _text(value):
    return isinstance(value, str) and value.strip() != ''


def _one_of(value, allowed):
    """決めた文字列のどれかか(配列やオブジェクトが来ても落ちない)。"""
    return isinstance(value, str) and value in allowed


def _number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _str_list(value):
    return isinstance(value, list) and all(isinstance(v, str) for v in value)


class Problems:
    """broken と incomplete の理由を集める。"""

    def __init__(self):
        self.broken = []
        self.incomplete = []

    def bad(self, text):
        self.broken.append(text)

    def todo(self, text):
        self.incomplete.append(text)

    def pair(self):
        return self.broken, self.incomplete


def check_findings(data):
    """findings.json の中身を検査し、(broken, incomplete) を返す。"""
    p = Problems()
    items = data.get('findings') if isinstance(data, dict) else None
    if not isinstance(items, list):
        p.bad('findings.json: findings が配列ではない')
        return p.pair()
    if not items:
        p.todo('findings.json: 所見がまだ無い')
    seen = set()
    for i, f in enumerate(items):
        where = f'findings.json: findings[{i}]'
        if not isinstance(f, dict):
            p.bad(f'{where}: オブジェクトではない')
            continue
        fid = f.get('id')
        if not (isinstance(fid, str) and FINDING_ID.match(fid)):
            p.bad(f'{where}: id は f001 の形')
        elif fid in seen:
            p.bad(f'{where}: id {fid} が重複')
        else:
            seen.add(fid)
            where = f'findings.json: {fid}'
        for key, allowed in (('layer', LAYERS), ('channel', CHANNELS), ('kind', KINDS)):
            if not _one_of(f.get(key), allowed):
                p.bad(f'{where}: {key} は {"・".join(allowed)} のどれか')
        for key in ('source', 'summary'):
            if not _text(f.get(key)):
                p.bad(f'{where}: {key} が空')
        if not isinstance(f.get('url'), str) or not URL.match(f['url']):
            p.bad(f'{where}: url は http:// か https:// で始まる')
        if not isinstance(f.get('read_on'), str) or not DATE.match(f['read_on']):
            p.bad(f'{where}: read_on は YYYY-MM-DD')
        for key in ('title', 'quote', 'reading'):
            if not isinstance(f.get(key, ''), str):
                p.bad(f'{where}: {key} は文字列')
        quote = f.get('quote', '')
        if isinstance(quote, str) and (len(quote.split()) >= QUOTE_MAX_WORDS or len(quote) >= QUOTE_MAX_CHARS):
            p.bad(f'{where}: quote が長い({QUOTE_MAX_WORDS} 語未満かつ {QUOTE_MAX_CHARS} 字未満にする)')
    return p.pair()


def findings_by_id(data):
    """id で引ける所見の辞書。形の正しい id を持つものだけ(重複は最初のもの)。"""
    out = {}
    items = data.get('findings') if isinstance(data, dict) else None
    for f in items if isinstance(items, list) else []:
        if isinstance(f, dict) and isinstance(f.get('id'), str) and FINDING_ID.match(f['id']):
            out.setdefault(f['id'], f)
    return out


def layer_counts(data):
    """層ごとの所見の数(LAYERS の順の辞書)。"""
    counts = {layer: 0 for layer in LAYERS}
    for f in findings_by_id(data).values():
        if f.get('layer') in counts:
            counts[f['layer']] += 1
    return counts
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_schema_findings.py`
Expected: `Ran 9 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 99 tests`、`OK`

- [ ] **Step 5: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_schema.py tool/tests/love_fixtures.py tool/tests/test_love_schema_findings.py
git commit -m "feat: 愛の地図の所見の形の検査(love_schema)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: love.json の形の検査と、層・強さの計算

**Files:**
- Modify: `twoyearsold_ui/tool/love_schema.py`(末尾に足す)
- Modify: `twoyearsold_ui/tool/tests/love_fixtures.py`(末尾に足す)
- Test: `twoyearsold_ui/tool/tests/test_love_schema_love.py`

**Interfaces:**
- Consumes: Task 3 の `Problems`・`findings_by_id`・定数・小道具
- Produces:
  - `love_schema.check_love(love, by_id, exists=lambda ref: True) -> tuple[list[str], list[str]]`。`exists(ref) -> bool` は評価の根拠(`evidence/…`・`code: …`・`measure: …`)の参照先があるかを答える
  - `love_schema.layers(aspect, by_id) -> list[str]`、`sources(aspect, by_id) -> list[str]`、`strength(aspect, by_id) -> str`('strong'・'medium'・'weak')
  - `love_schema.ref_kind(ref) -> str | None`('evidence'・'code'・'steps'・'measure')、正規表現 `CODE_REF`(`path` と `line` の組)
  - `love_fixtures.complete(n_aspects=10, app='Demo') -> (findings_data, love_data)`(終わりの条件を満たす一式。観点の id は `aspect_00`〜。速い確かめの命令は `['python3', 'ok.py']`)、`love_fixtures.aspect(love, aid) -> dict`、`love_fixtures.write_app(app_dir, findings_data=None, love=None) -> love_dir`

- [ ] **Step 1: テストの見本を足し、落ちるテストを書く**

`twoyearsold_ui/tool/tests/love_fixtures.py` の末尾に足す:

```python
def complete(n_aspects=10, app='Demo'):
    """終わりの条件を満たす (findings.json の中身, love.json の中身)。
    観点ごとに、love の所見 2 つ(daily と expert、発信者は別)と harm の所見 1 つ。確かめは速い確かめ(command)。"""
    fs, aspects = [], []
    for i in range(n_aspects):
        l1, l2, h = (f'f{3 * i + k:03d}' for k in (1, 2, 3))
        fs += [finding(l1, layer='daily'), finding(l2, layer='expert'), finding(h, layer='variant', kind='harm')]
        aspects.append({
            'id': f'aspect_{i:02d}', 'name': f'観点 {i}', 'description': f'説明 {i}',
            'evidence': [l1, l2],
            'harms': [{'text': f'裏返し {i}', 'evidence': [h]}],
            'examples': [{'name': f'作品 {i}', 'how': f'応え方 {i}', 'evidence': [l1]}],
            'verify': 'machine',
            'assessment': {
                'a': {'grade': 'meets', 'evidence': ['steps: 手順 A']},
                'b': {'grade': 'meets', 'evidence': ['steps: 手順 B']},
                'final': {'grade': 'meets', 'evidence': ['steps: 手順'], 'reconcile': ''},
                'fix': None, 'effort': None},
            'recommendation': {'decision': 'pursue', 'reason': f'推奨の理由 {i}'},
            'owner': {'decision': 'pursue', 'date': '2026-10-20', 'reason': f'決定の理由 {i}'},
            'check': {'kind': 'command', 'run': ['python3', 'ok.py'], 'timeout_s': 60},
            'target': None,
            'human': None,
        })
    love = {'app': app, 'aspects': aspects,
            'coverage_check': {'checklist_commit': 'abc1234',
                               'rows': [{'row': 'notes', 'aspect': 'aspect_00', 'note': ''},
                                        {'row': 'rewarded_ads', 'aspect': None, 'note': '広告は方針の外'}]},
            'fix_order': []}
    return {'findings': fs}, love


def aspect(love, aid):
    return next(a for a in love['aspects'] if a['id'] == aid)


def write_app(app_dir, findings_data=None, love=None):
    """アプリの quality/love/ に findings.json と love.json を書く(None のものは書かない)。"""
    love_dir = os.path.join(app_dir, 'quality', 'love')
    os.makedirs(love_dir, exist_ok=True)
    for name, data in (('findings.json', findings_data), ('love.json', love)):
        if data is not None:
            with open(os.path.join(love_dir, name), 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
    return love_dir
```

`twoyearsold_ui/tool/tests/test_love_schema_love.py`:

```python
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import love_schema  # noqa: E402
from love_fixtures import aspect, complete, finding  # noqa: E402


class LoveShapeTest(unittest.TestCase):
    def setUp(self):
        self.findings, self.love = complete()
        self.by_id = love_schema.findings_by_id(self.findings)

    def check(self, exists=lambda ref: True):
        return love_schema.check_love(self.love, self.by_id, exists)

    def grades(self, aid, grade):
        for key in ('a', 'b', 'final'):
            aspect(self.love, aid)['assessment'][key]['grade'] = grade

    def test_the_complete_fixture_has_no_problems(self):
        self.assertEqual(self.check(), ([], []))

    def test_aspect_count_outside_10_to_20_is_incomplete(self):
        for n in (9, 21):
            fs, love = complete(n)
            self.assertEqual(love_schema.check_love(love, love_schema.findings_by_id(fs)),
                             ([], [f'love.json: 観点の数が {n}(10〜20 にする)']))
        for n in (10, 20):
            fs, love = complete(n)
            self.assertEqual(love_schema.check_love(love, love_schema.findings_by_id(fs)), ([], []))

    def test_one_finding_or_one_source_is_incomplete(self):
        a = aspect(self.love, 'aspect_00')
        a['evidence'] = ['f001']
        self.assertEqual(self.check(), ([], ['love.json: aspect_00: evidence: 所見が 2 つ未満',
                                             'love.json: aspect_00: evidence: 発信者が 2 つ未満']))
        self.by_id['f002']['source'] = self.by_id['f001']['source']
        a['evidence'] = ['f001', 'f002']
        self.assertEqual(self.check(), ([], ['love.json: aspect_00: evidence: 発信者が 2 つ未満']))

    def test_references_to_missing_or_wrong_kind_findings_are_broken(self):
        a = aspect(self.love, 'aspect_00')
        a['evidence'] = ['f001', 'f999', 'f003']  # f003 は harm の所見
        a['harms'][0]['evidence'] = ['f002']  # f002 は love の所見
        broken, _ = self.check()
        self.assertEqual(broken, ['love.json: aspect_00: evidence: 所見 f999 が無い',
                                  'love.json: aspect_00: evidence: 所見 f003 は love の所見ではない',
                                  'love.json: aspect_00: harms[0]: 所見 f002 は harm の所見ではない'])

    def test_ids_must_be_lowercase_and_unique(self):
        self.love['aspects'][1]['id'] = 'Aspect-1'
        self.love['aspects'][2]['id'] = 'aspect_00'
        broken, _ = self.check()
        self.assertEqual(broken, ['love.json: aspects[1]: id は英小文字・数字・_',
                                  'love.json: aspects[2]: id aspect_00 が重複'])

    def test_layers_sources_and_strength(self):
        fs = {'findings': [
            finding('f001', layer='daily', source='A'), finding('f002', layer='expert', source='B'),
            finding('f003', layer='variant', source='C'), finding('f004', layer='any', source='D'),
            finding('f005', layer='any', source='E'), finding('f006', layer='daily', source='A'),
            finding('f007', layer='variant', kind='harm', source='F'), finding('f008', layer='any', source='G')]}
        by_id = love_schema.findings_by_id(fs)
        cases = [
            (['f001', 'f006'], ['daily'], ['A'], 'weak'),
            (['f001', 'f004'], ['daily'], ['A', 'D'], 'weak'),  # any は層に数えない
            (['f001', 'f004', 'f005'], ['daily'], ['A', 'D', 'E'], 'medium'),  # 発信者 3
            (['f001', 'f002'], ['daily', 'expert'], ['A', 'B'], 'medium'),  # 2 層
            (['f003', 'f002', 'f001'], ['daily', 'expert', 'variant'], ['A', 'B', 'C'], 'strong'),  # 3 層
            (['f001', 'f002', 'f004', 'f005', 'f008'], ['daily', 'expert'], ['A', 'B', 'D', 'E', 'G'], 'strong'),
            (['f001', 'f007'], ['daily'], ['A'], 'weak'),  # harm の所見は数えない
        ]
        for refs, want_layers, want_sources, want in cases:
            a = {'evidence': refs}
            self.assertEqual(love_schema.layers(a, by_id), want_layers, refs)
            self.assertEqual(love_schema.sources(a, by_id), want_sources, refs)
            self.assertEqual(love_schema.strength(a, by_id), want, refs)

    def test_wrong_types_do_not_raise_and_are_broken(self):  # Review Focus 1
        def edit(fn):
            _, love = complete()
            fn(love, aspect(love, 'aspect_00'))
            return love
        cases = [
            None, {'aspects': 'x'}, {'aspects': ['x']},
            edit(lambda love, a: a.update(evidence='f001')),
            edit(lambda love, a: a.update(name=3)),
            edit(lambda love, a: a.update(harms={'text': 'x'})),
            edit(lambda love, a: a.update(verify=['machine'])),
            edit(lambda love, a: a.update(assessment='meets')),
            edit(lambda love, a: a['assessment']['final'].update(evidence='steps: x')),
            edit(lambda love, a: a['assessment']['final'].update(reconcile=['x'])),
            edit(lambda love, a: a.update(owner='pursue')),
            edit(lambda love, a: a.update(check={'kind': 'command', 'run': 'flutter test'})),
            edit(lambda love, a: a.update(check={'kind': 'measure', 'tool': 'new_game', 'metric': 'median_ms'},
                                          target={'max': '1000'})),
            edit(lambda love, a: a.update(human=['手順'])),
            edit(lambda love, a: love.update(coverage_check=[])),
            edit(lambda love, a: love.update(fix_order={})),
        ]
        for love in cases:
            broken, _ = love_schema.check_love(love, self.by_id)
            self.assertTrue(broken, love)

    def test_missing_parts_are_incomplete_not_broken(self):
        a = aspect(self.love, 'aspect_00')
        for key in ('assessment', 'recommendation', 'owner', 'verify'):
            a[key] = None
        a['name'] = ''
        self.love['coverage_check'] = None
        broken, incomplete = self.check()
        self.assertEqual(broken, [])
        self.assertEqual(sorted(incomplete), sorted([
            'love.json: aspect_00: 名前(name)が空',
            'love.json: aspect_00: 確かめ方(verify)がまだ',
            'love.json: aspect_00: 評価がまだ',
            'love.json: aspect_00: 推奨: まだ',
            'love.json: aspect_00: オーナーの決定: まだ',
            'love.json: 見落としの点検(coverage_check)がまだ']))

    def test_grades_need_evidence_except_unverified(self):
        block = aspect(self.love, 'aspect_00')['assessment']
        block['a'] = {'grade': 'unverified', 'evidence': []}
        block['b'] = {'grade': 'meets', 'evidence': []}
        block['final'] = {'grade': 'unverified', 'evidence': [], 'reconcile': 'B の根拠が無い'}
        self.assertEqual(self.check(), ([], ['love.json: aspect_00: 評価 B: 根拠が無い',
                                             'love.json: aspect_00: 最終の段が未確認(unverified)']))

    def test_differing_grades_need_a_reconcile_reason(self):
        block = aspect(self.love, 'aspect_00')['assessment']
        block['b']['grade'] = 'lacks'
        self.assertEqual(self.check(), ([], [
            'love.json: aspect_00: A・B・最終の段が同じでないので、突き合わせの理由(reconcile)が要る']))
        block['final']['reconcile'] = 'B の写しは古いビルドだった'
        self.assertEqual(self.check(), ([], []))

    def test_lacks_and_violates_need_fix_and_effort(self):
        self.grades('aspect_00', 'lacks')
        self.love['fix_order'] = [{'id': 'aspect_00', 'reason': '手間が小さい'}]
        self.assertEqual(self.check(), ([], ['love.json: aspect_00: 直し方の案(fix)が空',
                                             'love.json: aspect_00: 手間(effort)がまだ']))
        aspect(self.love, 'aspect_00')['assessment'].update(fix='数字ごとの残りの数を出す', effort='huge')
        self.assertEqual(self.check(), (['love.json: aspect_00: effort は small・medium・large のどれか'], []))

    def test_evidence_strings_need_a_known_prefix_and_an_existing_target(self):  # Review Focus 2
        final = aspect(self.love, 'aspect_00')['assessment']['final']
        final['evidence'] = ['写真.png', 'code: lib/a.dart:0', 'code: lib/a.dart', 'evidence/a/x.png', 'steps: 見た']
        broken, _ = self.check(exists=lambda ref: False)
        self.assertEqual(broken, [
            'love.json: aspect_00: 最終の評価: 根拠「写真.png」は evidence/・code: ・steps: ・measure: のどれかで始める',
            'love.json: aspect_00: 最終の評価: 根拠「code: lib/a.dart:0」は code: <path>:<1 以上の行> の形',
            'love.json: aspect_00: 最終の評価: 根拠「code: lib/a.dart」は code: <path>:<1 以上の行> の形',
            'love.json: aspect_00: 最終の評価: 根拠の参照先が無い(evidence/a/x.png)'])

    def test_decisions_need_a_reason_and_the_owner_needs_a_date(self):
        a = aspect(self.love, 'aspect_00')
        a['recommendation'] = {'decision': 'keep', 'reason': ''}
        a['owner'] = {'decision': 'skip', 'date': '', 'reason': ' '}
        self.assertEqual(self.check(), (['love.json: aspect_00: 推奨: decision は pursue・skip・hold のどれか'], [
            'love.json: aspect_00: 推奨: 理由(reason)が空',
            'love.json: aspect_00: オーナーの決定: 理由(reason)が空',
            'love.json: aspect_00: オーナーの決定: 日付(date)がまだ']))
        a['owner']['date'] = '10/20'
        self.assertIn('love.json: aspect_00: オーナーの決定: date は YYYY-MM-DD', self.check()[0])

    def test_pursued_aspects_need_the_checks_their_verify_asks_for(self):
        a = aspect(self.love, 'aspect_00')
        a['verify'] = 'both'
        a['check'] = None
        self.assertEqual(self.check(), ([], ['love.json: aspect_00: 追う観点なので、機械の確かめ(check)が要る',
                                             'love.json: aspect_00: 追う観点なので、人の確かめの手順(human.steps)が要る']))
        a['owner']['decision'] = 'skip'
        self.assertEqual(self.check(), ([], []))

    def test_measure_checks_need_a_known_tool_and_a_target(self):
        a = aspect(self.love, 'aspect_00')
        a['check'] = {'kind': 'measure', 'tool': 'launch_time', 'metric': 'median_ms'}
        self.assertEqual(self.check(), ([], ['love.json: aspect_00: 測定の目標(target)がまだ']))
        a['target'] = {'max': 1200}
        self.assertEqual(self.check(), ([], []))
        a['check']['tool'] = 'cold_start'
        a['target'] = {'max': 1200, 'min': 0}
        self.assertEqual(self.check()[0], ['love.json: aspect_00: check.tool は launch_time・new_game のどれか',
                                           'love.json: aspect_00: target は {"max": 数} か {"min": 数}'])

    def test_the_human_record_has_a_fixed_shape(self):
        a = aspect(self.love, 'aspect_00')
        a.update(verify='human', check=None, human={
            'steps': ['★5 を 1 問解く'],
            'last': {'date': '2026-10-21', 'commit': 'abc1234', 'by': 'owner', 'result': 'pass', 'note': ''}})
        self.assertEqual(self.check(), ([], []))
        a['human']['last'] = {'date': 'today', 'commit': '', 'by': 'owner', 'result': 'ok'}
        self.assertEqual(self.check()[0], ['love.json: aspect_00: human.last.date は YYYY-MM-DD',
                                           'love.json: aspect_00: human.last.commit が空',
                                           'love.json: aspect_00: human.last.result は pass・fail のどれか'])

    def test_coverage_rows_point_at_an_aspect_or_explain_why_not(self):
        rows = self.love['coverage_check']['rows']
        rows.append({'row': 'timer', 'aspect': 'no_such', 'note': ''})
        rows.append({'row': 'themes', 'aspect': None, 'note': ''})
        self.assertEqual(self.check(), (['love.json: coverage_check.rows[2]: 観点 no_such が無い'],
                                        ['love.json: coverage_check.rows[3]: 当たる観点(aspect)か、当たらない理由(note)が要る']))

    def test_fix_order_lists_the_pursued_aspects_that_have_something_to_fix(self):
        self.grades('aspect_00', 'violates')
        aspect(self.love, 'aspect_00')['assessment'].update(fix='帯を数字のボタンから離す', effort='small')
        self.assertEqual(self.check(), ([], ['love.json: fix_order に aspect_00 が無い']))
        self.love['fix_order'] = [{'id': 'aspect_00', 'reason': '反している・手間が小さい'},
                                  {'id': 'aspect_01', 'reason': '応えている'}]
        self.assertEqual(self.check(), ([], ['love.json: fix_order[1]: aspect_01 は直す所のある追う観点ではない(外す)']))
        self.love['fix_order'] = [{'id': 'nope', 'reason': 'x'}]
        self.assertIn('love.json: fix_order[0]: id が観点の id ではない', self.check()[0])

    def test_ref_kind(self):
        self.assertEqual(love_schema.ref_kind('evidence/a/x.png'), 'evidence')
        self.assertEqual(love_schema.ref_kind('code: lib/a.dart:3'), 'code')
        self.assertEqual(love_schema.ref_kind('steps: 見た'), 'steps')
        self.assertEqual(love_schema.ref_kind('measure: measure/x.json'), 'measure')
        for bad in ('steps: ', 'evidence/', 'x.png', None, 3):
            self.assertIsNone(love_schema.ref_kind(bad))


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_schema_love.py`
Expected: `FAILED (errors=19)`。理由は `AttributeError: module 'love_schema' has no attribute 'check_love'` など

- [ ] **Step 3: 実装を `love_schema.py` の末尾に足す**

```python
REF_PREFIXES = (('evidence', 'evidence/'), ('code', 'code: '), ('steps', 'steps: '), ('measure', 'measure: '))
CODE_REF = re.compile(r'^code: (?P<path>[^:\s][^:]*):(?P<line>[1-9]\d*)$')


def _love_refs(aspect, by_id):
    """観点の根拠のうち、実在する love の所見。"""
    refs = aspect.get('evidence') if isinstance(aspect, dict) else None
    return [by_id[f] for f in refs if isinstance(f, str) and f in by_id and by_id[f].get('kind') == 'love'] \
        if isinstance(refs, list) else []


def layers(aspect, by_id):
    """根拠の所見の層(any は数えない)。COUNTED_LAYERS の順。"""
    found = {f.get('layer') for f in _love_refs(aspect, by_id)}
    return [layer for layer in COUNTED_LAYERS if layer in found]


def sources(aspect, by_id):
    """根拠の所見の発信者(重複なし、名前の順)。"""
    return sorted({f['source'] for f in _love_refs(aspect, by_id) if _text(f.get('source'))})


def strength(aspect, by_id):
    """強さの目安: 3 層か発信者 5 以上で strong、2 層か 3 以上で medium、ほかは weak。"""
    n_layers, n_sources = len(layers(aspect, by_id)), len(sources(aspect, by_id))
    if n_layers >= 3 or n_sources >= 5:
        return 'strong'
    if n_layers >= 2 or n_sources >= 3:
        return 'medium'
    return 'weak'


def ref_kind(ref):
    """評価の根拠の文字列の種類(evidence・code・steps・measure)。決まった形でなければ None。"""
    if not isinstance(ref, str):
        return None
    for kind, prefix in REF_PREFIXES:
        if ref.startswith(prefix) and _text(ref[len(prefix):]):
            return kind
    return None


def _need_text(p, where, value, label):
    if value is None or (isinstance(value, str) and not value.strip()):
        p.todo(f'{where}: {label}が空')
    elif not isinstance(value, str):
        p.bad(f'{where}: {label}は文字列')


def _check_finding_refs(p, where, refs, by_id, kind, minimum):
    """所見の id の並びを検査する。kind が None なら種類は問わない。"""
    if refs is None:
        p.todo(f'{where}: 所見がまだ')
        return
    if not _str_list(refs):
        p.bad(f'{where}: 所見の id の配列ではない')
        return
    for fid in refs:
        if fid not in by_id:
            p.bad(f'{where}: 所見 {fid} が無い')
        elif kind and by_id[fid].get('kind') != kind:
            p.bad(f'{where}: 所見 {fid} は {kind} の所見ではない')
    if len(set(refs)) < minimum:
        p.todo(f'{where}: 所見が {minimum} つ未満')


def _check_entries(p, where, entries, by_id, kind, keys):
    """harms・examples の並び。keys は文字の欄の (名前, 表示名)。"""
    if entries is None:
        return
    if not isinstance(entries, list):
        p.bad(f'{where}: 配列ではない')
        return
    for j, e in enumerate(entries):
        ew = f'{where}[{j}]'
        if not isinstance(e, dict):
            p.bad(f'{ew}: オブジェクトではない')
            continue
        for key, label in keys:
            _need_text(p, ew, e.get(key), label)
        _check_finding_refs(p, ew, e.get('evidence'), by_id, kind, 1)


def _check_map(p, where, a, by_id):
    """地図の部分: 名前・説明・根拠・発信者・裏返し・例・確かめ方。"""
    _need_text(p, where, a.get('name'), '名前(name)')
    _need_text(p, where, a.get('description'), '説明(description)')
    _check_finding_refs(p, f'{where}: evidence', a.get('evidence'), by_id, 'love', MIN_EVIDENCE)
    if _str_list(a.get('evidence')) and len(sources(a, by_id)) < MIN_SOURCES:
        p.todo(f'{where}: evidence: 発信者が {MIN_SOURCES} つ未満')
    _check_entries(p, f'{where}: harms', a.get('harms'), by_id, 'harm', (('text', '裏返し(text)'),))
    _check_entries(p, f'{where}: examples', a.get('examples'), by_id, None,
                   (('name', '作品の名前(name)'), ('how', '応え方(how)')))
    verify = a.get('verify')
    if verify is None:
        p.todo(f'{where}: 確かめ方(verify)がまだ')
    elif not _one_of(verify, VERIFY):
        p.bad(f'{where}: verify は {"・".join(VERIFY)} のどれか')


def _check_grade(p, where, block, exists):
    """評価 1 つ(grade と根拠)。段を返す(読めなければ None)。"""
    if block is None:
        p.todo(f'{where}: まだ')
        return None
    if not isinstance(block, dict):
        p.bad(f'{where}: オブジェクトではない')
        return None
    grade = block.get('grade')
    if grade is None:
        p.todo(f'{where}: 段(grade)がまだ')
    elif not _one_of(grade, GRADES):
        p.bad(f'{where}: grade は {"・".join(GRADES)} のどれか')
        grade = None
    refs = block.get('evidence', [])
    if not _str_list(refs):
        p.bad(f'{where}: 根拠(evidence)は文字列の配列')
        refs = []
    for ref in refs:
        kind = ref_kind(ref)
        if kind is None:
            p.bad(f'{where}: 根拠「{ref[:40]}」は evidence/・code: ・steps: ・measure: のどれかで始める')
        elif kind == 'code' and not CODE_REF.match(ref):
            p.bad(f'{where}: 根拠「{ref[:40]}」は code: <path>:<1 以上の行> の形')
        elif kind != 'steps' and not exists(ref):
            p.bad(f'{where}: 根拠の参照先が無い({ref[:60]})')
    if grade and grade != 'unverified' and not refs:
        p.todo(f'{where}: 根拠が無い')
    return grade


def _check_assessment(p, where, a, exists):
    block = a.get('assessment')
    if block is None:
        p.todo(f'{where}: 評価がまだ')
        return None
    if not isinstance(block, dict):
        p.bad(f'{where}: assessment はオブジェクト')
        return None
    ga = _check_grade(p, f'{where}: 評価 A', block.get('a'), exists)
    gb = _check_grade(p, f'{where}: 評価 B', block.get('b'), exists)
    final = block.get('final')
    gf = _check_grade(p, f'{where}: 最終の評価', final, exists)
    if gf == 'unverified':
        p.todo(f'{where}: 最終の段が未確認(unverified)')
    reconcile = final.get('reconcile', '') if isinstance(final, dict) else ''
    if not isinstance(reconcile, str):
        p.bad(f'{where}: reconcile は文字列')
    elif ga and gb and gf and not (ga == gb == gf) and not reconcile.strip():
        p.todo(f'{where}: A・B・最終の段が同じでないので、突き合わせの理由(reconcile)が要る')
    if gf in ('lacks', 'violates'):
        _need_text(p, where, block.get('fix'), '直し方の案(fix)')
        effort = block.get('effort')
        if effort is None:
            p.todo(f'{where}: 手間(effort)がまだ')
        elif not _one_of(effort, EFFORTS):
            p.bad(f'{where}: effort は {"・".join(EFFORTS)} のどれか')
    return gf


def _check_decision(p, where, block, need_date):
    """推奨かオーナーの決定。決定を返す(まだなら None)。"""
    if block is None or (isinstance(block, dict) and block.get('decision') is None):
        p.todo(f'{where}: まだ')
        return None
    if not isinstance(block, dict):
        p.bad(f'{where}: オブジェクトではない')
        return None
    decision = block.get('decision')
    if not _one_of(decision, DECISIONS):
        p.bad(f'{where}: decision は {"・".join(DECISIONS)} のどれか')
        decision = None
    _need_text(p, where, block.get('reason'), '理由(reason)')
    if need_date:
        date = block.get('date')
        if date is None or date == '':
            p.todo(f'{where}: 日付(date)がまだ')
        elif not (isinstance(date, str) and DATE.match(date)):
            p.bad(f'{where}: date は YYYY-MM-DD')
    return decision


def _target_ok(target):
    return (isinstance(target, dict) and len(target) == 1 and next(iter(target)) in ('max', 'min')
            and _number(next(iter(target.values()))))


def _check_check(p, where, check, target):
    if not isinstance(check, dict) or not _one_of(check.get('kind'), CHECK_KINDS):
        p.bad(f'{where}: check.kind は {"・".join(CHECK_KINDS)} のどれか')
        return
    if check['kind'] == 'command':
        run = check.get('run')
        if not (_str_list(run) and run and all(_text(x) for x in run)):
            p.bad(f'{where}: check.run は空でない文字列の配列')
        timeout = check.get('timeout_s', DEFAULT_TIMEOUT_S)
        if not (_number(timeout) and timeout > 0):
            p.bad(f'{where}: check.timeout_s は正の数')
        return
    if not _one_of(check.get('tool'), TOOLS):
        p.bad(f'{where}: check.tool は {"・".join(TOOLS)} のどれか')
    if check.get('metric') != 'median_ms':
        p.bad(f'{where}: check.metric は median_ms')
    if target is None:
        p.todo(f'{where}: 測定の目標(target)がまだ')
    elif not _target_ok(target):
        p.bad(f'{where}: target は {{"max": 数}} か {{"min": 数}}')


def _check_human(p, where, human):
    if not isinstance(human, dict):
        p.bad(f'{where}: human はオブジェクト')
        return
    if not _str_list(human.get('steps', [])):
        p.bad(f'{where}: human.steps は文字列の配列')
    last = human.get('last')
    if last is None:
        return
    if not isinstance(last, dict):
        p.bad(f'{where}: human.last はオブジェクト')
        return
    if not (isinstance(last.get('date'), str) and DATE.match(last['date'])):
        p.bad(f'{where}: human.last.date は YYYY-MM-DD')
    for key in ('commit', 'by'):
        if not _text(last.get(key)):
            p.bad(f'{where}: human.last.{key} が空')
    if not _one_of(last.get('result'), RESULTS):
        p.bad(f'{where}: human.last.result は {"・".join(RESULTS)} のどれか')
    if not isinstance(last.get('note', ''), str):
        p.bad(f'{where}: human.last.note は文字列')


def _check_line(p, where, a):
    """推奨・オーナーの決定・追う観点の確かめ方。オーナーの決定を返す。"""
    _check_decision(p, f'{where}: 推奨', a.get('recommendation'), need_date=False)
    decision = _check_decision(p, f'{where}: オーナーの決定', a.get('owner'), need_date=True)
    check, target, human = a.get('check'), a.get('target'), a.get('human')
    if check is not None:
        _check_check(p, where, check, target)
    if human is not None:
        _check_human(p, where, human)
    verify = a.get('verify')
    if decision != 'pursue' or not _one_of(verify, VERIFY):
        return decision
    if verify in ('machine', 'both') and check is None:
        p.todo(f'{where}: 追う観点なので、機械の確かめ(check)が要る')
    steps = human.get('steps') if isinstance(human, dict) else None
    if verify in ('human', 'both') and not (_str_list(steps) and any(_text(s) for s in steps)):
        p.todo(f'{where}: 追う観点なので、人の確かめの手順(human.steps)が要る')
    return decision


def _check_coverage(p, block, ids):
    if block is None:
        p.todo('love.json: 見落としの点検(coverage_check)がまだ')
        return
    if not isinstance(block, dict) or not isinstance(block.get('rows'), list):
        p.bad('love.json: coverage_check は rows(配列)を持つオブジェクト')
        return
    _need_text(p, 'love.json: coverage_check', block.get('checklist_commit'), '点検表の commit(checklist_commit)')
    if not block['rows']:
        p.todo('love.json: coverage_check の行がまだ無い')
    for i, row in enumerate(block['rows']):
        where = f'love.json: coverage_check.rows[{i}]'
        if not isinstance(row, dict) or not _text(row.get('row')):
            p.bad(f'{where}: row(下書きの行の id)が要る')
            continue
        aspect = row.get('aspect')
        if aspect is not None and aspect not in ids:
            p.bad(f'{where}: 観点 {aspect} が無い')
        elif aspect is None and not _text(row.get('note')):
            p.todo(f'{where}: 当たる観点(aspect)か、当たらない理由(note)が要る')


def _check_fix_order(p, block, fixes, ids):
    """fixes は、直す所のある追う観点(最終の段が lacks か violates)の id。"""
    if block is None:
        if fixes:
            p.todo('love.json: 直す順の案(fix_order)がまだ')
        return
    if not isinstance(block, list):
        p.bad('love.json: fix_order は配列')
        return
    listed = []
    for i, row in enumerate(block):
        where = f'love.json: fix_order[{i}]'
        if not isinstance(row, dict) or not isinstance(row.get('id'), str) or row['id'] not in ids:
            p.bad(f'{where}: id が観点の id ではない')
            continue
        if row['id'] not in fixes:
            p.todo(f'{where}: {row["id"]} は直す所のある追う観点ではない(外す)')
        _need_text(p, where, row.get('reason'), '理由(reason)')
        listed.append(row['id'])
    for aid in fixes:
        if aid not in listed:
            p.todo(f'love.json: fix_order に {aid} が無い')


def check_love(love, by_id, exists=lambda ref: True):
    """love.json の中身を検査し、(broken, incomplete) を返す。
    by_id は findings_by_id の結果。exists(ref) は評価の根拠(evidence/…・code: …・measure: …)の参照先があるかを答える。"""
    p = Problems()
    aspects = love.get('aspects') if isinstance(love, dict) else None
    if not isinstance(aspects, list):
        p.bad('love.json: aspects が配列ではない')
        return p.pair()
    if not MIN_ASPECTS <= len(aspects) <= MAX_ASPECTS:
        p.todo(f'love.json: 観点の数が {len(aspects)}({MIN_ASPECTS}〜{MAX_ASPECTS} にする)')
    ids, fixes = [], []
    for i, a in enumerate(aspects):
        where = f'love.json: aspects[{i}]'
        if not isinstance(a, dict):
            p.bad(f'{where}: オブジェクトではない')
            continue
        aid = a.get('id')
        if not (isinstance(aid, str) and ASPECT_ID.match(aid)):
            p.bad(f'{where}: id は英小文字・数字・_')
            aid = None
        elif aid in ids:
            p.bad(f'{where}: id {aid} が重複')
            aid = None
        else:
            ids.append(aid)
            where = f'love.json: {aid}'
        _check_map(p, where, a, by_id)
        final = _check_assessment(p, where, a, exists)
        decision = _check_line(p, where, a)
        if aid and decision == 'pursue' and final in ('lacks', 'violates'):
            fixes.append(aid)
    _check_coverage(p, love.get('coverage_check'), ids)
    _check_fix_order(p, love.get('fix_order'), fixes, ids)
    return p.pair()
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_schema_love.py`
Expected: `Ran 19 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 118 tests`、`OK`

- [ ] **Step 5: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_schema.py tool/tests/love_fixtures.py tool/tests/test_love_schema_love.py
git commit -m "feat: 愛の地図の観点・評価・線の形の検査と、層・強さの計算" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: ファイルの読み込みと、根拠の参照先の確かめ

**Files:**
- Modify: `twoyearsold_ui/tool/love_schema.py`(末尾に足す)
- Test: `twoyearsold_ui/tool/tests/test_love_schema_files.py`

**Interfaces:**
- Consumes: Task 3・4 の `check_findings`・`check_love`・`findings_by_id`・`ref_kind`・`CODE_REF`、`love_fixtures.complete`・`aspect`・`write_app`
- Produces:
  - `love_schema.ref_exists(app_dir, ref) -> bool`
  - `love_schema.load_app(app_dir) -> (findings_data | None, love_data | None, broken: list[str])`
  - `love_schema.check_app(app_dir) -> tuple[list[str], list[str]]`(love.json が無ければ所見だけを検査する)

- [ ] **Step 1: 落ちるテストを書く**

`twoyearsold_ui/tool/tests/test_love_schema_files.py`:

```python
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import love_schema  # noqa: E402
from love_fixtures import aspect, complete, write_app  # noqa: E402


class LoveFilesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.love_dir = os.path.join(self.app, 'quality', 'love')

    def write(self, rel, text='x\n'):
        path = os.path.join(self.app, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)

    def test_evidence_and_measure_refs_must_exist_inside_their_folders(self):  # Review Focus 2
        self.write('quality/love/evidence/a/x.png')
        self.write('quality/love/measure/quick_start.json', '{}')
        self.write('quality/love/love.json', '{}')
        self.write('quality/secret.png')
        exists = lambda ref: love_schema.ref_exists(self.app, ref)  # noqa: E731
        self.assertTrue(exists('evidence/a/x.png'))
        self.assertTrue(exists('measure: measure/quick_start.json'))
        self.assertTrue(exists('steps: 見た'))
        for ref in ('evidence/a/y.png', 'evidence/../love.json', 'evidence/../../secret.png', 'evidence//etc/hosts',
                    'measure: measure/none.json', 'measure: love.json', 'measure: measure/../love.json'):
            self.assertFalse(exists(ref), ref)

    def test_a_symlink_that_leaves_the_folder_does_not_count(self):  # Review Focus 2
        self.write('quality/secret.png')
        os.makedirs(os.path.join(self.love_dir, 'evidence'), exist_ok=True)
        os.symlink(os.path.join(self.app, 'quality', 'secret.png'), os.path.join(self.love_dir, 'evidence', 'link.png'))
        self.assertFalse(love_schema.ref_exists(self.app, 'evidence/link.png'))

    def test_code_refs_need_the_file_inside_the_app_and_the_line(self):  # Review Focus 2
        self.write('lib/a.dart', 'one\ntwo\nthree\n')
        self.write('../Other/lib/b.dart', 'x\n')
        exists = lambda ref: love_schema.ref_exists(self.app, ref)  # noqa: E731
        self.assertTrue(exists('code: lib/a.dart:1'))
        self.assertTrue(exists('code: lib/a.dart:3'))
        for ref in ('code: lib/a.dart:4', 'code: lib/a.dart:0', 'code: lib/none.dart:1',
                    'code: ../Other/lib/b.dart:1', 'code: /etc/hosts:1', 'code: lib:1'):
            self.assertFalse(exists(ref), ref)

    def test_check_app_reads_both_files_and_checks_references_on_disk(self):
        findings, love = complete()
        aspect(love, 'aspect_00')['assessment']['final']['evidence'] = ['evidence/a/aspect_00-1.png']
        write_app(self.app, findings, love)
        broken, incomplete = love_schema.check_app(self.app)
        self.assertEqual(broken, ['love.json: aspect_00: 最終の評価: 根拠の参照先が無い(evidence/a/aspect_00-1.png)'])
        self.write('quality/love/evidence/a/aspect_00-1.png')
        self.assertEqual(love_schema.check_app(self.app), ([], []))

    def test_without_love_json_only_the_findings_are_checked(self):
        findings, _ = complete()
        write_app(self.app, findings)
        self.assertEqual(love_schema.check_app(self.app), ([], []))
        write_app(self.app, {'findings': []})
        self.assertEqual(love_schema.check_app(self.app), ([], ['findings.json: 所見がまだ無い']))

    def test_missing_findings_is_incomplete_and_broken_json_is_broken(self):
        os.makedirs(self.love_dir)
        self.assertEqual(love_schema.check_app(self.app), ([], ['findings.json: まだ無い']))
        self.write('quality/love/findings.json', '{"findings": [')
        broken, _ = love_schema.check_app(self.app)
        self.assertEqual(len(broken), 1)
        self.assertTrue(broken[0].startswith('findings.json: 読めない('))

    def test_load_app_returns_none_for_missing_files(self):
        findings, love = complete()
        write_app(self.app, findings, None)
        got_findings, got_love, broken = love_schema.load_app(self.app)
        self.assertEqual(got_findings, findings)
        self.assertIsNone(got_love)
        self.assertEqual(broken, [])


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_schema_files.py`
Expected: `FAILED (errors=7)`。理由は `AttributeError: module 'love_schema' has no attribute 'ref_exists'` など

- [ ] **Step 3: 実装を `love_schema.py` の末尾に足す**

```python
def _inside(base, rel):
    """base の中のパス rel の実際の場所。base の外に出る(.. や絶対パス、外へのリンク)なら None。"""
    if not isinstance(rel, str) or not rel or os.path.isabs(rel):
        return None
    root = os.path.realpath(base)
    full = os.path.realpath(os.path.join(root, rel))
    return full if full.startswith(root + os.sep) else None


def ref_exists(app_dir, ref):
    """評価の根拠の参照先があるか。evidence/… は quality/love/evidence/ の中、measure: … は quality/love/measure/ の中、
    code: <path>:<行> はアプリの中のファイルで、その行があること。steps: は参照先を持たないので True。"""
    love_dir = os.path.join(app_dir, LOVE)
    kind = ref_kind(ref)
    if kind == 'steps':
        return True
    if kind == 'evidence':
        path = _inside(os.path.join(love_dir, 'evidence'), ref[len('evidence/'):])
        return bool(path) and os.path.isfile(path)
    if kind == 'measure':
        rel = ref[len('measure: '):].strip()
        path = _inside(os.path.join(love_dir, 'measure'), rel[len('measure/'):]) if rel.startswith('measure/') else None
        return bool(path) and os.path.isfile(path)
    if kind == 'code':
        m = CODE_REF.match(ref)
        path = _inside(app_dir, m.group('path')) if m else None
        if not (path and os.path.isfile(path)):
            return False
        try:
            with open(path, encoding='utf-8', errors='replace') as f:
                count = sum(1 for _ in f)
        except OSError:
            return False
        return int(m.group('line')) <= count
    return False


def load_app(app_dir):
    """(findings.json の中身, love.json の中身, broken) を返す。無いファイルは None。読めない JSON は None にして broken に書く。"""
    love_dir = os.path.join(app_dir, LOVE)
    out, broken = [], []
    for name in ('findings.json', 'love.json'):
        path = os.path.join(love_dir, name)
        if not os.path.exists(path):
            out.append(None)
            continue
        try:
            with open(path, encoding='utf-8') as f:
                out.append(json.load(f))
        except (OSError, ValueError) as e:
            out.append(None)
            broken.append(f'{name}: 読めない({e})')
    return out[0], out[1], broken


def check_app(app_dir):
    """アプリの findings.json と love.json を読んで検査し、(broken, incomplete) を返す。
    love.json が無ければ、所見だけを検査する。"""
    findings, love, broken = load_app(app_dir)
    incomplete = []
    if findings is None and not broken:
        incomplete.append('findings.json: まだ無い')
    if findings is not None:
        b, i = check_findings(findings)
        broken += b
        incomplete += i
    if love is not None:
        b, i = check_love(love, findings_by_id(findings), exists=lambda ref: ref_exists(app_dir, ref))
        broken += b
        incomplete += i
    return broken, incomplete
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_schema_files.py`
Expected: `Ran 7 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 125 tests`、`OK`

- [ ] **Step 5: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_schema.py tool/tests/test_love_schema_files.py
git commit -m "feat: 愛の地図の記録の読み込みと、根拠の参照先の確かめ" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: 記録が今のコードに対するものかの判定

**Files:**
- Create: `twoyearsold_ui/tool/love_check.py`
- Modify: `twoyearsold_ui/tool/tests/love_fixtures.py`(末尾に足す)
- Test: `twoyearsold_ui/tool/tests/test_love_check_current.py`

**Interfaces:**
- Consumes: `love_schema`(import のみ。Task 7 で使う)
- Produces:
  - `love_check.APP_CODE`(アプリのコードの範囲)、`OVERRIDES`(`'pubspec_overrides.yaml'`)
  - `love_check.run_command(args, cwd, timeout) -> (code: int, out_tail: str)`(gate.run_command と同じ形)
  - `love_check.current(app_dir, commit, run=run_command) -> (bool, reason: str)`
  - `love_fixtures.git(app_dir, *args) -> stdout`、`love_fixtures.git_app(app_dir) -> commit`(lib/・pubspec.yaml・quality/ を持つ git のリポジトリを作る)

- [ ] **Step 1: テストの見本を足し、落ちるテストを書く**

`twoyearsold_ui/tool/tests/love_fixtures.py` の末尾に足す:

```python
def git(app_dir, *args):
    """テスト用の git。手元の設定(署名・フック・名前)に左右されないようにする。標準出力を返す。"""
    import subprocess
    done = subprocess.run(['git', '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
                           '-c', 'user.name=test', '-c', 'user.email=test@example.com', *args],
                          cwd=app_dir, capture_output=True, text=True, check=True)
    return done.stdout.strip()


def git_app(app_dir):
    """app_dir を、アプリのコード(lib/・pubspec.yaml)と quality/ を持つ git のリポジトリにする。最初の commit を返す。"""
    for rel, text in (('lib/main.dart', 'void main() {}\n'), ('pubspec.yaml', 'name: demo\n'),
                      ('quality/gate.json', '{}\n')):
        path = os.path.join(app_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
    git(app_dir, 'init', '-q')
    git(app_dir, 'add', '-A')
    git(app_dir, 'commit', '-q', '-m', 'first')
    return git(app_dir, 'rev-parse', 'HEAD')
```

`twoyearsold_ui/tool/tests/test_love_check_current.py`:

```python
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import love_check  # noqa: E402
from love_fixtures import git, git_app  # noqa: E402


class CurrentTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.commit = git_app(self.app)

    def write(self, rel, text='x\n'):
        path = os.path.join(self.app, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)

    def commit_all(self, message='next'):
        git(self.app, 'add', '-A')
        git(self.app, 'commit', '-q', '-m', message)

    def test_unchanged_code_is_current(self):
        self.assertEqual(love_check.current(self.app, self.commit), (True, ''))

    def test_changes_outside_the_app_code_do_not_matter(self):
        self.write('quality/love/love.json', '{}')
        self.write('quality/gate.json', '{"ok": true}')
        self.write('test/x_test.dart')
        self.write('love_test/y_test.dart')
        self.commit_all('records')
        self.write('quality/love/measure/quick_start.json', '{}')  # 追跡していなくても、範囲の外なら構わない
        self.assertEqual(love_check.current(self.app, self.commit), (True, ''))

    def test_a_committed_change_to_lib_after_the_record_is_not_current(self):
        self.write('lib/main.dart', 'void main() { print(1); }\n')
        self.commit_all('change')
        ok, reason = love_check.current(self.app, self.commit)
        self.assertFalse(ok)
        self.assertIn('アプリのコードが、記録の commit', reason)

    def test_uncommitted_and_deleted_files_are_not_current(self):
        self.write('pubspec.yaml', 'name: demo2\n')
        self.assertFalse(love_check.current(self.app, self.commit)[0])
        git(self.app, 'checkout', '-q', '--', 'pubspec.yaml')
        os.remove(os.path.join(self.app, 'lib', 'main.dart'))
        self.assertFalse(love_check.current(self.app, self.commit)[0])

    def test_an_untracked_file_in_the_app_code_is_not_current(self):
        self.write('lib/new.dart')
        ok, reason = love_check.current(self.app, self.commit)
        self.assertFalse(ok)
        self.assertIn('追跡していないファイルがアプリのコードの中にある(lib/new.dart', reason)

    def test_ignored_files_do_not_count(self):
        self.write('.gitignore', 'android/build/\n')
        self.commit_all('ignore')
        self.write('android/build/app.apk')
        self.assertEqual(love_check.current(self.app, self.commit), (True, ''))

    def test_a_local_override_of_the_shared_package_cannot_be_current(self):
        self.write('pubspec_overrides.yaml', 'dependency_overrides: {}\n')
        ok, reason = love_check.current(self.app, self.commit)
        self.assertFalse(ok)
        self.assertIn('pubspec_overrides.yaml', reason)

    def test_short_shas_and_names_resolve_and_unknown_ones_do_not(self):  # Review Focus 3
        self.assertTrue(love_check.current(self.app, self.commit[:7])[0])
        self.assertTrue(love_check.current(self.app, 'HEAD')[0])
        for bad in ('0' * 40, 'no-such-branch', '--output=/tmp/x'):
            ok, reason = love_check.current(self.app, bad)
            self.assertFalse(ok, bad)
            self.assertIn('履歴に無い', reason)
        for empty in ('', ' ', None, 3):
            self.assertEqual(love_check.current(self.app, empty), (False, '記録に commit が無い'))

    def test_a_folder_outside_git_is_reported(self):
        plain = os.path.join(self.tmp, 'Plain')
        os.makedirs(plain)
        self.assertEqual(love_check.current(plain, self.commit), (False, 'git のリポジトリでない'))

    def test_a_missing_or_hanging_git_is_reported(self):  # Review Focus 3
        def missing(args, cwd, timeout):
            raise FileNotFoundError('git')

        def hang(args, cwd, timeout):
            raise subprocess.TimeoutExpired(args, timeout)
        self.assertEqual(love_check.current(self.app, self.commit, run=missing), (False, 'git が見つからない'))
        ok, reason = love_check.current(self.app, self.commit, run=hang)
        self.assertFalse(ok)
        self.assertIn('git を走らせられない', reason)


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_check_current.py`
Expected: `FAILED (errors=1)`。理由は `ModuleNotFoundError: No module named 'love_check'`

- [ ] **Step 3: 実装を書く**

`twoyearsold_ui/tool/love_check.py`:

```python
# coding: utf-8
"""愛の地図の確かめ — gate の love 検査の中身。

形の検査(love_schema)を通したうえで、オーナーが追うと決めた観点(owner.decision が pursue)を 1 つずつ確かめる。
  速い確かめ(check.kind が command)  アプリのディレクトリで命令を走らせ、終了コード 0 なら満たす。
  遅い測定(check.kind が measure)    quality/love/measure/<観点の id>.json が、今のコードで測った記録で、目標を満たすか。
  人の確かめ(verify が human)        love.json の human.last が、今のコードに対する pass か。
「今のコード」は、記録の commit から、アプリのコードの範囲(APP_CODE)に差が無いこと。差は作業ツリーと比べ、
commit していない変更と、追跡していないファイルも差に数える。共有をローカルで参照している間は決められない。

使い方:
  python3 twoyearsold_ui/tool/love_check.py <AppName>   # 理由と、追う観点ごとの結果を出す。fail なら exit 1
"""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
sys.path.insert(0, HERE)
import love_schema  # noqa: E402

APP_CODE = ('lib', 'assets', 'android', 'ios', 'web', 'pubspec.yaml', 'pubspec.lock')
OVERRIDES = 'pubspec_overrides.yaml'
GIT_TIMEOUT_S = 60


def run_command(args, cwd, timeout):
    """(終了コード, 出力の末尾) を返す(gate.run_command と同じ形)。命令が無ければ FileNotFoundError、時間切れは TimeoutExpired。"""
    done = subprocess.run(args, cwd=cwd, capture_output=True, text=True, errors='replace', timeout=timeout)
    return done.returncode, ((done.stdout or '') + (done.stderr or ''))[-4000:]


def _first_line(out):
    lines = out.strip().splitlines()
    return lines[0].strip() if lines else ''


def current(app_dir, commit, run=run_command):
    """記録の commit から、アプリのコードの範囲が変わっていないか。(今のコードか, 理由) を返す。"""
    if os.path.exists(os.path.join(app_dir, OVERRIDES)):
        return False, f'共有をローカルで参照している({OVERRIDES})ので、今のコードを決められない'
    if not (isinstance(commit, str) and commit.strip()):
        return False, '記録に commit が無い'
    commit = commit.strip()
    try:
        code, out = run(['git', 'rev-parse', '--is-inside-work-tree'], app_dir, GIT_TIMEOUT_S)
        if code != 0 or _first_line(out) != 'true':
            return False, 'git のリポジトリでない'
        code, _ = run(['git', 'cat-file', '-e', commit + '^{commit}'], app_dir, GIT_TIMEOUT_S)
        if code != 0:
            return False, f'記録の commit({commit})が履歴に無い'
        code, out = run(['git', 'diff', '--quiet', commit, '--', *APP_CODE], app_dir, GIT_TIMEOUT_S)
        if code == 1:
            return False, f'アプリのコードが、記録の commit({commit})の後に変わった'
        if code != 0:
            return False, f'git diff が失敗した({out.strip()[-200:]})'
        code, out = run(['git', 'ls-files', '--others', '--exclude-standard', '--', *APP_CODE], app_dir, GIT_TIMEOUT_S)
        if code != 0:
            return False, f'git ls-files が失敗した({out.strip()[-200:]})'
        if out.strip():
            return False, f'追跡していないファイルがアプリのコードの中にある({_first_line(out)} など)'
    except FileNotFoundError:
        return False, 'git が見つからない'
    except (OSError, subprocess.TimeoutExpired) as e:
        return False, f'git を走らせられない({e})'
    return True, ''
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_check_current.py`
Expected: `Ran 10 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 135 tests`、`OK`

- [ ] **Step 5: 実際の NumberPlace で読み取りだけ試す**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B -c "import sys; sys.path.insert(0, 'twoyearsold_ui/tool'); import love_check; print(love_check.current('NumberPlace', 'HEAD'))"`
Expected: `(True, '')`(NumberPlace のアプリのコードに、commit していない変更が無い場合)

- [ ] **Step 6: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_check.py tool/tests/love_fixtures.py tool/tests/test_love_check_current.py
git commit -m "feat: 記録が今のコードに対するものかの判定(love_check.current)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7: 追う観点の確かめと、love 検査の入口

**Files:**
- Modify: `twoyearsold_ui/tool/love_check.py`(末尾に足す)
- Test: `twoyearsold_ui/tool/tests/test_love_check_verify.py`

**Interfaces:**
- Consumes: Task 5 の `love_schema.check_app`・`load_app`、Task 6 の `current`・`run_command`
- Produces:
  - `love_check.verify_aspect(app_dir, aspect, run=run_command) -> (status, detail)`
  - `love_check.check(app_dir, run=run_command) -> (status, reasons: list[str], items: list[{"id", "status", "detail"}])`。status は 'pass'・'fail'・'unmeasured'
  - `love_check.failures(reasons, items) -> list[str]`(gate の detail に並べるもの)
  - `love_check.main(argv=None, root=ROOT, run=run_command) -> int`(fail なら 1、アプリが無ければ 2)

- [ ] **Step 1: 落ちるテストを書く**

`twoyearsold_ui/tool/tests/test_love_check_verify.py`:

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
import love_check  # noqa: E402
from love_fixtures import aspect, complete, git, git_app, write_app  # noqa: E402

PASS = [sys.executable, '-c', 'pass']


class VerifyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.commit = git_app(self.app)
        self.findings, self.love = complete()
        for a in self.love['aspects']:
            a['check']['run'] = PASS
        self.save()

    def save(self):
        write_app(self.app, self.findings, self.love)

    def check(self, run=love_check.run_command):
        self.save()
        return love_check.check(self.app, run=run)

    def items(self, run=love_check.run_command):
        return {i['id']: i for i in self.check(run)[2]}

    def record(self, aid, **values):
        rec = {'aspect': aid, 'tool': 'launch_time', 'metric': 'median_ms', 'value': 1000, 'runs': [1000],
               'status': 'ok', 'reason': '', 'commit': self.commit, 'measured_at': '2026-10-21T10:00:00+09:00',
               'load_avg_1m': 2.0, 'device': {'avd': 'yardstick_play_35'}}
        rec.update(values)
        path = os.path.join(self.app, 'quality', 'love', 'measure', aid + '.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(rec, f)

    def change_lib(self):
        with open(os.path.join(self.app, 'lib', 'main.dart'), 'w', encoding='utf-8') as f:
            f.write('void main() { print(2); }\n')
        git(self.app, 'commit', '-q', '-am', 'change')

    def test_no_love_json_is_unmeasured(self):
        os.remove(os.path.join(self.app, 'quality', 'love', 'love.json'))
        self.assertEqual(love_check.check(self.app), ('unmeasured', ['愛の地図がまだ無い(quality/love/love.json)'], []))

    def test_broken_records_fail_without_running_any_check(self):
        calls = []
        self.love = {'aspects': 'x'}
        status, reasons, items = self.check(run=lambda *a: calls.append(a) or (0, ''))
        self.assertEqual((status, reasons, items), ('fail', ['壊れている: love.json: aspects が配列ではない'], []))
        self.assertEqual(calls, [])

    def test_all_pursued_commands_pass(self):
        status, reasons, items = self.check()
        self.assertEqual((status, reasons), ('pass', []))
        self.assertEqual([i['id'] for i in items], [f'aspect_{i:02d}' for i in range(10)])
        self.assertTrue(all(i['status'] == 'pass' for i in items))

    def test_a_failing_command_fails_only_its_aspect(self):  # Review Focus 4
        aspect(self.love, 'aspect_00')['check']['run'] = [
            sys.executable, '-c', 'import sys; print("x" * 5000); print("最後の行"); sys.exit(3)']
        aspect(self.love, 'aspect_01')['check']['run'] = ['no-such-command-for-love-test']
        status, _, items = self.check()
        by_id = {i['id']: i for i in items}
        self.assertEqual(status, 'fail')
        self.assertEqual(by_id['aspect_00']['status'], 'fail')
        self.assertTrue(by_id['aspect_00']['detail'].startswith('終了コード 3: '))
        self.assertIn('最後の行', by_id['aspect_00']['detail'])
        self.assertLessEqual(len(by_id['aspect_00']['detail']), 320)
        self.assertEqual(by_id['aspect_01'], {'id': 'aspect_01', 'status': 'fail',
                                              'detail': 'no-such-command-for-love-test が見つからない'})
        self.assertEqual([i['status'] for i in items[2:]], ['pass'] * 8)

    def test_a_hanging_command_is_cut_off(self):  # Review Focus 4
        aspect(self.love, 'aspect_00')['check'].update(run=['hang'], timeout_s=5)

        def run(args, cwd, timeout):
            if args[0] == 'hang':
                raise subprocess.TimeoutExpired(args, timeout)
            return 0, ''
        self.assertEqual(self.items(run)['aspect_00']['detail'], '5 秒で終わらなかった')

    def test_skip_and_hold_aspects_are_not_checked(self):
        aspect(self.love, 'aspect_00')['owner']['decision'] = 'skip'
        aspect(self.love, 'aspect_01')['owner']['decision'] = 'hold'
        self.assertEqual(sorted(self.items()), [f'aspect_{i:02d}' for i in range(2, 10)])

    def test_incomplete_records_fail_but_pursued_aspects_are_still_checked(self):
        aspect(self.love, 'aspect_02')['owner'] = None
        status, reasons, items = self.check()
        self.assertEqual(status, 'fail')
        self.assertEqual(reasons, ['まだ: love.json: aspect_02: オーナーの決定: まだ'])
        self.assertEqual(len(items), 9)

    def use_measure(self, target):
        a = aspect(self.love, 'aspect_00')
        a.update(check={'kind': 'measure', 'tool': 'launch_time', 'metric': 'median_ms'}, target=target)

    def test_measure_needs_a_current_record_that_meets_the_target(self):
        self.use_measure({'max': 1200})
        self.assertEqual(self.items()['aspect_00']['detail'], '測定の記録が無い(love_measure.py で測る)')
        self.record('aspect_00', value=1000)
        self.assertEqual(self.items()['aspect_00'],
                         {'id': 'aspect_00', 'status': 'pass', 'detail': '1000(目標: 上限 1200)'})
        self.record('aspect_00', value=1300)
        self.assertEqual(self.items()['aspect_00']['detail'], '1300 が目標の上限 1200 を超える')
        self.use_measure({'min': 50})
        self.record('aspect_00', value=40)
        self.assertEqual(self.items()['aspect_00']['detail'], '40 が目標の下限 50 に届かない')

    def test_measure_records_that_are_old_unmeasured_or_for_another_tool_fail(self):
        self.use_measure({'max': 1200})
        self.record('aspect_00', status='unmeasured', value=None, reason='盤が現れない')
        self.assertEqual(self.items()['aspect_00']['detail'], '測れていない(盤が現れない)')
        self.record('aspect_00', tool='new_game')
        self.assertEqual(self.items()['aspect_00']['detail'], '測定の記録の道具か値の種類が、確かめ方と違う')
        self.record('aspect_00')
        self.change_lib()
        self.assertTrue(self.items()['aspect_00']['detail'].startswith('記録が古い: アプリのコードが、記録の commit'))
        with open(os.path.join(self.app, 'quality', 'love', 'measure', 'aspect_00.json'), 'w') as f:
            f.write('{')
        self.assertTrue(self.items()['aspect_00']['detail'].startswith('測定の記録が読めない('))

    def use_human(self, last, verify='human'):
        a = aspect(self.love, 'aspect_00')
        a.update(verify=verify, human={'steps': ['★5 を 1 問解き、推測が要る場面が無いかを見る'], 'last': last})
        if verify == 'human':
            a['check'] = None

    def test_human_checks_need_a_current_pass(self):
        self.use_human(None)
        self.assertEqual(self.items()['aspect_00']['detail'], '人の確かめの記録が無い')
        last = {'date': '2026-10-21', 'commit': self.commit, 'by': 'owner', 'result': 'pass', 'note': ''}
        self.use_human(last)
        self.assertEqual(self.items()['aspect_00'], {'id': 'aspect_00', 'status': 'pass',
                                                    'detail': '人の確かめ 2026-10-21(owner)'})
        self.use_human(dict(last, result='fail', note='帯が数字に重なる'))
        self.assertEqual(self.items()['aspect_00']['detail'], '人の確かめが fail(2026-10-21: 帯が数字に重なる)')
        self.use_human(last)
        self.change_lib()
        self.assertTrue(self.items()['aspect_00']['detail'].startswith('人の確かめが古い: '))

    def test_both_needs_the_machine_and_the_human_check(self):
        self.use_human(None, verify='both')
        item = self.items()['aspect_00']
        self.assertEqual((item['status'], item['detail']), ('fail', '人の確かめの記録が無い'))

    def test_failures_lists_reasons_then_failed_aspects(self):
        items = [{'id': 'a', 'status': 'pass', 'detail': ''}, {'id': 'b', 'status': 'fail', 'detail': '遅い'}]
        self.assertEqual(love_check.failures(['まだ: x'], items), ['まだ: x', 'b: 遅い'])

    def test_main_prints_and_sets_the_exit_code(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.save()
            self.assertEqual(love_check.main(['Demo'], root=self.tmp), 0)
            aspect(self.love, 'aspect_00')['check']['run'] = [sys.executable, '-c', 'import sys; sys.exit(1)']
            self.save()
            self.assertEqual(love_check.main(['Demo'], root=self.tmp), 1)
            self.assertEqual(love_check.main(['Nope'], root=self.tmp), 2)
        self.assertIn('=== love: Demo(pass) ===', out.getvalue())
        self.assertIn('✗ aspect_00: 終了コード 1', out.getvalue())


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_check_verify.py`
Expected: `FAILED (errors=13)`。理由は `AttributeError: module 'love_check' has no attribute 'check'` など

- [ ] **Step 3: 実装を `love_check.py` の末尾に足す**

```python
DETAIL_TAIL = 300
MARKS = {'pass': '○', 'fail': '✗', 'unmeasured': '−'}


def _number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _command_status(app_dir, check, run):
    args = check['run']
    timeout = check.get('timeout_s', love_schema.DEFAULT_TIMEOUT_S)
    try:
        code, out = run(args, app_dir, timeout)
    except FileNotFoundError:
        return 'fail', f'{os.path.basename(args[0])} が見つからない'
    except subprocess.TimeoutExpired:
        return 'fail', f'{timeout} 秒で終わらなかった'
    except OSError as e:
        return 'fail', f'{os.path.basename(args[0])} を実行できない({e.strerror or e})'
    if code == 0:
        return 'pass', ''
    tail = ' / '.join(line.strip() for line in out.strip().splitlines()[-3:])
    return 'fail', f'終了コード {code}: {tail[-DETAIL_TAIL:]}'


def _measure_status(app_dir, aspect, run):
    check, target = aspect['check'], aspect.get('target')
    path = os.path.join(app_dir, love_schema.LOVE, 'measure', aspect['id'] + '.json')
    try:
        with open(path, encoding='utf-8') as f:
            rec = json.load(f)
    except FileNotFoundError:
        return 'fail', '測定の記録が無い(love_measure.py で測る)'
    except (OSError, ValueError) as e:
        return 'fail', f'測定の記録が読めない({e})'
    if not isinstance(rec, dict):
        return 'fail', '測定の記録がオブジェクトではない'
    if rec.get('tool') != check.get('tool') or rec.get('metric') != check.get('metric'):
        return 'fail', '測定の記録の道具か値の種類が、確かめ方と違う'
    if rec.get('status') != 'ok':
        return 'fail', f'測れていない({rec.get("reason") or "理由なし"})'
    ok, reason = current(app_dir, rec.get('commit'), run=run)
    if not ok:
        return 'fail', f'記録が古い: {reason}'
    value = rec.get('value')
    if not _number(value):
        return 'fail', '測定の値が数ではない'
    if not isinstance(target, dict) or not target:
        return 'fail', '目標(target)が無い'
    if 'max' in target and value > target['max']:
        return 'fail', f'{value} が目標の上限 {target["max"]} を超える'
    if 'min' in target and value < target['min']:
        return 'fail', f'{value} が目標の下限 {target["min"]} に届かない'
    bound = f'上限 {target["max"]}' if 'max' in target else f'下限 {target["min"]}'
    return 'pass', f'{value}(目標: {bound})'


def _human_status(app_dir, aspect, run):
    human = aspect.get('human')
    last = human.get('last') if isinstance(human, dict) else None
    if not isinstance(last, dict):
        return 'fail', '人の確かめの記録が無い'
    if last.get('result') != 'pass':
        return 'fail', f'人の確かめが fail({last.get("date")}: {last.get("note") or "理由なし"})'
    ok, reason = current(app_dir, last.get('commit'), run=run)
    if not ok:
        return 'fail', f'人の確かめが古い: {reason}'
    return 'pass', f'人の確かめ {last.get("date")}({last.get("by")})'


def verify_aspect(app_dir, aspect, run=run_command):
    """追う観点 1 つを確かめ、(status, detail) を返す。both は両方を満たして pass。"""
    verify = aspect.get('verify')
    parts = []
    if verify in ('machine', 'both'):
        check = aspect.get('check')
        if not isinstance(check, dict):
            parts.append(('fail', '機械の確かめ(check)が無い'))
        elif check.get('kind') == 'command':
            parts.append(_command_status(app_dir, check, run))
        else:
            parts.append(_measure_status(app_dir, aspect, run))
    if verify in ('human', 'both'):
        parts.append(_human_status(app_dir, aspect, run))
    if not parts:
        return 'fail', '確かめ方(verify)が無い'
    status = 'pass' if all(s == 'pass' for s, _ in parts) else 'fail'
    return status, ' / '.join(d for _, d in parts if d)


def check(app_dir, run=run_command):
    """gate の love 検査。(status, 形の理由の並び, 追う観点ごとの結果 [{id, status, detail}]) を返す。
    love.json が無ければ unmeasured。形が壊れていれば確かめずに fail。まだの所があれば fail だが、追う観点は確かめる。"""
    if not os.path.isfile(os.path.join(app_dir, love_schema.LOVE, 'love.json')):
        return 'unmeasured', ['愛の地図がまだ無い(quality/love/love.json)'], []
    broken, incomplete = love_schema.check_app(app_dir)
    reasons = [f'壊れている: {r}' for r in broken] + [f'まだ: {r}' for r in incomplete]
    if broken:
        return 'fail', reasons, []
    _, love, _ = love_schema.load_app(app_dir)
    items = []
    for a in love['aspects']:
        owner = a.get('owner')
        if isinstance(owner, dict) and owner.get('decision') == 'pursue':
            status, detail = verify_aspect(app_dir, a, run=run)
            items.append({'id': a['id'], 'status': status, 'detail': detail})
    failed = any(i['status'] == 'fail' for i in items)
    return ('fail' if reasons or failed else 'pass'), reasons, items


def failures(reasons, items):
    """gate の detail に出す並び: 形の理由と、目標を満たさない観点。"""
    return list(reasons) + [f"{i['id']}: {i['detail']}" for i in items if i['status'] == 'fail']


def main(argv=None, root=ROOT, run=run_command):
    parser = argparse.ArgumentParser(description='愛の地図の確かめ')
    parser.add_argument('app')
    args = parser.parse_args(argv)
    app_dir = os.path.join(root, args.app)
    if not os.path.isdir(app_dir):
        print(f'アプリが見つかりません: {app_dir}')
        return 2
    status, reasons, items = check(app_dir, run=run)
    print(f'=== love: {args.app}({status}) ===')
    for r in reasons:
        print(f'- {r}')
    for i in items:
        print(f"{MARKS[i['status']]} {i['id']}" + (f": {i['detail']}" if i['detail'] else ''))
    return 1 if status == 'fail' else 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_check_verify.py`
Expected: `Ran 13 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 148 tests`、`OK`

- [ ] **Step 5: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_check.py tool/tests/test_love_check_verify.py
git commit -m "feat: 追う観点の確かめ(速い確かめ・測定の記録・人の確かめ)と love 検査の入口" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8: gate の market を love に入れ替える

**Files:**
- Modify: `twoyearsold_ui/tool/gate.py`
- Modify: `twoyearsold_ui/tool/tests/test_gate.py`
- Remove: `twoyearsold_ui/tool/market_check.py`、`twoyearsold_ui/tool/market_report.py`、`twoyearsold_ui/tool/tests/test_market_check.py`、`twoyearsold_ui/tool/tests/test_market_report.py`(git の履歴に残る)

**Interfaces:**
- Consumes: Task 7 の `love_check.check`・`failures`、Task 4・5 の `love_fixtures.complete`・`aspect`・`write_app`
- Produces: gate の結果の `checks` の 7 つ目が `{"name": "love", "status", "detail", "seconds", "items": [{"id", "status", "detail"}]}`(`items` は love の行だけが必ず持つ)。人が読む表では、love の行の下に `| love: <id> | ... |` の行が並ぶ。

- [ ] **Step 1: テストを直す(落ちるようにする)**

`twoyearsold_ui/tool/tests/test_gate.py` に、この差分を当てる:

```diff
--- a/tool/tests/test_gate.py
+++ b/tool/tests/test_gate.py
@@ -11,6 +11,7 @@
 
 sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
 import gate  # noqa: E402
+from love_fixtures import aspect, complete, write_app  # noqa: E402
 
 
 class GateTest(unittest.TestCase):
@@ -58,9 +59,10 @@
     def test_all_checks_run_in_order_and_pass(self):
         report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
         self.assertEqual([c['name'] for c in report['checks']],
-                         ['analyze', 'test', 'quality', 'i18n', 'rights', 'licenses', 'market'])
+                         ['analyze', 'test', 'quality', 'i18n', 'rights', 'licenses', 'love'])
         self.assertTrue(report['ok'])
-        self.assertEqual(self.statuses(report)['market'], 'unmeasured')
+        self.assertEqual(self.statuses(report)['love'], 'unmeasured')
+        self.assertEqual(report['checks'][-1]['items'], [])
         self.assertEqual(report['app'], 'Demo')
         self.assertEqual([c[1] for c in self.calls], [self.app] * 4)
 
@@ -167,9 +169,36 @@
     def test_render_lists_every_check(self):
         report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
         text = gate.render(report)
-        for name in ('analyze', 'test', 'quality', 'i18n', 'rights', 'licenses', 'market'):
+        for name in ('analyze', 'test', 'quality', 'i18n', 'rights', 'licenses', 'love'):
             self.assertIn(name, text)
 
+    def test_love_reports_each_pursued_aspect_and_fails_the_gate_when_one_misses(self):
+        findings, love = complete()
+        aspect(love, 'aspect_03')['check']['run'] = ['python3', 'slow.py']
+        write_app(self.app, findings, love)
+        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({'slow.py': (1, '1800ms > 1200ms')}))
+        row = report['checks'][-1]
+        self.assertEqual((row['name'], row['status']), ('love', 'fail'))
+        self.assertEqual(row['detail'], 'aspect_03: 終了コード 1: 1800ms > 1200ms')
+        self.assertEqual(len(row['items']), 10)
+        self.assertEqual([i['id'] for i in row['items'] if i['status'] == 'fail'], ['aspect_03'])
+        self.assertFalse(report['ok'])
+        self.assertIn('| love: aspect_03 | ✗ fail | | 終了コード 1: 1800ms > 1200ms |', gate.render(report))
 
+    def test_love_passes_when_every_pursued_aspect_meets_its_check(self):
+        findings, love = complete()
+        write_app(self.app, findings, love)
+        report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
+        self.assertEqual(self.statuses(report)['love'], 'pass')
+        self.assertTrue(report['ok'])
+
+    def test_an_exception_inside_love_is_reported_with_empty_items(self):
+        with mock.patch.object(gate.love_check, 'check', side_effect=RuntimeError('boom')):
+            report = gate.run_gate('Demo', root=self.tmp, run=self.fake_run({}))
+        row = report['checks'][-1]
+        self.assertEqual((row['status'], row['items']), ('fail', []))
+        self.assertIn('boom', row['detail'])
+
+
 if __name__ == '__main__':
     unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_gate.py`
Expected: `FAILED (failures=3, errors=2)`。理由は `Lists differ: [... 'market'] != [... 'love']`、`AttributeError: module 'gate' has no attribute 'love_check'` など

- [ ] **Step 3: gate を直し、market の道具を外す**

`twoyearsold_ui/tool/gate.py` に、この差分を当てる:

```diff
--- a/tool/gate.py
+++ b/tool/gate.py
@@ -2,7 +2,7 @@
 """第 1 層の入口 — 1 つのアプリについて、機械で確かめられる品質をまとめて確かめる。
 
 順に走らせる: flutter analyze / 全テスト(ゴールデンとタップ領域の巡回を含む)/ 横断ガード / 翻訳ガード /
-権利の語の検査 / ライセンス表示の確認 / 第 3 層の記録の形の検査。
+権利の語の検査 / ライセンス表示の確認 / 愛の地図の確かめ(love。追う観点ごとの結果を items に入れる)。
 人が読む表を標準出力に出し、--json を渡すとそこへ機械が読める JSON を書く。
 1 つでも不合格(fail)なら exit 1。未計測(unmeasured、理由つき)は不合格にしない。
 
@@ -22,7 +22,7 @@
 HERE = os.path.dirname(os.path.abspath(__file__))
 ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
 sys.path.insert(0, HERE)
-import market_check  # noqa: E402
+import love_check  # noqa: E402
 import rights_guard  # noqa: E402
 
 ANALYZE_TIMEOUT_S = 900
@@ -79,9 +79,9 @@
     return ('fail' if found else 'pass'), _joined(found)
 
 
-def _market(app_dir):
-    status, reasons = market_check.check_market(app_dir)
-    return status, _joined(reasons)
+def _love(app_dir, run):
+    status, reasons, items = love_check.check(app_dir, run=run)
+    return status, _joined(love_check.failures(reasons, items)), items
 
 
 def _guarded(check):
@@ -96,9 +96,11 @@
     app_dir = os.path.join(root, app)
     checks = []
 
-    def add(name, status, detail, started):
-        checks.append({'name': name, 'status': status, 'detail': detail,
-                       'seconds': round(time.monotonic() - started, 1)})
+    def add(name, status, detail, started, items=None):
+        row = {'name': name, 'status': status, 'detail': detail, 'seconds': round(time.monotonic() - started, 1)}
+        if name == 'love':
+            row['items'] = items or []
+        checks.append(row)
 
     commands = [
         ('analyze', ['flutter', 'analyze'], ANALYZE_TIMEOUT_S),
@@ -113,10 +115,10 @@
 
     for name, check in (('rights', lambda: _rights(app_dir)),
                         ('licenses', lambda: check_licenses(app_dir)),
-                        ('market', lambda: _market(app_dir))):
+                        ('love', lambda: _love(app_dir, run))):
         started = time.monotonic()
-        status, detail = _guarded(check)
-        add(name, status, detail, started)
+        status, detail, *items = _guarded(check)
+        add(name, status, detail, started, items[0] if items else None)
 
     return {
         'app': app,
@@ -135,6 +137,9 @@
     for c in report['checks']:
         detail = c['detail'].replace('|', '/')
         lines.append(f"| {c['name']} | {MARKS[c['status']]} {c['status']} | {c['seconds']} | {detail} |")
+        for item in c.get('items', []):
+            text = item['detail'].replace('|', '/')
+            lines.append(f"| {c['name']}: {item['id']} | {MARKS[item['status']]} {item['status']} | | {text} |")
     return '\n'.join(lines)
 
 
```

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git rm -q tool/market_check.py tool/market_report.py tool/tests/test_market_check.py tool/tests/test_market_report.py
grep -rn 'market_check\|market_report' tool || echo なし
```

Expected: `なし`

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_gate.py`
Expected: `Ran 14 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 133 tests`、`OK`(market のテスト 18 件が外れ、gate のテストが 3 件増える)

- [ ] **Step 5: NumberPlace で gate を走らせる(結果のファイルはまだ書かない)**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/gate.py NumberPlace`
Expected: 表の最後の行が `| love | − unmeasured | ... | 愛の地図がまだ無い(quality/love/love.json) |`。ほかの 6 つは `NumberPlace/quality/gate.json` の前回の結果と同じ(pass)。exit 0。数分かかる。

- [ ] **Step 6: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/gate.py tool/tests/test_gate.py
git commit -m "feat: gate の market(市場との比較)を love(愛の地図の確かめ)に入れ替える" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 9: 地図と評価の文書を作る

**Files:**
- Create: `twoyearsold_ui/tool/love_report.py`
- Test: `twoyearsold_ui/tool/tests/test_love_report.py`

**Interfaces:**
- Consumes: `love_schema.check_app`・`load_app`・`findings_by_id`・`layer_counts`・`layers`・`sources`・`strength`・`LAYERS`・`GRADES`・`DECISIONS`
- Produces:
  - `love_report.render_map(app, findings, love, incomplete=()) -> str`
  - `love_report.render_assessment(app, love, gate=None, incomplete=()) -> str`(gate は `quality/gate.json` の中身)
  - `love_report.main(argv=None, root=ROOT) -> int`(broken なら書かずに 2)。CLI は `python3 twoyearsold_ui/tool/love_report.py <App>`

- [ ] **Step 1: 落ちるテストを書く**

`twoyearsold_ui/tool/tests/test_love_report.py`:

```python
import contextlib
import io
import os
import shutil
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import love_report  # noqa: E402
from love_fixtures import aspect, complete, finding, write_app  # noqa: E402


class RenderTest(unittest.TestCase):
    def setUp(self):
        self.findings, self.love = complete()

    def lines(self, text):
        return text.splitlines()

    def test_the_map_shows_counts_strength_evidence_harms_examples_and_coverage(self):
        text = love_report.render_map('Demo', self.findings, self.love)
        lines = self.lines(text)
        for want in ('# 愛の地図(Demo)',
                     '所見: 全 30 件(毎日解く人 10 件・解き筋を極める愛好家 10 件・変種を楽しむ人 10 件・層を決められない 0 件)',
                     '## 1. 観点 0(`aspect_00`)', '- 層: 毎日解く人・解き筋を極める愛好家', '- 強さ: 中(2 層、発信者 2)',
                     '- 確かめ方: 機械', '- f001 発信者 f001「題 f001」: 要約 f001 <https://example.com/f001>',
                     '裏返し(これを損なうもの)', '- 裏返し 0', '  - f003 発信者 f003「題 f003」: 要約 f003 <https://example.com/f003>',
                     '愛されている例', '- 作品 0: 応え方 0(f001)', '## 見落としの点検',
                     '- notes → 観点 0', '- rewarded_ads → 当たらない: 広告は方針の外'):
            self.assertIn(want, lines)
        self.assertFalse([line for line in lines if line.startswith('|')], '表を使わない')

    def test_a_finding_without_a_title_has_no_empty_brackets(self):
        self.findings['findings'][0] = finding('f001', layer='daily', title='')
        self.assertIn('- f001 発信者 f001: 要約 f001 <https://example.com/f001>',
                      self.lines(love_report.render_map('Demo', self.findings, self.love)))

    def test_the_map_can_be_made_from_findings_alone(self):  # Review Focus 5
        text = love_report.render_map('Demo', self.findings, None, incomplete=['findings.json: x'])
        self.assertIn('所見: 全 30 件', text)
        self.assertIn('## まだの所', text)
        self.assertNotIn('## 1.', text)

    def test_the_assessment_shows_grades_fixes_decisions_checks_and_the_latest_gate(self):
        a0 = aspect(self.love, 'aspect_00')
        for key in ('a', 'b', 'final'):
            a0['assessment'][key]['grade'] = 'lacks'
        a0['assessment']['final']['evidence'] = ['evidence/a/aspect_00-1.png', 'code: lib/main.dart:1']
        a0['assessment'].update(fix='数字ごとの残りの数を出す', effort='small')
        a1 = aspect(self.love, 'aspect_01')
        a1.update(verify='both', check={'kind': 'measure', 'tool': 'new_game', 'metric': 'median_ms'},
                  target={'max': 800}, human={'steps': ['★5 を 1 問解く', '止まりを見る'], 'last': {
                      'date': '2026-10-21', 'commit': 'abc1234', 'by': 'owner', 'result': 'pass', 'note': ''}})
        aspect(self.love, 'aspect_02')['owner']['decision'] = 'skip'
        self.love['fix_order'] = [{'id': 'aspect_00', 'reason': '手間が小さい'}]
        gate = {'checked_at': '2026-10-21T10:00:00+09:00',
                'checks': [{'name': 'love', 'items': [{'id': 'aspect_00', 'status': 'fail', 'detail': '残りの数が無い'}]}]}
        lines = self.lines(love_report.render_assessment('Demo', self.love, gate))
        for want in ('# 評価と線(Demo)', '段: 応えている 9・足りない 1・反している 0・未確認 0・未 0',
                     '決定: 追う 9・追わない 1・保留 0・未 0',
                     '- 最終の段: 足りない(A: 足りない / B: 足りない)',
                     '  - ![evidence/a/aspect_00-1.png](evidence/a/aspect_00-1.png)', '  - code: lib/main.dart:1',
                     '- 愛されている例:', '  - 作品 0: 応え方 0',
                     '- 直し方の案: 数字ごとの残りの数を出す(手間: 小)', '- 推奨: 追う — 推奨の理由 0',
                     '- オーナーの決定: 追う(2026-10-20) — 決定の理由 0', '- 機械の確かめ: 速い確かめ `python3 ok.py`',
                     '- 最新の gate(2026-10-21T10:00:00+09:00): ✗ fail — 残りの数が無い',
                     '- 機械の確かめ: 出題の時間の中央値(ms)の上限 800', '- 人の確かめ:', '  1. ★5 を 1 問解く',
                     '  2. 止まりを見る', '  - 記録: 2026-10-21 owner pass(commit abc1234)',
                     '- オーナーの決定: 追わない(2026-10-20) — 決定の理由 2',
                     '## 直す順の案', '1. 観点 0(`aspect_00`): 手間が小さい'):
            self.assertIn(want, lines)
        self.assertFalse([line for line in lines if line.startswith('|')], '表を使わない')

    def test_parts_that_are_not_done_yet_show_as_not_yet(self):
        a0 = aspect(self.love, 'aspect_00')
        a0.update(assessment=None, owner=None, recommendation=None)
        lines = self.lines(love_report.render_assessment('Demo', self.love, None, incomplete=['love.json: x']))
        for want in ('- 最終の段: 未(A: 未 / B: 未)', '- 推奨: 未', '- オーナーの決定: 未',
                     '段: 応えている 9・足りない 0・反している 0・未確認 0・未 1', '## まだの所', '- love.json: x'):
            self.assertIn(want, lines)


class MainTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.love_dir = os.path.join(self.app, 'quality', 'love')
        self.findings, self.love = complete()

    def main(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = love_report.main(['Demo'], root=self.tmp)
        return code, out.getvalue()

    def read(self, name):
        with open(os.path.join(self.love_dir, name), encoding='utf-8') as f:
            return f.read()

    def test_writes_both_documents(self):
        write_app(self.app, self.findings, self.love)
        self.assertEqual(self.main(), (0, '書いた: map.md・assessment.md\n'))
        self.assertIn('# 愛の地図(Demo)', self.read('map.md'))
        self.assertIn('# 評価と線(Demo)', self.read('assessment.md'))

    def test_incomplete_records_are_written_with_the_count(self):
        aspect(self.love, 'aspect_00')['owner'] = None
        write_app(self.app, self.findings, self.love)
        self.assertEqual(self.main(), (0, '書いた: map.md・assessment.md(まだの所 1 件)\n'))
        self.assertIn('- love.json: aspect_00: オーナーの決定: まだ', self.read('assessment.md'))

    def test_findings_alone_write_only_the_map(self):  # Review Focus 5
        write_app(self.app, self.findings, None)
        self.assertEqual(self.main()[0], 0)
        self.assertTrue(os.path.exists(os.path.join(self.love_dir, 'map.md')))
        self.assertFalse(os.path.exists(os.path.join(self.love_dir, 'assessment.md')))

    def test_broken_records_are_not_written(self):
        write_app(self.app, self.findings, {'aspects': 'x'})
        code, out = self.main()
        self.assertEqual(code, 2)
        self.assertIn('形が壊れているので、書かない:', out)
        self.assertFalse(os.path.exists(os.path.join(self.love_dir, 'map.md')))

    def test_a_missing_folder_or_findings_is_refused(self):
        self.assertEqual(self.main()[0], 2)
        os.makedirs(self.love_dir)
        self.assertEqual(self.main(), (2, 'findings.json がまだ無い\n'))

    def test_a_failed_write_keeps_the_previous_document(self):  # Review Focus 5
        write_app(self.app, self.findings, self.love)
        with open(os.path.join(self.love_dir, 'map.md'), 'w', encoding='utf-8') as f:
            f.write('前の地図\n')
        with mock.patch.object(love_report.os, 'replace', side_effect=OSError('disk full')):
            with self.assertRaises(OSError):
                self.main()
        self.assertEqual(self.read('map.md'), '前の地図\n')

    def test_an_unreadable_gate_json_is_ignored(self):
        write_app(self.app, self.findings, self.love)
        os.makedirs(os.path.join(self.app, 'quality'), exist_ok=True)
        with open(os.path.join(self.app, 'quality', 'gate.json'), 'w', encoding='utf-8') as f:
            f.write('{')
        self.assertEqual(self.main()[0], 0)
        self.assertNotIn('最新の gate', self.read('assessment.md'))


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_report.py`
Expected: `FAILED (errors=1)`。理由は `ModuleNotFoundError: No module named 'love_report'`

- [ ] **Step 3: 実装を書く**

`twoyearsold_ui/tool/love_report.py`:

```python
# coding: utf-8
"""愛の地図の生成 — findings.json と love.json から、人が読む map.md と assessment.md を作る。

表は使わず、見出しと箇条書きで書く(オーナーは別の端末で読むことがある)。評価の根拠の画面の写しは画像として埋め込む。
形が壊れている(broken)ときは書かずに exit 2。まだの所(incomplete)は「未」と出して書く。
love.json がまだ無い(所見だけの)ときは、map.md だけを作る。書きかけで止まっても前の文書が壊れないよう、一時ファイルから置き換える。

使い方:
  python3 twoyearsold_ui/tool/love_report.py <AppName>
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
sys.path.insert(0, HERE)
import love_schema  # noqa: E402

LAYER_NAMES = {'daily': '毎日解く人', 'expert': '解き筋を極める愛好家', 'variant': '変種を楽しむ人', 'any': '層を決められない'}
STRENGTH_NAMES = {'strong': '強', 'medium': '中', 'weak': '弱'}
VERIFY_NAMES = {'machine': '機械', 'human': '人', 'both': '機械と人'}
GRADE_NAMES = {'meets': '応えている', 'lacks': '足りない', 'violates': '反している', 'unverified': '未確認'}
EFFORT_NAMES = {'small': '小', 'medium': '中', 'large': '大'}
DECISION_NAMES = {'pursue': '追う', 'skip': '追わない', 'hold': '保留'}
TOOL_NAMES = {'launch_time': '起動の時間', 'new_game': '出題の時間'}
MARKS = {'pass': '○', 'fail': '✗', 'unmeasured': '−'}
NOT_YET = '未'
DETAIL_LIMIT = 10


def _header(title, app):
    return [f'# {title}({app})', '',
            f'> 生成物。手で直さない。元は quality/love/findings.json と quality/love/love.json。'
            f'作り直すには `python3 twoyearsold_ui/tool/love_report.py {app}`。', '']


def _finding_line(f):
    title = f'「{f["title"]}」' if f.get('title') else ''
    return f'{f["id"]} {f["source"]}{title}: {f["summary"]} <{f["url"]}>'


def _aspects(love):
    return [a for a in (love or {}).get('aspects') or [] if isinstance(a, dict)]


def _not_yet_section(incomplete):
    return ['', '## まだの所', ''] + [f'- {r}' for r in incomplete] if incomplete else []


def render_map(app, findings, love, incomplete=()):
    by_id = love_schema.findings_by_id(findings)
    counts = love_schema.layer_counts(findings)
    lines = _header('愛の地図', app)
    lines.append(f'所見: 全 {sum(counts.values())} 件('
                 + '・'.join(f'{LAYER_NAMES[k]} {counts[k]} 件' for k in love_schema.LAYERS) + ')')
    lines += _not_yet_section(incomplete)
    aspects = _aspects(love)
    for n, a in enumerate(aspects, 1):
        lines += ['', f'## {n}. {a.get("name") or NOT_YET}(`{a.get("id")}`)', '', a.get('description') or NOT_YET, '']
        layer_names = [LAYER_NAMES[x] for x in love_schema.layers(a, by_id)]
        lines.append(f'- 層: {"・".join(layer_names) or NOT_YET}')
        lines.append(f'- 強さ: {STRENGTH_NAMES[love_schema.strength(a, by_id)]}'
                     f'({len(layer_names)} 層、発信者 {len(love_schema.sources(a, by_id))})')
        lines.append(f'- 確かめ方: {VERIFY_NAMES.get(a.get("verify"), NOT_YET)}')
        lines += ['', '根拠', ''] + [f'- {_finding_line(by_id[f])}' for f in a.get('evidence') or [] if f in by_id]
        harms = a.get('harms') or []
        if harms:
            lines += ['', '裏返し(これを損なうもの)', '']
            for h in harms:
                lines.append(f'- {h.get("text") or NOT_YET}')
                lines += [f'  - {_finding_line(by_id[f])}' for f in h.get('evidence') or [] if f in by_id]
        examples = a.get('examples') or []
        if examples:
            lines += ['', '愛されている例', '']
            lines += [f'- {e.get("name") or NOT_YET}: {e.get("how") or NOT_YET}({"・".join(e.get("evidence") or [])})'
                      for e in examples]
    cov = (love or {}).get('coverage_check')
    if isinstance(cov, dict):
        names = {a.get('id'): a.get('name') for a in aspects}
        lines += ['', '## 見落としの点検', '',
                  f'点検表: 旧方針の機能表の下書き(NumberPlace の commit {cov.get("checklist_commit") or NOT_YET})', '']
        for row in cov.get('rows') or []:
            if row.get('aspect'):
                lines.append(f'- {row["row"]} → {names.get(row["aspect"]) or row["aspect"]}')
            else:
                lines.append(f'- {row["row"]} → 当たらない: {row.get("note") or NOT_YET}')
    return '\n'.join(lines) + '\n'


def _grade(block):
    return GRADE_NAMES.get((block or {}).get('grade'), NOT_YET)


def _ref_line(ref):
    return f'![{ref}]({ref})' if ref.startswith('evidence/') else ref


def _machine_line(check, target):
    if not isinstance(check, dict):
        return NOT_YET
    if check.get('kind') == 'command':
        return '速い確かめ `' + ' '.join(check.get('run') or []) + '`'
    t = target if isinstance(target, dict) else {}
    bound = f'上限 {t["max"]}' if 'max' in t else (f'下限 {t["min"]}' if 'min' in t else NOT_YET)
    return f'{TOOL_NAMES.get(check.get("tool"), check.get("tool"))}の中央値(ms)の{bound}'


def _love_items(gate):
    for c in (gate or {}).get('checks') or []:
        if isinstance(c, dict) and c.get('name') == 'love':
            return {i.get('id'): i for i in c.get('items') or [] if isinstance(i, dict)}, gate.get('checked_at', '')
    return {}, ''


def render_assessment(app, love, gate=None, incomplete=()):
    aspects = _aspects(love)
    items, checked_at = _love_items(gate)
    lines = _header('評価と線', app)
    finals = [((a.get('assessment') or {}).get('final') or {}).get('grade') for a in aspects]
    lines.append('段: ' + '・'.join(f'{GRADE_NAMES[g]} {finals.count(g)}' for g in love_schema.GRADES)
                 + f'・{NOT_YET} {sum(1 for g in finals if g not in love_schema.GRADES)}')
    decisions = [(a.get('owner') or {}).get('decision') for a in aspects]
    lines.append('決定: ' + '・'.join(f'{DECISION_NAMES[d]} {decisions.count(d)}' for d in love_schema.DECISIONS)
                 + f'・{NOT_YET} {sum(1 for d in decisions if d not in love_schema.DECISIONS)}')
    lines += _not_yet_section(incomplete)
    for n, a in enumerate(aspects, 1):
        block = a.get('assessment') or {}
        final = block.get('final') or {}
        lines += ['', f'## {n}. {a.get("name") or NOT_YET}(`{a.get("id")}`)', '']
        lines.append(f'- 最終の段: {_grade(final)}(A: {_grade(block.get("a"))} / B: {_grade(block.get("b"))})')
        if final.get('reconcile'):
            lines.append(f'- 突き合わせ: {final["reconcile"]}')
        refs = final.get('evidence') or []
        if refs:
            lines += ['- 根拠:'] + [f'  - {_ref_line(r)}' for r in refs]
        examples = a.get('examples') or []
        if examples:  # 比べる相手ではなく、その観点にこう応えている例として並べる
            lines += ['- 愛されている例:'] + [f'  - {e.get("name") or NOT_YET}: {e.get("how") or NOT_YET}' for e in examples]
        if block.get('fix'):
            lines.append(f'- 直し方の案: {block["fix"]}(手間: {EFFORT_NAMES.get(block.get("effort"), NOT_YET)})')
        rec = a.get('recommendation') or {}
        lines.append(f'- 推奨: {DECISION_NAMES.get(rec.get("decision"), NOT_YET)}'
                     + (f' — {rec["reason"]}' if rec.get('reason') else ''))
        owner = a.get('owner') or {}
        if owner.get('decision') in DECISION_NAMES:
            lines.append(f'- オーナーの決定: {DECISION_NAMES[owner["decision"]]}({owner.get("date") or NOT_YET})'
                         + (f' — {owner["reason"]}' if owner.get('reason') else ''))
        else:
            lines.append(f'- オーナーの決定: {NOT_YET}')
        if a.get('verify') in ('machine', 'both'):
            lines.append(f'- 機械の確かめ: {_machine_line(a.get("check"), a.get("target"))}')
        if a.get('verify') in ('human', 'both'):
            human = a.get('human') or {}
            steps = human.get('steps') or []
            lines += ['- 人の確かめ:'] + ([f'  {i}. {s}' for i, s in enumerate(steps, 1)] or [f'  - 手順: {NOT_YET}'])
            last = human.get('last')
            lines.append(f'  - 記録: {last["date"]} {last["by"]} {last["result"]}(commit {last["commit"]})'
                         if isinstance(last, dict) else f'  - 記録: {NOT_YET}')
        item = items.get(a.get('id'))
        if item:
            lines.append(f'- 最新の gate({checked_at}): {MARKS.get(item.get("status"), "")} {item.get("status")}'
                         + (f' — {item["detail"]}' if item.get('detail') else ''))
    order = (love or {}).get('fix_order') or []
    if order:
        names = {a.get('id'): a.get('name') for a in aspects}
        lines += ['', '## 直す順の案', '']
        lines += [f'{i}. {names.get(r.get("id")) or r.get("id")}(`{r.get("id")}`): {r.get("reason") or NOT_YET}'
                  for i, r in enumerate(order, 1)]
    return '\n'.join(lines) + '\n'


def _write(path, text):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        f.write(text)
    os.replace(tmp, path)  # 書きかけで止まっても、前の文書は壊れない


def main(argv=None, root=ROOT):
    parser = argparse.ArgumentParser(description='愛の地図の生成')
    parser.add_argument('app')
    args = parser.parse_args(argv)
    app_dir = os.path.join(root, args.app)
    love_dir = os.path.join(app_dir, love_schema.LOVE)
    if not os.path.isdir(love_dir):
        print(f'愛の地図の場所が無い: {love_dir}')
        return 2
    broken, incomplete = love_schema.check_app(app_dir)
    if broken:
        print('形が壊れているので、書かない:')
        for r in broken[:DETAIL_LIMIT]:
            print(f'- {r}')
        if len(broken) > DETAIL_LIMIT:
            print(f'- ほか {len(broken) - DETAIL_LIMIT} 件')
        return 2
    findings, love, _ = love_schema.load_app(app_dir)
    if findings is None:
        print('findings.json がまだ無い')
        return 2
    _write(os.path.join(love_dir, 'map.md'), render_map(args.app, findings, love, incomplete))
    written = ['map.md']
    if love is not None:
        gate = None
        try:
            with open(os.path.join(app_dir, 'quality', 'gate.json'), encoding='utf-8') as f:
                gate = json.load(f)
        except (OSError, ValueError):
            gate = None
        _write(os.path.join(love_dir, 'assessment.md'), render_assessment(args.app, love, gate, incomplete))
        written.append('assessment.md')
    print('書いた: ' + '・'.join(written) + (f'(まだの所 {len(incomplete)} 件)' if incomplete else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_report.py`
Expected: `Ran 12 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests`
Expected: `Ran 145 tests`、`OK`

- [ ] **Step 5: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_report.py tool/tests/test_love_report.py
git commit -m "feat: 愛の地図と評価の文書を作る(love_report。表を使わない)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 10: 遅い測定の道具

**Files:**
- Create: `twoyearsold_ui/tool/love_measure.py`
- Test: `twoyearsold_ui/tool/tests/test_love_measure.py`

**Interfaces:**
- Consumes: Task 6・7 の `love_check.run_command`・`current`・`verify_aspect`、`love_schema.LOVE`・`TOOLS`、Task 2 の `conditions.json` の形
- Produces:
  - `love_measure.Stop(reason, code)`(code は 2・3・1)
  - `love_measure.measure(app_dir, aspect_id, run=..., load_avg=os.getloadavg, now=..., python=sys.executable) -> dict`(仕様 10.4 の記録。`quality/love/measure/<観点の id>.json` にも書く)
  - `love_measure.main(argv=None, root=ROOT, **deps) -> int`。CLI は `python3 twoyearsold_ui/tool/love_measure.py <App> <観点の id>`

- [ ] **Step 1: 落ちるテストを書く**

`twoyearsold_ui/tool/tests/test_love_measure.py`:

```python
import contextlib
import datetime as dt
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import love_check  # noqa: E402
import love_measure  # noqa: E402
from love_fixtures import aspect, complete, git, git_app, write_app  # noqa: E402

OK_RESULT = '{"runs": [900, 1000, 1100], "median": 1000, "status": "ok", "reason": ""}'
CONDITIONS = {'avd': 'yardstick_play_35', 'image': 'android-35 google_apis_playstore arm64-v8a',
              'load_limit_1m': 6.0, 'runs': {'launch_time': 11, 'new_game': 5},
              'decided_on': '2026-10-16', 'basis': 'テストの条件'}


class MeasureTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.app = os.path.join(self.tmp, 'Demo')
        self.commit = git_app(self.app)
        findings, love = complete()
        aspect(love, 'aspect_00').update(check={'kind': 'measure', 'tool': 'launch_time', 'metric': 'median_ms'},
                                         target={'max': 1200})
        self.love_dir = write_app(self.app, findings, love)
        self.write('measure/conditions.json', json.dumps(CONDITIONS))
        self.write('measure/scripts/self.json', '{"app": "self"}')
        self.calls = []
        self.outcomes = {}

    def write(self, rel, text):
        path = os.path.join(self.love_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)

    def run_fake(self, args, cwd, timeout):
        self.calls.append(args)
        if args[0] == 'git':
            return love_check.run_command(args, cwd, timeout)
        if args[1:3] == ['emu', 'avd']:
            key, default = 'avd', (0, 'yardstick_play_35\r\nOK\r\n')
        elif args[0] == 'flutter':
            key, default = 'build', (0, 'Built build/app/outputs/flutter-apk/app-release.apk\n')
        elif args[1:2] == ['install']:
            key, default = 'install', (0, 'Performing Streamed Install\nSuccess\n')
        else:
            key, default = 'tool', (0, '測っている\n' + OK_RESULT + '\n')
        outcome = self.outcomes.get(key, default)
        if isinstance(outcome, BaseException):
            raise outcome
        return outcome

    def measure(self, aid='aspect_00', load=2.5):
        jst = dt.timezone(dt.timedelta(hours=9))
        return love_measure.measure(self.app, aid, run=self.run_fake, load_avg=lambda: (load, 0.0, 0.0),
                                    now=lambda: dt.datetime(2026, 10, 21, 10, 0, tzinfo=jst))

    def record_path(self, aid='aspect_00'):
        return os.path.join(self.love_dir, 'measure', aid + '.json')

    def stop(self, **kwargs):
        with self.assertRaises(love_measure.Stop) as caught:
            self.measure(**kwargs)
        return caught.exception.code, str(caught.exception)

    def built(self):
        return any(c[0] == 'flutter' for c in self.calls)

    def test_measures_and_writes_a_record_with_commit_load_and_device(self):
        rec = self.measure()
        self.assertEqual(rec, {
            'aspect': 'aspect_00', 'tool': 'launch_time', 'metric': 'median_ms', 'value': 1000,
            'runs': [900, 1000, 1100], 'status': 'ok', 'reason': '', 'commit': self.commit,
            'measured_at': '2026-10-21T10:00:00+09:00', 'load_avg_1m': 2.5,
            'device': {'avd': 'yardstick_play_35', 'image': 'android-35 google_apis_playstore arm64-v8a'}})
        with open(self.record_path(), encoding='utf-8') as f:
            self.assertEqual(json.load(f), rec)
        tool_call = self.calls[-1]
        self.assertTrue(tool_call[2].endswith(os.path.join('perf', 'launch_time.py')))
        script = os.path.join(self.love_dir, 'measure', 'scripts', 'self.json')
        self.assertEqual(tool_call[3:], [script, '--runs', '11'])
        self.assertFalse(os.path.exists(self.record_path() + '.tmp'))

    def test_the_record_is_then_accepted_by_love_check_as_current(self):
        self.measure()
        with open(os.path.join(self.love_dir, 'love.json'), encoding='utf-8') as f:
            love = json.load(f)
        status, detail = love_check.verify_aspect(self.app, aspect(love, 'aspect_00'))
        self.assertEqual((status, detail), ('pass', '1000(目標: 上限 1200)'))

    def test_uncommitted_app_code_stops_before_building(self):
        with open(os.path.join(self.app, 'lib', 'new.dart'), 'w') as f:
            f.write('// new\n')
        code, reason = self.stop()
        self.assertEqual(code, 2)
        self.assertIn('今のコードを測れない: 追跡していないファイル', reason)
        self.assertFalse(self.built())
        self.assertFalse(os.path.exists(self.record_path()))

    def test_a_local_override_stops_before_building(self):
        with open(os.path.join(self.app, 'pubspec_overrides.yaml'), 'w') as f:
            f.write('dependency_overrides: {}\n')
        self.assertEqual(self.stop()[0], 2)
        self.assertFalse(self.built())

    def test_a_busy_mac_stops_before_building(self):
        code, reason = self.stop(load=9.0)
        self.assertEqual((code, reason), (3, 'Mac の負荷が高い(1 分値 9.0 が上限 6.0 を超える)。下がってから測る'))
        self.assertFalse(self.built())

    def test_another_emulator_stops_before_building(self):
        self.outcomes['avd'] = (0, 'np\r\nOK\r\n')
        self.assertEqual(self.stop(), (3, 'つながっているエミュレータ(np)が、条件の yardstick_play_35 ではない'))
        self.outcomes['avd'] = (1, 'error: no emulators found')
        self.assertEqual(self.stop()[0], 3)
        self.assertFalse(self.built())

    def test_a_failed_build_or_install_writes_no_record(self):
        self.outcomes['install'] = (1, 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match]')
        code, reason = self.stop()
        self.assertEqual(code, 1)
        self.assertIn('INSTALL_FAILED_UPDATE_INCOMPATIBLE', reason)
        self.outcomes['build'] = (1, 'Gradle task assembleRelease failed')
        self.assertEqual(self.stop()[0], 1)
        self.assertFalse(os.path.exists(self.record_path()))

    def test_a_device_failure_during_the_tool_writes_no_record(self):
        self.outcomes['tool'] = (3, '端末とのつながりの失敗で測れなかった(記録には書かない): device offline')
        self.assertEqual(self.stop()[0], 3)
        self.outcomes['tool'] = (0, 'no json here')
        self.assertEqual(self.stop()[0], 1)
        self.assertFalse(os.path.exists(self.record_path()))

    def test_an_unmeasured_result_is_recorded(self):
        self.outcomes['tool'] = (0, '{"runs": [], "median": null, "status": "unmeasured", "reason": "盤が現れない"}\n')
        rec = self.measure()
        self.assertEqual((rec['status'], rec['value'], rec['reason']), ('unmeasured', None, '盤が現れない'))
        self.assertTrue(os.path.exists(self.record_path()))

    def test_only_measure_aspects_with_conditions_can_be_measured(self):
        self.assertEqual(self.stop(aid='aspect_01'), (2, '観点 aspect_01 の確かめ方は measure ではない'))
        self.assertEqual(self.stop(aid='nope'), (2, '観点 nope が love.json に無い'))
        os.remove(os.path.join(self.love_dir, 'measure', 'conditions.json'))
        code, reason = self.stop()
        self.assertEqual(code, 2)
        self.assertTrue(reason.startswith('測定の条件(measure/conditions.json)が無い('))
        self.write('measure/conditions.json', '{"avd": "yardstick_play_35"}')
        self.assertEqual(self.stop(), (2, '測定の条件に load_limit_1m(数)と avd が要る'))

    def test_main_prints_the_record_and_sets_the_exit_code(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(love_measure.main(['Demo', 'aspect_00'], root=self.tmp, run=self.run_fake,
                                               load_avg=lambda: (1.0, 0.0, 0.0)), 0)
            self.assertEqual(love_measure.main(['Demo', 'aspect_00'], root=self.tmp, run=self.run_fake,
                                               load_avg=lambda: (99.0, 0.0, 0.0)), 3)
            self.assertEqual(love_measure.main(['Nope', 'aspect_00'], root=self.tmp), 2)
        self.assertIn('"value": 1000', out.getvalue())
        self.assertIn('測らずに止まった: Mac の負荷が高い', out.getvalue())

    def test_quality_files_do_not_block_measuring(self):
        git(self.app, 'add', '-A')
        git(self.app, 'commit', '-q', '-m', 'records')
        self.write('assessment.md', '# 生成物\n')  # quality/ の中は、追跡していなくても構わない
        self.assertEqual(self.measure()['status'], 'ok')


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: 走らせて、落ちるのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_measure.py`
Expected: `FAILED (errors=1)`。理由は `ModuleNotFoundError: No module named 'love_measure'`

- [ ] **Step 3: 実装を書く**

`twoyearsold_ui/tool/love_measure.py`:

```python
# coding: utf-8
"""遅い測定 — 追う観点の起動や出題の時間を、今のコードの release ビルドで測り、quality/love/measure/<観点の id>.json に書く。

測る前に次を確かめ、満たさなければ測らずに止まる。
  観点の確かめ方が measure であること、測定の条件 quality/love/measure/conditions.json があること(違えば exit 2)
  アプリのコードの範囲に、commit していない変更・追跡していないファイル・共有のローカル参照が無いこと(あれば exit 2)
  Mac の負荷(1 分値)が条件の上限以下で、つながっているエミュレータが条件の avd であること(違えば exit 3)
そのうえで release でビルドしてエミュレータに入れ直し、性能の道具(perf/launch_time.py か perf/new_game.py)を
quality/love/measure/scripts/self.json の台本で走らせ、結果に commit・日時・負荷・端末を付けて書く。
ビルドや入れ直しや道具の失敗は exit 1、端末とのつながりの失敗は exit 3 で、どちらも記録を書かない。

使い方:
  python3 twoyearsold_ui/tool/love_measure.py <AppName> <観点の id>
"""
import argparse
import datetime as dt
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))  # twoyearsold/
sys.path.insert(0, HERE)
import love_check  # noqa: E402
import love_schema  # noqa: E402

PERF = os.path.join(HERE, 'perf')
ADB = os.environ.get('ADB') or os.path.expanduser('~/Library/Android/sdk/platform-tools/adb')
APK = os.path.join('build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
GIT_TIMEOUT_S = 60
ADB_TIMEOUT_S = 30
BUILD_TIMEOUT_S = 1800
INSTALL_TIMEOUT_S = 300
TOOL_TIMEOUT_S = 3600
TAIL = 300


class Stop(Exception):
    """測らずに止まる。code は終了コード(2 は記録や作業の状態、3 は環境、1 はビルドや道具の失敗)。"""

    def __init__(self, reason, code):
        super().__init__(reason)
        self.code = code


def _load(path, label):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        raise Stop(f'{label}が無い({path})', 2)
    except (OSError, ValueError) as e:
        raise Stop(f'{label}が読めない({e})', 2)


def find_aspect(love, aspect_id):
    """確かめ方が measure の観点を返す。"""
    aspects = love.get('aspects') if isinstance(love, dict) else None
    for a in aspects if isinstance(aspects, list) else []:
        if isinstance(a, dict) and a.get('id') == aspect_id:
            check = a.get('check')
            if not (isinstance(check, dict) and check.get('kind') == 'measure'
                    and check.get('tool') in love_schema.TOOLS):
                raise Stop(f'観点 {aspect_id} の確かめ方は measure ではない', 2)
            return a
    raise Stop(f'観点 {aspect_id} が love.json に無い', 2)


def _run(run, args, cwd, timeout, what):
    try:
        return run(args, cwd, timeout)
    except FileNotFoundError:
        raise Stop(f'{what}: {os.path.basename(args[0])} が見つからない', 3)
    except subprocess.TimeoutExpired:
        raise Stop(f'{what}: {timeout} 秒で終わらなかった', 3)
    except OSError as e:
        raise Stop(f'{what}: 走らせられない({e})', 3)


def _first_line(out):
    lines = out.strip().splitlines()
    return lines[0].strip() if lines else ''


def measure(app_dir, aspect_id, run=love_check.run_command, load_avg=os.getloadavg,
            now=lambda: dt.datetime.now().astimezone(), python=sys.executable):
    """測って記録を書き、その記録(辞書)を返す。測らずに止まるときは Stop。"""
    love_dir = os.path.join(app_dir, love_schema.LOVE)
    aspect = find_aspect(_load(os.path.join(love_dir, 'love.json'), 'love.json'), aspect_id)
    cond = _load(os.path.join(love_dir, 'measure', 'conditions.json'), '測定の条件(measure/conditions.json)')
    limit = cond.get('load_limit_1m') if isinstance(cond, dict) else None
    if not isinstance(limit, (int, float)) or isinstance(limit, bool) or not cond.get('avd'):
        raise Stop('測定の条件に load_limit_1m(数)と avd が要る', 2)
    code, out = _run(run, ['git', 'rev-parse', 'HEAD'], app_dir, GIT_TIMEOUT_S, 'commit を引く')
    commit = _first_line(out) if code == 0 else ''
    if not commit:
        raise Stop('今の commit を引けない(git rev-parse HEAD)', 2)
    ok, reason = love_check.current(app_dir, commit, run=run)
    if not ok:
        raise Stop(f'今のコードを測れない: {reason}', 2)
    load = load_avg()[0]
    if load > limit:
        raise Stop(f'Mac の負荷が高い(1 分値 {load:.1f} が上限 {limit} を超える)。下がってから測る', 3)
    code, out = _run(run, [ADB, 'emu', 'avd', 'name'], app_dir, ADB_TIMEOUT_S, 'エミュレータの名前を引く')
    avd = _first_line(out) if code == 0 else ''
    if avd != cond['avd']:
        raise Stop(f'つながっているエミュレータ({avd or "無し"})が、条件の {cond["avd"]} ではない', 3)
    code, out = _run(run, ['flutter', 'build', 'apk', '--release'], app_dir, BUILD_TIMEOUT_S, 'release ビルド')
    if code != 0:
        raise Stop(f'release ビルドが失敗した: {out.strip()[-TAIL:]}', 1)
    code, out = _run(run, [ADB, 'install', '-r', APK], app_dir, INSTALL_TIMEOUT_S, '入れ直し')
    if code != 0 or 'Success' not in out:
        raise Stop(f'エミュレータに入れ直せない: {out.strip()[-TAIL:]}', 1)
    tool = aspect['check']['tool']
    args = [python, '-B', os.path.join(PERF, tool + '.py'), os.path.join(love_dir, 'measure', 'scripts', 'self.json')]
    runs = (cond.get('runs') or {}).get(tool)
    if runs:
        args += ['--runs', str(runs)]
    code, out = _run(run, args, app_dir, TOOL_TIMEOUT_S, '測定')
    if code == 3:
        raise Stop(f'端末とのつながりの失敗で測れなかった(記録には書かない): {out.strip()[-TAIL:]}', 3)
    results = [line for line in out.splitlines() if line.startswith('{')]
    if code != 0 or not results:
        raise Stop(f'測定の道具が失敗した(終了コード {code}): {out.strip()[-TAIL:]}', 1)
    try:
        result = json.loads(results[-1])
    except ValueError:
        raise Stop(f'測定の結果が読めない: {results[-1][-TAIL:]}', 1)
    rec = {'aspect': aspect_id, 'tool': tool, 'metric': aspect['check'].get('metric', 'median_ms'),
           'value': result.get('median'), 'runs': result.get('runs', []), 'status': result.get('status'),
           'reason': result.get('reason', ''), 'commit': commit, 'measured_at': now().isoformat(timespec='seconds'),
           'load_avg_1m': round(load, 2), 'device': {'avd': avd, 'image': cond.get('image', '')}}
    path = os.path.join(love_dir, 'measure', aspect_id + '.json')
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(rec, f, ensure_ascii=False, indent=2)
        f.write('\n')
    os.replace(tmp, path)  # 書きかけで止まっても、前の記録は壊れない
    return rec


def main(argv=None, root=ROOT, **deps):
    parser = argparse.ArgumentParser(description='遅い測定(追う観点の起動・出題の時間)')
    parser.add_argument('app')
    parser.add_argument('aspect')
    args = parser.parse_args(argv)
    app_dir = os.path.join(root, args.app)
    if not os.path.isdir(app_dir):
        print(f'アプリが見つかりません: {app_dir}')
        return 2
    try:
        rec = measure(app_dir, args.aspect, **deps)
    except Stop as e:
        print(f'測らずに止まった: {e}')
        return e.code
    print(json.dumps(rec, ensure_ascii=False))
    return 0 if rec['status'] == 'ok' else 1


if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: 走らせて、通るのを見る**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -m unittest discover -s tool/tests -p test_love_measure.py`
Expected: `Ran 12 tests`、`OK`
Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && /usr/bin/python3 -B -W default -m unittest discover -s tool/tests 2>&1 | tail -3`
Expected: `Ran 157 tests`、`OK`(警告の行が出ない)

- [ ] **Step 5: commit**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold_ui
git add tool/love_measure.py tool/tests/test_love_measure.py
git commit -m "feat: 遅い測定の道具(今のコードの release ビルドを、負荷と端末を確かめてから測る)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```


### Task 11: 調べる(統括と調べる係)

仕様 4 章。

**Files:**
- Create: `NumberPlace/quality/love/sources.md`
- Create: `NumberPlace/quality/love/findings.json`

**Interfaces:**
- Consumes: `love_schema.check_app`・`layer_counts`(Task 5)
- Produces: `findings.json`(仕様 10.1 の形。id は係ごとの範囲。Task 12 が読む)

- [ ] **Step 1: 調べる先の一覧を作る**

統括が Web で候補を探し、`NumberPlace/quality/love/sources.md` を書く。仕様 4.1 の種類ごとに 2 つ以上、層ごとに 5〜10 の先。reddit、ログインが要る所、紙の本の中身は入れない。

```markdown
# 調べる先(NumberPlace の愛の地図)

非公開。所見の出典の候補。作った日: YYYY-MM-DD。reddit・ログインが要る所・紙の本の中身は入れない。

## 毎日解く人(daily)

- <名前>: <URL> — <何を読むか>

## 解き筋を極める愛好家(expert)

- <名前>: <URL> — <何を読むか>

## 変種を楽しむ人(variant)

- <名前>: <URL> — <何を読むか>

## アプリと問題集の声(reviews)

- <名前>: <URL> — <何を読むか>
```

`<名前>` などは、統括が調べた実際の値で埋める。

- [ ] **Step 2: 層ごとの係を 4 人、並べて立てる**

立てる前に `mkdir -p /private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/love` で書き出し先を作る。そのうえで、同じメッセージで Agent を 4 つ呼ぶ(最も能力の高いモデル、裏で走らせる)。依頼文は次の形で、`<…>` を係ごとに埋める。係ごとの値は次のとおり。

- 毎日解く人: layer `daily`、id `f001`〜`f199`、channel は主に `words`(媒体の考え方)と `reviews`(毎日使われるアプリの声)
- 解き筋を極める愛好家: layer `expert`、id `f201`〜`f399`、channel は主に `words`
- 変種を楽しむ人: layer `variant`、id `f401`〜`f599`、channel は主に `words`
- アプリと問題集の声: layer は声の主で決める(分からなければ `any`)、id `f601`〜`f799`、channel は `reviews`

```text
あなたは、ナンプレ(number-placement puzzle)を愛する人たちが何を愛しているのかを調べる係です。担当は「<層の名前>」です。

読むもの: /Users/abe/dev/twoyearsold/NumberPlace/quality/love/sources.md の「<層の名前>」の節の先。そこから辿れる公開の文章も読んでよいです。
使わないもの: reddit、ログインが要る所、紙の本の中身。アカウントの作成・ログイン・購入はしません。
知りたいこと: この層の人が、ナンプレと、その遊び場(紙・アプリ)の何を愛しているか。何がその愛を損なうか。

所見の書き方(1 つの所見は、1 つの出典から読み取った 1 つの事柄):
{"id": "f<番号>", "layer": "<layer の値>", "channel": "words か reviews", "kind": "love か harm",
 "source": "発信者の名前(同じ発信者の別の記事は同じ名前)", "title": "出典の題(無ければ空)", "url": "https://...",
 "read_on": "YYYY-MM-DD", "summary": "要約(自分の言葉で)", "quote": "", "reading": "あなたの読み(任意)"}
- id は <id の範囲> の中で、f のあとに 3 桁以上の数字。
- 引用(quote)は 1 つの所見に 1 つまで、15 語未満かつ 60 字未満。ほとんどは空にして、要約に書く。
- 要約は出典に忠実に書く。あなたの解釈は reading に分けて書く。
- 声の主の層が分からないときは、layer を any にする。
- 15〜30 件。愛されているもの(love)を中心に、損なうもの(harm)も拾う。

書き出し先: /private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/love/findings-<layer の値か reviews>.json に {"findings": [...]} の形で書く。
返事は、件数と、愛されているもの・損なうものの要点を 5 行以内で。
```

- [ ] **Step 3: 4 人の結果を 1 つにまとめる**

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
/usr/bin/python3 - <<EOF
import glob, json
out = []
for path in sorted(glob.glob('$SCRATCH/love/findings-*.json')):
    with open(path, encoding='utf-8') as f:
        out += json.load(f)['findings']
with open('/Users/abe/dev/twoyearsold/NumberPlace/quality/love/findings.json', 'w', encoding='utf-8') as f:
    json.dump({'findings': out}, f, ensure_ascii=False, indent=2)
    f.write('\n')
print(len(out))
EOF
```

Expected: 所見の数(60〜120 が目安)。

- [ ] **Step 4: 形を検査し、層ごとの数を見る**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B -c "
import sys, json; sys.path.insert(0, 'twoyearsold_ui/tool'); import love_schema
b, i = love_schema.check_app('NumberPlace'); print('broken', b[:10]); print('incomplete', i)
print(love_schema.layer_counts(json.load(open('NumberPlace/quality/love/findings.json'))))"
```

Expected: `broken []`、`incomplete []`(love.json はまだ無いので、所見だけを見る)、層ごとの数。broken があれば、統括が直す。

- [ ] **Step 5: 足りない層を足す**

daily・expert・variant のどれかが 15 件未満なら、その層の係を 1 回だけ立て直す(id は前の係の続きから)。それでも足りなければ、台帳に `Task 11: Ruling: <層> の所見は N 件で止めた — 理由` と書く(地図の冒頭の数と強さに表れる)。

- [ ] **Step 6: 所見が出典に忠実かを抜き取りで確かめる**

統括が全件の要約を読み、層を混ぜて 10 件を選ぶ。それぞれの出典を WebFetch で開き、要約が出典と合っているかを見る。外れた所見は統括が直すか外し、台帳に件数を書く。

- [ ] **Step 7: 利用者に見える所に商標の語が無いことを確かめる**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/rights_guard.py NumberPlace; echo exit=$?`
Expected: `exit=0`(`quality/love/` は利用者に見える所ではないので検査の対象外。前と変わらない)

- [ ] **Step 8: commit(NumberPlace)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
git add quality/love/sources.md quality/love/findings.json
git commit -m "docs: 愛の地図の調べる先と所見" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 12: 観点にまとめる(統括、★オーナーの番)

仕様 5 章。

**Files:**
- Create: `NumberPlace/quality/love/love.json`
- Create(生成): `NumberPlace/quality/love/map.md`、`NumberPlace/quality/love/assessment.md`

**Interfaces:**
- Consumes: `findings.json`(Task 11)、Task 1 の `checklist_commit`、`love_report.py`(Task 9)
- Produces: `love.json` の地図の部分(観点の id・name・description・evidence・harms・examples・verify と、coverage_check)。Task 13〜16 が使う。

- [ ] **Step 1: 所見を読み、観点にまとめる**

所見を一覧で読む:

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -c "
import json
for f in json.load(open('NumberPlace/quality/love/findings.json'))['findings']:
    print(f['id'], f['layer'], f['kind'], f['source'], '|', f['summary'])"
```

愛されているものを 10〜20 の観点にまとめ、`NumberPlace/quality/love/love.json` を書く。各観点は仕様 10.2 の形で、評価から先の欄はまだ null にする。

```json
{
  "app": "NumberPlace",
  "aspects": [
    {"id": "<英小文字・数字・_>", "name": "<短い名前>", "description": "<何が、なぜ愛されているか>",
     "evidence": ["<love の所見の id を 2 つ以上。発信者が 2 つ以上別>"],
     "harms": [{"text": "<それを損なうもの>", "evidence": ["<harm の所見の id>"]}],
     "examples": [{"name": "<愛されている作品>", "how": "<どう応えているか>", "evidence": ["<所見の id>"]}],
     "verify": "<machine か human か both>",
     "assessment": null, "recommendation": null, "owner": null, "check": null, "target": null, "human": null}
  ],
  "coverage_check": null,
  "fix_order": null
}
```

確かめ方(verify)の決め方: 毎回機械で確かめられる性質(答えがひとつ・出題の速さ・通信しないなど)は `machine`。目で見る手触りや静けさは `human`。両方が要るものは `both`。

- [ ] **Step 2: 見落としを点検する**

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
mkdir -p $SCRATCH/love && cd /Users/abe/dev/twoyearsold/NumberPlace
git show <Task 1 の checklist_commit>:quality/market/features.json > $SCRATCH/love/features.json
/usr/bin/python3 -c "import json; [print(f['id'], f['name']) for f in json.load(open('$SCRATCH/love/features.json'))['features']]"
```

44 行のそれぞれについて、当たる観点の id か、当たらない理由を `coverage_check.rows` に書く(`{"row": "<行の id>", "aspect": "<観点の id か null>", "note": "<当たらない理由>"}`)。`checklist_commit` には Task 1 の commit を書く。愛にかかわりそうなのに、どの観点にも当たらない行があれば、所見を見直して観点を足すか、当たらない理由を書く。

- [ ] **Step 3: 形を検査する**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B -c "
import sys; sys.path.insert(0, 'twoyearsold_ui/tool'); import love_schema
b, i = love_schema.check_app('NumberPlace')
rest = [r for r in i if not r.endswith(('評価がまだ', '推奨: まだ', 'オーナーの決定: まだ'))]
print('broken', b[:10]); print('rest', rest)"
```

Expected: `broken []`、`rest []`(観点の数・根拠・発信者・点検に不足が無く、まだなのは評価・推奨・決定だけ)

- [ ] **Step 4: 文書を作る**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_report.py NumberPlace`
Expected: `書いた: map.md・assessment.md(まだの所 N 件)`

- [ ] **Step 5: commit(NumberPlace)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
git add quality/love/love.json quality/love/map.md quality/love/assessment.md
git commit -m "docs: 愛の地図の観点と見落としの点検" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 6: ★ オーナーに地図を見てもらう(仕様 15 章の 5)**

SendUserFile で `NumberPlace/quality/love/map.md` を送る(display は render)。AskUserQuestion で 1 問聞く。オーナーは表が見えないので、質問の文の中に、観点の数・強さの内訳・観点の名前を並べる。

- 質問の文: 「観点は N 個です(強 a・中 b・弱 c)。<観点の名前を・で並べる>。足りない観点や、余計な観点はありますか?」
- 選択肢: 「この地図でよい (Recommended)」「直したい所がある」

直したい所があれば、love.json を直して Step 3〜5 を繰り返す。

### Task 13: 自作を評価する — A(統括)

仕様 6 章。A の評価は、B が終わるまでリポジトリに入れない。

**Files:**
- Create(作業場): `$SCRATCH/love/a/assessment-a.json`、`$SCRATCH/love/a/evidence/<観点の id>-<番号>.png`

**Interfaces:**
- Consumes: `love.json` の地図(Task 12)、測定用のエミュレータに入った release ビルド(Task 2)
- Produces: `assessment-a.json` の形 `{"<観点の id>": {"grade": "...", "evidence": ["..."], "fix": "... か null", "effort": "... か null"}}`(Task 14 が love.json に入れる)

- [ ] **Step 1: 自作を動かせる状態にする**

Run: `~/Library/Android/sdk/platform-tools/adb emu avd name && ~/Library/Android/sdk/platform-tools/adb shell pm list packages net.twoyearsold.numberplace`
Expected: `yardstick_play_35`、`package:net.twoyearsold.numberplace`。Task 2 の後にアプリのコードを変えていたら、Task 2 の Step 3 のとおりに入れ直す。

- [ ] **Step 2: 観点ごとに確かめる**

観点ごとに、自作を動かして見る・コードを読む・手順を記録する。画面の写しは次のとおり撮る。画面を読んで押す小道具 `$SCRATCH/ui.py`(`dump`・`tap <文字>`・`shot <path>`)も使える。

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
mkdir -p $SCRATCH/love/a/evidence
~/Library/Android/sdk/platform-tools/adb exec-out screencap -p > $SCRATCH/love/a/evidence/<観点の id>-1.png
sips -Z 720 $SCRATCH/love/a/evidence/<観点の id>-1.png
```

根拠の書き方: `evidence/a/<観点の id>-<番号>.png`(移した後の場所で書く)、`code: lib/<path>:<行>`、`steps: <何をして、何が起きたか>`。
A だけが使う手がかり: 出題は約 0.5 秒、起動は 1.6〜2.4 秒、数字ごとの残りの数を出す機能が無い、ヒントの理由の帯(SnackBar、2 秒)が数字のボタンに重なる、時間を隠す設定が無い、デイリーチャレンジは実在する(`lib/presentation/home/home_screen.dart` の 78〜80 行)。根拠は撮り直す。

- [ ] **Step 3: A の評価を書く**

`$SCRATCH/love/a/assessment-a.json` に、すべての観点を書く。`lacks` と `violates` には `fix`(直し方の案)と `effort` を付ける。

- [ ] **Step 4: 書いた評価の形を確かめる**

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B - <<EOF
import json, sys
sys.path.insert(0, 'twoyearsold_ui/tool'); import love_schema
love = json.load(open('NumberPlace/quality/love/love.json'))
a = json.load(open('$SCRATCH/love/a/assessment-a.json'))
ids = [x['id'] for x in love['aspects']]
print('missing', [i for i in ids if i not in a])
print('bad grade', [i for i, v in a.items() if v.get('grade') not in love_schema.GRADES])
print('bad ref', [(i, r) for i, v in a.items() for r in v.get('evidence', []) if love_schema.ref_kind(r) is None])
print('no fix', [i for i, v in a.items() if v.get('grade') in ('lacks', 'violates') and not (v.get('fix') and v.get('effort'))])
EOF
```

Expected: 4 つとも `[]`

- [ ] **Step 5: 台帳に書く**

台帳に `Task 13: A の評価は $SCRATCH/love/a/ にある(B が終わるまでリポジトリに入れない)。段の数: 応えている x・足りない y・反している z・未確認 w` と書く。commit は無い。

### Task 14: 自作を評価する — B と突き合わせ(統括と評価の係)

**Files:**
- Create(作業場): `$SCRATCH/love/b/assessment-b.json`、`$SCRATCH/love/b/evidence/*.png`
- Create: `NumberPlace/quality/love/evidence/a/*.png`、`NumberPlace/quality/love/evidence/b/*.png`
- Modify: `NumberPlace/quality/love/love.json`(assessment)
- Modify(生成): `map.md`、`assessment.md`

**Interfaces:**
- Consumes: Task 13 の `assessment-a.json`、`love_schema.check_app`、`love_report.py`
- Produces: 各観点の `assessment`(`a`・`b`・`final`・`fix`・`effort`)。Task 15 が推奨の材料に使う。

- [ ] **Step 1: 評価の係 B を立てる**

立てる前に `mkdir -p /private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/love/b/evidence` で書き出し先を作る。そのうえで Agent を 1 つ呼ぶ(最も能力の高いモデル)。A と同じエミュレータを使うので、A が終わってから立てる。依頼文:

```text
あなたは、ナンプレのアプリ NumberPlace が、ナンプレを愛する人たちの愛するものにどれだけ応えているかを評価する係です。

読むもの: /Users/abe/dev/twoyearsold/NumberPlace/quality/love/map.md(観点の地図)と findings.json(所見)。
読まないもの: quality/love/love.json の assessment から後の欄、quality/love/assessment.md、/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/love/a/。別の評価なので、見ると偏ります。
自作の見方: コードは /Users/abe/dev/twoyearsold/NumberPlace/lib/。動かすには、adb でつながっている測定用のエミュレータ(yardstick_play_35)を使う。自作は release ビルドで入っている(パッケージ net.twoyearsold.numberplace)。adb は ~/Library/Android/sdk/platform-tools/adb。画面を読んで押す小道具 /private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/ui.py(dump・tap <文字>・shot <path>)も使える。
画面の写し: adb exec-out screencap -p > /private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/love/b/evidence/<観点の id>-<番号>.png のあと、sips -Z 720 でその写しを縮める。

観点ごとに段を決める: meets(応えている)/ lacks(足りない)/ violates(反している。その観点の裏返しに当たる)/ unverified(根拠を示せない)。
根拠を 1 つ以上付ける: "evidence/b/<観点の id>-<番号>.png"(写しを撮ったとき)、"code: lib/<path>:<行>"、"steps: <何をして、何が起きたか>"。
lacks と violates には、直し方の案(1〜2 文)と手間(small・medium・large)も付ける。

書き出し先: /private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad/love/b/assessment-b.json に
{"<観点の id>": {"grade": "...", "evidence": ["..."], "fix": "... か null", "effort": "... か null"}, ...}
自作の設定や遊んだ記録は変えてよい(測定用のエミュレータ)。ほかのアプリは触らない。アカウントの作成・ログイン・購入はしない。広告は押さない。
返事は、段の数と、気づいたことを 5 行以内で。
```

- [ ] **Step 2: B の評価の形を確かめる**

Task 13 の Step 4 の命令の `a/assessment-a.json` を `b/assessment-b.json` に替えて走らせる。
Expected: 4 つとも `[]`。欠けがあれば、B に続きを頼む(SendMessage)。

- [ ] **Step 3: 写しを置き、A と B を love.json に入れる**

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
LOVE=/Users/abe/dev/twoyearsold/NumberPlace/quality/love
mkdir -p $LOVE/evidence/a $LOVE/evidence/b
cp $SCRATCH/love/a/evidence/*.png $LOVE/evidence/a/ 2>/dev/null; cp $SCRATCH/love/b/evidence/*.png $LOVE/evidence/b/ 2>/dev/null
/usr/bin/python3 - <<EOF
import json
path = '$LOVE/love.json'
love = json.load(open(path, encoding='utf-8'))
a = json.load(open('$SCRATCH/love/a/assessment-a.json', encoding='utf-8'))
b = json.load(open('$SCRATCH/love/b/assessment-b.json', encoding='utf-8'))
for x in love['aspects']:
    x['assessment'] = {'a': {'grade': a[x['id']]['grade'], 'evidence': a[x['id']]['evidence']},
                       'b': {'grade': b[x['id']]['grade'], 'evidence': b[x['id']]['evidence']},
                       'final': None, 'fix': None, 'effort': None}
with open(path, 'w', encoding='utf-8') as f:
    json.dump(love, f, ensure_ascii=False, indent=2)
    f.write('\n')
print('differ:', [x['id'] for x in love['aspects'] if x['assessment']['a']['grade'] != x['assessment']['b']['grade']])
EOF
```

Expected: A と B の段が違う観点の id の並び。

- [ ] **Step 4: 突き合わせる**

段が違う観点は、統括がエミュレータとコードで確かめ直し、最終の段を決める。すべての観点に `final`(`grade`・`evidence`・`reconcile`)を書く。根拠は A と B のうち分かりやすいものを選ぶ。A・B・最終の段が同じでなければ、`reconcile` に決めた理由を書く。最終の段が `lacks` か `violates` なら、A と B の案を見て `fix` と `effort` を決める。

- [ ] **Step 5: 形を検査する**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B -c "
import sys; sys.path.insert(0, 'twoyearsold_ui/tool'); import love_schema
b, i = love_schema.check_app('NumberPlace')
rest = [r for r in i if not r.endswith(('推奨: まだ', 'オーナーの決定: まだ')) and 'fix_order' not in r]
print('broken', b[:10]); print('rest', rest)"
```

Expected: `broken []`、`rest []`

- [ ] **Step 6: 文書を作って commit(NumberPlace)**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_report.py NumberPlace
cd NumberPlace
git add quality/love/love.json quality/love/evidence quality/love/map.md quality/love/assessment.md
git commit -m "docs: 愛の地図の評価(A と B を別々に行い、突き合わせた)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 15: オーナーの線(統括、★オーナーの番)

仕様 7 章。

**Files:**
- Modify: `NumberPlace/quality/love/love.json`(recommendation・owner・check・target・human・fix_order)
- Modify(生成): `map.md`、`assessment.md`

**Interfaces:**
- Consumes: Task 14 の評価、Task 2 の測定の値(`conditions.json` の `basis`)
- Produces: 追う観点(`owner.decision` が pursue)と、その確かめ方(`check`・`target`・`human.steps`)。Task 16 が用意する。`fix_order`(直しの計画の材料)。

- [ ] **Step 1: 推奨を書く**

すべての観点に `recommendation`(`decision`・`reason`)を書く。理由には、強さ(map.md の強さ)・方針との合い方(DESIGN.md §0。静か・買い切り・広告なし・完全オフライン)・最終の段・手間を短く入れる。`violates` は原則 `pursue`。

- [ ] **Step 2: 文書を作って送る**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_report.py NumberPlace`
SendUserFile で `NumberPlace/quality/love/assessment.md` を送る(display は render)。

- [ ] **Step 3: ★ 観点ごとにオーナーに聞く**

AskUserQuestion で、1 回に 4 問まで、1 問に 1 つの観点を聞く。表は使わない。

- 質問の文: 「<観点の名前>: 自作は<最終の段>(<根拠の要点>)。強さは<強・中・弱>。推奨は<追う・追わない・保留>です(<理由>)。どうしますか?」
- 選択肢: 「追う」「追わない」「保留」。推奨のものを先頭にし、`(Recommended)` を付ける。

追うと決まった観点のうち、確かめ方が `measure` のものは、続けて目標を聞く。Task 2 の値をもとに、上限の候補を 3 つ出す(推奨を先頭にする)。確かめ方が `command` のものは、何を確かめるテストかを質問の文で伝える。

- [ ] **Step 4: 決定と確かめ方を書く**

- `owner`: `decision`、`date`(今日)、`reason`(オーナーのメモか「推奨のとおり」)。
- 追う観点で `verify` が `machine` か `both` のもの:
  - `check` は `{"kind": "command", "run": ["flutter", "test", "love_test/<観点の id>_test.dart"], "timeout_s": 600}` か、`{"kind": "measure", "tool": "launch_time" または "new_game", "metric": "median_ms"}` にする。
  - measure の観点は、`target` を `{"max": <決めた値>}` にする。
- 追う観点で `verify` が `human` か `both` のもの: `human` を `{"steps": ["<手順 1>", "<手順 2>"], "last": null}` にする。

- [ ] **Step 5: 直す順の案を書く**

追う観点のうち、最終の段が `lacks` か `violates` のものを、強さの強い順、同じ強さなら手間の小さい順に並べる。`fix_order` に `{"id": "...", "reason": "..."}` として書く。

- [ ] **Step 6: 形を検査する**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B -c "import sys; sys.path.insert(0, 'twoyearsold_ui/tool'); import love_schema; print(love_schema.check_app('NumberPlace'))"`
Expected: `([], [])`

- [ ] **Step 7: 文書を作って commit(NumberPlace)**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_report.py NumberPlace
cd NumberPlace
git add quality/love/love.json quality/love/map.md quality/love/assessment.md
git commit -m "docs: 愛の地図のオーナーの線・確かめ方・直す順の案" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 16: 追う観点の確かめを用意する(統括)

仕様 8 章。

**Files:**
- Create: `NumberPlace/love_test/<観点の id>_test.dart`(速い確かめの観点ごと)
- Create: `NumberPlace/quality/love/measure/<観点の id>.json`(遅い測定の観点ごと)
- Modify: `NumberPlace/quality/gate.json`、`map.md`、`assessment.md`

**Interfaces:**
- Consumes: Task 15 の `check`・`target`・`human`、`love_measure.py`(Task 10)、`gate.py`(Task 8)、`love_report.py`(Task 9)
- Produces: gate の love の行に、追う観点ごとの結果(`items`)。

- [ ] **Step 1: 速い確かめのテストを書く(観点ごと)**

`check.kind` が `command` の観点ごとに、`NumberPlace/love_test/<観点の id>_test.dart` を書く。どのテストにも、確かめそのものが落ちうることを示す逆の見本を入れる。次は、観点「答えがひとつに定まる問題だけ」の場合の形の例:

```dart
// 観点「答えがひとつに定まる問題だけ」の速い確かめ(愛の地図。quality/love/love.json)。
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_place/domain/board_dimensions.dart';
import 'package:number_place/domain/difficulty.dart';
import 'package:number_place/domain/generator.dart';
import 'package:number_place/domain/solver.dart';

void main() {
  final solver = SudokuSolver(BoardDimensions.nine);

  test('確かめそのものが、答えがひとつでない盤を見分ける(逆の見本)', () {
    expect(solver.hasUniqueSolution(List.filled(81, 0)), isFalse);
  });

  for (final difficulty in Difficulty.values) {
    test('9×9 の ${difficulty.name} は、どの問題も答えがひとつ', () {
      final generator = PuzzleGenerator(BoardDimensions.nine);
      for (var seed = 0; seed < 5; seed++) {
        final puzzle = generator.generate(difficulty: difficulty, rng: Random(seed));
        expect(solver.hasUniqueSolution(puzzle.givens), isTrue, reason: 'seed $seed');
      }
    });
  }
}
```

観点ごとに、Task 12 で書いた性質に合わせて中身を書く。

- [ ] **Step 2: 速い確かめを走らせる**

Run: `cd /Users/abe/dev/twoyearsold/NumberPlace && flutter test love_test/<観点の id>_test.dart`
Expected: 逆の見本のテストは必ず通る。観点のテストは、自作が応えていれば通る。応えていなければ落ちたままにし(未達。直しの計画の材料)、台帳に書く。
Run: `cd /Users/abe/dev/twoyearsold/NumberPlace && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: love_test を commit する(NumberPlace)**

```bash
cd /Users/abe/dev/twoyearsold/NumberPlace
git add love_test
git commit -m "test: 愛の地図の追う観点の速い確かめ(love_test)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: 遅い測定を測る(観点ごと)**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_measure.py NumberPlace <観点の id>`
Expected: 最後の行が記録の JSON(`"status": "ok"`)で、exit 0。exit 3 で負荷が理由なら、負荷が下がってから測り直す。exit 2 で「今のコードを測れない」なら、アプリのコードの commit していない変更を確かめる。

- [ ] **Step 5: gate を走らせ、結果を書く**

Run: `cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/gate.py NumberPlace --json NumberPlace/quality/gate.json`
Expected: love の行の下に、追う観点の数だけ `| love: <id> | ... |` の行が並ぶ。人の確かめの観点は「人の確かめの記録が無い」で fail(出す前にオーナーが見る。直しの計画の後)。ほかの 6 つは pass のまま。

- [ ] **Step 6: 文書を作って commit(NumberPlace)**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_report.py NumberPlace
cd NumberPlace
git add quality/love/measure quality/gate.json quality/love/map.md quality/love/assessment.md
git commit -m "chore: 愛の地図の最初の love 検査の結果と測定の記録" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 17: DESIGN.md への反映(統括、★オーナーの番)

仕様 16 章。

**Files:**
- Create(作業場): `$SCRATCH/love/design-proposal.md`
- Create: `twoyearsold-ops/docs/design-md/<日付>-before.md`、`twoyearsold-ops/docs/design-md/<日付>-after.md`
- Modify: `/Users/abe/dev/twoyearsold/DESIGN.md`(承認された分だけ。版管理の外)

**Interfaces:**
- Consumes: `map.md`・`assessment.md`(Task 12・16)
- Produces: DESIGN.md の新しい項と、その前後の写し

- [ ] **Step 1: 案を作る**

`$SCRATCH/love/design-proposal.md` に、足す所ごとに「どの節の、どこに、何を足すか」を書く。
- 全作に通じる観点(静けさ、考える時間を奪わないことなど)は、§0〜§10 の当てはまる節に短く足す。
- NumberPlace だけに当てはまる観点は、§10.5 に NumberPlace の項を設けて足す。

商標の語は入れない。次で確かめる:

```bash
SCRATCH=/private/tmp/claude-501/-Users-abe-dev-twoyearsold/165e32c3-00ea-4962-9b5f-2d5019b34cb4/scratchpad
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B -c "
import sys; sys.path.insert(0, 'twoyearsold_ui/tool'); import rights_guard as r
text = r.norm(open('$SCRATCH/love/design-proposal.md', encoding='utf-8').read())
print([t for t, form in r.load_terms() if form in text])"
```

Expected: `[]`

- [ ] **Step 2: ★ オーナーに案を見せる**

SendUserFile で案を送る。AskUserQuestion で、足す所ごとに聞く(1 回に 4 問まで)。質問の文に、足す節と文の要点を書く。選択肢は「足す (Recommended)」「直して足す」「足さない」。

- [ ] **Step 3: 書き換える前の写しを残す**

```bash
cd /Users/abe/dev/twoyearsold
mkdir -p twoyearsold-ops/docs/design-md
cp DESIGN.md twoyearsold-ops/docs/design-md/$(date +%Y-%m-%d)-before.md
cd twoyearsold-ops && git add docs/design-md && git commit -m "docs: DESIGN.md を書き換える前の写し(愛の地図の反映の前)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: 承認された分だけ DESIGN.md を書き換え、後の写しも残す**

承認された文を DESIGN.md に足す(Edit)。そのあと:

```bash
cd /Users/abe/dev/twoyearsold
cp DESIGN.md twoyearsold-ops/docs/design-md/$(date +%Y-%m-%d)-after.md
cd twoyearsold-ops && git add docs/design-md && git commit -m "docs: DESIGN.md に愛の地図を反映した後の写し" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push
cmp /Users/abe/dev/twoyearsold/DESIGN.md docs/design-md/$(date +%Y-%m-%d)-after.md && echo 同じ
```

Expected: `同じ`。push は承認済み。

### Task 18: 終わりの確かめ(統括、★オーナーの番)

仕様 17 章。

**Files:** 確かめるだけ。

- [ ] **Step 1: 終わりの条件を、命令で 1 つずつ確かめる**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B - <<'EOF'
import json, os, subprocess, sys
sys.path.insert(0, 'twoyearsold_ui/tool')
import love_schema
app = 'NumberPlace'
findings, love, _ = love_schema.load_app(app)
by_id = love_schema.findings_by_id(findings)
print('1 形:', love_schema.check_app(app))
print('2 層ごとの所見:', love_schema.layer_counts(findings))
print('3 観点の数:', len(love['aspects']), '発信者が 2 未満:',
      [a['id'] for a in love['aspects'] if len(love_schema.sources(a, by_id)) < 2])
print('4 最終の段:', sorted({a['assessment']['final']['grade'] for a in love['aspects']}))
print('5 決定:', [a['owner']['decision'] for a in love['aspects']])
print('6 直す順:', [r['id'] for r in love['fix_order']])
gate = json.load(open(f'{app}/quality/gate.json'))
row = [c for c in gate['checks'] if c['name'] == 'love'][0]
print('7 gate:', [c['name'] for c in gate['checks']], row['status'], len(row['items']), '件')
out = lambda *a: subprocess.run(a, capture_output=True, text=True).stdout.strip()
print('8 market:', out('git', '-C', app, 'ls-files', 'quality/market') or '無い',
      os.path.exists('twoyearsold_ui/tool/market_check.py'))
print('9 台本:', os.path.exists(f'{app}/quality/love/measure/scripts/self.json'))
EOF
```

Expected:
- 1: `([], [])`
- 2: 層ごとの数(daily・expert・variant が 15 以上。足りない層は Task 11 の Ruling にある)
- 3: 10〜20、`発信者が 2 未満: []`
- 4: `unverified` を含まない
- 5: どれも pursue・skip・hold のどれか
- 6: 直す所のある追う観点の id
- 7: 7 つの検査の名前、love の結果、追う観点の数と同じ件数
- 8: `無い False`
- 9: `True`

- [ ] **Step 2: 生成物が最新であることを確かめる**

```bash
cd /Users/abe/dev/twoyearsold && /usr/bin/python3 -B twoyearsold_ui/tool/love_report.py NumberPlace
git -C NumberPlace diff --quiet -- quality/love/map.md quality/love/assessment.md && echo 最新
```

Expected: `最新`

- [ ] **Step 3: 置き換えの 1 行と、旧計画の台帳を確かめる**

Run: `cd /Users/abe/dev/twoyearsold/twoyearsold_ui && grep -l '2026-10-15-numberplace-love-map' docs/superpowers/specs/2026-10-14-*.md docs/superpowers/plans/2026-10-14-numberplace-yardstick.md && tail -1 .superpowers/sdd/2026-10-14-numberplace-yardstick/progress.md | cut -c1-20`
Expected: 3 つのファイル名と、`Final: 中止`

- [ ] **Step 4: 全体の確認**

実行の手順(executing-plans か subagent-driven-development)の最後の、全体の確認を行う。範囲は twoyearsold_ui の `27ed373..HEAD`(道具と文書)。NumberPlace の記録は、Step 1〜2 で確かめた。

- [ ] **Step 5: ★ push してよいかを確かめる**

AskUserQuestion で 1 問聞く。質問の文に、出るものを書く。
- twoyearsold_ui(公開): 旧計画の道具の commit 14 件と、この計画の commit(道具・テスト・文書)。
- NumberPlace(非公開): この計画の commit(quality/love/・love_test/・quality/gate.json)。push すると Web の公開(Vercel)が走る。lib/ は変えていない。

選択肢: 「両方 push する」「twoyearsold_ui だけ」「まだ push しない」。
