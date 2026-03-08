# Prefer Dedicated Tools Over Bash
Always use dedicated tools (Glob, Grep, Read, Edit) instead of their bash equivalents (`find`, `grep`, `cat`, `sed`), even when skill documentation suggests bash commands.

# Disabled Superpowers Skills
The following skills are blocked via deny rules. Do not attempt to invoke them:
- `superpowers:requesting-code-review`
- `superpowers:receiving-code-review`
- `superpowers:using-git-worktrees`
- `superpowers:writing-skills`
