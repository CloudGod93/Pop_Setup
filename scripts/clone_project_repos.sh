#!/usr/bin/env bash
set -euo pipefail

RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V1_DIR="${V1_DIR:-$RIBBING_APP_PARENT/app/v1}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"
CC_PARENT="${CC_PARENT:-$HOME/Documents/Projects/CattleClassificationApp}"
CC_DIR="${CC_DIR:-$CC_PARENT/app}"
REPO_URL_V1="${REPO_URL_V1:-https://github.com/CloudGod93/Mw_RibbingCut.git}"
REPO_URL_V2="${REPO_URL_V2:-https://github.com/CloudGod93/RibbingApp.git}"
REPO_URL_CC="${REPO_URL_CC:-https://github.com/CloudGod93/Mw_CattleClassification.git}"

clone_repo() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    echo "Repo already present: $dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  git clone "$url" "$dest"
}

clone_repo "$REPO_URL_V2" "$V2_DIR"
clone_repo "$REPO_URL_V1" "$V1_DIR"
clone_repo "$REPO_URL_CC" "$CC_DIR"
