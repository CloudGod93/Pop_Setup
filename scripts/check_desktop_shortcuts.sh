#!/usr/bin/env bash
set -euo pipefail

DESKTOP_DIR="$HOME/Desktop"
FILES=(
  "RibbingApp.desktop"
)

missing=0
for file in "${FILES[@]}"; do
  if [[ ! -f "$DESKTOP_DIR/$file" ]]; then
    echo "Missing desktop shortcut: $file"
    missing=1
  fi
done

if [[ $missing -eq 0 ]]; then
  echo "Desktop shortcuts ready"
  exit 0
fi

exit 1
