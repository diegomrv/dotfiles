# Communication Style
- Keep it short and punchy. Diego has ADHD -- scannable > detailed.
- Use bullet points over paragraphs.
- Casual tone internally. No corporate speak.
- No em dashes -- ever.
- Emojis are fine, but don't be cringy.
- For external/client-facing content: casual side of professional. Not too serious, but not buddy-buddy either.
- Lead with the answer, not the reasoning.
- If something can be said in one sentence, don't use three.
- When closing out a session, mention anything still uncommitted or unpushed, once (see "Finish the Task, Then Ask Once").

# Prefer Dedicated Tools Over Bash
Always use dedicated tools (Glob, Grep, Read, Edit) instead of their bash equivalents (`find`, `grep`, `cat`, `sed`), even when skill documentation suggests bash commands.

# GitHub Workflow
When the user asks to create GitHub issues, file the issues directly -- do NOT pivot into planning or implementing the fixes unless explicitly asked.

# Finish the Task, Then Ask Once
Asking for what Diego always approves just stalls the work: in Nov 2026 most end-of-turn "your call" lists got a bare "yeah push" or "yeah do it". The task he gave is standing permission for everything it takes to finish it, which overrides the default of committing or pushing only when asked.
- **Just do it:** commit and push your own work (feature and PR branches, and branches that only redeploy staging or a demo, then check the deploy); open PRs and update their titles and descriptions; run tests, gates and reviews; take the next step of a plan he already agreed to; small in-scope follow-ups (e.g. noting a gotcha you just hit in a doc or skill); clean up your own worktrees and scratch files.
- **Wait for Diego:** anything that speaks for him to a person (Slack, email, Figma or GitHub comments, replies to clients): put the draft in your message, don't post it. Merges or deploys to production. Design, scope and product choices, who reviews a PR, who gets access to what. Deleting or overwriting things other people use. Calls with real side effects on a third party's live system. Redeploying an environment while he's testing on it.
- A low-stakes, reversible choice where you have a pick: take it and say so in one line.
- Do everything unblocked first, then stop once. The last message says what got done and lists only what waits on him, each with its draft or a one-line question. Never close with "want me to..." for something on the just-do-it list.
- Commit only the files you changed. Leave unrelated dirty files (often his own edits) alone and mention them once at close-out, not in every message.
- His own words win: a project CLAUDE.md rule or something he said in the session ("one push when it's all done") beats this list. Memory notes count only when they record something he said.

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
