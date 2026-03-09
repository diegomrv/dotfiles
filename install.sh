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
# Brew packages (via Brewfile)
# =============================================================================
echo ""
echo "=== Installing Homebrew packages from Brewfile ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
brew bundle --file="$SCRIPT_DIR/Brewfile"

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
