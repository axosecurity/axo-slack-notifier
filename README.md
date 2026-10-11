# 🤖 agy-slack-notifier

[![Author](https://img.shields.io/badge/Author-Axo%20Security-red.svg)](https://github.com/axosecurity)
[![Platform](https://img.shields.io/badge/Platform-Google%20Antigravity%20(agy)-4285F4.svg)](https://antigravity.google)
[![Token Cost](https://img.shields.io/badge/LLM%20Tokens-0%20Tokens-brightgreen.svg)](#-zero-token-architecture)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](#-license)

**agy-slack-notifier** is an ultra-lightweight, zero-token lifecycle hook for **Google Antigravity (`agy`)**. Whenever an autonomous AI agent finishes executing a task, this hook captures execution telemetry, retrieves session context, and delivers a formatted notification to your Slack channel.

Developed and maintained by **Axo Security**.

---

## ⚡ Key Highlights

- **🔒 Zero LLM Token Consumption:** Runs entirely as an external OS process outside the model inference loop. Does not query the LLM or consume API tokens.
- **💬 Real-Time Task Metadata:** Automatically looks up the human-readable **Conversation Title** from local SQLite summaries.
- **📊 Context Window Analytics:** Extracts current prompt token size (`cached tokens` + `prompt input` + `output generated`) via rapid reverse-seek parsing.
- **🖥️ System Telemetry:** Includes hostname, OS/kernel version, active user, network IP, and active workspace path.
- **🛡️ Built-in Debounce Protection:** Prevents duplicate webhooks when multiple hooks fire within 3 seconds.
- **⚡ Sub-100ms Execution:** Uses optimized byte-seek reading (`tail`) instead of reading large files into memory.

---

## 🏗️ Architecture & Flow

```
┌─────────────────────────────────────────────────────────────┐
│                 Google Antigravity (`agy`)                  │
│                                                             │
│  User Task Execution ──► Task Finishes / Agent Halts        │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼ (fires Stop event)
┌─────────────────────────────────────────────────────────────┐
│                    Antigravity Stop Hook                    │
│             (.agents/hooks.json or ~/.gemini/config/)       │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼ (passes JSON via stdin)
┌─────────────────────────────────────────────────────────────┐
│              scripts/send_slack_notification.sh             │
│                                                             │
│  1. Check Debounce Lock (/tmp/agy_slack_last_sent)          │
│  2. Read conversation metadata & workspace from stdin       │
│  3. Query conversation_summaries.db for task title          │
│  4. Fast-tail transcript.jsonl for token usage metrics      │
│  5. Gather host, OS, user, and IP information               │
│  6. POST payload to Slack Incoming Webhook (HTTP)           │
│  7. Output {"decision": "allow"} to agy runtime             │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     Slack Notification                      │
│             "Your AI agent has done the work"               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Zero-Token Guarantee

How does this tool consume **0 LLM tokens**?

1. **Lifecycle Isolation:** Antigravity triggers the `Stop` event **after** the model concludes execution (`model_stop`).
2. **Local Processing:** Telemetry and transcript reading happen using local file operations and SQLite queries on disk. No API calls are made to Gemini or Vertex AI.
3. **Hook Contract Compliance:** The hook outputs `{"decision": "allow"}` to `stdout`. This explicitly instructs the `agy` runtime that the agent can terminate normally, preventing re-prompting or continuation loops.

---

## 📋 Prerequisites

- **Linux / macOS / WSL**
- **bash** (>= 4.0)
- **python3** (uses standard library modules: `urllib`, `sqlite3`, `json`, `os`)
- **curl**
- **Google Antigravity CLI (`agy`)** installed

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/axosecurity/agy-slack-notifier.git
cd agy-slack-notifier
chmod +x install.sh uninstall.sh test_notification.sh scripts/*.sh
```

### 2. Install the Hook

#### Option A: Workspace Installation (Applies to current project)
```bash
./install.sh --workspace /path/to/your/project
```
This copies the hook to `/path/to/your/project/.agents/`.

#### Option B: Global Installation (Applies to all agy projects)
```bash
./install.sh --global
```
This installs the hook into `~/.gemini/config/`.

#### Option C: Install Both
```bash
./install.sh --all
```

---

## 🧪 Testing the Webhook

Run the test suite to verify connectivity and Slack rendering without running an AI agent task:

```bash
./test_notification.sh
```

If successful, `{"decision": "allow"}` will be printed, and your Slack channel will immediately display the notification.

---

## 📱 Slack Notification Preview

When an agent completes a task, Slack displays a rich card:

```text
====================================================================
🤖 Your AI agent has done the work
====================================================================
Your AI agent has completed the task successfully.
Conversation: Slack Webhook Bash Script
--------------------------------------------------------------------
🕒 Time:               2026-10-11 11:44:11 +06 (05:44:11 UTC)
🤖 Agent / Model:      Gemini 3.8 Flash (High)
💬 Conversation:       Slack Webhook Bash Script
📊 Context Window:     67,590 tokens (64,782 cached + 2,808 prompt, 1,231 out)
💻 Host & User:        root@prod-runner-01
🌐 IP Address:         192.168.1.100
📂 Workspace:          /root/project/demo-web-builder
🆔 Conversation ID:    e1609262-c67d-483b-ad4b-1f43f18c1686
--------------------------------------------------------------------
Status: model_stop • Hook LLM Token Cost: 0 tokens • Axo Security
====================================================================
```

---

## ⚙️ Configuration

### Changing the Webhook URL

You can override the default webhook URL at runtime using the `SLACK_WEBHOOK_URL` environment variable:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/CUSTOM/WEBHOOK"
```

Alternatively, copy `.env.example` to `.env` and configure your environment:

```bash
cp .env.example .env
```

### Hook Configuration (`hooks.json`)

The hook definition registered with Antigravity:

```json
{
  "slack-task-notifier": {
    "enabled": true,
    "Stop": [
      {
        "type": "command",
        "command": "bash ./scripts/send_slack_notification.sh",
        "timeout": 15
      }
    ]
  }
}
```

- **`enabled`**: Set to `false` to temporarily disable notifications.
- **`timeout`**: Maximum execution time in seconds (default: `15`).

---

## 📂 Repository Structure

```
agy-slack-notifier/
├── .env.example                     # Environment variable reference
├── .gitignore                       # Git ignore rules
├── hooks.json                       # Antigravity hook configuration
├── install.sh                       # Automated installation script
├── uninstall.sh                     # Uninstallation script
├── test_notification.sh             # Manual test script
├── scripts/
│   └── send_slack_notification.sh   # Main hook script (Bash + Python dispatcher)
└── README.md                        # Documentation
```

---

## 🗑️ Uninstallation

To remove the hook:

```bash
# Remove from project workspace
./uninstall.sh --workspace /path/to/your/project

# Remove global hook
./uninstall.sh --global

# Remove both
./uninstall.sh --all
```

---

## 🔐 Security Considerations

- **Secret Handling:** Webhook URLs grant posting rights to your Slack channel. Treat your Slack webhook URL as a secret. Do not commit sensitive webhooks into public repositories.
- **Sandboxing:** This script performs strictly local read-only queries (`sqlite3` and `transcript.jsonl`) and communicates only with `https://hooks.slack.com`.

---

## 👤 Author & Support

- **Organization:** [Axo Security](https://github.com/axosecurity)
- **Maintainer:** Axo Solaman (`axosecurity`)
- **Repository:** Private repository under the Axo Security account.
