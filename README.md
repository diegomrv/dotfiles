# dotfiles

Personal development environment configs. macOS primary, Linux/WSL compatible.

Managed with [GNU Stow](https://www.gnu.org/software/stow/) -- symlinks everything to `$HOME` automatically.

## What's in here

| Category | Tools | Config files |
|----------|-------|-------------|
| **Shell** | Zsh + Oh My Posh | `.zshrc`, `.aliases`, `.zsh/`, `.wolfius.omp.json` |
| **Terminal** | Ghostty | `.config/ghostty/config` |
| **Editors** | Neovim (LazyVim), Vim, Zed | `.config/nvim/`, `.vimrc`, `.config/zed/` |
| **Git** | Git, GitHub CLI, lazygit | `.gitconfig`, `.config/gh/` |
| **AI** | Claude Code | `claude-global/.claude/` |
| **Other** | fastfetch, yazi, 1Password SSH | `.config/fastfetch/`, `.config/yazi/`, `.config/1Password/` |
| **Fonts** | Hack Nerd Font, JetBrains Mono Nerd Font | `.fonts/` |

### Shell highlights

- OS-aware config: macOS and Ubuntu/WSL get separate sourced files
- [zoxide](https://github.com/ajgazrat/zoxide) for smart `cd`
- [eza](https://github.com/eza-community/eza) for `ls`
- zsh-autosuggestions + zsh-syntax-highlighting
- NVM with auto `.nvmrc` switching on directory change
- Machine-specific overrides via `.zshrc.local` (gitignored)

### Editor setup

- **Neovim**: LazyVim framework with Lazy.nvim plugin manager
- **Zed**: Gruvbox theme, Biome formatter for TS/TSX, JetBrains keymap
- **Vim**: Molokai colorscheme, legacy config

### Terminal look

- **Ghostty** with Hopscotch.256 theme, 95% opacity + blur
- **Oh My Posh** custom prompt with git status, node version, execution time, and clock

## Setup

```bash
git clone <this-repo> ~/dotfiles  # or wherever you want
cd ~/dotfiles

# 1. Install prerequisites (Homebrew, Zsh, Stow, NVM, pnpm, Claude Code)
chmod +x setup.sh && ./setup.sh

# 2. Install Homebrew packages + symlink dotfiles
chmod +x install.sh && ./install.sh
```

That's it. Restart your terminal.

### What the scripts do

**`setup.sh`** installs foundational tools:
- Homebrew (if missing)
- Zsh + sets as default shell
- GNU Stow
- NVM, pnpm, Claude Code

**`install.sh`** does the rest:
- Runs `brew bundle` from the Brewfile (CLI tools, casks, Mac App Store apps)
- Runs `stow` to symlink everything to `$HOME`

### Manual steps after install

- Sign into 1Password and enable the SSH agent
- Sign into GitHub CLI: `gh auth login`
- Import machine-specific overrides to `.zshrc.local` and `.gitconfig.local`

## Brewfile

All Homebrew packages, casks, and Mac App Store apps are tracked in the `Brewfile`. To update it after installing something new:

```bash
brewsave  # alias for: brew bundle dump --file=<path>/Brewfile --force
```

## Adding new dotfiles

1. Place the file at the repo root, mirroring its `$HOME` path (e.g., `.config/tool/config`)
2. Run `stow --adopt -t "$HOME" .` to create the symlink
3. If the file shouldn't be symlinked, add it to `.stow-local-ignore`
4. If it's machine-specific, add it to `.gitignore`

## Machine-specific config

These files are gitignored and loaded if present:

- **`.zshrc.local`** -- extra shell config (e.g., Laravel Herd paths)
- **`.gitconfig.local`** -- local git overrides (e.g., signing keys)
- **`.claude/settings.local.json`** -- local Claude Code settings
