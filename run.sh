#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/scratch-desktop"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "ERROR: nvm.sh not found at $NVM_DIR/nvm.sh" >&2
  echo "Please install nvm or set NVM_DIR to the correct path." >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"

nvm use 16 >/dev/null
NODE_ENV=production npm start