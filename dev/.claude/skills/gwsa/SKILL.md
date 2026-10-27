---
name: gwsa
description: Google Workspace from the terminal through Diego's local `gwsa` wrapper (Gmail, Google Calendar, Drive, Sheets, Docs, Slides, Tasks, People and the rest of the `gws` surface). Use whenever a task reads or writes email, calendar events, Drive files, spreadsheets or documents in Diego's personal or StrangePixels Google accounts, when a request mentions Gmail, Calendar, Drive, Sheets or Docs, or before calling `gws` directly. Covers the invocation shape, account choice, --params vs --json, auth errors and footguns.
---

# Skill: gwsa

`gws` (the Google Workspace CLI) is single-account by design. `gwsa` is Diego's zsh wrapper that keeps one credential store per Google account and forwards every call to `gws` with the right `GOOGLE_WORKSPACE_CLI_CONFIG_DIR`. Every Google Workspace call from an agent goes through `gwsa`, never through bare `gws` (bare `gws` has no credentials, or the wrong account's) and not through the claude.ai Gmail / Calendar / Drive MCP tools unless Diego asks for them (they truncate Gmail bodies, cover a fraction of the surface and need Anthropic's cloud).

## Where it is

| | |
|---|---|
| Command | `gwsa` on PATH (`~/.local/bin/gwsa` → `~/projects/code/gwsa/gwsa`) |
| Repo | `~/projects/code/gwsa/` (README: Google Cloud setup, encryption, quirks) |
| Credentials | `~/projects/code/gwsa/credentials/<account>/credentials.enc`, Keychain-bound per machine. Never `cat` / `Read` these, `client_secret.json`, or any `token_cache.json` |
| Accounts | `personal` = Diego's `@gmail.com`. `work` = `@strangepixels.co` |
| Machines | Mac Mini (bahamut) and MacBook (highwind). `gws` via `brew install googleworkspace-cli`, never npm (PATH shadowing). Not on kraken |

**Default to `personal`.** Use `work` only when the context is clearly StrangePixels: `strangepixels.co` addresses, the work calendar (`diego@strangepixels.co`), client or team email threads.

## Shape

```
gwsa <account> <gws args...>     # forward to gws under that account
gwsa accounts                    # list configured accounts
gwsa whoami <account>            # auth check: runs `gws auth status` under that account
gwsa setup <account> -s drive,gmail,calendar,sheets,docs   # (re)login, see Failure modes
```

`whoami` prints the signed-in address (`user`), auth method, scopes and enabled APIs, and whether the token is valid.

The `gws` surface is `<service> <resource> <method>` mirroring the Google API: `gmail users messages list`, `calendar events insert`, `drive files create`. `gwsa personal <service> --help` lists resources; `gwsa personal --help` lists services. Unlisted APIs take `<api>:<version>` syntax.

## --params vs --json

- `--params` is query / URL parameters ONLY: identifiers and filters (`userId`, `calendarId`, `q`, `maxResults`, `timeMin`).
- `--json` is the request body: the resource being created or updated (event, message, file metadata).

Putting body fields in `--params` fails with confusing API errors (`calendar events insert` returns `400: Missing end time.` when the whole event sits in `--params`).

## Common invocations

Gmail:

```bash
gwsa personal gmail users getProfile --params '{"userId":"me"}'
gwsa personal gmail users messages list --params '{"userId":"me","q":"is:unread newer_than:1d","maxResults":25}'
gwsa personal gmail users messages get --params '{"userId":"me","id":"<msgId>","format":"full"}'
gwsa personal gmail users threads list --params '{"userId":"me","q":"label:Banks after:<unix_ts>","maxResults":100}'
gwsa personal gmail users threads get --params '{"userId":"me","id":"<threadId>","format":"full"}'
gwsa personal gmail users messages attachments get --params '{"userId":"me","messageId":"<msgId>","id":"<attachmentId>"}'
```

Calendar (always pass `timeZone` as `America/Mexico_City`):

```bash
gwsa personal calendar events list --params '{"calendarId":"primary","timeMin":"<RFC3339>","timeMax":"<RFC3339>","singleEvents":true,"orderBy":"startTime","timeZone":"America/Mexico_City"}'
gwsa work     calendar events list --params '{"calendarId":"primary","timeMin":"<RFC3339>","timeMax":"<RFC3339>","singleEvents":true,"orderBy":"startTime","timeZone":"America/Mexico_City"}'
gwsa personal calendar events insert --params '{"calendarId":"primary"}' --json '{"start":{"date":"YYYY-MM-DD"},"end":{"date":"YYYY-MM-DD"},"summary":"...","description":"..."}'
```

Drive:

```bash
gwsa personal drive files list --params "{\"pageSize\":10,\"q\":\"name contains 'report'\"}"
gwsa personal drive files create --json '{"name":"...","mimeType":"application/vnd.google-apps.spreadsheet"}' --upload file.xlsx   # xlsx -> native Sheet
```

Run independent calls (personal + work, several accounts or services) in parallel.

## Footguns

- **Don't redirect stderr into stdout.** `gws` prints `Using keyring backend: keyring` on stderr before the JSON. `gwsa ... | jq` is fine; `gwsa ... 2>&1 | jq` corrupts the JSON.
- **All-day events use an EXCLUSIVE `end.date`.** One day on July 10 is `{"start":{"date":"2026-07-10"},"end":{"date":"2026-07-11"}}`. Same start and end is rejected.
- **`--upload` paths must be inside the current directory.** `gws` rejects `--upload /tmp/file.xlsx` with `resolves to ... outside the current directory`. `cd` to the file's directory and pass a relative path.
- **Writes are real.** Sending mail, creating or deleting events, trashing messages and sharing files hit Diego's live accounts. Confirm before anything outward-facing or hard to undo; reads need no confirmation.
- **Never read the credential files** (see the table above). Surface errors verbatim instead.

## Failure modes

- **`401 invalid_grant: Token has been expired or revoked`**: the refresh token is dead (password change, 6 months unused, access revoked; the OAuth app has been In production since 2026-09-28, so the old 7-day Testing expiry no longer applies). Re-auth, Diego approves in the browser:

  ```bash
  (gwsa setup personal -s drive,gmail,calendar,sheets,docs > /tmp/gws_login.log 2>&1 &)
  # then: open "<url printed in the log>"; the local callback finishes the flow
  ```

- **`403: Caller does not have required permission to use project <id>`** (usually the first call from `work`): the account has no IAM role on the Cloud project that owns the OAuth client. The error includes the IAM grant URL; the fix is a one-time grant (Editor or Service Usage Consumer), not a re-login. The existing token works once it propagates (~30 s).
- **`gws: command not found`**: `brew install googleworkspace-cli`. `gwsa` itself is the symlink in `~/.local/bin`.
- Report the actual error message. Do not fall back to the claude.ai Gmail / Calendar / Drive MCPs on your own.

## Inside mainframe

Mainframe skills (`good-morning`, `bank-email-sweep`, `sure-import`) build on this. Mainframe-specific rules live in `~/mainframe/references/sops/gwsa.md`.
