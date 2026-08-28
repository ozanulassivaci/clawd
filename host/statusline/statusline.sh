#!/usr/bin/env bash
# Claude Code statusLine command.
#
# Always prints a normal status line. As a non-blocking side effect, publishes
# the current 5-hour usage percentage and the minutes remaining until the
# 5-hour window resets to MQTT when the API has reported them
# (rate_limits.five_hour.* is absent -- not null -- before the session's
# first API response, and on non-Pro/Max plans).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

INPUT="$(cat)"

MODEL="Claude"
DIR_NAME=""
PCT=""
RESET_MIN=""

if clawd_have_cmd jq; then
  MODEL="$(jq -r '.model.display_name // "Claude"' <<<"$INPUT" 2>/dev/null)"
  CWD="$(jq -r '.workspace.current_dir // empty' <<<"$INPUT" 2>/dev/null)"
  [[ -n "$CWD" ]] && DIR_NAME="${CWD##*/}"

  PCT_RAW="$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$INPUT" 2>/dev/null)"
  if [[ -n "$PCT_RAW" ]]; then
    PCT="$(awk -v v="$PCT_RAW" 'BEGIN{printf "%.0f", v}' 2>/dev/null)"
  fi

  RESETS_AT="$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$INPUT" 2>/dev/null)"
  if [[ -n "$RESETS_AT" ]]; then
    NOW="$(date +%s)"
    RESET_MIN="$(awk -v r="$RESETS_AT" -v n="$NOW" 'BEGIN{d=r-n; if(d<0)d=0; printf "%d", d/60}' 2>/dev/null)"
  fi
fi

LINE="$MODEL"
[[ -n "$DIR_NAME" ]] && LINE="$LINE  $DIR_NAME"
[[ -n "$PCT" ]] && LINE="$LINE  ${PCT}% 5h"

printf '%s\n' "$LINE"

[[ -n "$PCT" ]] && clawd_mqtt_publish "$CLAWD_USAGE_TOPIC" "$PCT" 1
[[ -n "$RESET_MIN" ]] && clawd_mqtt_publish "$CLAWD_RESET_MINUTES_TOPIC" "$RESET_MIN" 1

exit 0
