# Mainframe Hub
Diego's operational repo lives at `~/mainframe/`. If you're working in a project repo, mainframe is the connective tissue.

- **Decision log:** `~/mainframe/decisions/log.md` -- append-only, for **cross-cutting** decisions only (machines, network, tools and workflow, money, which project gets time). Format: `[YYYY-MM-DD] DECISION: ... | REASONING: ... | CONTEXT: ...`, one or two lines.
- **Project READMEs:** `~/mainframe/projects/<name>/README.md` -- status and context for active workstreams
- **Skills:** `~/mainframe/.claude/skills/` -- reusable workflows (git-sync-check, sure-import, etc.)

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

## Known bug: `os error 35` on heavy pages -- IT'S A FALSE NEGATIVE (as of 0.38.1)

Upstream issue: https://github.com/vercel-labs/agent-browser/issues/322 (open since Jan 2026)

On render-heavy pages, commands print an error and exit non-zero:
`Failed to read: Resource temporarily unavailable (os error 35) (after 5 retries - daemon may be busy or unresponsive)`

**The operation actually succeeded.** Verified on 0.38.1: `screenshot --full` on a 60,520px Wikipedia page printed this error, then wrote a correct 1280x60520 / 21MB PNG. Reported on `open` too. The CLI just gives up reading the daemon's reply before the work finishes.

- It's agent-browser's Rust IPC layer, NOT macOS. Don't chase it as an OS bug.
- Root cause (per issue comments): the daemon calls Playwright without timeouts and hangs; the Rust CLI's socket read gives up after 5 retries. Retry logic shipped, the hang never got fixed.
- Trigger is render complexity/duration, not page height. Plain tall pages (30k px) are fine; Wikipedia-class pages fail every time. Viewport screenshots are unaffected.
- The daemon survives (same PID) and the session stays usable -- keep going after the error.
- **Do not trust the error or exit code. Verify the real outcome:** wait a few seconds, then check the file (`sips -g pixelWidth -g pixelHeight <file>`) or `agent-browser get url`.
- **`AGENT_BROWSER_DEFAULT_TIMEOUT` does not fix it and actively lies.** Setting it changes the browser launch hash, silently relaunching a blank browser -- you get `✓ Screenshot saved` with a tiny 1280x577 file instead of the real page. A green checkmark is weaker evidence than the error.

<posthog>
## PostHog

Use `posthog-cli api` for all PostHog-related data queries and operations. You should use `posthog-cli api` over direct MCP tool calls whenever the CLI is available.

Before your first PostHog command in a session, run `posthog-cli api --agent-help` and load its full output into your context. It prints the complete agent guide — command reference, schema drill-down rules, data discovery workflow, and the tool index — for interacting with PostHog APIs. Treat that output as instructions to follow, not just documentation.

Before starting a PostHog task, run `posthog-cli api skill list` and check for a skill matching the task. If one matches, install it with `posthog-cli api skill install <skill-id>` (add `--force` to refresh an already-installed skill), then read `.agents/skills/<skill-id>/SKILL.md` and follow it. Skills contain task-specific workflows that individual tools do not.
</posthog>
