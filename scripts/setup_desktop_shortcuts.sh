#!/usr/bin/env bash
set -euo pipefail

USB_DRIVE_PATH="${USB_DRIVE_PATH:-/media/Samsung_USB}"
RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"

DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

SYNC_SHORTCUT_SRC="$USB_DRIVE_PATH/Scripts/backup_sync/Sync Storage (Verbose + List).desktop"
RIBBING_APP_LAUNCHER_SH="$V2_DIR/RibbingApp.sh"
RIBBING_APP_SHORTCUT_SRC="$V2_DIR/RibbingApp.desktop"
USB_RIBBING_APP_SHORTCUT_SRC="$USB_DRIVE_PATH/Projects/RibbingApp/scripts/Launcher/RibbingApp.desktop"
RIBBING_APP_SHORTCUT_DEST="$DESKTOP_DIR/RibbingApp.desktop"

copy_desktop_file() {
  local src="$1" dest="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
    chmod +x "$dest"
    if command -v gio >/dev/null 2>&1; then
      gio set "$dest" metadata::trusted true || true
    fi
    echo "Copied $(basename "$dest") to Desktop"
    return 0
  fi
  return 1
}

if [[ -f "$SYNC_SHORTCUT_SRC" ]]; then
  cp "$SYNC_SHORTCUT_SRC" "$DESKTOP_DIR/"
  chmod +x "$DESKTOP_DIR/$(basename "$SYNC_SHORTCUT_SRC")"
  if command -v gio >/dev/null 2>&1; then
    gio set "$DESKTOP_DIR/$(basename "$SYNC_SHORTCUT_SRC")" metadata::trusted true || true
  fi
  echo "Sync shortcut deployed"
else
  echo "Sync shortcut source not found: $SYNC_SHORTCUT_SRC"
fi

if [[ -f "$RIBBING_APP_LAUNCHER_SH" ]]; then
  chmod +x "$RIBBING_APP_LAUNCHER_SH"
fi

if ! copy_desktop_file "$USB_RIBBING_APP_SHORTCUT_SRC" "$RIBBING_APP_SHORTCUT_DEST"; then
  copy_desktop_file "$RIBBING_APP_SHORTCUT_SRC" "$RIBBING_APP_SHORTCUT_DEST" || echo "RibbingApp shortcut source missing"
fi
