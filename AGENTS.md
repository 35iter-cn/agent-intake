# AGENTS.md

Conventions for anyone — human or agent — changing this repository. Read
`README.md` first: its **Structure**, **Configuration** and **Privacy** sections are
the contract and are not repeated here.

## Non-negotiables

- **Never commit to `main` directly.** Branch, push, open a PR, squash-merge.
- **Nothing site-specific in the tree.** Channel ids, group names, board or
  organisation names, hostnames and tokens stay in `~/.config/agent-intake/` or
  `~/.config/agent-relay/`. A round reads them from `intake.env`; nothing is injected
  into the prompt at build time any more.
- **No cross-repository references.** This repo talks to the outside world through
  three channels only: a CLI on `PATH` (`agent-relay`), a skill that `pi` has
  installed (`task-radar`), and the data contract under `~/.config/agent-intake/`.
  Never write another repository's path or URL here.
- **The schedule is not ours.** Timers, mutual exclusion, per-round sessions,
  delivery and pause-on-failure all belong to `agent-relay`. A systemd unit, a shell
  wrapper or a lock file in this tree is a regression, not a feature.
- **The round is read-only towards this checkout.** The only writes are the external
  `state.json`, the memory daily log and the round's final answer, which relay posts.

## Tests

There are none, deliberately: the moving parts are two prompts and relay's own loop
runtime. Verify a change with a real round —
`agent-relay loop run <id>`, then `agent-relay loop log <id>` and
`agent-relay loop show-run <runId>` — plus `state.json`. A change that alters either
prompt must be checked against a real round before it is merged.

## Deploying

```bash
git -C ~/code/agent-intake pull --ff-only
```

`scan.md` is read every round, so it is live on the next fire. `loop.md` is stored in
the relay state at creation time:

```bash
agent-relay loop update <id> --prompt-file ~/code/agent-intake/prompts/loop.md
```

## Layout

| Path | What |
| --- | --- |
| `prompts/loop.md` | the stored loop prompt: where the procedure is, how to deliver a round, `NOOP` silence |
| `prompts/scan.md` | the per-round procedure; the only place that describes the scan itself |
| `~/.config/agent-intake/` | `intake.env`, `state.json` — never in the repo |
