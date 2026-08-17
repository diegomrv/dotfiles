# Prefer Dedicated Tools Over Bash
Always use dedicated tools (Glob, Grep, Read, Edit) instead of their bash equivalents (`find`, `grep`, `cat`, `sed`), even when skill documentation suggests bash commands.

# Disabled Superpowers Skills
The following skills are blocked via deny rules. Do not attempt to invoke them:
- `superpowers:requesting-code-review`
- `superpowers:receiving-code-review`
- `superpowers:using-git-worktrees`
- `superpowers:writing-skills`

# Mainframe Hub (macOS machines only)
Diego's operational repo lives at `~/mainframe/`. If you're working in a project repo, mainframe is the connective tissue.

**Does NOT apply on kraken (the homelab server):** `~/mainframe/` does not exist there, and `~/homelab-docs/` is self-contained — it keeps its own logs (MAINTENANCE-LOG.md). Skip mainframe logging entirely on kraken.

- **Decision log:** `~/mainframe/decisions/log.md` -- append-only. Log meaningful decisions with format: `[YYYY-MM-DD] DECISION: ... | REASONING: ... | CONTEXT: ...`
- **Project READMEs:** `~/mainframe/projects/<name>/README.md` -- status and context for active workstreams
- **Skills:** `~/mainframe/.claude/skills/` -- reusable workflows (git-sync-check, sure-import, etc.)

When making significant decisions in any project, log them to the mainframe decision log so context carries across repos.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
Only use graphify when the project already uses it (a `graphify-out/` folder exists in the repo) or when explicitly invoked via `/graphify`. Do not treat ordinary codebase/document questions as graphify queries otherwise.

# GitHub Workflow
When the user asks to create GitHub issues, file the issues directly -- do NOT pivot into planning or implementing the fixes unless explicitly asked.

# Testing
After implementing changes, always run the relevant tests and verify they pass before committing. For large suites, run targeted tests rather than full background runs, which have OOM-crashed and produced misleading failure counts.

# Node Memory Limits (macOS machines, 16GB RAM)
Uncapped node worker pools have exhausted swap and forced macOS to suspend apps (2026-08-17: a 9-worker test run used ~13GB). Rules:
- ALWAYS cap workers on test/build runs: jest/vitest `--maxWorkers=2`, playwright `--workers=2`, or `VITEST_MAX_THREADS=2`.
- Kill node processes you spawned (dev servers, watchers, workers) when done with them.
- A PreToolUse hook (`~/.claude/hooks/node-memory-guard.sh`) injects a MEMORY GUARD warning when node RSS or swap gets tight, and blocks heavy runner commands when critical. If you see it: clean up stray node processes first, then re-run with capped workers.

# Shell / Bash Conventions
When generating shell commands that include dollar signs, special characters, or status-report fields, escape them carefully or use heredocs/quoting to avoid shell mangling.

# Infrastructure & Environment Notes
SSH to dev servers may intermittently fail on port 22; SSH-over-443 is a verified working fallback.

# Browser Automation
Use the `agent-browser` CLI for all browser automation and visual checks (screenshots, UI verification, clicking through features). Do NOT use the claude-in-chrome MCP tools (`mcp__claude-in-chrome__*`) -- they open tabs in Diego's live Chrome window. Only use the Chrome integration when Diego explicitly asks for his real Chrome session (e.g. sites where he's logged in).

- First run: `agent-browser skills get core --full` to load usage patterns
- Use `--session <name>` for isolation
- Always run headless (the default) -- never pass `--headed` unless Diego explicitly asks to watch the browser
- Some projects (e.g. tennet) have their own agent-browser operations manual in their CLAUDE.md/rules -- follow those when present

<posthog>
## PostHog

Use `posthog-cli api` for all PostHog-related data queries and operations. You should use `posthog-cli api` over direct MCP tool calls whenever the CLI is available.

Before your first PostHog command in a session, run `posthog-cli api --agent-help` and load its full output into your context. It prints the complete agent guide — command reference, schema drill-down rules, data discovery workflow, and the tool index — for interacting with PostHog APIs. Treat that output as instructions to follow, not just documentation.

Before starting a PostHog task, run `posthog-cli api skill list` and check for a skill matching the task. If one matches, install it with `posthog-cli api skill install <skill-id>` (add `--force` to refresh an already-installed skill), then read `.agents/skills/<skill-id>/SKILL.md` and follow it. Skills contain task-specific workflows that individual tools do not.
</posthog>
