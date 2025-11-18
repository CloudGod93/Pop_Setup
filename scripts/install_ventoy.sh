#!/usr/bin/env bash
set -euo pipefail

VENTOY_VERSION="${VENTOY_VERSION:-1.0.99}"
DOWNLOAD_URL="https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VERSION}/ventoy-${VENTOY_VERSION}-linux.tar.gz"
ARCHIVE="/tmp/ventoy-${VENTOY_VERSION}.tar.gz"
EXTRACT_DIR="/tmp/ventoy-${VENTOY_VERSION}"

if command -v ventoy >/dev/null 2>&1; then
  echo "Ventoy already installed"
  exit 0
fi

rm -rf "$EXTRACT_DIR"
wget -O "$ARCHIVE" "$DOWNLOAD_URL"
tar -xzf "$ARCHIVE" -C /tmp
sudo cp "$EXTRACT_DIR/Ventoy2Disk.sh" /usr/local/bin/ventoy
sudo chmod +x /usr/local/bin/ventoy
rm -rf "$EXTRACT_DIR" "$ARCHIVE"
