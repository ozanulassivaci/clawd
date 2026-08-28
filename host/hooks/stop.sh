#!/usr/bin/env bash
# Claude Code Stop hook. Fires when Claude has finished a full turn, so the
# device should show idle.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

clawd_mqtt_publish "$CLAWD_STATE_TOPIC" "IDLE" 1

exit 0
