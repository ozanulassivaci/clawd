#!/usr/bin/env bash
# Claude Code Notification hook.
#
# Does NOT parse stdin: the Notification hook's stdin JSON schema isn't fully
# documented, so install.sh instead registers this script once per matcher
# (permission_prompt, agent_needs_input, agent_completed, idle_prompt) with the
# target state passed as $1 in settings.json. See host/install.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

case "${1:-}" in
  IDLE|WORKING|NEEDS_APPROVAL)
    clawd_mqtt_publish "$CLAWD_STATE_TOPIC" "$1" 1
    ;;
esac

exit 0
