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
