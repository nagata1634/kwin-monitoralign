# Monitor Align

[English](README.md) | 日本語

[KDE Store](https://store.kde.org/p/2374311/) · [GitHub](https://github.com/nagata1634/kwin-monitoralign)

KDE Plasma (Wayland) で、横に並べたモニタの**上下のズレ**を System Settings から調整し、
モニタの境界をまたぐときに**カーソルが飛ばない**ようにする KWin スクリプト + 常駐ヘルパーです。

台座やアームの高さが違うと、モニタの上端は物理的に数百 px ずれます。KDE の「ディスプレイの設定」で
ドラッグして合わせるのは目分量になりがちで、少しずつ動かして目で確認するのに向いていません。
Monitor Align は「Primary を基準に、他のモニタを何 px 下げるか」だけをスライダー・±1/±10 ボタン・
数値欄で決められるようにします。

```
1. DP-5　横置き 2560×1440　—　基準（Primary） 0 px

              2. DP-6　縦置き 1440×2560
      [──────────────●──────────────────────]
   [−10] [−1] [ DP-5 より -745 px 下へ ▲▼ ] [+1] [+10]
```

## 特長

- **System Settings に組み込み**: ウィンドウの管理 › KWin スクリプト › Monitor Align の歯車から開く
- **接続中のモニタだけ**を接続名（`DP-5` など）で表示。抜き差しにも追従（10 秒以内に再生成）
- **横方向は自動**: 左から「内蔵パネル → 外部（接続名順）」に隙間なく並べるので、間隔が空いて
  カーソルが渡れなくなる事故が起きない
- **縦の重なりを保証**: 隣同士の縦範囲が必ず重なるようクランプ（カーソルが隔離されない）
- **安全**: 全モニタを `kscreen-doctor` に 1 コマンドで適用し、読み戻して照合。不一致なら直前の配置へ自動復帰
- **日本語 / 英語**: 設定ページとログはロケール（`LANG` が `ja*` なら日本語）で切り替わる
- Wayland ネイティブ。X11 / xrandr は使いません

## 仕組み

KWin スクリプトには出力を動かす API が無く、汎用 KCM（設定ダイアログ）はロジックを持てません。
そこで KWin スクリプト側は **設定ページの器だけ**（`code/main.js` は空）にし、値は
`~/.config/kwinrc` の `[Script-monitoralign]` に書かれます。常駐の `monitoralign-daemon`
（PySide6、`QFileSystemWatcher`）がそれを監視して配置を計算し、`kscreen-doctor` に渡します。

設定ページ（`contents/ui/config.ui` / `contents/config/main.xml`）は静的ファイルしか置けないため、
デーモンが**接続中のモニタから生成**します。

座標は `kscreen-doctor -j` の論理座標（`pos`、`round(size/scale)`）だけを使います。

## 必要なもの

- KDE Plasma 6（Wayland）
- `kscreen-doctor`, `kreadconfig6`, `kwriteconfig6`, `kpackagetool6`（Plasma に同梱）
- Python 3 + PySide6（Fedora: `python3-pyside6`）

## インストール

### KDE Store から（System Settings）

System Settings › ウィンドウの管理 › KWin スクリプト › **新しいウィンドウマネージャスクリプトをダウンロード** → 「Monitor Align」を検索 → インストール。
パッケージにはヘルパーデーモンも同梱しているので、端末で 1 回だけ有効化します:

```sh
~/.local/share/kwin/scripts/monitoralign/contents/install-daemon.sh
```

（歯車のページにも、デーモンが動くまで同じコマンドが表示されます。）

### Git から

```sh
git clone https://github.com/nagata1634/kwin-monitoralign.git
cd kwin-monitoralign
./install.sh          # KWin スクリプト + デーモン + systemd --user unit を導入して起動
```

開発中はコピーではなく symlink で: `./install.sh --link`　　アンインストール: `./install.sh --uninstall`

## 使い方

1. System Settings › ウィンドウの管理 › KWin スクリプト › **Monitor Align** の歯車
2. Primary 以外のモニタの行で、スライダーか `[−10] [−1] [+1] [+10]` か数値欄で値を決めて **[適用]**
3. 境界をまたいでカーソルを横に動かし、飛ばなくなる値を探す
   - 隣へ移ったときカーソルが実際より**上**に出る → 出発側を**下へ**（値を増やす）
   - **下**に出る → **上へ**

コマンドライン:

```sh
monitoralign-daemon --status   # 接続名 ↔ 現在の配置 ↔ 設定値
monitoralign-daemon --once     # 設定ページ生成と適用を 1 回だけ
journalctl --user -u monitoralign -f
```

## 制限

- 横一列のレイアウトのみ（縦積みは未対応）
- 設定値は接続名ではなく「論理サイズ＋同サイズ内の順番」（例 `y_1108x1969_1`）に紐づけます。
  DisplayPort MST で接続名が `DP-5/6` ↔ `DP-7/8` と揺れても値は引き継がれます。
  同じサイズ・同じ向きのモニタを複数繋いだ場合は名前順で番号を振るため、揺れ方によっては入れ替わります
- 値の反映は [適用] を押したとき（汎用 KCM の制約で、値変更で即適用にはできません）

## 既知の注意点

KWin 起動直後に出力配置を変えると KWin がクラッシュする事例があったため、デーモンは
`plasmashell` 起動後 15 秒待ってから動きます（`systemd/monitoralign.service`）。

## ライセンス

MIT
