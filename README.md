# dotfiles

Shell, editor and tool config for all my machines, linked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

Every machine gets only the packages it needs: a server doesn't get Node, Zed or the Mac apps.

## Packages

| Package | What's in it | Who gets it |
|---|---|---|
| `shell` | zsh, aliases, Oh My Posh prompt, git, gh, nvim, vim, fastfetch, herdr | everyone |
| `claude` | Claude Code: global CLAUDE.md, settings, hooks, shared skills, statusline | Macs, servers, ragnarok |
| `dev` | Node (nvm, pnpm), PHP, localdev, worktrunk, Zed, Amp, opencode, workstation rules + skills for Claude | Macs |
| `desktop` | Ghostty, yazi, fonts, video conversion helpers | Macs, ragnarok |
| `macos` | CodexBar, 1Password SSH agent, keychain unlock over SSH | Macs |

## Machines

Each machine has a folder in `machines/<hostname>/`:

- `packages`: which packages to link
- `Brewfile` or `apt`: the machine's tools. Homebrew on the Macs; Linux uses its own package manager (hades: `apt` list; ragnarok: pacman, not listed). kraken stays on Homebrew until it moves to Ubuntu 26.04: 24.04's apt is too old (fzf, neovim, Node) or missing things (fastfetch)
- `host.zsh`: shell config for that machine only, sourced straight from the repo

| Machine | What it is | Packages |
|---|---|---|
| bahamut | Mac mini M4, home | shell claude dev desktop macos |
| highwind | MacBook | shell claude dev desktop macos |
| kraken | homelab server, Ubuntu | shell claude |
| hades | backup server, Ubuntu, off-site | shell claude |
| ragnarok | gaming PC, CachyOS | shell claude desktop |

The repo lives at `~/mainframe/dotfiles` on the Macs and `~/dotfiles` on the Linux boxes.

## Setup

```bash
git clone git@github.com:diegomrv/dotfiles.git ~/dotfiles   # ~/mainframe/dotfiles on a Mac
cd ~/dotfiles
./install.sh
```

A new machine needs `machines/<hostname>/packages` first (copy the closest one). `install.sh` then:

1. Installs Homebrew and the machine's Brewfile, or its `apt` list, whichever it has
2. Installs zsh and stow if missing, makes zsh the login shell. Links `fdfind` to `fd` (Ubuntu's name), and installs oh-my-posh and herdr into `~/.local/bin` from upstream if no package manager provided them
3. Installs Claude Code (if `claude` is listed), and nvm + Node LTS + pnpm (if `dev` is listed)
4. Removes every old link into the repo, then links the listed packages. Files in the way go to `~/.dotfiles-backup/<timestamp>/`

`./install.sh --links` does only step 4. Run it after pulling a change that moves or removes files, or after editing a machine's `packages`.

**The Linux boxes update themselves.** kraken, hades and ragnarok list their repos in `AUTOPULL` in `host.zsh`. When you open a shell there, at most once every 12 hours, they fast-forward those repos and relink if a pull added or removed files in one of their packages. Local changes or commits that block a fast-forward just get a warning. `autopull -f` checks right now. The Macs pull by hand.

After setup: sign into 1Password (SSH agent), `gh auth login`, and put secrets in `~/.zshrc.local`.

## Homebrew

```bash
brewsave             # write this machine's installed packages to its Brewfile
brewinstall          # install from this machine's Brewfile
brewdiff             # what bahamut has that highwind doesn't
brewdiff bahamut kraken
```

`brew bundle` never uninstalls. To remove what's no longer listed: `brew bundle cleanup --file=machines/<host>/Brewfile --force`.

## Adding things

- **A config file:** put it in the right package at its `$HOME` path (e.g. `dev/.config/tool/config`), then `./install.sh --links`.
- **Shell config for one package:** `<package>/.zsh/conf.d/<name>.zsh`. `.zshrc` sources every file in `~/.zsh/conf.d/`.
- **Shell config for one machine:** `machines/<host>/host.zsh`.
- **Secrets:** `~/.zshrc.local` and `~/.gitconfig.local` (never tracked).
