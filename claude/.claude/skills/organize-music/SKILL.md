---
name: organize-music
description: Organize newly downloaded music albums from Nicotine+/Soulseek into the music library, and read/fix music metadata (tags). Use this skill whenever the user mentions organizing music, sorting downloads, cleaning up albums, moving music to the library, or anything related to their Nicotine+/Soulseek downloads and music collection. Also trigger when the user says things like "organize my downloads", "sort my music", "new albums to move", references the soulseek/nicotine downloads folder, or asks to check/fix album or track metadata, tags, artist names, or albums showing wrong info in their music player.
---

# Organize Music

Organize newly downloaded albums from Nicotine+ (Soulseek) into the user's music library on kraken.

## Prerequisites

This skill only works on **kraken** (the homelab server). Before doing anything, check the hostname (`hostname`). If not on kraken, inform the user and stop.

## Paths

- **Music library:** `/mnt/media/music/`
- **Nicotine+ downloads:** `/mnt/media/docker/soulseek/downloads/`

Note: `Unprocessed` in the music library is a band name, NOT a staging folder.

## Workflow

### Step 1: Scan downloads

List everything in `/mnt/media/docker/soulseek/downloads/` — both album directories and any loose audio files (which may be an album downloaded without a folder).

### Step 2: Identify metadata

For each album directory and any group of loose files, extract metadata from the first `.flac` or `.mp3` file using `ffprobe`:

```bash
ffprobe -v quiet -show_entries format_tags=artist,album,date -of default "<file>"
```

This gives you the artist name, album name, and release year. Present findings to the user in a table before moving anything.

### Step 3: Determine band folder name

Check if the artist already exists in `/mnt/media/music/`. If so, use the existing folder name exactly.

If creating a new band folder, follow these rules:

- **Default:** Title Case with lowercase prepositions and articles mid-name (e.g., "Bring Me the Horizon", "Born of Osiris", "A Perfect Circle")
- **"The" at the start:** Keep capitalized (e.g., "The Browning", "The Plot in You")
- **Stylized names:** Some bands have intentional capitalization that must be preserved. If the user confirms a stylized format, use it. Known examples from the library:
  - All lowercase: `thrown`, `vianova`, `breakk.away`
  - All caps: `VOLA`, `PRESIDENT`
- **When unsure:** Ask the user. Some band names look stylized but aren't — always confirm for new artists you haven't seen before.

### Step 4: Determine album folder name

Format: `(YYYY) Album Name`

- **Year first, in parentheses** — the whole library was normalized to this in July 2026. Do not use square brackets.
- **Album name:** Keep as downloaded / as per metadata. Don't "fix" capitalization or punctuation in album names unless the user asks.
- **Singles:** Use `(YYYY) Track Name - Single` format.
- **Year extraction:** Pull from metadata `date` tag. If it's a full date like `2019-01-11`, use just the year `2019`. If the year is in the folder name but not metadata, use the folder name. If neither has it, ask the user.
- **Loose files:** If audio files are sitting directly in the downloads root (not in a subfolder), they likely belong to one album. Check metadata to confirm they share the same album/artist, then create a proper `[YYYY] Album Name` folder for them.

### Step 5: Handle edge cases

- **Multiple singles by the same artist from the same year:** The user may want these combined into one folder. Ask before assuming.
- **"Limited Edition", "Deluxe", "Remaster" suffixes:** Keep them in the album name as downloaded.
- **Albums you can't identify:** Ask the user rather than guessing.

### Step 6: Present the plan

Before moving anything, show the user a complete table of:
- Source path (in downloads)
- Artist → target band folder
- Album → target album folder name
- Any new band folders being created

Wait for confirmation before executing moves.

### Step 7: Execute moves

Use `mv` to move album directories. For loose files, `mkdir` the target album folder first, then move files into it. Clean up any empty directories left in downloads after moving.

After all moves, verify by listing the new contents of each affected band folder and confirming the downloads directory is clean.

## File naming

Track filenames follow the template **`00 Title.ext`** (zero-padded track number, space, TITLE tag verbatim) — the whole library was normalized to this in July 2026. When organizing new albums, rename tracks to match.

- **Title source:** the TITLE tag, kept verbatim — preserve stylization (all caps, lowercase, punctuation) exactly as tagged.
- **Character policy:** only `/` is substituted (with `-`). Windows-unsafe characters (`?`, `:`, etc.) are kept verbatim; the library is ext4/Jellyfin-only.
- **Feat credits:** normalize to `(feat. Name)` — parentheses, lowercase "feat." — in both the TITLE tag and the filename (e.g. `[Ft. X]` → `(feat. X)`).
- **Multi-disc albums:** all discs live flat in the album folder (no `CD 1`/`Disc 1` subfolders) with a disc prefix on every disc: `01-01 Title`, `02-01 Title`. Single-disc albums never get the prefix.
- **Companion files** (`.lrc`, `.txt` lyrics sharing the audio file's basename) must be renamed in sync with their audio file, or lyric pairing breaks. Beware near-miss stems from Unicode look-alikes (U+2010 hyphen vs `-`): derive the companion's new name from the audio file's new name, not independently.
- **If track-number tags are missing** but filenames contain the numbers, backfill TRACKNUMBER from the filename first, then rename.
- Cover art (`cover.jpg`, `folder.jpg`), `album.nfo`, and booklet PDFs are left as-is.

## Reading and editing tags

The user also uses this skill's context for fixing metadata on albums already in the library ("shows as Unknown Artist", "shows as Single", etc.).

### Tools

- **`kid3-cli`** — primary tag editor. Works on FLAC, MP3, M4A, Ogg. Batch-capable.
- **`metaflac`** — FLAC-only fallback, always available.
- **`ffprobe`** — read-only inspection. Caution: it merges tags from all sources (including nonstandard ID3 blocks in FLACs), so what it shows isn't necessarily what players see. For FLAC, trust `metaflac`/`kid3-cli` output.

### kid3-cli usage

Full docs: https://docs.kde.org/trunk_kf6/en/kid3/kid3/kid3-cli.html

Passing a folder as the argument opens it; `select all` then targets every file. Edits are in-memory until `save` — **always end with `-c 'save'`**.

Read all tags of one file (add `all` after `get` for every frame):

```bash
kid3-cli -c 'get' "<file>"
```

Batch-edit a whole album folder:

```bash
kid3-cli -c 'select all' -c 'set artist "Born of Osiris"' -c 'set albumartist "Born of Osiris"' -c 'save' "<album-dir>"
```

Other useful commands (all operate on the selection, chainable via multiple `-c`):

- **Delete a frame:** set it to empty — `set subtitle ""`
- **Fill tags from filenames** (when files have no/bad tags): `totag '%{track} %{title}'` — format codes like `%{artist}`, `%{album}`, `%{title}`, `%{track}`, `%{year}`; falls back to common patterns if the format doesn't match
- **Autonumber tracks:** `numbertracks` (starts at 1, sequential over selection)
- **Cover art:** `set picture:'/path/cover.jpg' 'Cover'` to embed local art; `albumart 'https://…' all` to fetch from URL; `get picture:'/tmp/out.jpg'` to extract existing art
- **Preview reorganizing folders from tags:** `renamedir '%{artist}/[%{year}] %{album}' dryrun` (dry-run only — actual moves stay manual per this skill's workflow)
- **Filter files:** `filter '%{artist} contains "x"'` or predefined ones like `filter 'Filename Tag Mismatch'`
- **MP3 specifics:** `tag 1`/`tag 2` switch between ID3v1/ID3v2 contexts (default reads 2 falling back to 1, writes 2); `to24` converts ID3v2.3 → v2.4; `syncto 2` copies ID3v1 into ID3v2
- **Large batches:** default per-command timeout is ~3–10 s; raise with `timeout off` as the first `-c` command if a big library operation gets cut short

Do NOT use `fromtag` (renames track files from tags) — this skill's policy is to leave track filenames as-is.

### metaflac usage (FLAC batch)

```bash
for f in "<album-dir>"/*.flac; do
  metaflac --remove-tag=ARTIST --set-tag="ARTIST=Name" "$f"
done
```

Note: `--set-tag` appends — always `--remove-tag` the same field first to avoid duplicate values.

### Conventions and known gotchas

- **Artist casing must match the library's canonical casing exactly** (the band folder name / other albums' tags). A differently-cased `ARTIST`/`ALBUMARTIST` (e.g. `Vola` vs `VOLA`) breaks artist grouping in the music player and shows as "Unknown Artist". Set both `ARTIST` and `ALBUMARTIST`, on every track.
- **Verify across all tracks after editing**, e.g.: `for f in dir/*.flac; do metaflac --show-tag=ARTIST "$f"; done | sort | uniq -c` — every tag should appear exactly once per file count.
- **Scene-release junk:** downloads sometimes carry a wrong `ALBUM` tag like `Album Name - Single` on a full album, and spam frames advertising the release site (seen from CORERADIO: `SUBTITLE`, `Comment`, `Organization`, `SOURCE`, `URL`, and a polluted `Copyright`). Fix the album name; delete the spam frames. Check with `kid3-cli -c 'get'` (shows all frames) rather than a filtered ffprobe grep — spam hides in unexpected frames.
- **Album title casing:** leave as-is unless the user asks (same rule as folder names).
- **m4a promo blocks:** files from YouTube/Bandcamp often stash huge promo text in the MP4 `Long Description` frame (ffprobe shows it as `synopsis`) plus yt-dlp `purl` frames. Clear with `kid3-cli -c "set 'Long Description' ''" -c 'save'` — frame names containing spaces need quotes *inside* the command string; `set "long description" ""` silently does nothing.
- **Library-wide spam scan:** dump every file's tags and grep for release-site patterns (`coreradio`, ripper sigs like `.:WRE:.` in `ENCODED BY`/`SUPPLIER`, tool ads, random `.ru` URLs in `COPYRIGHT`/`LOCATION`/`ORGANIZATION`). Expect false positives — Discogs/Wikipedia URL frames, label copyrights, official sites in `RELATED`, and song titles are legit; review before deleting.
- After tag fixes, remind the user to rescan their music player's library so changes appear.
- The user's `ls` is aliased to quote filenames — don't parse `ls` output into paths; use globs.
