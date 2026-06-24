#!/bin/sh
# TWOYEARSOLD の各ゲームリポジトリ用 pre-push フック。
# push 前に i18n ガード(DESIGN.md §10.6 ローカライズ・ゲート)を実行し、違反があれば push を止める。
#
# インストール(各ゲームのローカル作業ツリーで一度だけ):
#   cp ../twoyearsold_ui/tool/git_pre_push_hook.sh .git/hooks/pre-push
#   chmod +x .git/hooks/pre-push
#
# 前提: モノレポ配置(twoyearsold/ 配下に各ゲームと twoyearsold_ui が兄弟で存在)。
set -e
APP=$(basename "$(pwd)")
GUARD="../twoyearsold_ui/tool/i18n_guard.py"
if [ ! -f "$GUARD" ]; then
  echo "i18n guard が見つかりません($GUARD)。モノレポ配置で実行してください。スキップします。"
  exit 0
fi
echo "▶ i18n ガード(DESIGN.md §10.6)を実行: $APP"
if ! python3 "$GUARD" "$APP"; then
  echo ""
  echo "✗ i18n ガード違反のため push を中止しました。"
  echo "  直書きは L10n 化するか行末に // i18n-ok。未訳/空値は全ロケール埋める。"
  echo "  文言変更後は build_cjk_fonts.py でフォント再生成。"
  exit 1
fi
