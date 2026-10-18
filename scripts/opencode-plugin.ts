import type { Plugin } from "@opencode-ai/plugin";

export const AxoSlackPlugin: Plugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      // Triggered when the agent finishes its turn / task and goes idle
      if (event.type === "session.idle") {
        try {
          // Look for local workspace script or global script
          await $`bash -c '
            if [ -x "./.agents/scripts/send_slack_notification.sh" ]; then
              ./.agents/scripts/send_slack_notification.sh "OpenCode" <<< "{\"status\":\"idle\"}"
            elif [ -x "$HOME/.config/opencode/scripts/send_slack_notification.sh" ]; then
              "$HOME/.config/opencode/scripts/send_slack_notification.sh" "OpenCode" <<< "{\"status\":\"idle\"}"
            elif [ -x "$HOME/.gemini/config/scripts/send_slack_notification.sh" ]; then
              "$HOME/.gemini/config/scripts/send_slack_notification.sh" "OpenCode" <<< "{\"status\":\"idle\"}"
            fi
          ' >/dev/null 2>&1`;
        } catch (error) {
          // Non-blocking zero-token execution
        }
      }
    },
  };
};

export default AxoSlackPlugin;
