#!/usr/bin/env bash
# Build monitoralign-<version>.kwinscript (zip) for the KDE Store / kpackagetool6 -i.
# Note: the archive only contains the settings page; monitoralign-daemon must be installed with install.sh.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; V="$(python3 -c 'import json;print(json.load(open("'"$HERE"'/package/metadata.json"))["KPlugin"]["Version"])')"
T="$(mktemp -d)"; cp -r "$HERE/package/." "$T/"; mkdir -p "$T/contents/config"; cp "$HERE/templates/main.xml" "$T/contents/config/"; cp "$HERE/templates/config.ui" "$T/contents/ui/"
( cd "$T" && zip -qr "$HERE/monitoralign-$V.kwinscript" . -x '*.pyc' )
rm -rf "$T"; echo "monitoralign-$V.kwinscript"
