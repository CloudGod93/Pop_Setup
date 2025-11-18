#!/usr/bin/env bash
set -euo pipefail

RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V1_DIR="${V1_DIR:-$RIBBING_APP_PARENT/app/v1}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"
CC_PARENT="${CC_PARENT:-$HOME/Documents/Projects/CattleClassificationApp}"
CC_DIR="${CC_DIR:-$CC_PARENT/app}"

mkdir -p "$(dirname "$V1_DIR")"
mkdir -p "$CC_PARENT"
mkdir -p "$RIBBING_APP_PARENT"
mkdir -p "$CC_DIR"
mkdir -p "$V2_DIR"

echo "Project directories prepared"
