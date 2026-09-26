#!/usr/bin/env bash
# Monitor Align を現在のユーザーに導入する（root 不要・冪等）。
#
#   ./install.sh          KWin スクリプトを kpackagetool6 で導入し、デーモンと unit をコピー
#   ./install.sh --link   コピーせず、このリポジトリへの symlink を張る（開発用）
#   ./install.sh --uninstall
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_ID=monitoralign
PKG_DIR="$HOME/.local/share/kwin/scripts/$PKG_ID"
BIN="$HOME/.local/bin/monitoralign-daemon"
UNIT="$HOME/.config/systemd/user/monitoralign.service"

ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

# 設定ページ(config.ui / main.xml)はデーモンが生成する。無い間の初期表示だけテンプレートで埋める。
seed_templates() {
  mkdir -p "$PKG_DIR/contents/config" "$PKG_DIR/contents/ui"
  [ -e "$PKG_DIR/contents/config/main.xml" ] || cp "$HERE/templates/main.xml" "$PKG_DIR/contents/config/main.xml"
  [ -e "$PKG_DIR/contents/ui/config.ui" ]    || cp "$HERE/templates/config.ui" "$PKG_DIR/contents/ui/config.ui"
}

uninstall() {
  systemctl --user disable --now monitoralign.service 2>/dev/null || true
  rm -f "$UNIT" "$BIN"
  if [ -L "$PKG_DIR" ]; then rm -f "$PKG_DIR"; else kpackagetool6 -t KWin/Script -r "$PKG_ID" 2>/dev/null || rm -rf "$PKG_DIR"; fi
  kwriteconfig6 --file kwinrc --group Plugins --key "${PKG_ID}Enabled" --delete 2>/dev/null || true
  systemctl --user daemon-reload
  ok "Monitor Align をアンインストールしました（kwinrc の [Script-monitoralign] は残しています）"
}

case "${1:-}" in
  --uninstall) uninstall; exit 0 ;;
  --link) LINK=1 ;;
  "") LINK=0 ;;
  *) echo "usage: $0 [--link|--uninstall]" >&2; exit 2 ;;
esac

for c in kpackagetool6 kscreen-doctor kreadconfig6 kwriteconfig6 python3; do
  command -v "$c" >/dev/null || { echo "必要なコマンドがありません: $c" >&2; exit 1; }
done
python3 -c 'import PySide6.QtCore' 2>/dev/null || { echo "python3-pyside6 が必要です（Fedora: rpm-ostree install python3-pyside6 / dnf install python3-pyside6）" >&2; exit 1; }

mkdir -p "$(dirname "$BIN")" "$(dirname "$UNIT")" "$(dirname "$PKG_DIR")"
if [ "$LINK" = 1 ]; then
  [ -d "$PKG_DIR" ] && [ ! -L "$PKG_DIR" ] && kpackagetool6 -t KWin/Script -r "$PKG_ID" >/dev/null 2>&1 || true
  ln -sfn "$HERE/package" "$PKG_DIR"
  ln -sf "$HERE/bin/monitoralign-daemon" "$BIN"
  ln -sf "$HERE/systemd/monitoralign.service" "$UNIT"
  ok "symlink を張りました: $PKG_DIR, $BIN, $UNIT"
  seed_templates
else
  if [ -L "$PKG_DIR" ]; then rm -f "$PKG_DIR"; fi
  if [ -d "$PKG_DIR" ]; then kpackagetool6 -t KWin/Script -u "$HERE/package" >/dev/null; else kpackagetool6 -t KWin/Script -i "$HERE/package" >/dev/null; fi
  install -m 0755 "$HERE/bin/monitoralign-daemon" "$BIN"
  install -m 0644 "$HERE/systemd/monitoralign.service" "$UNIT"
  seed_templates
  ok "導入しました: $PKG_DIR, $BIN, $UNIT"
fi

kwriteconfig6 --file kwinrc --group Plugins --key "${PKG_ID}Enabled" true
systemctl --user daemon-reload
systemctl --user enable --now monitoralign.service
sleep 1
info "設定ページ: System Settings › ウィンドウの管理 › KWin スクリプト › Monitor Align の歯車"
"$BIN" --status
