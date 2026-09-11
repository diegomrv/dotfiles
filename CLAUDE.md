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
- `.zsh/hosts/<hostname>.zsh` - Per-machine config, **tracked in git**, auto-sourced by `.zshrc` based on hostname (`bahamut` = Mac mini, `highwind` = MacBook, `kraken` = homelab server). NON-SECRET config only.
- `.zshrc.local` - Machine-specific **secrets** + overrides (gitignored -- API keys, Herd paths)
- `.aliases` - Custom shell aliases

### Homebrew Packages
- `Brewfile.<hostname>` - One Brewfile per machine (`Brewfile.bahamut` = Mac mini, `Brewfile.highwind` = MacBook, `Brewfile.kraken` = homelab server on Linuxbrew). The machines deliberately carry different packages, so there is no shared Brewfile.
- `brewsave` dumps the current machine into its own file, `brewinstall` installs from it, `brewdiff [a] [b]` lists what one machine has that another doesn't, defaulting to the two Macs (all defined in `.aliases`).
- All three resolve the repo through `$DOTFILES_DIR`, which `.aliases` derives from the `~/.aliases` stow symlink — the repo lives at `~/mainframe/dotfiles` on the Macs but `~/dotfiles` on kraken.
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

## Cross-platform gotchas

These files are shared verbatim with kraken (Ubuntu), so machine-absolute paths are bugs, not cosmetics:

- **Never hardcode `/Users/<user>/...` or `/opt/homebrew/...`.** Use `$HOME` and resolve binaries from `PATH`. Installers (Herd, LM Studio, pnpm, `gh auth setup-git`) append absolute-path blocks to `.zshrc` and `.gitconfig` on their own — move what they add into `.zsh/macos.zsh` and make it `$HOME`-relative.
- **Guard macOS-only commands** (`security`, `sysctl vm.swapusage`, `open`, `scutil`) by OS or by `command -v`. An unguarded one prints an error on every shell startup on Linux.
- **`.zshrc` tail beats `.zsh/ubuntu.zsh`.** OS files are sourced first, so anything appended to the bottom of `.zshrc` silently overrides them (this is how `PNPM_HOME` ended up pointing at a macOS path on kraken).
- **`claude-global/.claude/settings.json` is shared too.** Hook commands run through a shell, so use `$HOME`; guard hooks whose script only exists on one machine. `model`, `theme`, and similar preferences set there apply to *all three* machines — put per-machine ones in the gitignored `.claude/settings.local.json`.
- **Stow does not unlink.** Deleting something from the repo leaves a dangling symlink in `$HOME` on every other machine until it is removed by hand.
- **`.config/gh/hosts.yml` is tracked, and is only safe to track while a keyring works.** `gh` puts its OAuth token in the OS keyring — the Keychain on macOS, gnome-keyring on kraken (unlocked at session start by `.zsh/hosts/kraken.zsh`) — leaving the file with usernames and `git_protocol` only. If the keyring is ever unavailable, `gh` silently falls back to writing the token **in plaintext into that tracked file**, and prints `! Authentication credentials saved in plain text`. If you see that warning, fix the keyring before committing. `gh auth status` must say `(keyring)`, not a file path.
