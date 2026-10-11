#!/usr/bin/env bash
# ==============================================================================
# send_slack_notification.sh
# Part of agy-slack-notifier by Axo Security
#
# Antigravity (agy) Lifecycle Stop Hook Script
#
# Sends real-time Slack notifications whenever an Antigravity agent completes
# a task, including conversation title, context window token usage, hostname,
# user, IP address, timestamp, and task status.
#
# ZERO-TOKEN GUARANTEE:
# Runs entirely outside the LLM context loop via native bash/Python. Consumes
# 0 model API tokens and outputs '{"decision": "allow"}' to prevent re-prompting.
# ==============================================================================

set -u

# Default Slack Incoming Webhook URL (override via SLACK_WEBHOOK_URL env variable)
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/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}"

# Debounce mechanism: suppress duplicate triggers within 3 seconds
DEBOUNCE_FILE="/tmp/agy_slack_last_sent"
NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
if [ -f "$DEBOUNCE_FILE" ] && [ "$NOW_EPOCH" -gt 0 ]; then
  LAST_SENT=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo 0)
  DIFF=$((NOW_EPOCH - LAST_SENT))
  if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 3 ]; then
    echo '{"decision": "allow"}'
    exit 0
  fi
fi
echo "$NOW_EPOCH" > "$DEBOUNCE_FILE" 2>/dev/null || true

# Ingest hook metadata from stdin (agy Stop hook contract)
INPUT_JSON=""
if [ ! -t 0 ]; then
  INPUT_JSON=$(cat 2>/dev/null || true)
fi

# Collect machine and session telemetry (zero external API calls)
HOSTNAME_VAL=$(hostname 2>/dev/null || uname -n 2>/dev/null || echo "host")
USER_VAL=$(whoami 2>/dev/null || echo "${USER:-root}")
LOCAL_TIME=$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)
UTC_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || date)

# Primary network IP
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
LOCAL_IP="${LOCAL_IP:-127.0.0.1}"

# Operating system details
OS_NAME=""
if [ -f /etc/os-release ]; then
  OS_NAME=$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
fi
KERNEL_INFO=$(uname -s -r -m 2>/dev/null || echo "Linux")
OS_INFO="${OS_NAME:-Linux} (${KERNEL_INFO})"

# Forward environment variables to python dispatcher
export AGY_WEBHOOK_URL="$WEBHOOK_URL"
export AGY_INPUT_JSON="$INPUT_JSON"
export AGY_HOSTNAME="$HOSTNAME_VAL"
export AGY_USER="$USER_VAL"
export AGY_LOCAL_TIME="$LOCAL_TIME"
export AGY_UTC_TIME="$UTC_TIME"
export AGY_OS_INFO="$OS_INFO"
export AGY_LOCAL_IP="$LOCAL_IP"
export AGY_CWD="${PWD}"

# Execute lightweight Python dispatcher (standard library only)
python3 - << 'PY_EOF' >/dev/null 2>&1
import os
import glob
import json
import sqlite3
import urllib.request
import urllib.error

webhook_url = os.environ.get("AGY_WEBHOOK_URL", "")
raw_input = os.environ.get("AGY_INPUT_JSON", "")

conv_id = "N/A"
conv_title = ""
model_name = "AI Agent"
termination_reason = "Completed"
workspaces = os.environ.get("AGY_CWD", "")
error_msg = ""
transcript_path = ""

# 1. Parse agy Stop Hook JSON payload from stdin
if raw_input.strip():
    try:
        data = json.loads(raw_input)
        if data.get("conversationId"):
            conv_id = str(data["conversationId"])
        if data.get("title") or data.get("conversationTitle"):
            conv_title = str(data.get("title") or data.get("conversationTitle"))
        if data.get("modelName"):
            model_name = str(data["modelName"])
        if data.get("terminationReason"):
            termination_reason = str(data["terminationReason"])
        if data.get("transcriptPath"):
            transcript_path = str(data["transcriptPath"])
        ws = data.get("workspacePaths")
        if isinstance(ws, list) and ws:
            workspaces = ", ".join(ws)
        elif ws:
            workspaces = str(ws)
        if data.get("error"):
            error_msg = str(data["error"])
    except Exception:
        pass

# 2. Locate transcript.jsonl if not explicitly supplied
if not transcript_path or not os.path.exists(transcript_path):
    possible_paths = [
        f"/root/.gemini/antigravity-cli/brain/{conv_id}/.system_generated/logs/transcript.jsonl",
        os.path.expanduser(f"~/.gemini/antigravity-cli/brain/{conv_id}/.system_generated/logs/transcript.jsonl"),
        os.path.expanduser(f"~/.gemini/antigravity/brain/{conv_id}/.system_generated/logs/transcript.jsonl"),
    ]
    for p in possible_paths:
        if os.path.exists(p):
            transcript_path = p
            break
    if not transcript_path:
        matches = glob.glob(os.path.expanduser(f"~/.gemini/*/brain/{conv_id}/.system_generated/logs/transcript.jsonl"))
        if matches:
            transcript_path = matches[0]

# 3. Retrieve conversation title from conversation_summaries.db
if not conv_title and conv_id != "N/A":
    db_paths = [
        "/root/.gemini/antigravity-cli/conversation_summaries.db",
        os.path.expanduser("~/.gemini/antigravity-cli/conversation_summaries.db"),
        os.path.expanduser("~/.gemini/antigravity/conversation_summaries.db"),
    ]
    for db_p in db_paths:
        if os.path.exists(db_p):
            try:
                conn = sqlite3.connect(db_p, timeout=1)
                cur = conn.cursor()
                cur.execute("SELECT title FROM conversation_summaries WHERE conversation_id=?", (conv_id,))
                row = cur.fetchone()
                if row and row[0]:
                    conv_title = row[0].strip()
                conn.close()
                if conv_title:
                    break
            except Exception:
                pass

# 4. Extract token counts with reverse byte-seek (O(1) memory & ultra-fast)
latest_input = 0
latest_cache = 0
latest_output = 0

if transcript_path and os.path.exists(transcript_path):
    try:
        file_size = os.path.getsize(transcript_path)
        seek_offset = max(0, file_size - 16384)  # Read trailing 16KB
        with open(transcript_path, "rb") as f:
            f.seek(seek_offset)
            tail_lines = f.read().decode("utf-8", errors="ignore").splitlines()
        
        for line in reversed(tail_lines):
            line = line.strip()
            if not line:
                continue
            try:
                item = json.loads(line)
                if item.get("type") == "PLANNER_RESPONSE":
                    latest_input = item.get("input_tokens", 0)
                    latest_cache = item.get("cache_read_tokens", 0)
                    latest_output = item.get("output_tokens", 0)
                    break
            except Exception:
                pass
    except Exception:
        pass

title_display = conv_title if conv_title else "Antigravity AI Task"
total_context = latest_cache + latest_input

if total_context > 0:
    context_str = f"*{total_context:,} tokens* (`{latest_cache:,}` cached + `{latest_input:,}` prompt, `{latest_output:,}` out)"
else:
    context_str = "Not recorded"

time_str = f"{os.environ.get('AGY_LOCAL_TIME', '')}"
host_str = os.environ.get("AGY_HOSTNAME", "host")
user_str = os.environ.get("AGY_USER", "root")
os_str = os.environ.get("AGY_OS_INFO", "Linux")
ip_str = os.environ.get("AGY_LOCAL_IP", "127.0.0.1")

status_line = termination_reason
if error_msg:
    status_line += f" [Error: {error_msg}]"

notification_text = f"Your AI agent has done the work! [{title_display} | Agent: {model_name} | Host: {host_str}]"

# Slack blocks schema
payload = {
    "text": notification_text,
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "🤖 Your AI agent has done the work",
                "emoji": True
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Your AI agent has completed the task successfully.*\n*Conversation:* *{title_display}*"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*🕒 Time:*\n{time_str}"},
                {"type": "mrkdwn", "text": f"*🤖 Agent / Model:*\n`{model_name}`"},
                {"type": "mrkdwn", "text": f"*💬 Conversation:*\n*{title_display}*"},
                {"type": "mrkdwn", "text": f"*📊 Context Window:*\n{context_str}"},
                {"type": "mrkdwn", "text": f"*💻 Host & User:*\n`{user_str}@{host_str}`\n_{os_str}_"},
                {"type": "mrkdwn", "text": f"*🌐 IP Address:*\n`{ip_str}`"},
                {"type": "mrkdwn", "text": f"*📂 Workspace:*\n`{workspaces}`"},
                {"type": "mrkdwn", "text": f"*🆔 Conversation ID:*\n`{conv_id}`"}
            ]
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": f"*Status:* `{status_line}` • *Hook LLM Token Cost:* `0 tokens` • *Axo Security*"
                }
            ]
        }
    ]
}

# Deliver payload to Slack Incoming Webhook
req = urllib.request.Request(
    webhook_url,
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"}
)

try:
    with urllib.request.urlopen(req, timeout=5) as resp:
        pass
except Exception:
    # Minimal fallback in case of block rejection
    try:
        simple_payload = {"text": notification_text}
        simple_req = urllib.request.Request(
            webhook_url,
            data=json.dumps(simple_payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(simple_req, timeout=5) as resp:
            pass
    except Exception:
        pass
PY_EOF

# Antigravity Stop Hook Contract Output
# Informs the agent runtime that it may shut down cleanly without looping.
echo '{"decision": "allow"}'
exit 0
