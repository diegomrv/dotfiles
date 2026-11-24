---
name: voxl
description: See what's on one of Diego's Macs' screens (bahamut, and any other Mac running voxl) from any machine on the tailnet, kraken included, by pulling a screenshot, waiting for the screen to settle, or recording a clip. Use when asked to check, look at or screenshot a Mac's screen; when a command or brew cask hangs with no output and a macOS dialog (Gatekeeper, a permission prompt, a first-launch window) may be waiting on the display; or to confirm a GUI app's state on a machine you're not running on. Look only: it doesn't click or type.
---

# voxl: look at a Mac's screen

Each Mac with voxl serves its screen at `https://<host>.<tailnet>.ts.net:8443`, tailnet only, no password (Tailscale is the gate). Setup and gotchas: `~/mainframe/tools/voxl/README.md` on the Macs.

| Host | voxl |
|---|---|
| bahamut | yes (since 2026-11-24) |
| highwind | not yet |

## Commands

The helper resolves the host through Tailscale, so it works even where MagicDNS is off (kraken):

```sh
S=~/.claude/skills/voxl/screen.sh
$S bahamut shot "$SCRATCH/bahamut.png"            # PNG of the streamed display, prints its seq
$S bahamut wait 'idle=1000&timeout=30000'          # returns once nothing changed for 1 s
$S bahamut wait 'change&since=812'                 # returns at the first change after seq 812
$S bahamut record 10 "$SCRATCH/clip.mp4"           # MP4 of the next 10 s
$S bahamut url                                     # page for a human to open
```

Then open the PNG with the Read tool. On a Mac, `sips -Z 1720 file.png` first halves the ultrawide and saves tokens.

## Rules

- **Private content.** Screens show mail, chats, client work. Save captures to the session scratchpad (or `mktemp -d`), never in a repo, and delete them when done.
- **Look only.** voxl's HTTP API only looks. Don't drive the screen through its stream. If something on screen needs a click, tell Diego what it is. On bahamut, operating native apps is the `agent-desktop` CLI's job (workstation rules).
- **Don't wake the display to get a picture.** `caffeinate -u` turns Diego's monitors on. If the shot is black, stale or the lock screen, report that as the answer.
- **One display at a time.** The shot is whichever display the stream is on (bahamut: the 3440x1440 ultrawide by default). Its vertical monitor only shows if someone picked it in the page's Display picker.
- **Exit 3** means no voxl on that host (not installed, offline, or Tailscale serve off). Say so; don't install it remotely, since it needs permission clicks at that Mac.
