# Shared by every machine. What only some machines need lives elsewhere:
#   ~/.zsh/conf.d/*.zsh                       one drop-in per stowed package (dev, desktop, macos)
#   $DOTFILES_DIR/machines/<host>/host.zsh    this machine only (tracked, non-secret)
#   ~/.zshrc.local                            secrets and local overrides (untracked)

# Repo root, resolved through the stow symlink (~/.zshrc -> <repo>/shell/.zshrc).
# It sits at ~/mainframe/dotfiles on the Macs and ~/dotfiles on the Linux boxes.
export DOTFILES_DIR="${${:-$HOME/.zshrc}:A:h:h}"
HOST_NAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"

# Homebrew (macOS or Linuxbrew), if this machine has it
for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [[ -x $_brew ]] && { eval "$($_brew shellenv)"; break; }
done
unset _brew

export PATH="$HOME/.local/bin:$PATH"         # claude, gwsa, herdr, pi, etc.

# History file configuration
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000

export EDITOR='nvim'
export SUDO_EDITOR='nvim'
export VISUAL='nvim'

# Initialize zsh completion system with additional completions
[[ -n $HOMEBREW_PREFIX ]] && FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
autoload -Uz compinit && compinit

# fzf: Ctrl+R fuzzy history, Ctrl+T fuzzy file picker, Alt+C fuzzy cd, **<Tab> completion.
# Uses fd for file/dir listing (respects .gitignore, includes dotfiles, skips .git).
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  # Alt+C is unreachable on macOS with the Latin American layout (Option is needed for @ [] {} \),
  # so also bind fuzzy-cd to Ctrl+G. Esc then C works too.
  bindkey '^G' fzf-cd-widget
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

source ~/.aliases

# Package drop-ins, then this machine's own file, then local secrets
for _f in ~/.zsh/conf.d/*.zsh(N); do source "$_f"; done
unset _f
[[ -f "$DOTFILES_DIR/machines/$HOST_NAME/host.zsh" ]] && source "$DOTFILES_DIR/machines/$HOST_NAME/host.zsh"
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Prompt (Apple's Terminal.app can't render it)
if command -v oh-my-posh >/dev/null 2>&1 && [[ $TERM_PROGRAM != Apple_Terminal ]]; then
  eval "$(oh-my-posh init zsh --config ~/.wolfius.omp.json)"
fi

# Only init zoxide in interactive shells (prevents errors in scripts/subshells)
if [[ $- == *i* ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# Plugins from Homebrew, Arch (/usr/share/zsh/plugins) or Debian (/usr/share).
# Autosuggestions use history first, then completion (like fish).
# Syntax highlighting must be sourced last.
_zsh_plugin() {
  local d
  for d in "$HOMEBREW_PREFIX/share" /usr/share/zsh/plugins /usr/share; do
    [[ -f "$d/$1/$1.zsh" ]] && { source "$d/$1/$1.zsh"; return; }
  done
}
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
_zsh_plugin zsh-autosuggestions
_zsh_plugin zsh-syntax-highlighting
unfunction _zsh_plugin

command -v fastfetch >/dev/null 2>&1 && fastfetch

# NOTE: installers (LM Studio, pnpm, nvm, ...) like to append their own blocks down
# here, often with absolute /Users/<user>/... paths that then leak onto every other
# machine. Move anything they add into the right package's ~/.zsh/conf.d file, or
# into machines/<host>/host.zsh, and keep it $HOME-relative.
