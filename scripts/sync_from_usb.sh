#!/usr/bin/env bash
set -euo pipefail

USB_DRIVE_PATH="${USB_DRIVE_PATH:-/media/Samsung_USB}"
RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
CC_PARENT="${CC_PARENT:-$HOME/Documents/Projects/CattleClassificationApp}"

if [[ ! -d "$USB_DRIVE_PATH" ]]; then
  echo "USB drive not found at $USB_DRIVE_PATH"
  exit 0
fi

USB_PROJECTS_SRC="$USB_DRIVE_PATH/Projects"
mkdir -p "$RIBBING_APP_PARENT" "$CC_PARENT"

sync_directory() {
  local src="$1" dest="$2"
  if [[ -d "$src" ]]; then
    echo "Syncing $src -> $dest"
    mkdir -p "$dest"
    rsync -a --info=progress2 "$src/" "$dest/"
  else
    echo "Source missing, skipping: $src"
  fi
}

sync_file() {
  local src="$1" dest_dir="$2"
  if [[ -f "$src" ]]; then
    echo "Syncing file $src"
    mkdir -p "$dest_dir"
    rsync -a "$src" "$dest_dir/"
  else
    echo "File missing, skipping: $src"
  fi
}

sync_directory "$USB_PROJECTS_SRC/RibbingApp/data" "$RIBBING_APP_PARENT/data"
sync_directory "$USB_PROJECTS_SRC/RibbingApp/model" "$RIBBING_APP_PARENT/model"
sync_file "$USB_PROJECTS_SRC/RibbingApp/Screencast from 2025-08-28 11-12-24.webm" "$RIBBING_APP_PARENT"

sync_directory "$USB_PROJECTS_SRC/CattleClassifier/assets" "$CC_PARENT/assets"
sync_directory "$USB_PROJECTS_SRC/CattleClassifier/data" "$CC_PARENT/data"
sync_directory "$USB_PROJECTS_SRC/CattleClassifier/Model" "$CC_PARENT/Model"

DOCUMENTS_DEST="$HOME/Documents"
DIRECTORIES_TO_SYNC=(
  applications
  Machine_Manuals
  Scripts
  Tingley
  _Logos
  Mission_MidWestBeef
  Robotics
  spiranetlite
)
for dir in "${DIRECTORIES_TO_SYNC[@]}"; do
  sync_directory "$USB_DRIVE_PATH/$dir" "$DOCUMENTS_DEST/$dir"
done
