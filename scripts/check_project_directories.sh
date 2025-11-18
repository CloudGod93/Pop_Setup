#!/usr/bin/env bash
set -euo pipefail

RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V1_DIR="${V1_DIR:-$RIBBING_APP_PARENT/app/v1}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"
CC_PARENT="${CC_PARENT:-$HOME/Documents/Projects/CattleClassificationApp}"
CC_DIR="${CC_DIR:-$CC_PARENT/app}"

missing=0
for path in "$RIBBING_APP_PARENT" "$V1_DIR" "$V2_DIR" "$CC_PARENT" "$CC_DIR"; do
  if [[ ! -d "$path" ]]; then
    echo "Missing directory: $path"
    missing=1
  fi
done

if [[ $missing -eq 0 ]]; then
  echo "All project directories exist"
  exit 0
fi

exit 1
