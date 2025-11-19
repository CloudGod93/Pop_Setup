#!/usr/bin/env bash
set -euo pipefail

USB_DRIVE_PATH="${USB_DRIVE_PATH:-/media/Samsung_USB}"
RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"

APPLICATIONS_DIR="$HOME/.local/share/applications"
mkdir -p "$APPLICATIONS_DIR"

SYNC_SHORTCUT_SRC="$USB_DRIVE_PATH/Scripts/backup_sync/Sync Storage (Verbose + List).desktop"
RIBBING_APP_LAUNCHER_SH="$V2_DIR/RibbingApp.sh"
RIBBING_APP_SHORTCUT_SRC="$V2_DIR/RibbingApp.desktop"
USB_RIBBING_APP_SHORTCUT_SRC="$USB_DRIVE_PATH/Projects/RibbingApp/scripts/Launcher/RibbingApp.desktop"
RIBBING_APP_SHORTCUT_DEST="$APPLICATIONS_DIR/RibbingApp.desktop"

installed_any=0

install_desktop_file() {
  local src="$1" dest="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
    chmod +x "$dest"
    installed_any=1
    echo "Installed $(basename "$dest") to ${APPLICATIONS_DIR}"
    return 0
  fi
  return 1
}

SYNC_SHORTCUT_DEST="$APPLICATIONS_DIR/$(basename "$SYNC_SHORTCUT_SRC")"
if ! install_desktop_file "$SYNC_SHORTCUT_SRC" "$SYNC_SHORTCUT_DEST"; then
  echo "Sync shortcut source not found: $SYNC_SHORTCUT_SRC"
fi

if [[ -f "$RIBBING_APP_LAUNCHER_SH" ]]; then
  chmod +x "$RIBBING_APP_LAUNCHER_SH"
fi

if ! install_desktop_file "$USB_RIBBING_APP_SHORTCUT_SRC" "$RIBBING_APP_SHORTCUT_DEST"; then
  install_desktop_file "$RIBBING_APP_SHORTCUT_SRC" "$RIBBING_APP_SHORTCUT_DEST" || echo "RibbingApp shortcut source missing"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR"
elif [[ $installed_any -eq 1 ]]; then
  echo "update-desktop-database command not found; desktop database not refreshed"
fi
