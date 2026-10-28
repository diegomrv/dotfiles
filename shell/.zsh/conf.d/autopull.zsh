# autopull: keeps machines Diego rarely logs into from sitting on old config.
# A machine opts in from its machines/<host>/host.zsh:
#   AUTOPULL=(~/dotfiles ~/homelab-docs)
# Right before the first prompt (after fastfetch), at most once every 12 hours, each
# repo is fetched and fast-forwarded. It never merges, rebases or stashes: local
# changes or commits that block a fast-forward get a one-line warning instead. When a
# dotfiles pull adds or removes files in a package this machine links, it relinks with
# install.sh --links. `autopull -f` runs it now, ignoring the 12 hours.
# The Macs don't opt in: highwind's GitHub key waits for 1Password approval on screen.

autopull() {
  local force=0
  [[ $1 == -f ]] && { force=1; shift }
  (( $# )) || set -- $AUTOPULL
  (( $# )) || { print "autopull: no repos (set AUTOPULL in this machine's host.zsh)"; return 1 }

  local -a fresh=( ~/.cache/autopull(N.mh-12) )
  (( force || ! $#fresh )) || return 0

  local -a to=()
  (( $+commands[timeout] )) && to=(timeout 20)
  local repo name behind before fetched=0
  for repo in "$@"; do
    name=${repo/#$HOME/'~'}
    [[ -d $repo/.git ]] || { print -P "%F{yellow}autopull: $name is not a git repo%f"; continue }
    if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5' \
        $to git -C $repo fetch -q 2>/dev/null; then
      print -P "%F{yellow}autopull: couldn't fetch $name (offline, or no GitHub access)%f"
      continue
    fi
    fetched=1
    if ! behind=$(git -C $repo rev-list --count HEAD..@{u} 2>/dev/null); then
      print -P "%F{yellow}autopull: $name has no upstream branch%f"
      continue
    fi
    (( behind )) || continue
    before=$(git -C $repo rev-parse HEAD)
    if ! git -C $repo merge -q --ff-only @{u} >/dev/null 2>&1; then
      print -P "%F{yellow}autopull: $name is $behind commit(s) behind; local changes or commits block the update (git -C $name status)%f"
      continue
    fi
    print "autopull: $name +$behind commit(s)$(_autopull_relink $repo $before)"
  done
  # Only a fetch that reached GitHub starts the 12 hours, so a machine that just woke
  # up offline tries again with the next shell.
  (( fetched )) && { mkdir -p ~/.cache; : >| ~/.cache/autopull }
  return 0
}

# For the dotfiles repo: relink when the pull added or removed files in a package
# this machine links. Prints the rest of autopull's summary line.
_autopull_relink() {
  local repo=$1 before=$2
  [[ $repo:A == $DOTFILES_DIR:A ]] || return 0
  local -a pkgs changed
  local line out
  for line in ${(f)"$(<$repo/machines/$HOST_NAME/packages)"}; do
    line=${line%%\#*}; line=${line//[[:space:]]/}
    [[ -n $line ]] && pkgs+=$line
  done
  changed=( ${(f)"$(git -C $repo diff --name-only --no-renames --diff-filter=AD $before HEAD)"} )
  for line in $changed; do
    (( ${pkgs[(Ie)${line%%/*}]} )) || continue
    if out=$($repo/install.sh --links 2>&1); then
      print -n ", relinked"
      [[ $out == *'Backed up'* ]] && print -n " (files in the way moved to ~/.dotfiles-backup/)"
    else
      print -n ", relink FAILED: run ${repo/#$HOME/'~'}/install.sh --links"
    fi
    break
  done
  print -n "; open a new shell to load it"
}

_autopull_first_prompt() {
  add-zsh-hook -d precmd _autopull_first_prompt
  (( $#AUTOPULL )) && autopull
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _autopull_first_prompt
