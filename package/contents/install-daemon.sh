#!/usr/bin/env bash
# Install the Monitor Align helper daemon from this package (e.g. after installing the KWin
# script from the KDE Store via System Settings > KWin Scripts > Get New...). No root needed.
#   ~/.local/share/kwin/scripts/monitoralign/contents/install-daemon.sh            install + start
#   ~/.local/share/kwin/scripts/monitoralign/contents/install-daemon.sh --uninstall
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin/monitoralign-daemon"
UNIT="$HOME/.config/systemd/user/monitoralign.service"
ok() { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
if [ "${1:-}" = "--uninstall" ]; then
  systemctl --user disable --now monitoralign.service 2>/dev/null || true
  rm -f "$BIN" "$UNIT"; systemctl --user daemon-reload; ok "daemon removed"; exit 0
fi
for c in kscreen-doctor kreadconfig6 kwriteconfig6 python3; do
  command -v "$c" >/dev/null || { echo "missing command: $c" >&2; exit 1; }
done
python3 -c 'import PySide6.QtCore' 2>/dev/null || { echo "PySide6 for Python 3 is required (Fedora: dnf install python3-pyside6; Arch: pyside6; Debian/Ubuntu: python3-pyside6.qtcore)" >&2; exit 1; }
mkdir -p "$(dirname "$BIN")" "$(dirname "$UNIT")"
install -m 0755 "$HERE/bin/monitoralign-daemon" "$BIN"
install -m 0644 "$HERE/systemd/monitoralign.service" "$UNIT"
kwriteconfig6 --file kwinrc --group Plugins --key monitoralignEnabled true
systemctl --user daemon-reload
systemctl --user enable --now monitoralign.service
sleep 1
ok "installed: $BIN, $UNIT (monitoralign.service enabled)"
echo "Reopen System Settings > Window Management > KWin Scripts > Monitor Align (gear) to see the per-monitor rows."
"$BIN" --status
