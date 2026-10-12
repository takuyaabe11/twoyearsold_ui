#!/usr/bin/env bash
# Vercel 上で Flutter Web をビルドする。Flutter は同梱されないため固定版を取得する。
set -euo pipefail

git config --global --add safe.directory '*'
git clone --depth 1 -b 3.44.1 https://github.com/flutter/flutter.git _flutter
_flutter/bin/flutter config --enable-web
_flutter/bin/flutter pub get
# --no-web-resources-cdn: CanvasKit を gstatic CDN ではなく自オリジンに同梱
# (オフライン動作の前提 + 第三者CDNへの依存を断つ)。
_flutter/bin/flutter build web --release --no-tree-shake-icons --no-web-resources-cdn
# オフライン用の先取り一覧を service worker(web/app_sw.js)へ埋め込む。
bash pwa_postbuild.sh build/web
