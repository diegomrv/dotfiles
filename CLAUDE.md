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
stow --adopt .

# Preview what stow would do without making changes
stow -n -v .
```

## Architecture

### Stow Deployment
- Root-level files/directories are symlinked to `$HOME`
- `.stow-local-ignore` defines exclusions (scripts, docs, IDE files)
- Run stow from `~/dotfiles` directory

### Shell Configuration
- `.zshrc` - Main config, detects OS and sources appropriate file
- `.zsh/macos.zsh` - macOS-specific (Homebrew paths, Herd PHP)
- `.zsh/ubuntu.zsh` - Linux/WSL-specific (LinuxBrew, Wayland)
- `.zshrc.local` - Machine-specific overrides (gitignored)
- `.aliases` - Custom shell aliases

### Editor Configuration
- `.vimrc` - Traditional Vim with molokai theme
- `.config/nvim/` - Neovim using NvChad framework with Lazy.nvim

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
