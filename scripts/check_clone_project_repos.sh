#!/usr/bin/env bash
set -euo pipefail

RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V1_DIR="${V1_DIR:-$RIBBING_APP_PARENT/app/v1}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"
CC_PARENT="${CC_PARENT:-$HOME/Documents/Projects/CattleClassificationApp}"
CC_DIR="${CC_DIR:-$CC_PARENT/app}"

missing=0
for dir in "$V2_DIR" "$V1_DIR" "$CC_DIR"; do
  if [[ ! -d "$dir/.git" ]]; then
    echo "Repository missing or not a git repo: $dir"
    missing=1
  fi
done

if [[ $missing -eq 0 ]]; then
  echo "All repositories cloned"
  exit 0
fi

exit 1
