# AGENTS.md

Conventions for anyone — human or agent — changing this repository. Read
`README.md` first: its **Structure**, **Configuration** and **Privacy** sections
are the contract and are not repeated here.

## Non-negotiables

- **Never commit to `main` directly.** Branch, push, open a PR, squash-merge.
- **Nothing site-specific in the tree.** Channel ids, group names, board or
  organisation names, hostnames, tokens and absolute home paths stay in
  `~/.config/agent-intake/` or `~/.config/agent-relay/`. The prompt receives them
  as a `【运行配置】` block at run time.
- **No cross-repository references.** This repo talks to the outside world through
  three channels only: a CLI on `PATH` (`agent-relay`), a skill that `pi` has
  installed (`task-radar`), and the data contract under
  `~/.config/agent-intake/`. Never write another repository's path or URL here.
- **External binaries are called by name.** `PATH` is owned by the systemd user
  environment (`~/.config/environment.d/`); neither the unit nor `intake.sh` sets
  or rewrites `PATH`. A single override is allowed per binary
  (`AGENT_INTAKE_PI`), and its value may be an absolute path when PATH is broken.
- **The round is read-only towards its instance root.** The only writes are the
  external `state.json`, the round log, the memory daily log and one notice.

## Tests

There are none, deliberately: the moving part is 30 lines of `flock` + `exec`, and
its behaviour is visible in `logs/intake/<round>.jsonl` plus `state.json`. Verify a
change by running one round by hand and reading those two files; a change that
alters the prompt must be checked against a real round before it is merged.

## Deploying

```bash
git -C ~/code/agent-intake pull --ff-only
```

Script and prompt changes take effect on the next timer fire — no restart, no
install step. Unit changes need `systemctl --user daemon-reload`; `PATH` changes
need the user manager to re-read its environment (`daemon-reexec` or a new login).

## Layout

| Path | What |
| --- | --- |
| `intake.sh` | the whole runtime: config sourcing, lock, log rotation, prompt assembly, `exec pi` |
| `prompts/scan.md` | the per-round prompt; the only place that describes the scan itself |
| `systemd/` | the timer and its service, both `Type=oneshot` |
| `~/.config/agent-intake/` | `intake.env`, `state.json`, `logs/` — never in the repo |
