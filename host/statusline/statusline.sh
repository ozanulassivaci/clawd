#!/usr/bin/env bash
# Claude Code statusLine command.
#
# Always prints a normal status line. As a non-blocking side effect, publishes
# the current 5-hour usage percentage to MQTT when the API has reported one
# (rate_limits.five_hour.used_percentage is absent -- not null -- before the
# session's first API response, and on non-Pro/Max plans).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

INPUT="$(cat)"

MODEL="Claude"
DIR_NAME=""
PCT=""

if clawd_have_cmd jq; then
  MODEL="$(jq -r '.model.display_name // "Claude"' <<<"$INPUT" 2>/dev/null)"
  CWD="$(jq -r '.workspace.current_dir // empty' <<<"$INPUT" 2>/dev/null)"
  [[ -n "$CWD" ]] && DIR_NAME="${CWD##*/}"

  PCT_RAW="$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$INPUT" 2>/dev/null)"
  if [[ -n "$PCT_RAW" ]]; then
    PCT="$(awk -v v="$PCT_RAW" 'BEGIN{printf "%.0f", v}' 2>/dev/null)"
  fi
fi

LINE="$MODEL"
[[ -n "$DIR_NAME" ]] && LINE="$LINE  $DIR_NAME"
[[ -n "$PCT" ]] && LINE="$LINE  ${PCT}% 5h"

printf '%s\n' "$LINE"

[[ -n "$PCT" ]] && clawd_mqtt_publish "$CLAWD_USAGE_TOPIC" "$PCT" 1

exit 0
