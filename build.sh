#!/usr/bin/env bash
set -euo pipefail

# ---- versions pinned by upstream build script ----
VM_REF="0.2.0-prerelease.20220222132735"
GUI_REF="scratch-desktop-v3.29.0"
DESKTOP_REF="v3.29.1"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: '$1' が見つかりません。先にインストールしてください。" >&2
    echo "  - node/npm を入れる (例: Node.js をインストール)" >&2
    echo "  - git を入れる" >&2
    exit 1
  }
}

# idempotent: 無ければ clone / あれば指定 ref に強制的に揃える
clone_or_update() {
  local dir="$1"
  local url="$2"
  local ref="$3"

  if [[ -d "$dir/.git" ]]; then
    echo "[update] $dir -> $ref"
    (
      cd "$dir"
      git fetch --all --prune
      # ref がブランチ/タグ両方あり得るので checkout を柔軟に
      git checkout -q "$ref" 2>/dev/null || git checkout -q -B "$ref" "origin/$ref"
      # 可能なら origin/ref に同期（タグの場合は origin/ が無いので ref に同期）
      git reset --hard "origin/$ref" 2>/dev/null || git reset --hard "$ref"
    )
  elif [[ -e "$dir" ]]; then
    echo "ERROR: '$dir' は存在しますが git リポジトリではありません（.git がありません）。" >&2
    echo "削除するか、空ディレクトリにしてから再実行してください。" >&2
    exit 1
  else
    echo "[clone] $dir <- $url ($ref)"
    git clone --filter=blob:none "$url" -b "$ref" "$dir"
  fi
}

npm_install() {
  local dir="$1"
  echo "[npm install] $dir"
  (cd "$dir" && npm install --legacy-peer-deps)
}

# ---- run from script directory (実行場所ブレ対策) ----
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---- prereq check (npm が無いときに途中で死なないよう最初に検知) ----
require_cmd git
require_cmd node
require_cmd npm

# ---- clone/update repositories ----
clone_or_update "scratch-vm"      "https://github.com/scratchfoundation/scratch-vm.git"      "$VM_REF"
clone_or_update "scratch-gui"     "https://github.com/scratchfoundation/scratch-gui.git"     "$GUI_REF"
clone_or_update "scratch-desktop" "https://github.com/scratchfoundation/scratch-desktop.git" "$DESKTOP_REF"

# ---- install + link ----
npm_install "scratch-vm"
(cd scratch-vm && npm link)

npm_install "scratch-gui"
(cd scratch-gui && npm link scratch-vm --legacy-peer-deps)
(cd scratch-gui && npm link)

npm_install "scratch-desktop"

# ---- force scratch-desktop to use local scratch-gui ----
mkdir -p scratch-desktop/node_modules
(
  cd scratch-desktop/node_modules
  rm -rf scratch-gui
  ln -s ../../scratch-gui scratch-gui
)

# ---- apply scratch3-tello patch into scratch-desktop (明示的にコピー先指定) ----
rm -rf scratch3-tello
git clone --depth 1 https://github.com/kebhr/scratch3-tello
cp -r scratch3-tello/. scratch-desktop/
rm -rf scratch3-tello

echo "Done. Next:"
echo "  cd scratch-desktop && npm start"
