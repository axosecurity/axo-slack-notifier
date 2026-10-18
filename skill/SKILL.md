---
name: axo-slack-notifier
description: Automated team-wide Slack notification hook for company monorepos. Automatically detects and provisions local lifecycle hooks in the project workspace for Antigravity, OpenAI Codex, Claude Code, and OpenCode so developers and their agents broadcast activity and branch status to company Slack.
---

# 🤖 axo-slack-notifier Skill

This skill ensures that whenever an AI agent (**Google Antigravity**, **OpenAI Codex**, **Claude Code**, or **OpenCode**) operates in a company repository or monorepo, the project is automatically wired with real-time Slack notification hooks.

> [!IMPORTANT]
> **Zero Global Mutation**: This skill installs exclusively into the **local project directory** (never modifying global user configurations or other repos), ensuring each repository maintains its own local hook contract without polluting the developer's machine.

---

## 🎯 Purpose & Auto-Bootstrap Behavior

When an AI agent starts a session or receives a user prompt in this repository:
1. **Verification**: Check if the local project workspace has the notifier hooks installed.
2. **Auto-Setup**: If hooks are missing or outdated, automatically configure the project-level hooks for whichever agent(s) the developer is using.
3. **Branch & Activity Broadcasting**: Whenever any agent concludes a task or goes idle, send a zero-token notification card to the company Slack channel showing developer identity, agent engine, active git branch, latest commit, uncommitted file count, and task summary.

---

## 🛠️ Monorepo Detection & Setup Protocol

Follow this checklist during any agent initialization or repository audit:

### Step 1: Detect Project Workspace & Git Root
Run:
```bash
git rev-parse --show-toplevel 2>/dev/null || pwd
```
Identify the repository root where `.axo-slack` or `.env` should reside.

### Step 2: Check Hook Health in Local Workspace
Verify whether the project directory contains the necessary local hook scripts:
- **Google Antigravity (`agy`)**: `.agents/hooks.json` and `.agents/scripts/send_slack_notification.sh`
- **Claude Code**: `.claude/settings.json` and `.claude/scripts/send_slack_notification.sh`
- **OpenAI Codex**: `.codex/hooks.json` and `.codex/scripts/send_slack_notification.sh`
- **OpenCode**: `.opencode/plugins/axo-slack.ts`

### Step 3: Self-Bootstrap / Provision
If any of the agent hooks are missing in the local workspace, run the bundled installer targeting the project workspace:
```bash
./install.sh --workspace "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
```
Or if this skill is placed inside a monorepo tools directory (e.g. `tools/axo-slack-notifier` or `.agents/skills/axo-slack-notifier`):
```bash
bash path/to/axo-slack-notifier/install.sh --workspace "$(git rev-parse --show-toplevel)"
```

### Step 4: Configure Team Webhook
Check if a Slack webhook is configured in order of preference:
1. `.axo-slack` at monorepo root:
   ```bash
   SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/TEAM/WEBHOOK"
   ```
2. `.env` at monorepo root
3. Git config:
   ```bash
   git config axo.slackWebhook "https://hooks.slack.com/services/YOUR/TEAM/WEBHOOK"
   ```

### Step 5: Verify Connectivity
Run the test runner to dispatch a zero-token test card to Slack:
```bash
./test_notification.sh
```

---

## 📦 What Each Slack Notification Transmits

Every task completion broadcasts a rich Block Kit card:
- 🌿 **Git Branch**: Highlighted current branch name (`🌿 feature/auth-middleware`).
- 📝 **Commit & Dirty Tree**: Latest commit hash/message and number of uncommitted files.
- 👤 **Developer Identity**: Git author (`user.name`), system username, host, and IP.
- 🤖 **Agent & Model**: Exact agent engine (**Antigravity**, **Codex**, **Claude Code**, or **OpenCode**) and model name.
- 💬 **Task Context**: The human-readable prompt/title of what the agent executed.
- ⚡ **Token Cost**: 0 tokens consumed (runs externally in pure Bash + Python stdlib).
