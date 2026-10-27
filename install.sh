#!/bin/bash
# Set up this machine from machines/<hostname>/:
#   packages   which stow packages to link (shell, claude, dev, desktop, macos)
#   Brewfile   Homebrew packages; machines without one skip Homebrew
#   host.zsh   machine-only shell config, sourced by .zshrc straight from the repo
#
#   ./install.sh            install tools, then link
#   ./install.sh --links    link only. Run it after pulling a change that moves or
#                           drops files, or after editing machines/<host>/packages
#   ./install.sh --unlink   remove every link into this repo, then stop
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOST_NAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
MACHINE="$DOTFILES/machines/$HOST_NAME"
MODE="${1:-all}"

have() { command -v "$1" >/dev/null 2>&1; }

# Homebrew on PATH even from a bare shell (fresh machine, ssh host command)
brew_shellenv() {
  local b
  for b in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x $b ]] && { eval "$("$b" shellenv)"; return; }
  done
}
brew_shellenv

# =============================================================================
# Links
# =============================================================================

# Absolute target of a symlink, worked out on paper: stow writes relative links,
# and readlink -f can't resolve one whose target is already gone.
link_target() {
  local t part
  local -a out=()
  t="$(readlink "$1")"
  [[ $t == /* ]] || t="$(dirname "$1")/$t"
  local IFS=/
  for part in $t; do
    case "$part" in
      '' | .) ;;
      ..) [[ ${#out[@]} -gt 0 ]] && unset "out[$((${#out[@]} - 1))]" ;;
      *) out+=("$part") ;;
    esac
  done
  echo "/${out[*]}"
}

# Every symlink in $HOME that points into this repo. Only the names the packages
# use are searched (~/.config, ~/.claude, ~/.zshrc, ...), 4 levels deep.
repo_links() {
  local pkg entry name seen=" "
  for pkg in "$DOTFILES"/*/; do
    [[ $(basename "$pkg") == machines ]] && continue
    for entry in "$pkg".[!.]* "$pkg"[!.]*; do
      [[ -e $entry || -L $entry ]] || continue
      name="$(basename "$entry")"
      [[ $seen == *" $name "* ]] && continue
      seen="$seen$name "
      find "$HOME/$name" -maxdepth 4 -type l 2>/dev/null || true
    done
  done | while IFS= read -r link; do
    [[ $(link_target "$link") == "$DOTFILES"/* ]] && echo "$link"
  done
}

# Stow never removes links on its own, so a file that moved or left a package
# would stay linked (or dangle) forever. Clearing them all first fixes that.
unlink_all() {
  local link n=0
  while IFS= read -r link; do
    rm "$link"
    n=$((n + 1))
  done < <(repo_links)
  echo "Removed $n old links"
}

link_packages() {
  # Real directories, so stow links what's inside instead of folding the whole
  # directory into the repo (apps would then write their state into the repo)
  mkdir -p "$HOME/.config" "$HOME/.claude/skills" "$HOME/.zsh/conf.d"

  # No --adopt: it moves existing files INTO the repo, over the tracked ones.
  # Move anything in the way to a timestamped backup instead, then stow normally.
  local backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)" target
  local stow=(stow -d "$DOTFILES" -t "$HOME" --ignore='\.DS_Store')
  # The dry run lists each conflict as "... over existing target <path> since ..."
  # (path relative to $HOME). Other conflict kinds aren't parsed here; the real
  # stow below then fails loudly instead.
  { "${stow[@]}" -n "${PACKAGES[@]}" 2>&1 || true; } |
    sed -n 's/.* over existing target \(.*\) since neither a link nor a directory.*/\1/p' |
    while IFS= read -r target; do
      mkdir -p "$backup/$(dirname "$target")"
      mv "$HOME/$target" "$backup/$target"
      echo "  Backed up ~/$target -> $backup/$target"
    done
  "${stow[@]}" "${PACKAGES[@]}"
  echo "Linked: ${PACKAGES[*]}"
}

# =============================================================================
# Tools
# =============================================================================

uses() { [[ " ${PACKAGES[*]} " == *" $1 "* ]]; }

install_tools() {
  # Homebrew, only on machines that have a Brewfile
  if [[ -f "$MACHINE/Brewfile" ]]; then
    if ! have brew && [[ ! -x /opt/homebrew/bin/brew && ! -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      echo "=== Installing Homebrew ==="
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew_shellenv
    echo "=== Homebrew packages from machines/$HOST_NAME/Brewfile ==="
    brew bundle --file="$MACHINE/Brewfile"
  fi

  # zsh and stow: the Mac Brewfiles carry them, Linux gets them from the system
  local -a missing=()
  have zsh || missing+=(zsh)
  have stow || missing+=(stow)
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "=== Installing ${missing[*]} ==="
    if have apt-get; then sudo apt-get install -y "${missing[@]}"
    elif have pacman; then sudo pacman -S --needed --noconfirm "${missing[@]}"
    elif have brew; then brew install "${missing[@]}"
    else echo "Install ${missing[*]} by hand, then run this again"; exit 1
    fi
  fi
  [[ $SHELL == */zsh ]] || chsh -s "$(command -v zsh)"

  if uses claude && ! have claude && [[ ! -x "$HOME/.local/bin/claude" ]]; then
    echo "=== Installing Claude Code ==="
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  # Node for dev machines: nvm (PROFILE=/dev/null keeps its installer out of
  # .zshrc; dev.zsh loads it), the LTS release, and pnpm through corepack
  if uses dev && [[ ! -d "$HOME/.nvm" ]]; then
    echo "=== Installing nvm + Node LTS + pnpm ==="
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | PROFILE=/dev/null bash
    # nvm.sh trips over set -u
    set +u
    source "$HOME/.nvm/nvm.sh"
    nvm install --lts
    corepack enable pnpm
    set -u
  fi
}

# =============================================================================
# Main
# =============================================================================

case "$MODE" in
  --unlink) unlink_all; exit 0 ;;
  all | --links) ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac

if [[ ! -f "$MACHINE/packages" ]]; then
  echo "No machines/$HOST_NAME/packages yet. Create it with one package per line, from:"
  echo "  $(cd "$DOTFILES" && ls -d */ | grep -v machines | tr -d / | tr '\n' ' ')"
  exit 1
fi
PACKAGES=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [[ -n $line ]] && PACKAGES+=("$line")
done < "$MACHINE/packages"

[[ $MODE == all ]] && install_tools

echo ""
echo "=== Linking dotfiles for $HOST_NAME ==="
have stow || { echo "stow not found: run ./install.sh without --links first"; exit 1; }
unlink_all
link_packages

echo ""
echo "Done. Open a new terminal, or run: source ~/.zshrc"
