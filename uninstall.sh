#!/usr/bin/env bash
# ==============================================================================
# uninstall.sh
# Uninstallation script for axo-slack-notifier by Axo Security
# ==============================================================================

set -euo pipefail

TARGET_MODE="${1:---workspace}"
WORKSPACE_PATH="${2:-.}"

echo "=================================================="
echo "   Axo Security: axo-slack-notifier Uninstaller   "
echo "=================================================="

case "$TARGET_MODE" in
  --global|-g)
    echo "[*] Removing global installation across agents..."
    rm -f "$HOME/.gemini/config/scripts/send_slack_notification.sh"
    rm -f "$HOME/.claude/scripts/send_slack_notification.sh"
    rm -f "$HOME/.codex/scripts/send_slack_notification.sh"
    rm -f "$HOME/.config/opencode/scripts/send_slack_notification.sh"
    rm -f "$HOME/.config/opencode/plugins/axo-slack.ts"
    echo "[✓] Global scripts removed."
    ;;

  --workspace|-w)
    echo "[*] Removing workspace installation from: $WORKSPACE_PATH"
    rm -f "$WORKSPACE_PATH/.agents/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.claude/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.codex/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.opencode/plugins/axo-slack.ts"
    echo "[✓] Workspace hooks removed."
    ;;

  --all|-a)
    echo "[*] Removing both global and workspace installations..."
    rm -f "$HOME/.gemini/config/scripts/send_slack_notification.sh"
    rm -f "$HOME/.claude/scripts/send_slack_notification.sh"
    rm -f "$HOME/.codex/scripts/send_slack_notification.sh"
    rm -f "$HOME/.config/opencode/scripts/send_slack_notification.sh"
    rm -f "$HOME/.config/opencode/plugins/axo-slack.ts"
    rm -f "$WORKSPACE_PATH/.agents/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.claude/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.codex/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.opencode/plugins/axo-slack.ts"
    echo "[✓] All installations removed."
    ;;

  *)
    echo "Usage:"
    echo "  ./uninstall.sh --workspace [project_path]"
    echo "  ./uninstall.sh --global"
    echo "  ./uninstall.sh --all"
    exit 1
    ;;
esac
echo "=================================================="
