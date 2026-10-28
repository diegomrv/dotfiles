# Machine-specific zsh config for ragnarok (gaming PC -- CachyOS, Arch-based)
# Tracked in git. NON-SECRET config only -- secrets go in ~/.zshrc.local

setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# Kept from the CachyOS default config: suggest the package for unknown commands
[[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh

# Up/Down search history by what's already typed
if [[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# Arch/CachyOS helpers (kept from the CachyOS default zsh config)
alias update="sudo pacman -Syu"
alias rmpkg="sudo pacman -Rsn"
alias jctl="journalctl -p 3 -xb"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

# Fast-forward these repos before the first prompt, at most every 12 hours (shell/.zsh/conf.d/autopull.zsh)
AUTOPULL=(~/dotfiles)
