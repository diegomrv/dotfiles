#!/bin/bash
# PreToolUse(Bash) hook: keeps Claude Code sessions aware of runaway node memory.
# Warn  -> inject context so the session cleans up / caps workers before heavy runs.
# Block -> deny only test/build runner commands when memory is critical, so
#          cleanup commands (kill, ps, etc.) always still work.
#
# Context: 2026-08-17 a 9-worker test run (~13GB of node RSS) exhausted swap on
# the 16GB Mac mini and macOS suspended Chrome + Wave Link.

WARN_NODE_KB=${NODE_GUARD_WARN_KB:-6291456}        # 6 GB total node RSS
CRIT_NODE_KB=${NODE_GUARD_CRIT_KB:-10485760}       # 10 GB total node RSS
WARN_SWAP_FREE_MB=${NODE_GUARD_WARN_SWAP_FREE_MB:-1024}
CRIT_SWAP_FREE_MB=${NODE_GUARD_CRIT_SWAP_FREE_MB:-512}

# macOS ships jq at /usr/bin/jq, but kraken has it under linuxbrew, so resolve it
# from PATH instead of hardcoding. Without jq this hook can neither read its input
# nor emit its output, so bail quietly rather than pretending to guard anything.
JQ=$(command -v jq) || exit 0

input=$(/bin/cat)
cmd=$(printf '%s' "$input" | "$JQ" -r '.tool_input.command // ""' 2>/dev/null)

# Total RSS (KB) of all processes whose executable is literally "node"
node_kb=$(/bin/ps axo rss=,comm= | /usr/bin/awk '{r=$1; $1=""; if ($0 ~ /(^| |\/)node$/) s+=r} END {print s+0}')
node_kb=${node_kb:-0}

# Swap in MB (integers).
if [ "$(uname)" = "Darwin" ]; then
  # "sysctl -n vm.swapusage" ->
  #   total = 5120.00M  used = 3774.75M  free = 1345.25M  (encrypted)
  # macOS allocates swap on demand: total = 0 means no swap pressure at all, not
  # exhausted swap (this used to read "free = 0.00M" as critical and block commands).
  swap_usage=$(/usr/sbin/sysctl -n vm.swapusage 2>/dev/null)
  swap_total_mb=$(printf '%s' "$swap_usage" | /usr/bin/awk '{gsub(/M/,""); printf "%d", $3}')
  swap_free_mb=$(printf '%s' "$swap_usage" | /usr/bin/awk '{gsub(/M/,""); printf "%d", $9}')
else
  # Linux: /proc/meminfo reports SwapTotal/SwapFree in kB.
  swap_total_mb=$(/usr/bin/awk '/^SwapTotal:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
  swap_free_mb=$(/usr/bin/awk '/^SwapFree:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
fi
swap_total_mb=${swap_total_mb:-0}
swap_free_mb=${swap_free_mb:-99999}
[ "$swap_total_mb" -eq 0 ] && swap_free_mb=99999

level=""
if [ "$node_kb" -gt "$CRIT_NODE_KB" ] || [ "$swap_free_mb" -lt "$CRIT_SWAP_FREE_MB" ]; then
  level="critical"
elif [ "$node_kb" -gt "$WARN_NODE_KB" ] || [ "$swap_free_mb" -lt "$WARN_SWAP_FREE_MB" ]; then
  level="warn"
fi
[ -z "$level" ] && exit 0

node_gb=$(/usr/bin/awk -v kb="$node_kb" 'BEGIN {printf "%.1f", kb/1048576}')
top=$(/bin/ps axo rss=,pid=,comm= | /usr/bin/awk '{r=$1; p=$2; $1=$2=""; if ($0 ~ /(^| |\/)node$/) printf "%d\tpid %s: %d MB\n", r, p, r/1024}' | /usr/bin/sort -rn | /usr/bin/head -3 | /usr/bin/cut -f2 | /usr/bin/tr '\n' '; ')

msg="MEMORY GUARD (${level}): node processes are using ${node_gb} GB RSS total; swap free: ${swap_free_mb} MB. Top node: ${top}. Uncapped node worker pools have exhausted memory on these ~16GB machines before (2026-08-17: macOS suspended apps on the Mac mini). Before running anything heavy: kill stray node workers you started, and cap workers on test/build runs (jest/vitest --maxWorkers=2, VITEST_MAX_THREADS=2, playwright --workers=2)."

heavy=0
printf '%s' "$cmd" | /usr/bin/grep -qiE '(vitest|jest|playwright|next +build|(npm|pnpm|yarn|bun)( +run)? +(test|build))' && heavy=1

if [ "$level" = "critical" ] && [ "$heavy" = "1" ]; then
  printf '%s' "$msg" | "$JQ" -Rs '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:("Blocked heavy command: memory is critical. " + . + " Re-run after cleanup, with capped workers.")}}'
else
  printf '%s' "$msg" | "$JQ" -Rs '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:.}}'
fi
exit 0
