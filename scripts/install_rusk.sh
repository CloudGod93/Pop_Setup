#!/usr/bin/env bash
set -euo pipefail

REPO="rustdesk/rustdesk"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

wait_for_apt_lock() {
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for apt lock to clear..."
    sleep 5
  done
}

apt_exec() {
  wait_for_apt_lock
  sudo DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

if [[ "$(id -u)" -eq 0 ]]; then
  echo "[!] Do not run this as root. Use your normal user."
  exit 1
fi

ARCH="$(dpkg --print-architecture || echo amd64)"
echo "[*] Rusk installer for Pop!_OS"
echo "[*] Detected architecture: ${ARCH}"

case "${ARCH}" in
  amd64)
    ASSET_REGEX="x86_64\\.deb$"
    ;;
  arm64)
    ASSET_REGEX="aarch64\\.deb$"
    ;;
  armhf)
    ASSET_REGEX="armv7.*\\.deb$"
    ;;
  *)
    echo "[!] Unsupported or unknown architecture: ${ARCH}"
    echo "[i] You may need to install Rusk manually for this arch."
    exit 1
    ;;
esac

echo "[*] Installing dependencies (curl, jq)..."
apt_exec update
apt_exec install -y curl jq

if command -v rustdesk >/dev/null 2>&1; then
  echo "[*] Rusk (rustdesk) already installed at: $(command -v rustdesk)"
else
  echo "[*] Fetching latest Rusk release info from GitHub..."

  DEB_URL="$(
    curl -sL "${API_URL}" \
    | jq -r --arg re "${ASSET_REGEX}" '
        .assets[]
        | select(.name | test($re))
        | .browser_download_url
      ' \
    | head -n 1
  )"

  if [[ -z "${DEB_URL}" || "${DEB_URL}" == "null" ]]; then
    echo "[!] Could not find a .deb matching regex: ${ASSET_REGEX}"
    echo "[i] Available assets:"
    curl -sL "${API_URL}" | jq -r '.assets[].name'
    exit 1
  fi

  echo "[*] Found .deb: ${DEB_URL}"
  TMP_DEB="/tmp/$(basename "${DEB_URL}")"

  echo "[*] Downloading to ${TMP_DEB}..."
  curl -L "${DEB_URL}" -o "${TMP_DEB}"

  echo "[*] Installing Rusk via apt..."
  apt_exec install -y "${TMP_DEB}"

  echo "[*] Cleaning up downloaded package..."
  rm -f "${TMP_DEB}"
fi

DESKTOP_DIR="${HOME}/.local/share/applications"
mkdir -p "${DESKTOP_DIR}"

DESKTOP_FILE="${DESKTOP_DIR}/rusk.desktop"
ICON_CANDIDATES=(
  "/usr/share/icons/hicolor/256x256/apps/rustdesk.png"
  "/usr/share/pixmaps/rustdesk.png"
)

ICON_PATH="rustdesk"
for CAND in "${ICON_CANDIDATES[@]}"; do
  if [[ -f "${CAND}" ]]; then
    ICON_PATH="${CAND}"
    break
  fi
done

cat > "${DESKTOP_FILE}" <<EOF_DESKTOP
[Desktop Entry]
Type=Application
Name=Rusk (RustDesk)
Comment=Remote desktop client
Exec=rustdesk
Icon=${ICON_PATH}
Terminal=false
Categories=Network;RemoteAccess;
StartupNotify=true
EOF_DESKTOP

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${DESKTOP_DIR}" || true
fi

if [[ -d "${HOME}/Desktop" ]]; then
  DESKTOP_SHORTCUT="${HOME}/Desktop/Rusk.desktop"
  cp "${DESKTOP_FILE}" "${DESKTOP_SHORTCUT}"
  chmod +x "${DESKTOP_SHORTCUT}"
fi

echo "[*] Done. Rusk should be in your app launcher and on the Desktop (if present)."
