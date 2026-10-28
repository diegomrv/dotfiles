# Mainframe Hub
Diego's operational repo lives at `~/mainframe/` (Macs only): project status in `projects/<name>/README.md`, the cross-cutting decision log in `decisions/log.md`, shared skills in `.claude/skills/`. Its `CLAUDE.md` has the rules.

Project decisions (PRs, client calls, design or scope choices) go in that project's own repo (e.g. `docs/decisions.md`), NOT the mainframe log. Only log there when a decision reaches beyond the project.

# Remote Sessions (herdr --remote)
**Assume Diego is sitting at the machine this session runs on.** Occasionally he drives bahamut from his MacBook with `herdr --remote`, but nothing inside a pane tells you that (`HERDR_ENV=1` is set either way), so never infer it.

- Bring up "remote" only when a file he says he just downloaded/saved is genuinely missing on this machine (`No such file`, and `mdfind -name` finds nothing). Then ask in one line whether he's on the MacBook; if so, he copies it to `~/Desktop` on bahamut.
- `Operation not permitted` / EPERM on `~/Downloads`, `~/Desktop` or Google Drive is NOT a missing file: macOS privacy (TCC) is blocking this session. Usually the herdr server is older than a Ghostty permission change, and only restarting herdr itself fixes it. Meanwhile ask him to drag the file into iCloud Drive, which stays readable.
- Never suggest copying things to the MacBook, or saving output somewhere because it syncs to the MacBook, unless he asks.

# Obsidian
Diego's personal notes are an Obsidian vault at `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Wolfius Vault/` (plain Markdown, iCloud-synced between Mac Mini and MacBook, not on kraken). It is his reading layer, not a replacement for repo docs. Before writing there, read the `obsidian` skill (`~/.claude/skills/obsidian/SKILL.md`): layout, conventions, what belongs (short dated status, decisions, inventories, pointers) and what doesn't (logs, code, secrets, copies of repo docs). The `obsidian` MCP server only connects while Obsidian.app is open; otherwise use the files directly.

# Google Workspace
Gmail, Google Calendar, Drive, Sheets and Docs are reached through `gwsa`, Diego's local multi-account wrapper around the `gws` CLI. Accounts: `personal` (gmail.com, the default) and `work` (strangepixels.co). Never call `gws` bare: it has no credentials, or the wrong account's. Prefer `gwsa` over the claude.ai Gmail / Calendar / Drive MCP tools unless Diego asks for them. Load the `gwsa` skill (`~/.claude/skills/gwsa/SKILL.md`) before the first call: invocation shape, `--params` vs `--json`, auth errors.

# Node Memory Limits (16GB RAM Macs)
Uncapped node worker pools have exhausted swap and forced macOS to suspend apps (2026-08-17: a 9-worker test run used ~13GB). Rules:
- ALWAYS cap workers on test/build runs: jest/vitest `--maxWorkers=2`, playwright `--workers=2`, or `VITEST_MAX_THREADS=2`.
- Kill node processes you spawned (dev servers, watchers, workers) when done with them.

# Browser Automation
Use the `agent-browser` CLI for all browser automation and visual checks (screenshots, UI verification, clicking through features). Do NOT use the claude-in-chrome MCP tools (`mcp__claude-in-chrome__*`) -- they open tabs in Diego's live Chrome window. Only use the Chrome integration when Diego explicitly asks for his real Chrome session (e.g. sites where he's logged in).

- First run: `agent-browser skills get core --full` to load usage patterns
- Use `--session <name>` for isolation
- Always run headless (the default) -- never pass `--headed` unless Diego explicitly asks to watch the browser
- Some projects (e.g. tennet) have their own agent-browser operations manual in their CLAUDE.md/rules -- follow those when present

## Screenshots fail with `os error 35` while the display sleeps

Verified 2026-10-28 on 0.40.0 (bahamut): with the displays asleep, every `screenshot`, even a viewport shot of example.com, prints `Failed to read: Resource temporarily unavailable (os error 35)` and writes no file, while `open` and `get url` keep working. With the display awake, a full-page Wikipedia screenshot (1280x83554) saved fine.

- Before screenshots, keep the display awake: start `caffeinate -du -t 300` in the background. It's harmless when the display is already on. `system_profiler SPDisplaysDataType | grep 'Display Asleep'` shows the state.
- If a screenshot still fails after waking the display, `close` the session and open a new one.
- Check the file, not the exit code: `sips -g pixelWidth -g pixelHeight <file>`.
- `AGENT_BROWSER_DEFAULT_TIMEOUT` doesn't help (seen on 0.38.1): changing it relaunches a blank browser, and you get `✓ Screenshot saved` with a tiny 1280x577 file.
