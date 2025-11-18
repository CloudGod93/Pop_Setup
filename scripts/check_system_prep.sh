#!/usr/bin/env bash
set -euo pipefail

missing=0
for cmd in git flatpak alacritty; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd not found"
    missing=1
  fi
done

if [[ $missing -eq 0 ]]; then
  echo "Base packages detected"
  exit 0
fi

exit 1
