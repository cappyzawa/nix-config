#!/usr/bin/env bash
# Prepares the per-host key that nix/home/default.nix (githubSshKey) uses for
# GitHub SSH auth and commit signing. Idempotent; run via `make github-key`.
set -euo pipefail

host=${1:?usage: setup-github-key.sh <host> <key-path>}
key=${2:?usage: setup-github-key.sh <host> <key-path>}
repo_root=$(cd "$(dirname "$0")/.." && pwd)
allowed_signers=$repo_root/config/git/allowed_signers
local_gitconfig=$HOME/.gitconfig.local

if [[ ! -f $key ]]; then
  mkdir -p "$(dirname "$key")"
  chmod 700 "$(dirname "$key")"
  ssh-keygen -q -t ed25519 -N "" -C "git@$host" -f "$key"
  echo "Generated $key"
fi
pubkey=$(cut -d' ' -f1,2 "$key.pub")

if ! grep -qF "$pubkey" "$allowed_signers"; then
  printf '* namespaces="git" %s %s\n' "$pubkey" "$host" >>"$allowed_signers"
  echo "Added the public key to config/git/allowed_signers; commit it."
fi

# ~/.gitconfig.local is included after the Nix-managed signing settings, so
# leftovers from the 1Password setup would override them.
if [[ -f $local_gitconfig ]]; then
  for name in user.signingkey gpg.format gpg.ssh.program commit.gpgsign; do
    if git config --file "$local_gitconfig" --get-all "$name" >/dev/null; then
      git config --file "$local_gitconfig" --unset-all "$name"
      echo "Removed $name from $local_gitconfig"
    fi
  done
fi

if ! command -v gh >/dev/null; then
  echo "gh is not installed yet. Register $key.pub on GitHub as both an"
  echo "Authentication key and a Signing key, or rerun this after bootstrap."
  exit 0
fi

# admin:public_key lets anyone holding the gh token add SSH auth keys, so the
# scopes live only as long as this script needs them.
key_scopes=admin:public_key,admin:ssh_signing_key
if ! gh api user/keys >/dev/null 2>&1 || ! gh api user/ssh_signing_keys >/dev/null 2>&1; then
  gh auth refresh -h github.com -s "$key_scopes"
  trap 'gh auth refresh -h github.com --remove-scopes "$key_scopes"' EXIT
fi

register() {
  local type=$1 endpoint=$2
  if gh api --paginate "$endpoint" --jq '.[].key' | grep -qF "$pubkey"; then
    echo "Already registered on GitHub as $type key"
  else
    gh ssh-key add "$key.pub" --type "$type" --title "$host"
  fi
}
register authentication user/keys
register signing user/ssh_signing_keys
