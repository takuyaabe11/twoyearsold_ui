#!/usr/bin/env bash
# `flutter build web` の後処理。オフライン用の先取り一覧を app_sw.js へ埋め込む。
# 使い方: bash pwa_postbuild.sh [出力ディレクトリ(既定 build/web)]
set -euo pipefail

cd "${1:-build/web}"

# Flutter 同梱の service worker は「自分を unregister するだけ」の非推奨版なので撤去し、
# 自前の SW(web/app_sw.js → ここへコピー済み)に任せる。
rm -f flutter_service_worker.js

# 先取り対象 = 配信物すべて。ただし canvaskit/ は除く(端末ごとに使う版が違い重い。
# ページが実際に読んだ版を SW へ渡して控えさせる)。
files=$(find . -type f \
  ! -name '.*' ! -name 'app_sw.js' ! -name '*.symbols' ! -name '*.map' \
  ! -path './canvaskit/*' | sed 's|^\./||' | LC_ALL=C sort)

# 中身が 1 バイトでも変われば版が変わり、SW が入れ替わって控えを取り直す。
version=$(printf '%s\n' "$files" | while IFS= read -r f; do cksum < "$f"; done | cksum | cut -d' ' -f1)
list=$(printf '%s\n' "$files" | sed 's|.*|"&"|' | paste -sd, -)

{
  printf "const VERSION = '%s';\n" "$version"
  printf 'const PRECACHE = [%s];\n' "$list"
  grep -v -e '^const VERSION = ' -e '^const PRECACHE = ' app_sw.js
} > app_sw.js.tmp
mv app_sw.js.tmp app_sw.js

echo "pwa_postbuild: version $version, $(printf '%s\n' "$files" | wc -l | tr -d ' ') files precached"
