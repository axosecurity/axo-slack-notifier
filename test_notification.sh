#!/usr/bin/env bash
# ==============================================================================
# test_notification.sh
# Sends mock payloads simulating different AI agents to verify Slack delivery
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_TARGET="${1:-all}"

echo "=================================================="
echo "    Axo Security: axo-slack-notifier Test Suite  "
echo "=================================================="

run_test() {
  local agent_name="$1"
  local mock_payload="$2"

  echo "[*] Testing agent event for: $agent_name..."
  rm -f /tmp/axo_slack_last_sent /tmp/agy_slack_last_sent
  echo "$mock_payload" | bash "$SCRIPT_DIR/scripts/send_slack_notification.sh" "$agent_name"
  echo "    [✓] Dispatched $agent_name event!"
  sleep 1
}

case "$AGENT_TARGET" in
  antigravity|agy)
    run_test "Antigravity" '{
      "conversationId": "test-agy-001",
      "title": "Build Monorepo Slack Dispatcher",
      "modelName": "Gemini 3.8 Flash (High)",
      "workspacePaths": ["/Users/solaman/project/monorepo"],
      "terminationReason": "completed"
    }'
    ;;

  codex)
    run_test "OpenAI Codex" '{
      "sessionId": "codex-test-789",
      "task_description": "Implement authentication middleware",
      "model": "gpt-6.1-sol",
      "cwd": "/Users/solaman/project/monorepo/apps/auth",
      "status": "success"
    }'
    ;;

  claude)
    run_test "Claude Code" '{
      "sessionId": "claude-session-456",
      "task_description": "Refactor database migrations and schema",
      "model": "claude-3-7-sonnet",
      "cwd": "/Users/solaman/project/monorepo/packages/db",
      "status": "idle"
    }'
    ;;

  opencode)
    run_test "OpenCode" '{
      "sessionId": "opencode-session-321",
      "task_description": "Run biome check and auto-format",
      "model": "claude-sonnet-4-5",
      "cwd": "/Users/solaman/project/monorepo/services/billing",
      "status": "idle"
    }'
    ;;

  all|*)
    echo "[+] Running full multi-agent simulation test suite..."
    run_test "Antigravity" '{
      "conversationId": "test-agy-monorepo",
      "title": "Refactor Core Authentication Flow",
      "modelName": "Gemini 3.8 Flash (High)",
      "workspacePaths": ["/Users/solaman/project/monorepo"],
      "terminationReason": "completed"
    }'

    run_test "OpenAI Codex" '{
      "sessionId": "test-codex-feature",
      "task_description": "Optimize SQL queries for order processing",
      "model": "gpt-6.1-sol",
      "cwd": "/Users/solaman/project/monorepo/apps/orders",
      "status": "completed"
    }'

    run_test "Claude Code" '{
      "sessionId": "test-claude-ui",
      "task_description": "Design responsive navigation bar island",
      "model": "claude-3-7-sonnet",
      "cwd": "/Users/solaman/project/monorepo/apps/storefront",
      "status": "idle"
    }'

    run_test "OpenCode" '{
      "sessionId": "test-opencode-lint",
      "task_description": "Execute system test suite and verify build",
      "model": "claude-sonnet-4-5",
      "cwd": "/Users/solaman/project/monorepo",
      "status": "idle"
    }'
    ;;
esac

echo ""
echo "[✓] All requested test events executed. Check your Slack channel!"
echo "=================================================="
