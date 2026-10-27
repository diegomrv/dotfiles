# CLAUDE.md

Guidance for Claude Code when working in this repository. For the human overview (packages, machines, setup), read `README.md` first.

## Layout

GNU Stow, one package per role. Each top-level folder except `machines/` is a package that mirrors `$HOME`:

- `shell/` (every machine), `claude/` (Macs, servers, ragnarok), `dev/` (Macs), `desktop/` (Macs, ragnarok), `macos/` (Macs)
- `machines/<hostname>/packages` lists what that machine links; `Brewfile` its Homebrew packages; `host.zsh` its own shell config (sourced from the repo by `.zshrc`, not stowed)
- `install.sh` does everything: tools, then `--links` (remove every link into the repo, then stow the machine's packages). `--unlink` only removes

Where shell config goes:

- `shell/.zshrc`: only what every machine needs. No OS or role branches in it
- `<package>/.zsh/conf.d/<name>.zsh`: anything tied to a package (nvm lives in `dev`, keychain unlock in `macos`). `.zshrc` sources `~/.zsh/conf.d/*.zsh`
- `machines/<host>/host.zsh`: one machine only. `~/.zshrc.local`: secrets, never tracked

Claude Code instructions are split the same way: `claude/.claude/CLAUDE.md` is for every machine; Mac-only instructions (mainframe, Obsidian, gwsa, agent-browser) are in `dev/.claude/rules/workstation.md`, loaded as a user-level rule. Skills that only make sense on the Macs go in `dev/.claude/skills/`.

## Commands

```bash
./install.sh                 # full setup for this machine
./install.sh --links         # relink only (after moving files or editing packages)
stow -n -v -d . -t "$HOME" shell claude   # preview what stow would do
```

Never use `stow --adopt`: it moves existing `$HOME` files into the repo over the tracked ones. `install.sh` backs conflicts up to `~/.dotfiles-backup/<timestamp>/` instead.

## Gotchas

- **Never hardcode `/Users/<user>/...` or `/opt/homebrew/...`.** Use `$HOME`, `$HOMEBREW_PREFIX`, and binaries from `PATH`. Installers (LM Studio, pnpm, nvm, `gh auth setup-git`) append absolute-path blocks to `.zshrc` and `.gitconfig` on their own: move what they add into the right package's `conf.d` file or `host.zsh`.
- **Guard commands that only exist on some machines** (`security`, `scutil`, `brew`, `npx`) with `command -v`, or put them in the package that owns them. An unguarded one prints an error on every shell startup elsewhere.
- **`~/.config`, `~/.claude`, `~/.claude/skills` and `~/.zsh/conf.d` must stay real directories.** `install.sh` creates them before stowing. If stow folds one of them into the repo, every app writes its state (credentials included) into the repo. App folders inside them (`~/.config/nvim`, `~/.config/herdr`) are folded on purpose so apps that rewrite their config atomically keep writing into the repo; their runtime files are gitignored.
- **`claude/.claude/settings.json` is shared by every machine.** Hook commands run through a shell, so use `$HOME` and guard hooks whose script or binary only exists on some machines (the statusline needs `npx`, which servers don't have). `model`, `theme` and similar preferences apply everywhere. There is no per-machine user-level override: `settings.local.json` is only read per project. `/model` saves to `~/.claude/settings.json`, which writes through the link into this repo. For a temporary switch, press `s` in the `/model` picker or run `claude --model ...`.
- **`shell/.config/gh/hosts.yml` is tracked, and is only safe to track while a keyring works.** `gh` keeps its OAuth token in the OS keyring (Keychain on macOS, gnome-keyring on kraken, unlocked by `machines/kraken/host.zsh`), leaving usernames and `git_protocol` in the file. If the keyring is unavailable, `gh` silently writes the token **in plaintext into that tracked file** and prints `! Authentication credentials saved in plain text`. Fix the keyring before committing. `gh auth status` must say `(keyring)`.
