# 🤖 axo-slack-notifier

[![Author](https://img.shields.io/badge/Author-Axo%20Security-red.svg)](https://github.com/axosecurity)
[![Multi-Agent](https://img.shields.io/badge/Agents-Antigravity%20%7C%20Codex%20%7C%20Claude%20%7C%20OpenCode-blueviolet.svg)](#-supported-agents)
[![Monorepo Ready](https://img.shields.io/badge/Monorepo-Mesh%20Aware-success.svg)](#-company-monorepo-integration)
[![Token Cost](https://img.shields.io/badge/LLM%20Tokens-0%20Tokens-brightgreen.svg)](#-zero-token-architecture)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](#-license)

**axo-slack-notifier** is an ultra-lightweight, zero-token lifecycle notification engine built for engineering teams and monorepos. Whenever any developer's AI agent (**Google Antigravity**, **OpenAI Codex**, **Claude Code**, or **OpenCode**) completes a task or turn, this tool captures live git branch context, developer identity, and session telemetry, instantly broadcasting an informative card to your team's Slack channel.

Developed and maintained by **Axo Security**.

---

## 🌟 What's New in `axo-slack-notifier`

1. **Multi-Agent Universal Support:** Seamlessly works across:
   - **Google Antigravity (`agy`)** via lifecycle `Stop` hook
   - **OpenAI Codex** via `[[hooks.Stop]]`
   - **Claude Code** via `hooks.Stop`
   - **OpenCode** via `@opencode-ai/plugin` (`session.idle`)
2. **Company Monorepo Mesh:**
   - Place inside the company monorepo so every developer's AI agent posts directly to the central team Slack webhook.
   - Automatically crawls up to git root to find `.env`, `.axo-slack`, or git configuration (`axo.slackWebhook`).
   - Team members can see in real-time who is working on what, which branch they are touching, and what their AI agent just accomplished.
3. **Deep Git Branch & Worktree Intelligence:**
   - Prominently showcases the active **Git Branch** (`🌿 branch-name`).
   - Displays latest commit summary (`hash - subject`).
   - Warns if the working tree has uncommitted modifications.
   - Attaches Developer identity (`user.name`, system user, host, IP).
4. **Zero-Token Overhead Guarantee:**
   - Operates 100% outside model inference loops using native Bash and Python standard library.
   - 0 prompt or completion tokens consumed.

---

## 🏗️ Monorepo Architecture & Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Developer Workstation / Agents                        │
│                                                                             │
│   [Developer A: Claude Code]       [Developer B: OpenAI Codex]              │
│   [Developer C: Antigravity]       [Developer D: OpenCode]                  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ (fires lifecycle completion hook)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                 Company Monorepo Root (.git / .axo-slack)                   │
│                                                                             │
│  1. Detect caller agent engine (agy / codex / claude / opencode)            │
│  2. Read central monorepo webhook from .axo-slack or .env                   │
│  3. Extract Git Branch, latest commit, dirty working tree status            │
│  4. Extract developer git author name & system telemetry                    │
│  5. Check debounce lock (/tmp/axo_slack_last_sent)                          │
│  6. POST payload to company Slack channel                                   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Company Monorepo Slack Channel                           │
│        "🤖 [OpenAI Codex] Alice finished on branch 'feature/auth'"          │
│        "🤖 [Antigravity] Bob finished on branch 'fix/billing-api'"          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Setup in Company Monorepos

### 1. Add to your Monorepo

Clone or add `axo-slack-notifier` to your company repository:

```bash
git clone https://github.com/axosecurity/axo-slack-notifier.git
cd axo-slack-notifier
chmod +x install.sh uninstall.sh test_notification.sh scripts/*.sh
```

### 2. Configure the Monorepo Webhook

In your monorepo root directory, add the Slack Incoming Webhook URL to `.axo-slack` or `.env`:

```bash
echo 'SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/COMPANY/WEBHOOK"' >> /path/to/monorepo/.axo-slack
```

*(Alternatively, set it once via git config: `git config axo.slackWebhook "https://hooks.slack.com/..."`)*

### 3. Install Across Developers

#### Workspace Installation (Recommended for Monorepos)
Configures hooks for all 4 agents in the current project/monorepo:

```bash
./install.sh --workspace /path/to/monorepo
```

This creates:
- `.agents/hooks.json` & `.agents/scripts/` (for Antigravity)
- `.claude/settings.json` & `.claude/scripts/` (for Claude Code)
- `.codex/hooks.json` & `.codex/scripts/` (for OpenAI Codex)
- `.opencode/plugins/axo-slack.ts` (for OpenCode)

#### Global Installation (Applies to all developer projects on machine)
```bash
./install.sh --global
```

---

## 🧪 Testing the Webhook

Run the multi-agent test suite to simulate all supported agents without having to wait for a task:

```bash
# Test all 4 engines
./test_notification.sh all

# Or test a single engine
./test_notification.sh antigravity
./test_notification.sh codex
./test_notification.sh claude
./test_notification.sh opencode
```

---

## 📱 Slack Notification Card Preview

When an agent concludes a task, a rich card is broadcasted to Slack:

```text
====================================================================
🤖 Agent Activity: OpenAI Codex [monorepo-core]
====================================================================
Developer: Alice Smith (alice@company.com) • Engine: OpenAI Codex
Task / Prompt: Implement multi-tenant authentication middleware
--------------------------------------------------------------------
🌿 Git Branch & Status:
`🌿 feature/auth-middleware`
Last commit: `7f18a2c - add JWT validation tests`
Working tree: 2 uncommitted changes

📦 Repository / Monorepo:  `monorepo-core`
👤 Developer System:       alice@macbook-pro.local (macOS 15.3 Darwin)
🕒 Timestamp:              2026-10-18 19:55:00 +06 (13:55:00 UTC)
🤖 Model / Runtime:        `gpt-6.1-sol`
📊 Context / Tokens:       Completed (native zero-token hook)
🌐 IP Address:             192.168.1.42
📂 Working Directory:      `/Users/alice/monorepo/apps/auth-service`
--------------------------------------------------------------------
Branch: `feature/auth-middleware` • Status: completed • Hook Overhead: 0 tokens • Axo Security
====================================================================
```

---

## ⚙️ Configuration Reference

### Webhook Resolution Order
1. `SLACK_WEBHOOK_URL` environment variable.
2. Monorepo root `.axo-slack` file.
3. Monorepo root `.env` file.
4. Local project `.axo-slack` or `.env`.
5. Local or global `git config --get axo.slackWebhook`.
6. Default fallback webhook.

---

## 📂 Repository Structure

```
axo-slack-notifier/
├── .env.example                     # Environment template
├── .gitignore                       # Git ignore rules
├── hooks.json                       # Antigravity hook definition
├── install.sh                       # Multi-agent automated installer
├── uninstall.sh                     # Uninstallation script
├── test_notification.sh             # Multi-agent simulation test runner
├── scripts/
│   ├── send_slack_notification.sh   # Core multi-agent webhook dispatcher
│   └── opencode-plugin.ts           # OpenCode TypeScript lifecycle plugin
└── README.md                        # Documentation
```

---

## 👤 Author & Support

- **Organization:** [Axo Security](https://github.com/axosecurity)
- **Product:** axo-slack-notifier
- **Maintainer:** Axo Solaman (`axosecurity`)
