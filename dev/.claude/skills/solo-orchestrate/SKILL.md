---
name: solo-orchestrate
description: "Run a big planned task unattended (overnight or while the user is away) — or accelerated with 2-3 parallel batch crews while the user is around — by orchestrating a fleet of Solo/Soloterm agents: PM agents that drive implementer and reviewer subagents, coordinated through Solo scratchpads/todos/kv and woken by push notifications + Solo timers. Use whenever the user wants to leave an agent working autonomously for hours, mentions night runs, unattended execution, 'keep working while I'm out', orchestrating subagents through Soloterm, or executing a multi-batch plan with PM/implementer/reviewer roles — even if they don't name Solo explicitly."
trigger: /solo-orchestrate
---

# /solo-orchestrate — Unattended multi-agent execution via Soloterm

Turn an approved, batched plan into an unattended execution run: this session (the ORCHESTRATOR)
spawns per-batch PM agents; each PM drives an implementer and an adversarial reviewer; everything
coordinates through Solo scratchpads/todos/kv; Solo timers wake the orchestrator between batches.
The user comes back to committed work and an execution log, not a stalled prompt.

Born from the tennet PR #272 night run (2026-07-21) — mechanics below were probe-verified live.
Extended 2026-07-22 from the same run's day shift: parallel batches, push-wake protocol, field
gotchas.

## The one hard constraint

**The orchestrator session MUST be a Solo-managed process.** Solo timers can only deliver to Solo
agent processes — an externally-attached session (plain terminal + Solo MCP) can spawn and drive
agents but CANNOT be woken by timers (`timer_* tools require delivery_process_id when the current
actor is not a Solo-managed process`). Check first:

- `mcp__solo__whoami` → has a `process_id` → you're Solo-managed, proceed.
- External actor → tell the user to relaunch the orchestrator inside Soloterm (state lives in
  scratchpads, so nothing is lost), or offer the fallback: spawn ONE long-lived Solo orchestrator
  agent that runs the loop while this session just kicks it off.

## Intake — settle these with the user BEFORE anything runs

Unattended means nobody can answer questions at 3am. Every ambiguity you leave open now becomes a
stalled or misguided batch later. Establish:

1. **The plan**: a scratchpad id (preferred — all agents can read it) or a file to copy into one.
   It must already be decomposed into ordered batches/phases with explicit file-ownership or
   dependency constraints. If it isn't, do that decomposition WITH the user first — don't improvise
   it unattended.
2. **Commit policy**: commits require explicit per-run authorization from the user — never assume
   it. The proven pattern: pre-authorized LOCAL commits per batch after the full review chain, one
   commit per batch, conventional message naming the batch. **Pushing is never pre-authorized**
   (deploys may hang off push hooks — e.g. pushing tennet's `alpha` auto-deploys staging).
3. **Hard rules**: per-project irreversible actions the night crew must never touch (deploy
   targets, webhooks, real databases, external APIs, seeding). Write them into the run spec —
   agents can't know them by instinct.
4. **Pacing**: sequential (one crew alive at a time) vs parallel (2-3 batch crews) is a dial,
   not a mode. Parallel is authorized attended AND unattended (Diego, 2026-07-22) whenever the
   "Parallel batches" conditions hold, and the orchestrator sizes concurrency to the live usage
   budget at every transition (see "Budget-aware pacing"). Fall back to sequential whenever
   disjointness can't be proven. Add fixed timer gaps between batches only if the user wants
   spend spread further.
5. **Review chain**: default is implementer (Opus) → adversarial reviewer (Codex) → PM final quick
   review → commit. Confirm models with the user.

## Probe first

Before trusting a whole night to the mechanics, spend two minutes verifying them — Solo agent-tool
configs and CLI flags drift:

1. `mcp__solo__list_agent_tools` → note the Claude and Codex tool ids.
2. Spawn a throwaway Claude agent, send "reply OK", confirm output, confirm it can call
   `mcp__solo__whoami` (spawned agents auto-identify with full Solo MCP).
3. Set a 10s `timer_set` targeting it, confirm the body arrives as a user turn.
4. Spawn a throwaway Codex agent with the intended model/flags, confirm the banner shows the right
   model.
5. `close_process` both probes.

If any step fails, fix the invocation now and record the working one in the run spec.

## Verified mechanics (probed 2026-07-21, may drift — re-probe if in doubt)

- `spawn_agent(agent_tool_id, name, extra_args)` spawns a real CLI session in the project cwd.
  Claude spawns default to **plan mode and the session-default model** — always pass mode/model
  args explicitly.
- Claude agents: `["--permission-mode","auto"]` ran artisan, pint, `git log`, and
  `git commit --dry-run` with zero permission prompts while keeping deny rules active. Prefer it
  over `--dangerously-skip-permissions`; fall back to the latter only if a probe shows auto mode
  prompting on commands the run needs.
- Model overrides: `["--model","opus"]` etc. Codex: `["--model","<model>","--sandbox","read-only",
  "--ask-for-approval","never"]` — read-only suffices for a reviewer.
- `timer_set(delay_ms, body, delivery_process_id)` injects `body` verbatim as a fresh user turn.
  Write bodies self-contained (ids, scratchpad numbers, next action) — the receiver may have no
  other context. `timer_fire_when_idle_any([pids], max_wait_ms, body)` is the primary wake signal;
  `max_wait_ms` is a hard deadline, not a poll interval.
- `close_process(id)` removes an agent. Close crew members when their batch is accepted — fresh
  agents per batch keep context small and tokens bounded.

## Roles

- **Orchestrator (this session)**: spawns/wakes/closes PMs, tracks kv state, escalates blocks,
  writes the completion report. Does NOT implement or review.
- **PM (one per batch)**: reads the plan section + evidence, spawns and drives the implementer,
  then the reviewer, triages findings, fix-forwards, runs the final quick review (diff vs plan,
  targeted tests green, formatter clean), commits if authorized, stamps kv + log, reports, pushes
  the orchestrator a one-line closeout notification, goes idle.
- **Implementer**: implements the batch per plan, writes the batch's tests.
- **Reviewer**: adversarial diff review against the plan section (conformance, correctness, missed
  findings, test quality). Findings go to the PM, not straight to the implementer.

## Coordination fabric

Namespace everything by a run slug (e.g. `pr272`):

- **Todos**: one per batch at kickoff; PM completes its own.
- **KV**: `<slug>:current_batch` = `{n, status: implementing|reviewing|fixing|committed|blocked}`;
  `<slug>:batch:<n>:commit` = sha; `<slug>:blocked` = `{batch, reason}`.
- **Execution log**: a dedicated scratchpad created at kickoff. Per batch the PM appends: files
  changed, test results, reviewer findings + dispositions, commit sha, deviations from plan, open
  questions. This log IS the morning deliverable — write it for the user, not for other agents.

## The loop

1. **Kickoff**: create todos, execution-log scratchpad, kv state; confirm the run spec (plan
   scratchpad section pointers, commit policy, hard rules) is written down where PMs will read it.
2. **Per batch**: spawn PM → send a kickoff prompt containing: batch number, plan + evidence
   scratchpad pointers, todo id, log id, review chain, commit policy, hard rules, and the
   instruction to spawn its own implementer/reviewer and close them when done.
3. **Wake yourself — push first, poll last** (full rationale in "Wake protocol" below): every
   PM's kickoff instructs it to `send_input` the orchestrator a one-line push at closeout
   ("BATCH n COMMITTED <sha> — todo done, report in #80, crew closed") and on block ("BATCH n
   BLOCKED — see <slug>:blocked"), so transitions fire instantly. Back it with
   `timer_fire_when_idle_any([pm_pid], ~60min, "<self-contained instructions: check kv + log;
   committed → close crew, start batch n+1; blocked → decide per dependency constraints or stop
   with a report>")` PLUS a ~30min looping heartbeat timer as backstop (an agent sitting on a
   rare permission prompt registers as busy, not idle — the heartbeat catches it; read its PTY
   with `get_process_output` and unstick or restart). Cancel stale timers when a batch closes.
4. **Rate limits**: if agents stall on usage-block limits, don't churn — one-shot timer +60-90min,
   retry the SAME batch with a fresh PM.
5. **Blocked protocol**: plan ambiguity or unexpected reality → the PM writes `<slug>:blocked` +
   a log entry and stops that batch; it never guesses. The orchestrator skips ahead ONLY when the
   dependency/file-ownership constraints prove the next batch independent; when in doubt, stop the
   chain — an early stop with a clear report beats a night of compounding on a wrong guess.
6. **Completion report** (final log entry): batches completed, commit shas, test status, reviewer
   findings summary, blocked items, decisions needed. Then close remaining processes and cancel
   remaining timers — leave nothing running.

## Wake protocol — event-driven without false fires

Idle detection has a false-positive problem: implementer CLIs "blip" idle between turns, and when
a PM drip-feeds instructions, the gap between instruction N and N+1 is GENUINE idleness — no
detector can tell it from done. Layer three signals, in this order:

1. **Push (primary — zero latency, zero false fires)**: completion announces itself. Spawned Solo
   agents carry Solo MCP, so a worker's brief ends with "your LAST action: send_input to process
   <supervisor pid> one line: 'IMPL DONE — report above'"; PM closeouts push the orchestrator the
   same way ("BATCH n COMMITTED <sha>"). Inference from idleness stops mattering.
2. **Idle-watch with fire-then-verify (backstop for a dead or forgetful worker)**: keep
   `timer_fire_when_idle_any` armed (~15min ceiling attended, longer overnight), and write the
   body defensively: "read the PTY tail; if it shows an active spinner/mid-work, re-arm this same
   watch". That turns blip false-fires from a correctness bug into a small token cost.
3. **Looping heartbeat (backstop for states Solo can't see)**: permission prompts register busy,
   not idle; crashes and rate-limit stalls produce neither idle nor push. A dumb ~30min loop
   catches all of them.

Shrink the blip surface too: one big self-contained brief per phase instead of drip-feeding makes
idle ≈ done. Fixed-interval polling as the PRIMARY signal is the anti-pattern — the interval is
guaranteed average dead time per phase. Check whether Soloterm has grown `sustained_idle_ms`
debounce or pattern-triggered wakes ("fire when output matches /DONE/") — either would make
completion host-detected; request them via `submit_solo_feedback` if still missing.

## Parallel batches (2-3 at a time)

Parallel saves wall-clock AND orchestration overhead (fewer wake-turns per batch-hour). Run 2-3
batches concurrently — attended or unattended — ONLY when all of these hold:

- **Provable file disjointness**: the plan's file-ownership table shows no shared files between
  the candidate batches, and none of its sequenced-constraint files are touched by either.
  "Probably fine" is not proof. A polish/cleanup batch that sweeps many areas overlaps everything
  — it stays last, gated on ALL batches whose files it revisits.
- **Explicit boundaries in every kickoff**: each PM gets a do-not-touch list naming the files the
  OTHER live batches own, relays it verbatim to its implementer, and BLOCKS (not edits) if an
  item seems to require crossing it.
- **Git serialization via lease lock**: `lock_acquire('<slug>:git', 600s)` → stage ONLY your
  batch's files explicitly by path (never `git add -A` / `git add .`) → verify
  `git diff --cached --name-only` shows zero foreign files → commit → `lock_release`. Lock held →
  wait ~60s, retry.
- **KV ownership split**: in parallel mode the ORCHESTRATOR owns `<slug>:current_batch` (a PM's
  blind closeout write would clobber the other batch's entry); each PM's completion signal is its
  own `<slug>:batch:<n>:commit` key + push message. Per-batch commit keys are the ground truth.
- **Budget + adaptability**: parallel multiplies token burn-rate — size concurrency to the live
  usage budget (see "Budget-aware pacing"). Unattended parallel is authorized (Diego,
  2026-07-22): the orchestrator may regroup, reorder, or split batches dynamically so long as
  file-disjointness stays provable; when it can't be proven, run sequential instead of guessing.

## Budget-aware pacing (usage % + block time)

Every spawned Claude agent's PTY footer renders live usage data the orchestrator can read with
`get_process_output` at any time — no extra tooling:

    Model: Fable 5 | ⎇ alpha | (+2987,-341)
    Block: 4hr 31m | Ctx(u) Used: 27.0% | Session: 30.0%

`Block` = time elapsed in the current 5-hour usage block; `Session` = share of the allowance
consumed. All agents draw on the same account, so any live footer reflects the fleet. The weekly
per-model cap is separate — footers only surface it as a warning when close; for detail, send
`/usage` to an IDLE agent's TUI, read the panel via `get_process_output`, then Escape (do this
only at major decision points, it's intrusive). Usage-limit stalls announce themselves in the PTY
("limit reached, resets at ..."), which the heartbeat catches.

Sample at EVERY batch transition and size the next move:

- **Low usage** (< ~50%): fan out — 2-3 disjoint batches, or pull smaller batches forward.
- **High usage** (> ~80%): finish in-flight work, then at most ONE small batch — or park the
  chain with a one-shot timer at the block/limit reset and a log entry saying why.
- **Block nearly over + usage near cap**: don't start a heavy batch that will stall mid-flight;
  queue it for after the reset. A parked chain with a clear log beats three agents frozen on the
  same limit message.
- Log every budget decision to the execution log — the user should be able to see why the chain
  sped up, slowed down, or paused.

## Context hygiene — compact workers in the review window

Fix-forward chains balloon the implementer's context (implement → report → fix rounds 1..n); past
~50% quality degrades and ghost-text risk rises. The reviewer's window is the implementer's idle
window — compaction there costs zero wall-clock. PM protocol:

- When dispatching a review/delta-review, check the implementer's footer (`Ctx(u)`): above ~40% →
  send it `/compact <focus>` while the reviewer works. The focus names what must survive: the
  batch's item list + files touched, fixes applied so far, test commands, hard rules, and the
  IMPL-DONE push protocol.
- Compact only AFTER the implementer has delivered its round report — its state then lives in the
  PTY and the PM's hands, so compaction can't lose anything load-bearing. Never mid-work.
- Verify the PTY shows compaction completed before sending the next fix round.
- Past ~70%, or after ghost-text/degradation: don't compact — close and respawn a fresh
  implementer with a delta brief (agents are disposable; scratchpads + the diff carry the state).
- PMs watch their own footer too on long batches; same thresholds, compact between phases.

## Field gotchas (all hit live — don't relearn them at 3am)

- **PM idle ≠ batch done**: PMs idle between their own timers. Watch/route on whichever process
  is actually BUSY, not the PM by default.
- **PTY ghost text**: frozen text stuck in an agent's input box surviving Escape/Ctrl+U → don't
  fight it: capture the agent's report from the PTY, `close_process`, respawn fresh. (Benign
  variant: stale renders that clear on next output — check twice before nuking.)
- **Never `git checkout --` on files carrying uncommitted batch work** — a PM reset a
  mid-mutation-check file to HEAD and the work had to be reconstructed from captured diffs. Say it
  in every kickoff.
- **Formatter-hook import races**: an auto-format hook (e.g. Pint on PostToolUse) can strip a
  momentarily-unused import between edit and commit. Deadliest in namespace-less files
  (`routes/*.php`) where `Foo::class` then silently degrades to the bare string `"Foo"` and a
  test asserting the bare word still passes. After the FINAL format pass, re-grep the `use` lines;
  write tests asserting FQNs.
- **Hard rules go in EVERY brief, not just the PM's**: an implementer ran a forward-only `migrate`
  on the real dev DB because the no-real-DB rule lived one level up. PMs relay hard rules verbatim
  to workers.
- **Stale line refs**: plan line numbers rot as batches land. Every kickoff says "locate by
  content, not line"; good PMs re-verify anchors against source BEFORE briefing the implementer.
- **Carry cautions forward**: each kickoff includes the accumulated cross-batch cautions
  (preservation rules for earlier batches' changes, known races, rebase notes). The kickoff is the
  only context a fresh PM has.
- **PM verifies, never relays blindly**: reviewer findings and implementer claims get checked
  against source by the PM personally before dispatching fixes or accepting reports.

## Why these choices (so you can adapt, not just obey)

- Sequential contains failures to one batch; provably-disjoint parallel batches flip the trade —
  same review rigor, less wall-clock, fewer orchestrator wakes. The gate is disjointness proof +
  budget headroom, not whether the user is watching.
- Push over poll: a polling interval is guaranteed average dead time; a push at closeout costs one
  tool call and makes transitions instant. Polls survive only as backstops.
- Fresh agents per batch: context accumulation degrades long sessions; the scratchpads carry the
  state, so agents are disposable.
- Reviewer is a different model family: diverse-lens review catches what author-family review
  misses.
- Idle-timer + heartbeat: idle detection is the precise signal, but only for states Solo can see;
  the dumb heartbeat is the insurance for the states it can't.
