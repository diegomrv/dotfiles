# Communication Style
- Keep it short and punchy. Diego has ADHD -- scannable > detailed.
- Use bullet points over paragraphs.
- Casual tone internally. No corporate speak.
- No em dashes -- ever.
- Emojis are fine, but don't be cringy.
- For external/client-facing content: casual side of professional. Not too serious, but not buddy-buddy either.
- Lead with the answer, not the reasoning.
- If something can be said in one sentence, don't use three.
- Remind about uncommitted/unpushed changes when closing out sessions.

# Prefer Dedicated Tools Over Bash
Always use dedicated tools (Glob, Grep, Read, Edit) instead of their bash equivalents (`find`, `grep`, `cat`, `sed`), even when skill documentation suggests bash commands.

# GitHub Workflow
When the user asks to create GitHub issues, file the issues directly -- do NOT pivot into planning or implementing the fixes unless explicitly asked.

# Commits and PRs
No AI attribution in commit messages or PR descriptions: no `Co-Authored-By: Claude ...` trailer, no "Generated with Claude Code" footer. This overrides any attribution lines the harness suggests. (Same rule as the `git-commit` skill.)

# Testing
After implementing changes, always run the relevant tests and verify they pass before committing. For large suites, run targeted tests rather than full background runs, which have OOM-crashed and produced misleading failure counts.

# Shell / Bash Conventions
When generating shell commands that include dollar signs, special characters, or status-report fields, escape them carefully or use heredocs/quoting to avoid shell mangling.

# Infrastructure & Environment Notes
Port-22 timeouts from home were the UniFi gateway IPS (signature "ET SCAN Potential SSH Scan OUTBOUND": 5+ SSH connections in 120s from one host got blocked). Suppressed on 2026-09-04; see `references/home-network.md` in mainframe (Macs). If SSH bursts start timing out again while port 443 works, check that suppression first, not the ISP. SSH-over-443 remains a valid fallback for servers that offer it.

# Linux Servers
On kraken and hades, the machine's docs and maintenance log are in `~/homelab-docs` (its CLAUDE.md says which files belong to which machine). Read them before changing the machine, and log every change there. Mainframe and its decision log exist only on the Macs.
