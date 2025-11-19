#!/usr/bin/env bash
set -euo pipefail

BASHRC_FILE="$HOME/.bashrc"
ALACRITTY_CFG="$HOME/.config/alacritty/alacritty.yml"

if [[ ! -f "$BASHRC_FILE" ]]; then
  echo "$BASHRC_FILE missing"
  exit 1
fi

if ! grep -qE '# Added by Pop(!?_OS)? setup script: NVM (Environment )?Start' "$BASHRC_FILE"; then
  echo "NVM block not found in $BASHRC_FILE"
  exit 1
fi

if [[ ! -f "$ALACRITTY_CFG" ]] || ! grep -q "zellij" "$ALACRITTY_CFG"; then
  echo "Alacritty config missing zellij launcher"
  exit 1
fi

echo "Shell configuration blocks detected"
exit 0
