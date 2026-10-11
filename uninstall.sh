#!/usr/bin/env bash
# ==============================================================================
# uninstall.sh
# Uninstallation script for agy-slack-notifier by Axo Security
# ==============================================================================

set -euo pipefail

TARGET_MODE="${1:---workspace}"
WORKSPACE_PATH="${2:-.}"

echo "=================================================="
echo "   Axo Security: agy-slack-notifier Uninstaller   "
echo "=================================================="

case "$TARGET_MODE" in
  --global|-g)
    echo "[*] Removing global installation..."
    rm -f "$HOME/.gemini/config/scripts/send_slack_notification.sh"
    rm -f "$HOME/.gemini/config/hooks.json"
    echo "[✓] Global hooks removed."
    ;;

  --workspace|-w)
    echo "[*] Removing workspace installation from: $WORKSPACE_PATH/.agents"
    rm -f "$WORKSPACE_PATH/.agents/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.agents/hooks.json"
    echo "[✓] Workspace hooks removed."
    ;;

  --all|-a)
    echo "[*] Removing both global and workspace installations..."
    rm -f "$HOME/.gemini/config/scripts/send_slack_notification.sh"
    rm -f "$HOME/.gemini/config/hooks.json"
    rm -f "$WORKSPACE_PATH/.agents/scripts/send_slack_notification.sh"
    rm -f "$WORKSPACE_PATH/.agents/hooks.json"
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
