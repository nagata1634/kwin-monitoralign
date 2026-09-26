# Monitor Align

English | [日本語](README.ja.md)

A KWin script + small helper daemon for KDE Plasma (Wayland) that lets you fix the **vertical
misalignment between side-by-side monitors from System Settings**, so the cursor **doesn't jump**
when it crosses from one screen to the next.

Different stands and arms put monitor tops hundreds of pixels apart. Dragging screens around in
KDE's Display Configuration is guesswork; you want to nudge the value a few pixels at a time and
watch the cursor. Monitor Align reduces the problem to one number per monitor — "how many px below
the Primary" — and gives you a slider, ±1/±10 buttons and a spin box for it.

```
1. DP-5  landscape 2560×1440  —  reference (Primary) 0 px

              2. DP-6  portrait 1440×2560
      [──────────────●──────────────────────]
   [−10] [−1] [ DP-5 + -745 px down ▲▼ ] [+1] [+10]
```

## Features

- **Lives in System Settings**: Window Management › KWin Scripts › Monitor Align › ⚙
- Shows **only the connected monitors**, by connector name (`DP-5`, …); follows hot-plug within 10 s
- **X is automatic**: monitors are laid out left to right (internal panel first, then external ones
  by name) with no gap, so a gap that strands the cursor can't happen
- **Vertical overlap is guaranteed**: values are clamped so neighbours always overlap (the cursor
  can always cross)
- **Safe**: all outputs are applied with a single `kscreen-doctor` call, read back and verified;
  on mismatch the previous layout is restored automatically
- **English / Japanese** settings page and log, chosen by locale (`LANG` = `ja*` → Japanese)
- Wayland native. No X11 / xrandr involved

## How it works

KWin scripts have no API to move outputs, and the generic config dialog (KCM) can't run logic.
So the KWin script is **only the container for the settings page** (`code/main.js` is empty);
values land in `~/.config/kwinrc` under `[Script-monitoralign]`. The resident
`monitoralign-daemon` (PySide6, `QFileSystemWatcher`) watches that file, computes the layout and
hands it to `kscreen-doctor`.

Because the settings page (`contents/ui/config.ui` / `contents/config/main.xml`) can only be a static
file, the daemon **generates it from the connected monitors**.

Coordinates come exclusively from `kscreen-doctor -j` logical values (`pos`, `round(size/scale)`).

## Requirements

- KDE Plasma 6 (Wayland)
- `kscreen-doctor`, `kreadconfig6`, `kwriteconfig6`, `kpackagetool6` (ship with Plasma)
- Python 3 + PySide6 (Fedora: `python3-pyside6`; Arch: `pyside6`; Debian/Ubuntu: `python3-pyside6.qtcore`)

## Install

```sh
git clone https://github.com/nagata1634/kwin-monitoralign.git
cd kwin-monitoralign
./install.sh          # installs the KWin script, the daemon and a systemd --user unit, then starts it
```

For development use symlinks instead of copies: `./install.sh --link`. Remove: `./install.sh --uninstall`.

`make-kwinscript.sh` builds a `.kwinscript` archive (KDE Store / `kpackagetool6 -i`). Note that the
archive only contains the settings page; the daemon still has to be installed with `install.sh`.

## Usage

1. System Settings › Window Management › KWin Scripts › **Monitor Align** › ⚙
2. For every monitor except the Primary, pick a value with the slider, `[−10] [−1] [+1] [+10]` or
   the spin box, then **Apply**
3. Move the cursor sideways across the boundary and find the value where it stops jumping
   - it arrives **higher** than expected on the neighbour → move the source monitor **down** (increase)
   - **lower** → move it **up**

Command line:

```sh
monitoralign-daemon --status   # connector ↔ current position ↔ setting
monitoralign-daemon --once     # regenerate the page and apply once
journalctl --user -u monitoralign -f
```

## Limitations

- Single-row layouts only (no stacking)
- Settings are keyed by logical size plus index among identical sizes (e.g. `y_1108x1969_1`),
  not by connector name, so DisplayPort MST renames (`DP-5/6` ↔ `DP-7/8`) keep their values.
  Several monitors of the same size *and* orientation are numbered by name and may swap on a rename
- Values take effect on **Apply** (a generic KCM cannot apply on change)

## Known caveat

Changing the output layout in the first seconds after KWin starts crashed KWin once, so the daemon
waits 15 s after `plasmashell` is up (`systemd/monitoralign.service`).

## License

MIT
