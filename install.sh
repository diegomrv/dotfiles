#!/bin/bash
set -euo pipefail

# =============================================================================
# Preflight check
# =============================================================================
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew not found. Run ./setup.sh first."
  exit 1
fi

# =============================================================================
# Brew packages (via per-machine Brewfile.<hostname>)
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_NAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
BREWFILE="$SCRIPT_DIR/Brewfile.$HOST_NAME"

echo ""
if [ -f "$BREWFILE" ]; then
  echo "=== Installing Homebrew packages from Brewfile.$HOST_NAME ==="
  brew bundle --file="$BREWFILE"
else
  echo "=== No Brewfile.$HOST_NAME found, skipping Homebrew packages ==="
  echo "    Available: $(ls "$SCRIPT_DIR"/Brewfile.* 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
fi

# =============================================================================
# Stow dotfiles
# =============================================================================
echo ""
echo "=== Applying dotfiles with Stow ==="

if command -v stow &>/dev/null; then
  stow --adopt -t "$HOME" .
  stow --adopt -t "$HOME" claude-global
  echo "Symlinks created"
else
  echo "Warning: stow not found, skipping dotfiles linking"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=== Installation complete ==="
echo "Restart your terminal or run: source ~/.zshrc"
