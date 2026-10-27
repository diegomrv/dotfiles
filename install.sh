#!/bin/bash
set -euo pipefail

# =============================================================================
# Brew packages (via per-machine Brewfile.<hostname>)
#
# A missing Homebrew is not fatal: symlinking the dotfiles is the important part
# and must still happen on a machine that manages packages some other way.
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_NAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
BREWFILE="$SCRIPT_DIR/Brewfile.$HOST_NAME"

# Fresh Linux box: brew is installed but not on PATH until the stowed .zshrc loads
if ! command -v brew &>/dev/null && [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo ""
if ! command -v brew &>/dev/null; then
  echo "=== Homebrew not found, skipping packages (run ./setup.sh to install it) ==="
elif [ -f "$BREWFILE" ]; then
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

# No --adopt: it moves existing files (e.g. the stub ~/.zshrc a pnpm installer
# writes) INTO the repo, over the tracked ones. Instead, move anything in the
# way to a timestamped backup, then stow normally.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

stow_with_backup() {
  local pkg="$1" target
  # Dry run lists each conflict as "... over existing target <path> since ..."
  # (path relative to $HOME). Other conflict kinds aren't parsed here; the real
  # stow below then fails loudly instead.
  { stow -n -t "$HOME" "$pkg" 2>&1 || true; } |
    sed -n 's/.* over existing target \(.*\) since neither a link nor a directory.*/\1/p' |
    while IFS= read -r target; do
      mkdir -p "$BACKUP_DIR/$(dirname "$target")"
      mv "$HOME/$target" "$BACKUP_DIR/$target"
      echo "  Backed up ~/$target -> $BACKUP_DIR/$target"
    done
  stow -t "$HOME" "$pkg"
}

if command -v stow &>/dev/null; then
  cd "$SCRIPT_DIR"
  stow_with_backup .
  stow_with_backup claude-global
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
