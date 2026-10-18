#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh
# Automated self-provisioning script for axo-slack-notifier in local monorepos
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "=================================================="
echo " [axo-slack-notifier] Self-Bootstrap Inspection"
echo " Target Workspace: $REPO_ROOT"
echo "=================================================="

MISSING=0

# Check Antigravity
if [ ! -f "$REPO_ROOT/.agents/scripts/send_slack_notification.sh" ] || [ ! -f "$REPO_ROOT/.agents/hooks.json" ]; then
  MISSING=1
fi

# Check Claude Code
if [ ! -f "$REPO_ROOT/.claude/scripts/send_slack_notification.sh" ] || [ ! -f "$REPO_ROOT/.claude/settings.json" ]; then
  MISSING=1
fi

# Check Codex
if [ ! -f "$REPO_ROOT/.codex/scripts/send_slack_notification.sh" ] || [ ! -f "$REPO_ROOT/.codex/hooks.json" ]; then
  MISSING=1
fi

# Check OpenCode
if [ ! -f "$REPO_ROOT/.opencode/plugins/axo-slack.ts" ]; then
  MISSING=1
fi

if [ "$MISSING" -eq 1 ]; then
  echo "[!] Notifier hooks missing in project workspace. Auto-provisioning now..."
  bash "$SCRIPT_DIR/install.sh" --workspace "$REPO_ROOT"
  echo "[✓] Local workspace hooks provisioned successfully!"
else
  echo "[✓] Notifier hooks already present and verified in project workspace."
fi
