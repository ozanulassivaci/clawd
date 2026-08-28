#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook. Fires once per turn start (unlike
# PreToolUse, which fires once per tool call), so the device should show
# working. Prints nothing to stdout: some hook events treat stdout as a
# blocking-decision signal.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

clawd_mqtt_publish "$CLAWD_STATE_TOPIC" "WORKING" 1

exit 0
