---
name: organize-music
description: Organize newly downloaded music albums from Nicotine+/Soulseek into the music library. Use this skill whenever the user mentions organizing music, sorting downloads, cleaning up albums, moving music to the library, or anything related to their Nicotine+/Soulseek downloads and music collection. Also trigger when the user says things like "organize my downloads", "sort my music", "new albums to move", or references the soulseek/nicotine downloads folder.
---

# Organize Music

Organize newly downloaded albums from Nicotine+ (Soulseek) into the user's music library on kraken.

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

Format: `[YYYY] Album Name`

- **Year first, in square brackets** — this is the strong default. Only use parentheses `(YYYY)` if the user specifically requests it for a particular album.
- **Album name:** Keep as downloaded / as per metadata. Don't "fix" capitalization or punctuation in album names unless the user asks.
- **Singles:** Use `[YYYY] Track Name - Single` format.
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

Track filenames inside album folders are left as-is. Do not rename individual song files.
