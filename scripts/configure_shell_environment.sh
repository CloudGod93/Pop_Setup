#!/usr/bin/env bash
set -euo pipefail

BASHRC_FILE="$HOME/.bashrc"
ZSHRC_FILE="$HOME/.zshrc"

read -r -d '' NVM_BLOCK <<'BLOCK'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \ . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \ . "$NVM_DIR/bash_completion"
BLOCK

read -r -d '' CUDA_BLOCK <<'BLOCK'
export PATH=/usr/local/cuda-11.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
BLOCK

ensure_block() {
  local file="$1" start_tag="$2" end_tag="$3" contents="$4"
  [[ -f "$file" ]] || { echo "Skipping $file (not found)"; return; }
  local tmp
  tmp="${file}.tmp"
  if grep -qF "$start_tag" "$file"; then
    awk -v start="$start_tag" -v end="$end_tag" '
      BEGIN {p=1}
      $0 == start {p=0}
      p {print}
      $0 == end {p=1}
    ' "$file" > "$tmp" && mv "$tmp" "$file"
  fi
  {
    echo "$start_tag"
    echo "$contents"
    echo "$end_tag"
  } >> "$file"
}

ensure_block "$BASHRC_FILE" "# Added by Pop Setup: CUDA Start" "# Added by Pop Setup: CUDA End" "$CUDA_BLOCK"
ensure_block "$BASHRC_FILE" "# Added by Pop Setup: NVM Start" "# Added by Pop Setup: NVM End" "$NVM_BLOCK"

if [[ -f "$ZSHRC_FILE" ]]; then
  ensure_block "$ZSHRC_FILE" "# Added by Pop Setup: CUDA Start" "# Added by Pop Setup: CUDA End" "$CUDA_BLOCK"
  ensure_block "$ZSHRC_FILE" "# Added by Pop Setup: NVM Start" "# Added by Pop Setup: NVM End" "$NVM_BLOCK"
fi

ALACRITTY_DIR="$HOME/.config/alacritty"
ALACRITTY_CFG="$ALACRITTY_DIR/alacritty.yml"
mkdir -p "$ALACRITTY_DIR"
if [[ -f "$ALACRITTY_CFG" && ! -f "$ALACRITTY_CFG.bak" ]]; then
  cp "$ALACRITTY_CFG" "$ALACRITTY_CFG.bak"
fi
cat <<'ALACRITTY' > "$ALACRITTY_CFG"
shell:
  program: /bin/bash
  args:
    - -c
    - "zellij || exec bash"
ALACRITTY
