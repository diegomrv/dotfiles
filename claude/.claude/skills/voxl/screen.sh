#!/bin/sh
# Look at a Mac's screen through its voxl server over Tailscale (https://<host>.<tailnet>:8443).
#   screen.sh <host> shot <out.png>             screenshot of the streamed display
#   screen.sh <host> wait [query]               block until the screen settles, e.g. 'idle=1000&timeout=30000'
#   screen.sh <host> record <seconds> <out.mp4>
#   screen.sh <host> url                        the page to open in a browser
# Resolves the host through `tailscale ip`, so it works where MagicDNS is off (kraken).
set -eu

host=${1:?usage: screen.sh <host> shot|wait|record|url ...}
cmd=${2:-shot}
ts=$(command -v tailscale || echo /Applications/Tailscale.app/Contents/MacOS/Tailscale)

ip=$("$ts" ip -4 "$host") || { echo "screen.sh: $host is not on the tailnet" >&2; exit 2; }
sfx=$("$ts" status --json | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["MagicDNSSuffix"])')
name="$host.$sfx"
base="https://$name:8443"

get() {
  curl -sS --fail-with-body --connect-timeout 5 --max-time "${TIMEOUT:-60}" --resolve "$name:8443:$ip" "$@" || {
    echo "screen.sh: no voxl answer from $host:8443 (voxl not installed there, machine offline, or Tailscale serve off)" >&2
    exit 3
  }
}

case $cmd in
  url) echo "$base/" ;;
  shot)
    out=${3:?usage: screen.sh <host> shot <out.png>}
    hdr=$(mktemp)
    trap 'rm -f "$hdr"' EXIT
    get -D "$hdr" -o "$out" "$base/screenshot"
    echo "$out (seq $(tr -d '\r' <"$hdr" | awk -F': ' 'tolower($1)=="x-voxl-seq"{print $2}'))"
    ;;
  wait) get "$base/wait${3:+?$3}"; echo ;;
  record)
    secs=${3:?usage: screen.sh <host> record <seconds> <out.mp4>}
    TIMEOUT=$((secs + 30)) get -o "${4:?out.mp4}" "$base/record?seconds=$secs"
    echo "$4"
    ;;
  *) echo "screen.sh: unknown command $cmd" >&2; exit 2 ;;
esac
