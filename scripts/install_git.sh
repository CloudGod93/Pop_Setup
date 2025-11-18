#!/usr/bin/env bash
set -euo pipefail

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
GITHUB_USER="${GITHUB_USER:-}"
GITHUB_PAT="${GITHUB_PAT:-}"

if [[ -n "$GIT_USER_NAME" ]]; then
  git config --global user.name "$GIT_USER_NAME"
  echo "Set git user.name to $GIT_USER_NAME"
fi

if [[ -n "$GIT_USER_EMAIL" ]]; then
  git config --global user.email "$GIT_USER_EMAIL"
  echo "Set git user.email to $GIT_USER_EMAIL"
fi

git config --global pull.rebase false
git config --global init.defaultBranch main
git config --global credential.helper store

if [[ -n "$GITHUB_USER" && -n "$GITHUB_PAT" ]]; then
  CRED_FILE="$HOME/.git-credentials"
  printf "https://%s:%s@github.com\n" "$GITHUB_USER" "$GITHUB_PAT" > "$CRED_FILE"
  chmod 600 "$CRED_FILE"
  printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n' \
    "$GITHUB_USER" "$GITHUB_PAT" | git credential approve
  echo "Stored GitHub credentials in $CRED_FILE"
else
  echo "GITHUB_USER or GITHUB_PAT not set; skipping credential store pre-population"
fi
