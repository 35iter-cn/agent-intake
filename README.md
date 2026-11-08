# agent-intake

Intake scans for coding agents. An `agent-relay` loop round every 30 minutes reads
three sources — a GitHub project board, the open issues of a backend repository, and
one Slack channel — and posts de-duplicated candidates into the Slack channel the
relay serves (replying in that message's thread is how a candidate gets picked up).

The loop is a **trigger**, not a scanner: the scanning logic lives in the
`task-radar` skill that `pi` has installed, and the scheduling, per-round session,
message delivery, round history and failure handling all live in `agent-relay`.
This repository only owns the round prompts and the state contract, which is why it
has no dependencies, no script and no tests.

## Structure

```
agent-intake/
├── prompts/loop.md        the loop prompt relay stores: pointer + delivery rules
└── prompts/scan.md        the round procedure, read at run time by every round
```

`loop.md` is copied into the relay state when the loop is created or updated;
`scan.md` is read from this checkout on every round, so a procedure change takes
effect on the next round without touching the loop.

## Requirements

- `agent-relay` running the target platform, with its own config under
  `~/.config/agent-relay/` (the channels and credentials are resolved there, never
  here). The loop runs inside that daemon: `pi` is started by relay.
- The `task-radar` skill installed for `pi` (`~/.pi/agent/skills/task-radar`), which
  owns the scanners under `scripts/` and the reference docs under `references/`.

## Configuration

Deployment identifiers live outside the repository, in
`~/.config/agent-intake/intake.env` (mode `600`). The round reads it for the Slack
channel it scans, so nothing site-specific is committed:

```sh
AGENT_INTAKE_SLACK_CHANNEL=C0000000000
AGENT_INTAKE_SLACK_LABEL=#channel
```

The state file path is fixed at `~/.config/agent-intake/state.json`.

## State and logs

- `~/.config/agent-intake/state.json` — the watermarks: `channels`,
  `lastBoardKnownIssues`, `lastBoardScan`, `backendKnownCandidates`. Written only as
  "read, change the keys, tmp + rename" inside the round.
- Relay owns the round history: `agent-relay loop log <id>` for one line per round
  (`ok` / `noop` / `failed`) and `agent-relay loop show-run <runId>` for that round's
  output; the raw rows are in `~/.config/agent-relay/loops/<id>.jsonl`.
- The daily memory log gets one line per round; a round with nothing to report ends
  with `NOOP`, which relay does not deliver.

The `task-radar` skill reads and writes the same `state.json`; a manual skill run and
a loop round therefore share one watermark.

## Install

```bash
agent-relay loop create --platform slack --cron "*/30 * * * *" \
  --prompt-file ~/code/agent-intake/prompts/loop.md
```

The schedule is wall-clock aligned on purpose: an `--every 30m` loop drifts with
round duration, and the watermarks already tolerate a late or missed round.

## Deploying

```bash
git -C ~/code/agent-intake pull --ff-only
```

A `scan.md` change is live on the next round — no install step. A `loop.md` change
needs the stored copy refreshed:

```bash
agent-relay loop update <id> --prompt-file ~/code/agent-intake/prompts/loop.md
```

Run one round by hand with `agent-relay loop run <id>`, then read
`agent-relay loop log <id>` and `agent-relay loop show-run <runId>`; a failed round
counts towards relay's "3 in a row pauses the loop" rule.

## Privacy

Nothing in this repository names a channel, a group, a project board, an
organisation or a host; those live in `~/.config/agent-intake/intake.env` and in the
`agent-relay` config. Credentials are never read here — `agent-relay` owns them.
Keep it that way when editing: see `AGENTS.md`.
