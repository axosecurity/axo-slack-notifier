#!/usr/bin/env bash
# ==============================================================================
# install.sh
# Universal installation script for axo-slack-notifier by Axo Security
# Supports: Antigravity (agy), OpenAI Codex, Claude Code, OpenCode
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_MODE="${1:---workspace}"
WORKSPACE_PATH="${2:-.}"

echo "=================================================="
echo "    Axo Security: axo-slack-notifier Installer   "
echo "  Universal Mesh for Antigravity, Codex, Claude  "
echo "=================================================="

case "$TARGET_MODE" in
  --global|-g)
    echo "[+] Installing globally across all supported AI agents..."

    # 1. Google Antigravity (agy)
    AGY_DIR="$HOME/.gemini/config"
    mkdir -p "$AGY_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$AGY_DIR/scripts/"
    chmod +x "$AGY_DIR/scripts/send_slack_notification.sh"
    cp "$SCRIPT_DIR/hooks.json" "$AGY_DIR/hooks.json"
    echo "  [✓] Google Antigravity: $AGY_DIR/hooks.json"

    # 2. Claude Code (~/.claude/settings.json)
    CLAUDE_DIR="$HOME/.claude"
    if [ -d "$CLAUDE_DIR" ] || [ -f "$CLAUDE_DIR/settings.json" ]; then
      mkdir -p "$CLAUDE_DIR/scripts"
      cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$CLAUDE_DIR/scripts/"
      chmod +x "$CLAUDE_DIR/scripts/send_slack_notification.sh"

      python3 -c "
import json, os
p = os.path.expanduser('~/.claude/settings.json')
data = {}
if os.path.exists(p):
    try:
        with open(p, 'r') as f: data = json.load(f)
    except: pass
hooks = data.setdefault('hooks', {})
stop_list = hooks.setdefault('Stop', [])
hook_entry = {'hooks': [{'type': 'command', 'command': 'bash ~/.claude/scripts/send_slack_notification.sh \"Claude Code\"', 'timeout': 15}]}
if not any('send_slack_notification' in str(h) for h in stop_list):
    stop_list.append(hook_entry)
with open(p, 'w') as f: json.dump(data, f, indent=2)
"
      echo "  [✓] Claude Code: $CLAUDE_DIR/settings.json"
    fi

    # 3. OpenAI Codex (~/.codex/config.toml)
    CODEX_DIR="$HOME/.codex"
    if [ -d "$CODEX_DIR" ]; then
      mkdir -p "$CODEX_DIR/scripts"
      cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$CODEX_DIR/scripts/"
      chmod +x "$CODEX_DIR/scripts/send_slack_notification.sh"
      CODEX_CONF="$CODEX_DIR/config.toml"
      if [ -f "$CODEX_CONF" ]; then
        if ! grep -q "send_slack_notification" "$CODEX_CONF"; then
          cat << 'EOF' >> "$CODEX_CONF"

# Axo Slack Notifier Hook
[[hooks.Stop]]
matcher = "always"

  [[hooks.Stop.hooks]]
  type = "command"
  command = "bash ~/.codex/scripts/send_slack_notification.sh 'OpenAI Codex'"
  timeout = 15
  trust_level = "trusted"
EOF
        fi
      fi
      echo "  [✓] OpenAI Codex: $CODEX_CONF"
    fi

    # 4. OpenCode (~/.config/opencode/)
    OPENCODE_DIR="$HOME/.config/opencode"
    if [ -d "$OPENCODE_DIR" ]; then
      mkdir -p "$OPENCODE_DIR/scripts" "$OPENCODE_DIR/plugins"
      cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$OPENCODE_DIR/scripts/"
      chmod +x "$OPENCODE_DIR/scripts/send_slack_notification.sh"
      cp "$SCRIPT_DIR/scripts/opencode-plugin.ts" "$OPENCODE_DIR/plugins/axo-slack.ts"
      echo "  [✓] OpenCode: $OPENCODE_DIR/plugins/axo-slack.ts"
    fi

    echo "[✓] Global installation completed successfully!"
    ;;

  --workspace|-w)
    echo "[+] Installing to project / monorepo workspace: $WORKSPACE_PATH"

    # Antigravity project hooks (.agents)
    DEST_DIR="$WORKSPACE_PATH/.agents"
    mkdir -p "$DEST_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$DEST_DIR/scripts/"
    chmod +x "$DEST_DIR/scripts/send_slack_notification.sh"
    cp "$SCRIPT_DIR/hooks.json" "$DEST_DIR/hooks.json"

    # Claude Code workspace hooks (.claude/settings.json)
    mkdir -p "$WORKSPACE_PATH/.claude/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$WORKSPACE_PATH/.claude/scripts/"
    python3 -c "
import json, os
p = os.path.join('$WORKSPACE_PATH', '.claude', 'settings.json')
data = {}
if os.path.exists(p):
    try:
        with open(p, 'r') as f: data = json.load(f)
    except: pass
hooks = data.setdefault('hooks', {})
stop_list = hooks.setdefault('Stop', [])
hook_entry = {'hooks': [{'type': 'command', 'command': 'bash .claude/scripts/send_slack_notification.sh \"Claude Code\"', 'timeout': 15}]}
if not any('send_slack_notification' in str(h) for h in stop_list):
    stop_list.append(hook_entry)
with open(p, 'w') as f: json.dump(data, f, indent=2)
"

    # OpenAI Codex workspace hooks (.codex/hooks.json)
    mkdir -p "$WORKSPACE_PATH/.codex/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$WORKSPACE_PATH/.codex/scripts/"
    python3 -c "
import json, os
p = os.path.join('$WORKSPACE_PATH', '.codex', 'hooks.json')
data = {}
if os.path.exists(p):
    try:
        with open(p, 'r') as f: data = json.load(f)
    except: pass
hooks = data.setdefault('hooks', {})
stop_list = hooks.setdefault('Stop', [])
hook_entry = {'hooks': [{'type': 'command', 'command': 'bash .codex/scripts/send_slack_notification.sh \"OpenAI Codex\"', 'timeout': 15}]}
if not any('send_slack_notification' in str(h) for h in stop_list):
    stop_list.append(hook_entry)
with open(p, 'w') as f: json.dump(data, f, indent=2)
"

    # OpenCode workspace plugins (.opencode/plugins)
    mkdir -p "$WORKSPACE_PATH/.opencode/plugins"
    cp "$SCRIPT_DIR/scripts/opencode-plugin.ts" "$WORKSPACE_PATH/.opencode/plugins/axo-slack.ts"

    echo "[✓] Successfully installed across all agent configurations in workspace!"
    echo "    Antigravity: $DEST_DIR/hooks.json"
    echo "    Claude Code: $WORKSPACE_PATH/.claude/settings.json"
    echo "    Codex:       $WORKSPACE_PATH/.codex/hooks.json"
    echo "    OpenCode:    $WORKSPACE_PATH/.opencode/plugins/axo-slack.ts"
    ;;

  --all|-a)
    echo "[+] Running both Global and Workspace installations..."
    "$SCRIPT_DIR/install.sh" --global
    "$SCRIPT_DIR/install.sh" --workspace "$WORKSPACE_PATH"
    ;;

  *)
    echo "Usage:"
    echo "  ./install.sh --workspace [project_path]   # Configure monorepo / project (default)"
    echo "  ./install.sh --global                    # Configure user home (~/.claude, ~/.codex, ~/.gemini)"
    echo "  ./install.sh --all                       # Configure both workspace and global"
    exit 1
    ;;
esac

echo ""
echo "Test your installation anytime by running:"
echo "  ./test_notification.sh"
echo "=================================================="
