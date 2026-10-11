#!/usr/bin/env bash
# ==============================================================================
# install.sh
# Installation script for agy-slack-notifier by Axo Security
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_MODE="${1:---workspace}"
WORKSPACE_PATH="${2:-.}"

echo "=================================================="
echo "    Axo Security: agy-slack-notifier Installer   "
echo "=================================================="

case "$TARGET_MODE" in
  --global|-g)
    DEST_DIR="$HOME/.gemini/config"
    echo "[+] Installing globally into: $DEST_DIR"
    mkdir -p "$DEST_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$DEST_DIR/scripts/"
    chmod +x "$DEST_DIR/scripts/send_slack_notification.sh"
    cp "$SCRIPT_DIR/hooks.json" "$DEST_DIR/hooks.json"
    echo "[✓] Successfully installed globally!"
    echo "    Hooks:   $DEST_DIR/hooks.json"
    echo "    Scripts: $DEST_DIR/scripts/send_slack_notification.sh"
    ;;

  --workspace|-w)
    DEST_DIR="$WORKSPACE_PATH/.agents"
    echo "[+] Installing to project workspace: $DEST_DIR"
    mkdir -p "$DEST_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$DEST_DIR/scripts/"
    chmod +x "$DEST_DIR/scripts/send_slack_notification.sh"
    cp "$SCRIPT_DIR/hooks.json" "$DEST_DIR/hooks.json"
    echo "[✓] Successfully installed to workspace!"
    echo "    Hooks:   $DEST_DIR/hooks.json"
    echo "    Scripts: $DEST_DIR/scripts/send_slack_notification.sh"
    ;;

  --all|-a)
    echo "[+] Installing to BOTH global config and current workspace..."
    # Global
    GLOBAL_DIR="$HOME/.gemini/config"
    mkdir -p "$GLOBAL_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$GLOBAL_DIR/scripts/"
    chmod +x "$GLOBAL_DIR/scripts/send_slack_notification.sh"
    cp "$SCRIPT_DIR/hooks.json" "$GLOBAL_DIR/hooks.json"
    # Workspace
    WS_DIR="$WORKSPACE_PATH/.agents"
    mkdir -p "$WS_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$WS_DIR/scripts/"
    chmod +x "$WS_DIR/scripts/send_slack_notification.sh"
    cp "$SCRIPT_DIR/hooks.json" "$WS_DIR/hooks.json"
    echo "[✓] Successfully installed globally and to workspace!"
    ;;

  *)
    echo "Usage:"
    echo "  ./install.sh --workspace [project_path]   # Install to project .agents/ (default)"
    echo "  ./install.sh --global                    # Install globally to ~/.gemini/config/"
    echo "  ./install.sh --all                       # Install both globally and locally"
    exit 1
    ;;
esac

echo ""
echo "Test your installation anytime by running:"
echo "  ./test_notification.sh"
echo "=================================================="
