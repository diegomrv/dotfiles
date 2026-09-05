# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository using **GNU Stow** for symlink-based deployment. Supports macOS (primary) and Linux/WSL.

## Commands

```bash
# Initial setup (installs Homebrew, zsh, Stow, NVM, pnpm, Deno)
./setup.sh

# Install packages and create symlinks
./install.sh

# Apply dotfiles manually (creates symlinks to $HOME)
stow --adopt -t "$HOME" .

# Preview what stow would do without making changes
stow -n -v -t "$HOME" .
```

## Architecture

### Stow Deployment
- Root-level files/directories are symlinked to `$HOME`
- `.stow-local-ignore` defines exclusions (scripts, docs, IDE files)
- The `-t "$HOME"` flag allows the repo to live anywhere, not just `~/dotfiles`

### Shell Configuration
- `.zshrc` - Main config, detects OS and sources appropriate file
- `.zsh/macos.zsh` - macOS-specific (Homebrew paths, Herd PHP)
- `.zsh/ubuntu.zsh` - Linux/WSL-specific (LinuxBrew, Wayland)
- `.zsh/hosts/<hostname>.zsh` - Per-machine config, **tracked in git**, auto-sourced by `.zshrc` based on hostname (e.g. `bahamut` = Mac mini, `highwind` = MacBook). NON-SECRET config only.
- `.zshrc.local` - Machine-specific **secrets** + overrides (gitignored -- API keys, Herd paths)
- `.aliases` - Custom shell aliases

### Homebrew Packages
- `Brewfile.<hostname>` - One Brewfile per machine (`Brewfile.bahamut` = Mac mini, `Brewfile.highwind` = MacBook). The two Macs deliberately carry different packages, so there is no shared Brewfile.
- `brewsave` dumps the current machine into its own file, `brewinstall` installs from it, `brewdiff` lists what one machine has that the other doesn't (all defined in `.aliases`).
- `brew bundle` never uninstalls. To drop packages that are no longer listed: `brew bundle cleanup --file=Brewfile.<hostname>` (add `--force` to actually remove them).

### Editor Configuration
- `.vimrc` - Traditional Vim with molokai theme
- `.config/nvim/` - Neovim using LazyVim framework with Lazy.nvim

### Terminal & Prompt
- `.wolfius.omp.json` - Oh-my-posh prompt theme
- `.config/ghostty/config` - Ghostty terminal settings
- `.config/fastfetch/config.jsonc` - System info on shell startup

## Key Patterns

When adding new dotfiles:
1. Place files at root level matching their `$HOME` location
2. Update `.stow-local-ignore` if files shouldn't be symlinked
3. Add to `.gitignore` if machine-specific

OS-specific code goes in `.zsh/macos.zsh` or `.zsh/ubuntu.zsh`, not in `.zshrc`.
