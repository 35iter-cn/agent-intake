#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${AGENT_INTAKE_CONFIG:-$HOME/.config/agent-intake/intake.env}"
LOG_DIR="${AGENT_INTAKE_LOGS:-$HOME/.config/agent-intake/logs}"
STATE="${AGENT_INTAKE_STATE:-$HOME/.config/agent-intake/state.json}"
PI="${AGENT_INTAKE_PI:-pi}"

if [ -f "$CONFIG" ]; then
  . "$CONFIG"
fi

mkdir -p "$LOG_DIR/intake" || exit 0
find "$LOG_DIR/intake" -type f -mmin +4320 -delete 2>/dev/null

exec 9>"$ROOT/.lock" || exit 0
flock -n 9 || exit 0

cd ~/code

export AGENT_LEDGER_SOURCE=automation

RUN_CONFIG="【运行配置】
Slack 频道: ${AGENT_INTAKE_SLACK_LABEL:-未配置} (${AGENT_INTAKE_SLACK_CHANNEL:-未配置})
通知平台: ${AGENT_INTAKE_NOTIFY_PLATFORM:-feishu}（目标群与凭据由 agent-relay 自己从 ~/.config/agent-relay/ 读取，勿打印）"

PROMPT="$(cat "$ROOT/prompts/scan.md")

运行实例根目录（本轮所有读写均以它为准，只读）: $ROOT
外置 state 文件（唯一读写目标）: $STATE

$RUN_CONFIG"

exec "$PI" --mode json --print "$PROMPT" >> "$LOG_DIR/intake/$(date +%F-%H%M).jsonl" 2>&1
