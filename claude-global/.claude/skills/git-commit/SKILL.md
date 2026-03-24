---
name: git-commit
description: Commit, push, and create PRs with project-specific git workflow rules. Triggers on "commit", "commit and push", "push this", "create a PR", "open a PR", "ship it", or any request to commit/push/PR code changes.
---

# Git Commit & Push

Handles committing, pushing, and PR creation with Diego's workflow rules baked in.

## Workflow Rules

These rules are non-negotiable:

- **Default PR target:** `develop` branch (unless explicitly told otherwise)
- **Warn before pushing to main/master** -- always confirm first
- **Check remote exists** before pushing -- don't retry blindly if it fails
- **Never skip hooks** -- if pre-commit fails, fix the issue and create a NEW commit (don't amend)
- **Never force push** unless explicitly asked
- **Don't commit secrets** -- skip .env, credentials.json, etc. Warn if asked to commit them

## Modes

Detect the intent from context:

| User says | Action |
|-----------|--------|
| "commit" / "commit this" | Commit only |
| "commit and push" / "push this" | Commit + push |
| "create a PR" / "open a PR" / "ship it" | Commit + push + PR |

## Commit Flow

1. Run `git status` and `git diff` (staged + unstaged) in parallel
2. Run `git log --oneline -5` to match the repo's commit message style
3. Stage relevant files (prefer specific files over `git add .`)
4. Draft a concise commit message -- focus on the "why", match repo style
5. Create the commit with attribution:
   ```
   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```
6. Run `git status` after to verify

## Push Flow (if pushing)

1. Check the current branch has a remote tracking branch
2. If no remote, set upstream with `git push -u origin <branch>`
3. If on main/master, **STOP and confirm** with Diego before pushing
4. Push and verify

## PR Flow (if creating PR)

1. Check if on main -- if so, create a feature branch first
2. Push the branch
3. Create PR with `gh pr create`:
   - Target: `develop` (unless told otherwise)
   - Title: short, under 70 chars
   - Body format:
     ```
     ## Summary
     <1-3 bullet points>

     ## Test plan
     <checklist>

     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     ```
4. Return the PR URL

## Important

- Use HEREDOC for commit messages to preserve formatting
- Always pass the commit message via `cat <<'EOF'` pattern
- If there are no changes to commit, say so -- don't create empty commits
- After completing, show a brief summary of what was done (branch, commit hash, PR URL if applicable)
