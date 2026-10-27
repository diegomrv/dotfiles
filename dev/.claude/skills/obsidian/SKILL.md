---
name: obsidian
description: Read and write Diego's Obsidian vault (Wolfius Vault, iCloud). Use when Diego says "put this in Obsidian", "note this", "add it to the vault", "what do my notes say about X", asks to check or refresh a vault section (Homelab, a project hub), or when a project that already has a folder under "01 - Projects" reaches a milestone worth recording. Obsidian is Diego's personal reading layer, not a replacement for repo docs.
---

# Skill: Obsidian

Repos hold the docs agents and teammates need. The vault holds what Diego wants to re-read himself: status, decisions, inventories, how-tos for his own stuff. Short but complete: every note should answer what it is, where it is, how to reach it, and what to watch out for.

## Where it is

| | |
|---|---|
| Vault | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Wolfius Vault/` |
| Machines | Mac Mini (bahamut) and MacBook (highwind), synced by iCloud. Not on kraken: `/mnt/media/Obsidian/` there is a dead Syncthing mirror, stale since Feb 2026. |
| Format | Plain Markdown. Use Read / Edit / Write on the files. Obsidian.app does not need to be open. |
| MCP | The `obsidian` MCP server is the Local REST API plugin on `127.0.0.1:27123`. It only connects while Obsidian.app is open. Handy for search or opening a note in the app, never required. If it failed to connect, use the files. |

Never touch `.obsidian/` (app config) or `.trash/` (Obsidian's recycle bin). Retire a note by moving it to `.trash/`, or to `07 - Archives/` if it has historical value. Don't `rm`.

iCloud gotcha: on the MacBook a file may be evicted. If a note seems missing, look for `.<name>.md.icloud` next to it and run `brctl download "<path>"`.

## Layout (PARA)

| Folder | What lives there |
|---|---|
| `00 - Map of Contents/Home.md` | entry point; links every area and project hub |
| `01 - Projects/<Name>/` | work with an end date (Fundlien, Tennet Ingestion v5) |
| `02 - Areas/<Name>/` | ongoing responsibilities (Homelab, Car, Linux) |
| `03 - Resources/<Topic>/` | reference material by topic (CSS, JS, Wordpress) |
| `04 - Permanent/`, `05 - Fleeting/` | Zettelkasten leftovers; fleeting = quick captures |
| `06 - Daily/` | daily notes, rarely used |
| `07 - Archives/` | retired material (old app exports, dead projects). Move here, never delete |
| `99 - Meta/` | templates and `Assets/` (attachment folder set in app config) |
| `Clippings/` | web clipper output |

## Conventions

- **Filenames:** Title Case with spaces, `.md`. Numbered prefixes (`00 Home`, `01 Architecture Map`) only inside project folders that already use them.
- **Hub note per folder:** `00 Home.md` in projects, `<Area>.md` in areas (`Homelab.md`). The hub links every child note. Add new notes to the hub, and new hubs to `Home.md`.
- **Links:** `[[Note Name]]` wikilinks, no path needed. Link instead of repeating content.
- **Frontmatter:**

  ```yaml
  ---
  tags: [area-or-project, topic]
  created: 2026-09-08
  updated: 2026-09-08
  ---
  ```

  Bump `updated` on every edit. Older notes use `date:`; leave it and add `updated:`.
- **Shape of a note:** title, one-line TL;DR or dated status, then tables for inventories and short bullets for facts. Headers only when a note covers more than one thing.
- **Pointers, not copies:** "full doc at `~/mainframe/homelab-docs/NETWORK.md`" beats pasting it.

## What belongs, what doesn't

Write:

- Status and outcome, dated. Not the process.
- Decisions with the why, one or two lines each.
- Inventories: services, URLs, IPs, people, accounts (as pointers).
- Where the real thing lives: repo path, doc, ticket, dashboard.
- How-tos Diego will need again in six months.

Don't:

- Duplicate repo READMEs, CLAUDE.md files or design docs. Link to them.
- Paste logs, transcripts, compose files, code. Those go in repos. A project folder may keep raw sources in a `Pads/` or `Scripts/` subfolder, out of the hub.
- Write secrets. Say "in 1Password", "in the stack env", "in `~/.secrets/`".
- Pad. Past roughly 100 lines a note is probably repo material or needs splitting.

Prefer updating an existing note over adding one. One note per topic.

## When to write

- Diego asks.
- A project with a vault folder hits a milestone: refresh the hub's status line and append one line to its session log. Do it at wrap-up, not mid-work.
- A new project needs a folder: ask once ("want a vault folder for this?"), then create `01 - Projects/<Name>/00 Home.md` and link it from `Home.md`.
- "What do my notes say about X": grep the vault, skipping `.trash/`, `.obsidian/` and `07 - Archives/` unless asked.

## Homelab

`02 - Areas/Homelab/Homelab.md` is Diego's overview of kraken (services, URLs, storage, gotchas), with short how-to notes beside it. Source of truth for agents stays `~/mainframe/homelab-docs/` (on kraken: `~/homelab-docs/`). When homelab-docs changes, refresh the hub's service table and its `updated` date. Don't copy the maintenance log over.
