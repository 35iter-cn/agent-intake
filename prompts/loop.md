intake 扫描轮。完整流程、判定标准与边界在 `~/code/agent-intake/prompts/scan.md`，先读它再照做（含其中的【运行配置】）。

补充三条：

- 本轮最终回答就是投递到这个 Slack 频道的消息正文（有候选时一轮一条）；没有候选就只输出一行 `NOOP`。
- 不要用 `agent-relay notice emit` 或任何平台 API 自己发消息，投递与失败记录由 relay 负责。
- 外置 state 在 `~/.config/agent-intake/state.json`，每轮都要「读 → 改单键 → 同目录 tmp + mv」推进水位，出错也要写进当日 daily log。
