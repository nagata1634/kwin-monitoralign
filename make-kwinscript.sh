#!/usr/bin/env bash
# KDE Store / kpackagetool6 -i 用の monitoralign.kwinscript (zip) を作る。
# 注意: この zip は設定ページの器だけ。実際に配置を変える monitoralign-daemon は別途 install.sh で導入が必要。
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; V="$(python3 -c 'import json;print(json.load(open("'"$HERE"'/package/metadata.json"))["KPlugin"]["Version"])')"
T="$(mktemp -d)"; cp -r "$HERE/package/." "$T/"; mkdir -p "$T/contents/config"; cp "$HERE/templates/main.xml" "$T/contents/config/"; cp "$HERE/templates/config.ui" "$T/contents/ui/"
( cd "$T" && zip -qr "$HERE/monitoralign-$V.kwinscript" . -x '*.pyc' )
rm -rf "$T"; echo "monitoralign-$V.kwinscript"
