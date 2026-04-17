#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -d scratch-vm || ! -d scratch-gui || ! -d scratch-desktop ]]; then
  echo "ERROR: scratch-vm, scratch-gui, scratch-desktop directories are required." >&2
  exit 1
fi

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    rm -rf "$dst"
    mkdir -p "$(dirname -- "$dst")"
    cp -r "$src" "$dst"
  else
    echo "ERROR: expected patch source not found: $src" >&2
    exit 1
  fi
}

PATCH_DIR="$(mktemp -d)"
trap 'rm -rf "$PATCH_DIR"' EXIT

echo "[patch] fetch scratch3-tello"
git clone --depth 1 https://github.com/kebhr/scratch3-tello "$PATCH_DIR/scratch3-tello"

echo "[patch] apply tello to scratch-vm"
copy_if_exists \
  "$PATCH_DIR/scratch3-tello/scratch-vm/src/extensions/scratch3_tello" \
  "scratch-vm/src/extensions/scratch3_tello"
copy_if_exists \
  "$PATCH_DIR/scratch3-tello/scratch-vm/src/extension-support/extension-manager.js" \
  "scratch-vm/src/extension-support/extension-manager.js"

echo "[patch] apply tello to scratch-gui"
copy_if_exists \
  "$PATCH_DIR/scratch3-tello/scratch-gui/src/lib/libraries/extensions/tello" \
  "scratch-gui/src/lib/libraries/extensions/tello"
copy_if_exists \
  "$PATCH_DIR/scratch3-tello/scratch-gui/src/lib/libraries/extensions/index.jsx" \
  "scratch-gui/src/lib/libraries/extensions/index.jsx"

echo "[link] scratch-vm"
(cd scratch-vm && npm link)

echo "[link] scratch-gui -> scratch-vm"
(cd scratch-gui && npm link scratch-vm --legacy-peer-deps)
(cd scratch-gui && npm link)

echo "[symlink] scratch-desktop/node_modules/{scratch-gui,scratch-vm}"
mkdir -p scratch-desktop/node_modules
(
  cd scratch-desktop/node_modules
  rm -rf scratch-gui scratch-vm
  ln -s ../../scratch-gui scratch-gui
  ln -s ../../scratch-vm scratch-vm
)

echo "Done. Next: cd scratch-desktop && npm start"
