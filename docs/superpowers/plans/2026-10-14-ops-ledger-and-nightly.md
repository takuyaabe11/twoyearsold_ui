# 台帳と運転 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** アプリごとの台帳、安全装置の設定、毎晩の実行、朝の報告を持つ運用リポジトリ `twoyearsold-ops` を作る。

**Architecture:** 台帳は Markdown(先頭部 + 5 つの見出し)で、人と Claude が読み書きする。毎晩の実行(`ops/nightly.py`)は台帳を読み、アプリごとに「次の一手」を実行者(無人実行の Claude)へ渡し、実行後に台帳・設定・秘密の検査をしてから報告を作り、commit と push を行う。実行者は関数として差し替えられるので、テストでは偽の実行者を使う。

**Tech Stack:** Python 3.9(標準ライブラリのみ)、unittest、git、launchd、Claude Code CLI(`claude -p`)。

**Spec:** `twoyearsold_ui/docs/superpowers/specs/2026-10-14-ecosystem-design.md`(第 3.3 節、第 5.2 節の「安全装置を変えられる人と場所」、第 7 節、第 9 節)

## Global Constraints

- リポジトリは `/Users/abe/dev/twoyearsold/twoyearsold-ops`(GitHub は `takuyaabe11/twoyearsold-ops`、非公開)。
- Python は 3.9 で動くこと。外部パッケージを入れない(`yaml` も `tomllib` も使えない)。
- テストは `python3 -m unittest discover -s tests -v` で走ること。
- コメントと文面は日本語。識別子は英語。
- 安全装置の数値は `policy/release.yaml` 1 つにまとめる。自動実行はこのファイルを書き換えない。
- 台帳は `ledger/<アプリ>.md`。報告は `reports/YYYY-MM-DD.md`。
- 毎晩の実行は 2:00。失敗したら台帳に記録して止まり、同じ作業をやり直さない。
- 鍵と API キーは、報告・ログ・台帳に出さない。
- 台に固有の設定は `machine.json` 1 つにまとめ、git で管理しない。
- この計画の自動実行は、ストアへの登録と公開を行わない(計画③の範囲)。
- 対象のアプリ: NumberPlace / 2048 / AirHockey / FreeThrow / Gobblet(製品名 Cover Three)/ Minesweeper / PK / Reversi / Solitaire。

## Review Focus

1. 台帳の 1 つが壊れている(見出しが欠ける、先頭部が閉じていない): その 1 作だけ「止まった」として報告し、ほかの作は進める。→ Task 3、Task 5
2. 実行者が `policy/release.yaml` を書き換えた: 変更を戻し、その作を「止まった」とする。→ Task 5
3. 実行者が終わらない、または異常終了した: 制限時間で打ち切り、台帳に記録して次の作へ進む。→ Task 5
4. 台帳や報告に鍵らしき文字列が入った: commit も push もせず、非ゼロで終わる。→ Task 5
5. Mac が閉じられていて前の晩の実行が抜けた: 次の報告の先頭に「前日の報告がない」と出す。→ Task 4

---

### Task 0: 前提を確かめる

仕様の第 9 節のうち、この計画に関わる前提を先に確かめる。結果は `docs/assumptions.md` に残す。

**Files:**
- Create: `/Users/abe/dev/twoyearsold/twoyearsold-ops/docs/assumptions.md`
- Create: `/Users/abe/dev/twoyearsold/twoyearsold-ops/.gitignore`

**Interfaces:**
- Produces: リポジトリ `twoyearsold-ops`(ローカルと GitHub)。`docs/assumptions.md` に、無人実行で使える `--permission-mode` の値と、保護設定の可否。

- [ ] **Step 1: リポジトリを作る**

GitHub への非公開リポジトリの作成は外に出る操作なので、実行の前にオーナーへ確認する。

```bash
mkdir -p /Users/abe/dev/twoyearsold/twoyearsold-ops && cd /Users/abe/dev/twoyearsold/twoyearsold-ops
git init -b main
printf 'machine.json\nlogs/\n.nightly.lock\n__pycache__/\n*.pyc\n' > .gitignore
mkdir -p docs && printf '# 前提の確認\n\n' > docs/assumptions.md
git add -A && git commit -m "chore: リポジトリを作る"
gh repo create takuyaabe11/twoyearsold-ops --private --source=. --remote=origin --push
```

Expected: `gh repo view takuyaabe11/twoyearsold-ops --json visibility --jq .visibility` が `PRIVATE`。

- [ ] **Step 2: 無人実行の Claude が動くか確かめる**

本番の実行者は、アプリのリポジトリを作業場所にして、(1) 作業場所の外にある台帳を書き換え、(2) 検査の命令を走らせる。この 2 つが無人でできるかを確かめる。

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold-ops
printf 'before\n' > probe.txt
( cd /Users/abe/dev/twoyearsold/2048 && claude -p "/Users/abe/dev/twoyearsold/twoyearsold-ops/probe.txt の中身を、python3 --version を実行して得た出力の 1 行だけに書き換えてください。ほかのファイルには触れないでください。" --permission-mode acceptEdits --add-dir /Users/abe/dev/twoyearsold/twoyearsold-ops )
cat probe.txt; rm -f probe.txt
```

Expected: `Python 3.9.6`。`before` のままなら、命令の実行か、作業場所の外の書き換えが止められている。次の順に替えて試し、最初に動いた組み合わせを `docs/assumptions.md` に書く(Task 5 の `machine.json` の `permission_mode` と `extra_args` に入れる値になる)。

1. `--permission-mode acceptEdits --allowedTools "Bash(python3:*)"`(動いたら、本番では `Bash(flutter:*)`、`Bash(dart:*)`、`Bash(python3:*)`、`Bash(git status:*)`、`Bash(git diff:*)`、`Bash(git add:*)`、`Bash(git commit:*)` を許す)
2. `--permission-mode auto`
3. `--permission-mode dontAsk` と 1 の `--allowedTools`

`bypassPermissions` は使わない(止める手段がなくなるため)。どれも動かない場合は、ここで止まってオーナーへ報告する。

- [ ] **Step 3: launchd から同じ命令が動くか確かめる**

```bash
cd /Users/abe/dev/twoyearsold/twoyearsold-ops
CLAUDE_BIN=$(which claude)
printf 'before\n' > probe.txt
launchctl submit -l net.twoyearsold.ops.probe -o "$PWD/probe.out" -e "$PWD/probe.err" -- /bin/bash -c "export PATH=$(dirname "$CLAUDE_BIN"):/opt/homebrew/bin:/usr/bin:/bin; cd $PWD && $CLAUDE_BIN -p 'probe.txt の中身を after の 1 行だけに書き換えてください。' --permission-mode acceptEdits"
sleep 90; cat probe.txt; tail -3 probe.err
launchctl remove net.twoyearsold.ops.probe; rm -f probe.txt probe.out probe.err
```

Expected: `after`。動かない場合は `probe.err` の内容(認証、PATH など)を `docs/assumptions.md` に書き、ここで止まってオーナーへ報告する。

- [ ] **Step 4: 保護設定が使えるか確かめる**

```bash
gh api repos/takuyaabe11/twoyearsold-ops/branches/main/protection 2>&1 | head -3
```

Expected: `Branch not protected`(使えるが未設定)か、プランの制限を示すエラー。結果を `docs/assumptions.md` に書く。使えない場合も、Task 5 の「設定の書き換えを戻す検査」で守る。

- [ ] **Step 5: 結果を残す**

`docs/assumptions.md` に、Step 2〜4 の結果を 1 項目ずつ事実として書く(動いた命令、使った値、エラーの文面)。

```bash
git add -A && git commit -m "docs: 前提の確認結果" && git push
```

---

### Task 1: 設定を読む最小の YAML 読み込み

**Files:**
- Create: `ops/__init__.py`(空)
- Create: `ops/miniyaml.py`
- Test: `tests/test_miniyaml.py`

**Interfaces:**
- Produces: `ops.miniyaml.loads(text: str) -> dict`。`key: value` と、字下げ 2 つの空白による 2 階層までの入れ子を読む。値は `int` / `float` / `bool` / `str`。読めない書き方は `ValueError`。

- [ ] **Step 1: 失敗するテストを書く**

```python
# tests/test_miniyaml.py
import unittest
from ops import miniyaml


class LoadsTest(unittest.TestCase):
    def test_flat_and_nested_values(self):
        text = (
            "# コメント\n"
            "name: release\n"
            "rollout:\n"
            "  first_percent: 10\n"
            "  wait_hours: 24  # 行末のコメント\n"
            "halt:\n"
            "  crash_free_drop_points: 0.5\n"
            "enabled: true\n"
        )
        self.assertEqual(
            miniyaml.loads(text),
            {
                "name": "release",
                "rollout": {"first_percent": 10, "wait_hours": 24},
                "halt": {"crash_free_drop_points": 0.5},
                "enabled": True,
            },
        )

    def test_quoted_string_keeps_digits(self):
        self.assertEqual(miniyaml.loads('version: "1.20"\n'), {"version": "1.20"})

    def test_rejects_tabs_bad_indent_and_duplicates(self):
        for bad in ("a:\n\tb: 1\n", "a:\n    b: 1\n", "a: 1\na: 2\n", "just text\n", "a:\n  b:\n"):
            with self.assertRaises(ValueError, msg=repr(bad)):
                miniyaml.loads(bad)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `mkdir -p ops tests && touch ops/__init__.py tests/__init__.py && python3 -m unittest tests.test_miniyaml -v`
Expected: FAIL(`cannot import name 'miniyaml'`)

- [ ] **Step 3: 実装する**

```python
# ops/miniyaml.py
"""安全装置の設定で使う、YAML のごく一部だけを読む。

対応: `key: value`、字下げ 2 つの空白による 2 階層までの入れ子、`#` のコメント、
整数・小数・true / false・文字列(引用符は任意)。それ以外は ValueError。
外部パッケージを入れない方針のための最小実装で、YAML 全体は読めない。
"""
import re


def _scalar(text, line_no):
    t = text.strip()
    if t == "":
        raise ValueError(f"{line_no} 行目: 値がありません")
    if len(t) >= 2 and t[0] == t[-1] and t[0] in "\"'":
        return t[1:-1]
    if t in ("true", "false"):
        return t == "true"
    if re.fullmatch(r"-?\d+", t):
        return int(t)
    if re.fullmatch(r"-?\d+\.\d+", t):
        return float(t)
    return t


def loads(text):
    root = {}
    parent = None
    for line_no, raw in enumerate(text.splitlines(), 1):
        if raw.lstrip().startswith("#"):
            continue
        line = raw.split(" #", 1)[0].rstrip()
        if not line.strip():
            continue
        if "\t" in line:
            raise ValueError(f"{line_no} 行目: タブは使えません")
        indent = len(line) - len(line.lstrip(" "))
        if ":" not in line:
            raise ValueError(f"{line_no} 行目: `key: value` の形ではありません")
        key, _, rest = line.strip().partition(":")
        key = key.strip()
        if indent == 0:
            if key in root:
                raise ValueError(f"{line_no} 行目: {key} が重複しています")
            if rest.strip() == "":
                root[key] = {}
                parent = key
            else:
                root[key] = _scalar(rest, line_no)
                parent = None
        elif indent == 2 and parent is not None:
            if rest.strip() == "":
                raise ValueError(f"{line_no} 行目: 入れ子は 2 階層までです")
            if key in root[parent]:
                raise ValueError(f"{line_no} 行目: {parent}.{key} が重複しています")
            root[parent][key] = _scalar(rest, line_no)
        else:
            raise ValueError(f"{line_no} 行目: 字下げが正しくありません")
    return root
```

- [ ] **Step 4: 通ることを確かめる**

Run: `python3 -m unittest tests.test_miniyaml -v`
Expected: `OK`(3 件)

- [ ] **Step 5: Commit**

```bash
git add ops tests && git commit -m "feat: 設定を読む最小の YAML 読み込み"
```

---

### Task 2: 安全装置の設定

**Files:**
- Create: `policy/release.yaml`
- Create: `ops/policy.py`
- Test: `tests/test_policy.py`

**Interfaces:**
- Consumes: `ops.miniyaml.loads`
- Produces: `ops.policy.load(path) -> dict`(検証済みの設定)。問題があれば `ops.policy.PolicyError`(`ValueError` の子)。

- [ ] **Step 1: 失敗するテストを書く**

```python
# tests/test_policy.py
import tempfile
import unittest
from pathlib import Path

from ops import policy

GOOD = """\
rollout:
  first_percent: 10
  second_percent: 50
  wait_hours: 24
halt:
  crash_free_drop_points: 0.5
  low_rating_count: 3
  low_rating_window_hours: 24
visual:
  max_diff_percent: 2
frequency:
  max_releases_per_day: 1
market:
  competitors: 10
"""


def write(text):
    d = tempfile.mkdtemp()
    p = Path(d) / "release.yaml"
    p.write_text(text, encoding="utf-8")
    return p


class PolicyTest(unittest.TestCase):
    def test_repository_policy_is_valid(self):
        repo_policy = Path(__file__).resolve().parent.parent / "policy" / "release.yaml"
        loaded = policy.load(repo_policy)
        self.assertEqual(loaded["rollout"]["first_percent"], 10)
        self.assertEqual(loaded["halt"]["crash_free_drop_points"], 0.5)

    def test_missing_key_is_rejected(self):
        with self.assertRaises(policy.PolicyError) as cm:
            policy.load(write(GOOD.replace("  wait_hours: 24\n", "")))
        self.assertIn("rollout.wait_hours", str(cm.exception))

    def test_out_of_range_is_rejected(self):
        for old, new in (
            ("first_percent: 10", "first_percent: 0"),
            ("second_percent: 50", "second_percent: 5"),  # 最初の割合より小さい
            ("max_releases_per_day: 1", "max_releases_per_day: 0"),
            ("crash_free_drop_points: 0.5", "crash_free_drop_points: -1"),
        ):
            with self.assertRaises(policy.PolicyError, msg=new):
                policy.load(write(GOOD.replace(old, new)))

    def test_unknown_key_is_rejected(self):
        with self.assertRaises(policy.PolicyError):
            policy.load(write(GOOD + "extra:\n  x: 1\n"))

    def test_unreadable_yaml_is_rejected(self):
        with self.assertRaises(policy.PolicyError):
            policy.load(write("rollout:\n\tfirst_percent: 10\n"))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `python3 -m unittest tests.test_policy -v`
Expected: FAIL(`cannot import name 'policy'`)

- [ ] **Step 3: 設定と実装を書く**

```yaml
# policy/release.yaml
# 更新版の自動公開の安全装置。変更できるのはオーナーだけ。
# 自動実行はこのファイルを書き換えない(毎晩の実行が検査して戻す)。
rollout:
  first_percent: 10       # 最初に配る利用者の割合
  second_percent: 50      # 次に広げる割合(このあと 100% にする)
  wait_hours: 24          # 次の割合へ広げるまでに待つ時間
halt:
  crash_free_drop_points: 0.5   # クラッシュのない利用者の割合が、前の版よりこれ以上下がったら止める
  low_rating_count: 3           # 星 1〜2 のレビューがこの件数に達したら止める
  low_rating_window_hours: 24   # 上の件数を数える時間の幅
visual:
  max_diff_percent: 2     # 1 画面あたりの差分がこれを超えたら承認待ちに回す
frequency:
  max_releases_per_day: 1 # 1 つのアプリにつき、1 日に公開してよい回数
market:
  competitors: 10         # 市場との比較で相手にするアプリの本数
```

```python
# ops/policy.py
"""安全装置の設定(policy/release.yaml)を読んで検証する。"""
from pathlib import Path

from . import miniyaml


class PolicyError(ValueError):
    pass


# (区分, 項目, 型, 下限, 上限)。上限 None は上限なし。
_SCHEMA = (
    ("rollout", "first_percent", int, 1, 99),
    ("rollout", "second_percent", int, 2, 100),
    ("rollout", "wait_hours", int, 1, None),
    ("halt", "crash_free_drop_points", (int, float), 0, 100),
    ("halt", "low_rating_count", int, 1, None),
    ("halt", "low_rating_window_hours", int, 1, None),
    ("visual", "max_diff_percent", (int, float), 0, 100),
    ("frequency", "max_releases_per_day", int, 1, None),
    ("market", "competitors", int, 1, None),
)


def load(path):
    try:
        data = miniyaml.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        raise PolicyError(f"設定を読めません: {e}")
    known = {}
    for group, key, _, _, _ in _SCHEMA:
        known.setdefault(group, set()).add(key)
    for group, value in data.items():
        if group not in known or not isinstance(value, dict):
            raise PolicyError(f"知らない項目です: {group}")
        for key in value:
            if key not in known[group]:
                raise PolicyError(f"知らない項目です: {group}.{key}")
    for group, key, kind, low, high in _SCHEMA:
        if group not in data or key not in data[group]:
            raise PolicyError(f"項目がありません: {group}.{key}")
        v = data[group][key]
        if isinstance(v, bool) or not isinstance(v, kind):
            raise PolicyError(f"数値ではありません: {group}.{key}")
        if v < low or (high is not None and v > high):
            raise PolicyError(f"範囲の外です: {group}.{key} = {v}")
    if data["rollout"]["second_percent"] <= data["rollout"]["first_percent"]:
        raise PolicyError("rollout.second_percent は first_percent より大きくします")
    return data
```

- [ ] **Step 4: 通ることを確かめる**

Run: `python3 -m unittest tests.test_policy -v`
Expected: `OK`(5 件)

- [ ] **Step 5: Commit**

```bash
git add policy ops/policy.py tests/test_policy.py && git commit -m "feat: 安全装置の設定と検証"
```

---

### Task 3: 台帳

**Files:**
- Create: `ops/ledger.py`
- Create: `ledger/NumberPlace.md` ほか 8 作ぶん(Step 5)
- Test: `tests/test_ledger.py`

**Interfaces:**
- Produces:
  - `ops.ledger.STAGES = ("build", "quality", "release", "feedback")`
  - `ops.ledger.SECTIONS = ("次の一手", "課題", "承認待ち", "人の作業", "未検証の前提")`
  - `ops.ledger.Ledger`(`meta: dict[str, str]`、`sections: dict[str, str]`、`app`、`next_step`、`items(name) -> list[str]`)
  - `ops.ledger.parse(text) -> Ledger`、`ops.ledger.render(ledger) -> str`、`ops.ledger.load(path) -> Ledger`
  - `ops.ledger.LedgerError`(`ValueError` の子)

- [ ] **Step 1: 失敗するテストを書く**

```python
# tests/test_ledger.py
import unittest
from pathlib import Path

from ops import ledger

GOOD = """\
---
app: NumberPlace
stage: release
stage_since: 2026-10-14
web: 1.2.0
android: test 1.1.9
ios: none
---

## 次の一手
1.20 の版を作る。

## 課題
- [bug] 文字拡大でホームの行が折れる(根拠: 2026-10-13 のエミュレータ)
- [idea] 候補メモの色

## 承認待ち

## 人の作業
- アップロード鍵のリセットの承認を待つ

## 未検証の前提
"""


class LedgerTest(unittest.TestCase):
    def test_parse_reads_meta_and_sections(self):
        l = ledger.parse(GOOD)
        self.assertEqual(l.app, "NumberPlace")
        self.assertEqual(l.meta["stage"], "release")
        self.assertEqual(l.meta["web"], "1.2.0")  # 版は文字列のまま(数値にしない)
        self.assertEqual(l.next_step, "1.20 の版を作る。")
        self.assertEqual(len(l.items("課題")), 2)
        self.assertEqual(l.items("承認待ち"), [])
        self.assertEqual(l.items("人の作業"), ["アップロード鍵のリセットの承認を待つ"])

    def test_render_round_trips(self):
        l = ledger.parse(GOOD)
        self.assertEqual(ledger.parse(ledger.render(l)).sections, l.sections)
        self.assertEqual(ledger.parse(ledger.render(l)).meta, l.meta)

    def test_broken_ledgers_are_rejected_with_a_reason(self):
        cases = {
            "先頭に ---": GOOD[4:],
            "閉じる ---": GOOD.replace("ios: none\n---\n", "ios: none\n"),
            "stage": GOOD.replace("stage: release", "stage: shipping"),
            "ios": GOOD.replace("ios: none\n", ""),
            "人の作業": GOOD.replace("## 人の作業\n", "## ひとの作業\n"),
            "2 回": GOOD + "\n## 課題\n",
        }
        for expected, text in cases.items():
            with self.assertRaises(ledger.LedgerError, msg=expected) as cm:
                ledger.parse(text)
            self.assertIn(expected, str(cm.exception))

    def test_every_ledger_in_the_repository_is_valid(self):
        files = sorted((Path(__file__).resolve().parent.parent / "ledger").glob("*.md"))
        self.assertEqual(len(files), 9)
        for f in files:
            l = ledger.load(f)
            self.assertEqual(l.app, f.stem)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `python3 -m unittest tests.test_ledger -v`
Expected: FAIL(`cannot import name 'ledger'`)

- [ ] **Step 3: 実装する**

```python
# ops/ledger.py
"""アプリごとの台帳(ledger/<アプリ>.md)の読み書き。

形: 先頭部(--- で挟んだ `key: value`)と、5 つの見出し。
毎晩の実行は前回の記憶を持たないので、このファイルだけ読めば続きができるように書く。
"""
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List

STAGES = ("build", "quality", "release", "feedback")
SECTIONS = ("次の一手", "課題", "承認待ち", "人の作業", "未検証の前提")
REQUIRED = ("app", "stage", "stage_since", "web", "android", "ios")


class LedgerError(ValueError):
    pass


@dataclass
class Ledger:
    meta: Dict[str, str]
    sections: Dict[str, str]

    @property
    def app(self) -> str:
        return self.meta["app"]

    @property
    def next_step(self) -> str:
        return self.sections["次の一手"].strip()

    def items(self, name: str) -> List[str]:
        return [
            line[2:].strip()
            for line in self.sections[name].splitlines()
            if line.startswith("- ")
        ]


def parse(text: str) -> Ledger:
    if not text.startswith("---\n"):
        raise LedgerError("先頭に --- がありません")
    head, sep, body = text[4:].partition("\n---\n")
    if not sep:
        raise LedgerError("先頭部を閉じる --- がありません")
    meta: Dict[str, str] = {}
    for line in head.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, colon, value = line.partition(":")
        if not colon:
            raise LedgerError(f"先頭部の行が `key: value` の形ではありません: {line}")
        # 版の番号(1.20 など)が数値に化けないよう、値はすべて文字列で持つ。
        meta[key.strip()] = value.strip()
    for key in REQUIRED:
        if not meta.get(key):
            raise LedgerError(f"先頭部に {key} がありません")
    if meta["stage"] not in STAGES:
        raise LedgerError(f"stage は {' / '.join(STAGES)} のどれかです: {meta['stage']}")
    sections: Dict[str, str] = {}
    current = None
    for line in body.splitlines():
        if line.startswith("## "):
            current = line[3:].strip()
            if current in sections:
                raise LedgerError(f"見出し「{current}」が 2 回あります")
            sections[current] = ""
        elif current is not None:
            sections[current] += line + "\n"
    for name in SECTIONS:
        if name not in sections:
            raise LedgerError(f"見出し「{name}」がありません")
    unknown = [name for name in sections if name not in SECTIONS]
    if unknown:
        raise LedgerError(f"知らない見出しです: {'、'.join(unknown)}")
    return Ledger(meta=meta, sections=sections)


def render(ledger: Ledger) -> str:
    head = "".join(f"{key}: {ledger.meta[key]}\n" for key in REQUIRED)
    parts = []
    for name in SECTIONS:
        body = ledger.sections[name].strip()
        parts.append(f"## {name}\n{body}\n" if body else f"## {name}\n")
    return f"---\n{head}---\n\n" + "\n".join(parts)


def load(path) -> Ledger:
    try:
        return parse(Path(path).read_text(encoding="utf-8"))
    except OSError as e:
        raise LedgerError(f"台帳を読めません: {e}")
```

- [ ] **Step 4: 通ることを確かめる(台帳そのものの検査だけはまだ落ちる)**

Run: `python3 -m unittest tests.test_ledger -v`
Expected: 3 件 `ok`、`test_every_ledger_in_the_repository_is_valid` だけ FAIL(`0 != 9`)

- [ ] **Step 5: 9 作の台帳を書く**

各アプリのリポジトリで事実を確かめてから書く。確かめる命令:

```bash
cd /Users/abe/dev/twoyearsold && for d in NumberPlace 2048 AirHockey FreeThrow Gobblet Minesweeper PK Reversi Solitaire; do echo "$d $(grep -m1 '^version:' $d/pubspec.yaml)"; done
```

`ledger/NumberPlace.md` は次の内容にする。

```markdown
---
app: NumberPlace
stage: release
stage_since: 2026-10-14
web: 1.2.0
android: test 1.1.9
ios: none
---

## 次の一手

## 課題
- [idea] アプリ内からプライバシーポリシーを開けるようにする(根拠: Play Console の案内。外部リンクを開く部品と 37 言語の文言が要る)
- [check] 実機での見え方と音を確かめていない(根拠: 2026-10-13 の確認はエミュレータのみ)

## 承認待ち

## 人の作業
- アップロード鍵のリセットの承認を待つ(2026-10-13 に申請済み)。届いたら Claude に知らせる。
- 承認後、1.2.0 の AAB(`~/Desktop/NumberPlace-Play/number-place-1.2.0-13.aab`)のアップロードと審査への送信を承認する。
- テスターを 12 人以上集める(募集文は `NumberPlace/store/play/testers.md`。Reddit への投稿は本人)。

## 未検証の前提
- 個人から組織へ種別を変えたアカウントで、クローズドテストの要件が外れる。
- Google Play の API で、更新版の審査への送信まで完了できる。
```

残り 8 作(`2048.md`、`AirHockey.md`、`FreeThrow.md`、`Gobblet.md`、`Minesweeper.md`、`PK.md`、`Reversi.md`、`Solitaire.md`)は、次の形で書く。`app` はファイル名と同じ、`web` は上の命令で確かめた版(`+` より前)、ほかは下のとおり。

```markdown
---
app: 2048
stage: quality
stage_since: 2026-10-14
web: 1.0.0
android: none
ios: none
---

## 次の一手

## 課題
- [check] Android と iOS のビルドと実機相当での検査をまだ行っていない(根拠: 2026-10-13 時点でストア向けの確認は NumberPlace のみ)

## 承認待ち

## 人の作業

## 未検証の前提
```

追加で書く内容:

- `Gobblet.md` の「課題」に 1 行足す: `- [rights] URL(gobblet-mu.vercel.app)・識別子・パッケージ名に他社の商標が残っている。ストアへ出す前に net.twoyearsold.coverthree と coverthree.twoyearsold.net へ移す(根拠: 2026-10-13 の権利の確認)`
- `PK.md` の「課題」に 1 行足す: `- [quality] 品質ガードに 5 件の穴(読み上げ・文字拡大・キーボード・ゴールデン・タップ領域)と、ライセンス表示の未対応が残る(根拠: quality_baseline.json、2026-10-13)`
- `Minesweeper.md` と `2048.md` の「課題」に 1 行足す: `- [rights] 名称の商標の登録状況を確かめていない(根拠: 2026-10-13 の検索では確認できなかった)`

「次の一手」は 9 作とも空で始める。最初の一手は、運転を始めるときにオーナーと決める。

- [ ] **Step 6: 通ることを確かめて commit**

Run: `python3 -m unittest tests.test_ledger -v`
Expected: `OK`(4 件)

```bash
git add ops/ledger.py tests/test_ledger.py ledger && git commit -m "feat: 台帳の形と、9 作の最初の台帳"
```

---

### Task 4: 朝の報告

**Files:**
- Create: `ops/report.py`
- Test: `tests/test_report.py`

**Interfaces:**
- Consumes: `ops.ledger.Ledger`
- Produces:
  - `ops.report.RunResult`(`NamedTuple`: `app: str`、`status: str`、`detail: str`)。`status` は `"advanced"` / `"waiting"` / `"failed"` のどれか。
  - `ops.report.build(date: datetime.date, ledgers: list[Ledger], results: list[RunResult], previous_report_exists: bool) -> str`

販売数や評価などの数字は、計画③と計画④でストアと統計の取得ができてからこの報告に足す。

- [ ] **Step 1: 失敗するテストを書く**

```python
# tests/test_report.py
import datetime as dt
import unittest

from ops import ledger, report

BASE = """\
---
app: {app}
stage: quality
stage_since: 2026-10-14
web: 1.0.0
android: none
ios: none
---

## 次の一手
{next_step}

## 課題

## 承認待ち
{approval}

## 人の作業
{human}

## 未検証の前提
"""


def make(app, next_step="", approval="", human=""):
    return ledger.parse(BASE.format(app=app, next_step=next_step, approval=approval, human=human))


class ReportTest(unittest.TestCase):
    def setUp(self):
        self.ledgers = [
            make("NumberPlace", approval="- 価格を 300 円にするか", human="- 鍵の承認を待つ"),
            make("Reversi", next_step="出題を軽くする"),
        ]
        self.results = [
            report.RunResult("NumberPlace", "waiting", "次の一手がない"),
            report.RunResult("Reversi", "failed", "テストが 2 件落ちた"),
        ]

    def test_approvals_and_human_work_come_first(self):
        text = report.build(dt.date(2026, 10, 15), self.ledgers, self.results, True)
        self.assertLess(text.index("## 承認待ち"), text.index("## 進んだこと"))
        self.assertLess(text.index("## あなたの作業"), text.index("## 進んだこと"))
        self.assertIn("- NumberPlace: 価格を 300 円にするか", text)
        self.assertIn("- NumberPlace: 鍵の承認を待つ", text)

    def test_failures_are_listed_with_the_reason(self):
        text = report.build(dt.date(2026, 10, 15), self.ledgers, self.results, True)
        self.assertIn("- Reversi: テストが 2 件落ちた", text)

    def test_empty_sections_say_so(self):
        text = report.build(dt.date(2026, 10, 15), [make("2048")], [report.RunResult("2048", "advanced", "検査を足した")], True)
        self.assertIn("## 承認待ち\nありません。", text)
        self.assertIn("## 止まったこと\nありません。", text)
        self.assertIn("- 2048: 検査を足した", text)

    def test_missing_previous_report_is_called_out_at_the_top(self):
        text = report.build(dt.date(2026, 10, 15), self.ledgers, self.results, False)
        self.assertLess(text.index("前日(2026-10-14)の報告がありません"), text.index("## 承認待ち"))

    def test_state_table_lists_every_app(self):
        text = report.build(dt.date(2026, 10, 15), self.ledgers, self.results, True)
        self.assertIn("| NumberPlace | quality | 1.0.0 | none | none |", text)
        self.assertIn("| Reversi | quality | 1.0.0 | none | none |", text)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `python3 -m unittest tests.test_report -v`
Expected: FAIL(`cannot import name 'report'`)

- [ ] **Step 3: 実装する**

```python
# ops/report.py
"""朝の報告(reports/YYYY-MM-DD.md)を作る。

読むのはオーナー。判断が要ること(承認待ち・本人にしかできない作業)を先に置く。
"""
import datetime as dt
from typing import List, NamedTuple

from .ledger import Ledger


class RunResult(NamedTuple):
    app: str
    status: str  # "advanced" / "waiting" / "failed"
    detail: str


def _section(title: str, lines: List[str]) -> str:
    body = "\n".join(lines) if lines else "ありません。"
    return f"## {title}\n{body}\n"


def build(date: dt.date, ledgers: List[Ledger], results: List[RunResult], previous_report_exists: bool) -> str:
    parts = [f"# 報告 {date.isoformat()}\n"]
    if not previous_report_exists:
        yesterday = date - dt.timedelta(days=1)
        parts.append(
            f"**前日({yesterday.isoformat()})の報告がありません。** "
            "その晩の実行が動かなかった可能性があります(Mac の電源やスリープを確かめてください)。\n"
        )
    approvals = [f"- {l.app}: {item}" for l in ledgers for item in l.items("承認待ち")]
    human = [f"- {l.app}: {item}" for l in ledgers for item in l.items("人の作業")]
    advanced = [f"- {r.app}: {r.detail}" for r in results if r.status == "advanced"]
    failed = [f"- {r.app}: {r.detail}" for r in results if r.status == "failed"]
    parts.append(_section("承認待ち", approvals))
    parts.append(_section("あなたの作業", human))
    parts.append(_section("進んだこと", advanced))
    parts.append(_section("止まったこと", failed))
    table = ["| アプリ | 段 | Web | Android | iOS |", "|---|---|---|---|---|"]
    for l in ledgers:
        table.append(f"| {l.app} | {l.meta['stage']} | {l.meta['web']} | {l.meta['android']} | {l.meta['ios']} |")
    parts.append("## 各アプリの状態\n" + "\n".join(table) + "\n")
    return "\n".join(parts)
```

- [ ] **Step 4: 通ることを確かめる**

Run: `python3 -m unittest tests.test_report -v`
Expected: `OK`(5 件)

- [ ] **Step 5: Commit**

```bash
git add ops/report.py tests/test_report.py && git commit -m "feat: 朝の報告"
```

---

### Task 5: 毎晩の実行

**Files:**
- Create: `ops/secrets.py`
- Create: `ops/nightly.py`
- Create: `machine.example.json`
- Test: `tests/test_secrets.py`
- Test: `tests/test_nightly.py`

**Interfaces:**
- Consumes: `ops.ledger`、`ops.policy`、`ops.report.RunResult`、`ops.report.build`
- Produces:
  - `ops.secrets.find(text: str) -> list[tuple[str, int]]`(見つけた種類の名前と行番号)
  - `ops.nightly.run(root: Path, apps_root: Path, date: datetime.date, executor, push: bool, timeout_s: int) -> int`(終了コード。0 = 正常、2 = 秘密らしき文字列を見つけて commit しなかった、3 = 設定が読めない、4 = ほかの実行が動いている)
  - `executor` は `(app: str, ledger_path: Path, repo_dir: Path, timeout_s: int) -> RunResult` の関数。
  - `ops.nightly.claude_executor(machine: dict)` が本番の実行者を返す。
  - `python3 -m ops.nightly` で `machine.json` を読んで実行する。

- [ ] **Step 1: 秘密の検査の、失敗するテストを書く**

```python
# tests/test_secrets.py
import unittest

from ops import secrets


class SecretsTest(unittest.TestCase):
    def test_finds_key_material(self):
        samples = [
            "-----BEGIN PRIVATE KEY-----",
            "-----BEGIN RSA PRIVATE KEY-----",
            "storePassword=Zx81kQpLmN02abCDefGH",
            "token: ghp_" + "a" * 36,
            "key AIza" + "B" * 35,
            'api_key = "abcdefghijklmnopqrstuvwxyz012345"',
        ]
        for s in samples:
            self.assertTrue(secrets.find("ふつうの行\n" + s + "\n"), msg=s)
            self.assertEqual(secrets.find("ふつうの行\n" + s + "\n")[0][1], 2)

    def test_ordinary_text_is_not_flagged(self):
        text = (
            "- アップロード鍵のリセットの承認を待つ\n"
            "鍵は ~/keystores/key.properties にある(中身は書かない)\n"
            "SHA256: C0:A5:F8:90:15:04:24:7D\n"
            "password を変更する手順\n"
        )
        self.assertEqual(secrets.find(text), [])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめてから、秘密の検査を実装する**

Run: `python3 -m unittest tests.test_secrets -v`
Expected: FAIL(`cannot import name 'secrets'`)

```python
# ops/secrets.py
"""台帳や報告に、鍵や API キーらしき文字列が入っていないかを見る。"""
import re
from typing import List, Tuple

_PATTERNS = (
    ("秘密鍵", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("鍵のパスワード", re.compile(r"\b(storePassword|keyPassword)\s*=\s*\S+")),
    ("GitHub のトークン", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}")),
    ("Google の API キー", re.compile(r"\bAIza[0-9A-Za-z_\-]{30,}")),
    (
        "秘密らしき値",
        re.compile(r"(?i)\b(api[_-]?key|secret|token|password)\b\s*[:=]\s*['\"]?[A-Za-z0-9_\-/+]{20,}"),
    ),
)


def find(text: str) -> List[Tuple[str, int]]:
    found = []
    for line_no, line in enumerate(text.splitlines(), 1):
        for name, pattern in _PATTERNS:
            if pattern.search(line):
                found.append((name, line_no))
                break
    return found
```

Run: `python3 -m unittest tests.test_secrets -v`
Expected: `OK`(2 件)

- [ ] **Step 3: 毎晩の実行の、失敗するテストを書く**

```python
# tests/test_nightly.py
import datetime as dt
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from ops import nightly
from ops.report import RunResult

REPO = Path(__file__).resolve().parent.parent
DATE = dt.date(2026, 10, 15)

LEDGER = """\
---
app: {app}
stage: quality
stage_since: 2026-10-14
web: 1.0.0
android: none
ios: none
---

## 次の一手
{next_step}

## 課題

## 承認待ち

## 人の作業

## 未検証の前提
"""


def git(root, *args):
    return subprocess.run(["git", *args], cwd=str(root), capture_output=True, text=True, check=True).stdout


class NightlyTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.apps = Path(tempfile.mkdtemp())
        shutil.copytree(REPO / "policy", self.root / "policy")
        (self.root / "ledger").mkdir()
        (self.root / "reports").mkdir()
        (self.root / "reports" / "2026-10-14.md").write_text("# 報告 2026-10-14\n", encoding="utf-8")
        for app, step in (("Alpha", "検査を足す"), ("Beta", "色を直す"), ("Gamma", "")):
            (self.root / "ledger" / f"{app}.md").write_text(LEDGER.format(app=app, next_step=step), encoding="utf-8")
            (self.apps / app).mkdir()
        (self.root / ".gitignore").write_text(".nightly.lock\n", encoding="utf-8")
        git(self.root, "init", "-b", "main")
        git(self.root, "config", "user.email", "ops@example.invalid")
        git(self.root, "config", "user.name", "ops")
        git(self.root, "add", "-A")
        git(self.root, "commit", "-m", "init")
        self.calls = []

    def run_with(self, executor):
        return nightly.run(self.root, self.apps, DATE, executor, push=False, timeout_s=5)

    def ok(self, app, ledger_path, repo_dir, timeout_s):
        self.calls.append(app)
        return RunResult(app, "advanced", "進めた")

    def report(self):
        return (self.root / "reports" / "2026-10-15.md").read_text(encoding="utf-8")

    def test_advances_apps_that_have_a_next_step_and_commits_the_report(self):
        self.assertEqual(self.run_with(self.ok), 0)
        self.assertEqual(self.calls, ["Alpha", "Beta"])  # 次の一手が空の Gamma は呼ばない
        self.assertIn("- Alpha: 進めた", self.report())
        self.assertEqual(git(self.root, "status", "--porcelain").strip(), "")
        self.assertIn("nightly: 2026-10-15", git(self.root, "log", "-1", "--format=%s"))

    def test_a_broken_ledger_stops_only_that_app(self):
        (self.root / "ledger" / "Alpha.md").write_text("壊れた台帳\n", encoding="utf-8")
        git(self.root, "commit", "-am", "break")
        self.assertEqual(self.run_with(self.ok), 0)
        self.assertEqual(self.calls, ["Beta"])
        self.assertIn("- Alpha: 台帳を読めない", self.report())

    def test_an_executor_that_raises_or_times_out_is_recorded_and_the_rest_continues(self):
        def flaky(app, ledger_path, repo_dir, timeout_s):
            if app == "Alpha":
                raise subprocess.TimeoutExpired(cmd="claude", timeout=timeout_s)
            return RunResult(app, "advanced", "進めた")

        self.assertEqual(self.run_with(flaky), 0)
        text = self.report()
        self.assertIn("- Alpha: 制限時間", text)
        self.assertIn("- Beta: 進めた", text)

    def test_a_change_to_the_policy_is_reverted_and_reported(self):
        original = (self.root / "policy" / "release.yaml").read_text(encoding="utf-8")

        def loosens(app, ledger_path, repo_dir, timeout_s):
            p = self.root / "policy" / "release.yaml"
            p.write_text(p.read_text(encoding="utf-8").replace("first_percent: 10", "first_percent: 90"), encoding="utf-8")
            return RunResult(app, "advanced", "進めた")

        self.assertEqual(self.run_with(loosens), 0)
        self.assertEqual((self.root / "policy" / "release.yaml").read_text(encoding="utf-8"), original)
        self.assertIn("- Alpha: 安全装置の設定を書き換えようとした", self.report())

    def test_a_ledger_broken_by_the_executor_is_restored(self):
        before = (self.root / "ledger" / "Alpha.md").read_text(encoding="utf-8")

        def breaks(app, ledger_path, repo_dir, timeout_s):
            if app == "Alpha":
                ledger_path.write_text("こわした\n", encoding="utf-8")
            return RunResult(app, "advanced", "進めた")

        self.assertEqual(self.run_with(breaks), 0)
        self.assertEqual((self.root / "ledger" / "Alpha.md").read_text(encoding="utf-8"), before)
        self.assertIn("- Alpha: 実行のあと台帳が読めなくなった", self.report())

    def test_a_secret_in_the_ledger_blocks_the_commit(self):
        def leaks(app, ledger_path, repo_dir, timeout_s):
            ledger_path.write_text(
                ledger_path.read_text(encoding="utf-8").replace("## 課題\n", "## 課題\n- storePassword=Zx81kQpLmN02abCDefGH\n"),
                encoding="utf-8",
            )
            return RunResult(app, "advanced", "進めた")

        head = git(self.root, "rev-parse", "HEAD")
        self.assertEqual(self.run_with(leaks), 2)
        self.assertEqual(git(self.root, "rev-parse", "HEAD"), head)  # commit していない

    def test_missing_previous_report_is_called_out(self):
        (self.root / "reports" / "2026-10-14.md").unlink()
        git(self.root, "commit", "-am", "drop")
        self.assertEqual(self.run_with(self.ok), 0)
        self.assertIn("前日(2026-10-14)の報告がありません", self.report())

    def test_an_unreadable_policy_stops_everything(self):
        (self.root / "policy" / "release.yaml").write_text("rollout:\n\tx: 1\n", encoding="utf-8")
        git(self.root, "commit", "-am", "bad policy")
        self.assertEqual(self.run_with(self.ok), 3)
        self.assertEqual(self.calls, [])

    def test_a_second_run_at_the_same_time_does_nothing(self):
        import fcntl

        with open(self.root / ".nightly.lock", "w") as held:
            fcntl.flock(held, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(self.run_with(self.ok), 4)
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 4: 失敗を確かめる**

Run: `python3 -m unittest tests.test_nightly -v`
Expected: FAIL(`cannot import name 'nightly'`)

- [ ] **Step 5: 毎晩の実行を実装する**

`machine.example.json`(写して `machine.json` を作る。`machine.json` は git で管理しない):

```json
{
  "apps_root": "/Users/abe/dev/twoyearsold",
  "claude_bin": "/Users/abe/.nvm/versions/node/v24.16.0/bin/claude",
  "permission_mode": "acceptEdits",
  "extra_args": [],
  "timeout_minutes": 45,
  "push": true
}
```

`permission_mode` と `extra_args` は、Task 0 の Step 2 で動いた組み合わせにする(例: `"extra_args": ["--allowedTools", "Bash(flutter:*)", "Bash(dart:*)", "Bash(python3:*)"]`)。

```python
# ops/nightly.py
"""毎晩の実行。台帳の「次の一手」を実行者へ渡し、検査してから報告を残す。

実行者(本番は無人実行の Claude)を信頼しきらない。実行のあとに必ず、
安全装置の設定・台帳の形・秘密らしき文字列を確かめる。
"""
import argparse
import datetime as dt
import fcntl
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Callable, List

from . import ledger as ledger_mod
from . import policy as policy_mod
from . import report as report_mod
from . import secrets as secrets_mod
from .report import RunResult

Executor = Callable[[str, Path, Path, int], RunResult]

PROMPT = """\
あなたは TWOYEARSOLD の運用を進める担当です。アプリ「{app}」の台帳は {ledger} です。
台帳の「次の一手」に書かれた作業を 1 つだけ進めてください。

守ること:
- 作業の結果を台帳に書く(「次の一手」を次の作業に書き換える。判断が要ることは「承認待ち」、
  本人にしかできない操作は「人の作業」に手順つきで書く。根拠のない課題は足さない)。
- 台帳の見出し(次の一手 / 課題 / 承認待ち / 人の作業 / 未検証の前提)と先頭部の項目を変えない。
- 失敗したら、何が起きたかを台帳に書いて止まる。同じ作業をやり直さない。
- しないこと: 価格の変更、削除、規約への同意、外部への投稿、ストアへの登録と公開、
  新しいアプリの着手、{policy} の変更。
- 鍵や API キーの中身を、台帳にも出力にも書かない。
最後に、進めたことを 1 文で答えてください。
"""


def _git(root: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=str(root), capture_output=True, text=True, check=True).stdout


def _policy_changed(root: Path) -> bool:
    return _git(root, "status", "--porcelain", "--", "policy").strip() != ""


def _restore(root: Path, path: str) -> None:
    _git(root, "checkout", "--", path)
    _git(root, "clean", "-fdq", "--", path)


def run(root: Path, apps_root: Path, date: dt.date, executor: Executor, push: bool, timeout_s: int) -> int:
    root = Path(root)
    lock = open(root / ".nightly.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("ほかの実行が動いています。何もしません。", file=sys.stderr)
        lock.close()
        return 4
    try:
        try:
            policy_mod.load(root / "policy" / "release.yaml")
        except policy_mod.PolicyError as e:
            print(f"安全装置の設定を読めません。何もしません: {e}", file=sys.stderr)
            return 3

        results: List[RunResult] = []
        for path in sorted((root / "ledger").glob("*.md")):
            app = path.stem
            rel = f"ledger/{path.name}"
            try:
                current = ledger_mod.load(path)
            except ledger_mod.LedgerError as e:
                results.append(RunResult(app, "failed", f"台帳を読めない({e})"))
                continue
            if not current.next_step:
                results.append(RunResult(app, "waiting", "次の一手がない"))
                continue
            try:
                result = executor(app, path, Path(apps_root) / app, timeout_s)
            except subprocess.TimeoutExpired:
                result = RunResult(app, "failed", f"制限時間({timeout_s // 60} 分)で終わらなかった")
            except Exception as e:  # 実行者の失敗で、ほかのアプリを止めない。
                result = RunResult(app, "failed", f"実行に失敗した({type(e).__name__}: {e})")
            if _policy_changed(root):
                _restore(root, "policy")
                result = RunResult(app, "failed", "安全装置の設定を書き換えようとした(変更は戻した)")
            try:
                ledger_mod.load(path)
            except ledger_mod.LedgerError as e:
                _restore(root, rel)
                result = RunResult(app, "failed", f"実行のあと台帳が読めなくなった({e})。台帳は実行前に戻した")
            results.append(result)

        ledgers = []
        for path in sorted((root / "ledger").glob("*.md")):
            try:
                ledgers.append(ledger_mod.load(path))
            except ledger_mod.LedgerError:
                pass  # 読めない台帳は「止まったこと」に出ている。
        previous = root / "reports" / f"{(date - dt.timedelta(days=1)).isoformat()}.md"
        text = report_mod.build(date, ledgers, results, previous.exists())
        (root / "reports").mkdir(exist_ok=True)
        (root / "reports" / f"{date.isoformat()}.md").write_text(text, encoding="utf-8")

        _git(root, "add", "-A")
        added = [
            line[1:]
            for line in _git(root, "diff", "--cached", "--unified=0").splitlines()
            if line.startswith("+") and not line.startswith("+++")
        ]
        found = secrets_mod.find("\n".join(added))
        if found:
            _git(root, "reset", "-q")
            kinds = "、".join(sorted({name for name, _ in found}))
            print(f"鍵や API キーらしき文字列({kinds})があります。commit も push もしません。", file=sys.stderr)
            return 2
        if _git(root, "status", "--porcelain").strip():
            _git(root, "commit", "-q", "-m", f"nightly: {date.isoformat()}")
        if push:
            _git(root, "push", "-q")
        return 0
    finally:
        fcntl.flock(lock, fcntl.LOCK_UN)
        lock.close()


def claude_executor(machine: dict) -> Executor:
    def execute(app: str, ledger_path: Path, repo_dir: Path, timeout_s: int) -> RunResult:
        prompt = PROMPT.format(app=app, ledger=ledger_path, policy=ledger_path.parent.parent / "policy")
        env = dict(os.environ)
        env["PATH"] = os.pathsep.join(
            [str(Path(machine["claude_bin"]).parent), "/opt/homebrew/bin", "/usr/bin", "/bin", env.get("PATH", "")]
        )
        done = subprocess.run(
            [
                machine["claude_bin"],
                "-p",
                prompt,
                "--permission-mode",
                machine["permission_mode"],
                # 台帳は作業場所(アプリのリポジトリ)の外にあるので、読み書きを許す。
                "--add-dir",
                str(ledger_path.parent.parent),
                *machine.get("extra_args", []),
            ],
            cwd=str(repo_dir),
            capture_output=True,
            text=True,
            timeout=timeout_s,
            env=env,
        )
        tail = (done.stdout or done.stderr).strip().splitlines()
        last = tail[-1][:200] if tail else "出力なし"
        if done.returncode != 0:
            return RunResult(app, "failed", f"実行者が異常終了した({last})")
        return RunResult(app, "advanced", last)

    return execute


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="毎晩の実行")
    parser.add_argument("--date", help="報告の日付(YYYY-MM-DD)。省略時は今日")
    args = parser.parse_args(argv)
    root = Path(__file__).resolve().parent.parent
    machine = json.loads((root / "machine.json").read_text(encoding="utf-8"))
    date = dt.date.fromisoformat(args.date) if args.date else dt.date.today()
    return run(
        root,
        Path(machine["apps_root"]),
        date,
        claude_executor(machine),
        push=bool(machine["push"]),
        timeout_s=int(machine["timeout_minutes"]) * 60,
    )


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 6: 通ることを確かめる**

Run: `python3 -m unittest discover -s tests -v`
Expected: `OK`(Task 1〜5 のテストすべて)

- [ ] **Step 7: Commit**

```bash
git add ops/secrets.py ops/nightly.py machine.example.json tests/test_secrets.py tests/test_nightly.py && git commit -m "feat: 毎晩の実行(実行のあとの検査と報告)"
```

---

### Task 6: 予定の登録と、使い方の文書

**Files:**
- Create: `bin/nightly.sh`
- Create: `launchd/net.twoyearsold.ops.nightly.plist`
- Create: `bin/install_schedule.sh`
- Create: `README.md`
- Test: `tests/test_schedule.py`

**Interfaces:**
- Consumes: `python3 -m ops.nightly`
- Produces: `bin/install_schedule.sh`(予定を登録する)、`bin/install_schedule.sh --remove`(外す)。

- [ ] **Step 1: 失敗するテストを書く**

```python
# tests/test_schedule.py
import plistlib
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


class ScheduleTest(unittest.TestCase):
    def test_plist_runs_the_nightly_script_at_two(self):
        with open(REPO / "launchd" / "net.twoyearsold.ops.nightly.plist", "rb") as f:
            plist = plistlib.load(f)
        self.assertEqual(plist["Label"], "net.twoyearsold.ops.nightly")
        self.assertEqual(plist["StartCalendarInterval"], {"Hour": 2, "Minute": 0})
        self.assertEqual(plist["ProgramArguments"], ["/bin/bash", "__OPS__/bin/nightly.sh"])
        self.assertTrue(plist["StandardErrorPath"].startswith("__OPS__/logs/"))

    def test_scripts_exist_and_are_executable(self):
        for name in ("nightly.sh", "install_schedule.sh"):
            p = REPO / "bin" / name
            self.assertTrue(p.exists(), name)
            self.assertTrue(p.stat().st_mode & 0o100, name)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 失敗を確かめる**

Run: `python3 -m unittest tests.test_schedule -v`
Expected: FAIL(ファイルがない)

- [ ] **Step 3: 実装する**

```bash
#!/bin/bash
# bin/nightly.sh — launchd から呼ばれる入口。
set -u
OPS="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OPS/logs"
cd "$OPS" || exit 1
echo "=== $(date '+%Y-%m-%d %H:%M:%S') 開始"
/usr/bin/python3 -m ops.nightly
code=$?
echo "=== $(date '+%Y-%m-%d %H:%M:%S') 終了($code)"
exit $code
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- launchd/net.twoyearsold.ops.nightly.plist。__OPS__ は登録のときにリポジトリの場所へ置き換える。 -->
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>net.twoyearsold.ops.nightly</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>__OPS__/bin/nightly.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>2</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>__OPS__/logs/nightly.out.log</string>
  <key>StandardErrorPath</key>
  <string>__OPS__/logs/nightly.err.log</string>
</dict>
</plist>
```

```bash
#!/bin/bash
# bin/install_schedule.sh — 毎晩 2:00 の予定を登録する。--remove で外す。
set -eu
OPS="$(cd "$(dirname "$0")/.." && pwd)"
LABEL=net.twoyearsold.ops.nightly
TARGET="$HOME/Library/LaunchAgents/$LABEL.plist"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if [ "${1:-}" = "--remove" ]; then
  rm -f "$TARGET"
  echo "予定を外しました。"
  exit 0
fi
[ -f "$OPS/machine.json" ] || { echo "machine.json がありません。machine.example.json を写して作ってください。" >&2; exit 1; }
mkdir -p "$HOME/Library/LaunchAgents" "$OPS/logs"
sed "s#__OPS__#$OPS#g" "$OPS/launchd/$LABEL.plist" > "$TARGET"
launchctl bootstrap "gui/$(id -u)" "$TARGET"
echo "毎晩 2:00 に実行します。ログ: $OPS/logs/"
```

```bash
chmod +x bin/nightly.sh bin/install_schedule.sh
```

`README.md` には次を書く。

```markdown
# twoyearsold-ops

TWOYEARSOLD のアプリを運用する台帳と、毎晩の実行。設計は
`twoyearsold_ui/docs/superpowers/specs/2026-10-14-ecosystem-design.md`。

## 置いてあるもの

- `ledger/<アプリ>.md` — アプリごとの台帳。いまの段、次の一手、課題、承認待ち、人の作業、未検証の前提。
- `policy/release.yaml` — 更新版の自動公開の安全装置。**変更できるのはオーナーだけ。**
- `reports/YYYY-MM-DD.md` — 朝の報告。
- `ops/` — 毎晩の実行の中身。`python3 -m unittest discover -s tests -v` でテストする。

## 朝にすること

その日の報告(`reports/`)を読む。上から順に、承認待ち、あなたの作業、進んだこと、止まったこと。
承認や差し戻しは、台帳の「承認待ち」の項目を書き換えるか、Claude に伝える。

## 次の一手の決め方

台帳の「次の一手」に、次の晩に進める作業を 1 つ書く。空のアプリは、その晩は何もしない。

## 予定の登録

1. `machine.example.json` を写して `machine.json` を作り、この Mac に合わせて直す。
2. `bin/install_schedule.sh` を実行する(外すときは `bin/install_schedule.sh --remove`)。

Mac を閉じている間は実行されない。抜けた晩は、次の報告の先頭に出る。

## 台を移すとき

新しい Mac でリポジトリを取得し、`machine.json` を作り、`bin/install_schedule.sh` を実行する。
古い Mac では `bin/install_schedule.sh --remove` を実行する。台に固有の設定は `machine.json` だけ。

## 守られていること

- 自動実行が `policy/` を書き換えたら、変更を戻して報告に出す。
- 自動実行が台帳を壊したら、実行前に戻して報告に出す。
- 台帳や報告に鍵や API キーらしき文字列が入ったら、commit も push もしない。
- 設定が読めないときは、何もしない。
```

- [ ] **Step 4: 通ることを確かめる**

Run: `python3 -m unittest discover -s tests -v`
Expected: `OK`(全テスト)

- [ ] **Step 5: 偽の実行者なしで、1 回だけ手で動かして確かめる**

9 作とも「次の一手」が空なので、実行者は 1 度も呼ばれない。報告だけが作られる。

```bash
cp machine.example.json machine.json
python3 - <<'EOF'
import json, pathlib
p = pathlib.Path("machine.json"); m = json.loads(p.read_text()); m["push"] = False; p.write_text(json.dumps(m, indent=2) + "\n")
EOF
python3 -m ops.nightly; echo "exit=$?"; cat "reports/$(date +%F).md" | head -20; git log -1 --format=%s
```

Expected: `exit=0`。報告に 9 作の状態の表と、NumberPlace の「あなたの作業」3 件が出る。最後の commit が `nightly: <今日の日付>`。

- [ ] **Step 6: Commit と push**

```bash
git add bin launchd README.md tests/test_schedule.py && git commit -m "feat: 毎晩の予定の登録と、使い方の文書" && git push
```

- [ ] **Step 7: 予定の登録(オーナーの承認後)**

予定の登録は、この Mac に常駐の設定を足す操作なので、実行の前にオーナーへ確認する。承認されたら:

```bash
python3 - <<'EOF'
import json, pathlib
p = pathlib.Path("machine.json"); m = json.loads(p.read_text()); m["push"] = True; p.write_text(json.dumps(m, indent=2) + "\n")
EOF
bin/install_schedule.sh && launchctl print "gui/$(id -u)/net.twoyearsold.ops.nightly" | grep -E "state|path" | head -3
```

Expected: `毎晩 2:00 に実行します。` と、登録された予定の状態。

- [ ] **Step 8: 保護設定(Task 0 の Step 4 で使えると分かった場合)**

`policy/` への変更にオーナーの承認を必須にする。リポジトリの設定を変える操作なので、実行の前にオーナーへ確認する。

```bash
mkdir -p .github && printf '/policy/ @takuyaabe11\n' > .github/CODEOWNERS
git add .github && git commit -m "chore: policy の変更にオーナーの承認を必須にする" && git push
```

使えないと分かった場合は、この Step を飛ばし、その旨を `docs/assumptions.md` に書く。その場合の守りは、Task 5 の「設定の書き換えを戻す検査」になる。
