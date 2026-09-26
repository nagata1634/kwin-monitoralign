#!/usr/bin/env bash
# Build monitoralign-<version>.kwinscript (zip) for the KDE Store / kpackagetool6 -i.
# The archive also carries the daemon and unit under contents/; after a Store install run
#   ~/.local/share/kwin/scripts/monitoralign/contents/install-daemon.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; V="$(python3 -c 'import json;print(json.load(open("'"$HERE"'/package/metadata.json"))["KPlugin"]["Version"])')"
T="$(mktemp -d)"; cp -r "$HERE/package/." "$T/"; find "$T" -name __pycache__ -type d -exec rm -rf {} +; mkdir -p "$T/contents/config"; cp "$HERE/templates/main.xml" "$T/contents/config/"; cp "$HERE/templates/config.ui" "$T/contents/ui/"
( cd "$T" && zip -qr "$HERE/monitoralign-$V.kwinscript" . -x '*.pyc' )
rm -rf "$T"; echo "monitoralign-$V.kwinscript"
