#!/usr/bin/env bash
# ==============================================================================
# test_notification.sh
# Sends a test payload to verify Slack webhook delivery
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Sending mock Antigravity Stop Hook event to Slack..."

# Clear any temporary debounce lock
rm -f /tmp/agy_slack_last_sent

# Mock hook stdin JSON
MOCK_PAYLOAD='{
  "conversationId": "test-verify-axo-1234",
  "title": "Axo Security Test Run",
  "modelName": "Gemini 3.8 Flash (High)",
  "workspacePaths": ["/root/project/demo-web-builder"],
  "terminationReason": "manual_test_verification"
}'

echo "$MOCK_PAYLOAD" | bash "$SCRIPT_DIR/scripts/send_slack_notification.sh"

echo "[✓] Test payload executed. Check your Slack channel!"
