#!/usr/bin/env bash
# Claude Code statusLine command.
#
# Always prints a normal status line. As a non-blocking side effect, publishes
# the current 5-hour usage percentage and the wall-clock time the 5-hour
# window resets at to MQTT when the API has reported them
# (rate_limits.five_hour.* is absent -- not null -- before the session's
# first API response, and on non-Pro/Max plans).
#
# The reset time is published as an absolute HH:MM (not "minutes remaining")
# on purpose: this only updates when statusLine fires, so a countdown would
# drift further from reality with every minute that passes without a fresh
# update. An absolute clock time stays correct regardless of staleness, as
# long as the 5-hour window hasn't rolled over since the last update.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

INPUT="$(cat)"

MODEL="Claude"
DIR_NAME=""
PCT=""
RESET_TIME=""

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
    RESET_TIME="$(date -d "@$RESETS_AT" +%H:%M 2>/dev/null)"
  fi
fi

LINE="$MODEL"
[[ -n "$DIR_NAME" ]] && LINE="$LINE  $DIR_NAME"
[[ -n "$PCT" ]] && LINE="$LINE  ${PCT}% 5h"

printf '%s\n' "$LINE"

[[ -n "$PCT" ]] && clawd_mqtt_publish "$CLAWD_USAGE_TOPIC" "$PCT" 1
[[ -n "$RESET_TIME" ]] && clawd_mqtt_publish "$CLAWD_RESET_TIME_TOPIC" "$RESET_TIME" 1

exit 0
