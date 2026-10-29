# agent-intake

Timer-driven intake loop for coding agents. Every 30 minutes it starts one
`pi --print` session that reads three sources — a GitHub project board, the open
issues of a backend repository, and one Slack channel — and reports de-duplicated
candidates through `agent-relay notice emit`.

The loop is a **trigger**, not a scanner: the scanning logic lives in the
`task-radar` skill that `pi` has installed, and the notice delivery lives in
`agent-relay`. This repository only owns the schedule, the round prompt and the
state contract, which is why it has no dependencies and no tests.

## Structure

```
agent-intake/
├── intake.sh              flock, log rotation, prompt assembly, exec pi
├── prompts/scan.md        the fixed per-round prompt
└── systemd/
    ├── agent-intake.service
    └── agent-intake.timer
```

## Requirements

- `pi` on `PATH` (override with `AGENT_INTAKE_PI`).
- The `task-radar` skill installed for `pi` (`~/.pi/agent/skills/task-radar`).
- `agent-relay` on `PATH`, with its own config under `~/.config/agent-relay/`
  (the notice target and credentials are resolved there, never here).
- A `PATH` that contains those binaries. `PATH` is owned by the systemd user
  environment (`~/.config/environment.d/*.conf`); neither the unit nor the
  script sets it.

## Configuration

Deployment identifiers (channel id, channel label, notice platform) live outside
the repository, in `~/.config/agent-intake/intake.env` (mode `600`). `intake.sh`
sources it when present and injects its values into the prompt as a
`【运行配置】` block, so nothing site-specific is committed:

```sh
AGENT_INTAKE_SLACK_CHANNEL=C0000000000
AGENT_INTAKE_SLACK_LABEL=#channel
AGENT_INTAKE_NOTIFY_PLATFORM=feishu
```

Optional overrides: `AGENT_INTAKE_CONFIG`, `AGENT_INTAKE_LOGS`, `AGENT_INTAKE_STATE`,
`AGENT_INTAKE_PI`.

## State and logs

- `~/.config/agent-intake/state.json` — the watermarks: `channels`,
  `lastBoardKnownIssues`, `lastBoardScan`, `backendKnownCandidates`. Written only
  as "read, change the keys, tmp + rename" inside the round.
- `~/.config/agent-intake/logs/intake/<YYYY-MM-DD-HHMM>.jsonl` — one file per
  round, stdout/stderr of the `pi` session, rotated after 72 hours.

The `task-radar` skill reads and writes the same `state.json`; a manual skill run
and a timer round therefore share one watermark.

## Install

```bash
ln -sf ~/code/agent-intake/systemd/agent-intake.service ~/.config/systemd/user/
ln -sf ~/code/agent-intake/systemd/agent-intake.timer   ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now agent-intake.timer
```

## Deploying

The timer starts `intake.sh` fresh on every fire, so a script or prompt change
takes effect on the next round — no restart. A unit change needs
`systemctl --user daemon-reload`; a `PATH` change needs the user manager to
re-read `~/.config/environment.d/` (`systemctl --user daemon-reexec` or a fresh
login).

Run one round by hand with `~/code/agent-intake/intake.sh` (it takes the lock and
writes the same files the timer would).

## Privacy

Nothing in this repository names a channel, a group, a project board, an
organisation or a host; those live in `~/.config/agent-intake/intake.env` and in
the `agent-relay` config. Credentials are never read here — `agent-relay` owns
them. Keep it that way when editing: see `AGENTS.md`.
