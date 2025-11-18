#!/usr/bin/env bash
set -euo pipefail

ZELLIJ_VERSION="${ZELLIJ_VERSION:-0.43.1}"
DOWNLOAD_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
ARCHIVE="/tmp/zellij-${ZELLIJ_VERSION}.tar.gz"

if command -v zellij >/dev/null 2>&1; then
  echo "Zellij already installed"
  exit 0
fi

wget -O "$ARCHIVE" "$DOWNLOAD_URL"
tar -xzf "$ARCHIVE" -C /tmp
sudo mv /tmp/zellij /usr/local/bin/zellij
rm -f "$ARCHIVE"
