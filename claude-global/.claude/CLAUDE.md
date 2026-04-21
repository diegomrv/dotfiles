# Prefer Dedicated Tools Over Bash
Always use dedicated tools (Glob, Grep, Read, Edit) instead of their bash equivalents (`find`, `grep`, `cat`, `sed`), even when skill documentation suggests bash commands.

# Disabled Superpowers Skills
The following skills are blocked via deny rules. Do not attempt to invoke them:
- `superpowers:requesting-code-review`
- `superpowers:receiving-code-review`
- `superpowers:using-git-worktrees`
- `superpowers:writing-skills`

# Mainframe Hub
Diego's operational repo lives at `~/mainframe/`. If you're working in a project repo, mainframe is the connective tissue.

- **Decision log:** `~/mainframe/decisions/log.md` -- append-only. Log meaningful decisions with format: `[YYYY-MM-DD] DECISION: ... | REASONING: ... | CONTEXT: ...`
- **Project READMEs:** `~/mainframe/projects/<name>/README.md` -- status and context for active workstreams
- **Skills:** `~/mainframe/.claude/skills/` -- reusable workflows (git-sync-check, sure-import, etc.)

When making significant decisions in any project, log them to the mainframe decision log so context carries across repos.
