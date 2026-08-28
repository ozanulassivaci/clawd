#!/usr/bin/env bash
# Removes exactly the hook/statusLine entries host/install.sh added from
# ~/.claude/settings.json. Leaves any unrelated hooks or a user-configured
# statusLine untouched.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"

NOTIFY_SCRIPT="$REPO_DIR/hooks/notification.sh"
STOP_SCRIPT="$REPO_DIR/hooks/stop.sh"
PROMPT_SCRIPT="$REPO_DIR/hooks/user-prompt-submit.sh"
STATUSLINE_SCRIPT="$REPO_DIR/statusline/statusline.sh"

# Must match install.sh's sq() exactly so removal matches what was installed.
sq() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

echo "== Clawd host uninstaller =="

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "$SETTINGS_FILE not found, nothing to do."
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required." >&2
  exit 1
fi

BACKUP_FILE="$SETTINGS_FILE.bak.$(date +%s)"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo "Backed up settings to $BACKUP_FILE."

# remove_hook EVENT MATCHER COMMAND
#
# Removes COMMAND from the matcher-entry's hooks array (matching "" against a
# missing matcher key). Drops the matcher-entry if that empties its hooks
# array, and drops the event key entirely if that empties its array.
remove_hook() {
  local event="$1" matcher="$2" command="$3"
  local tmp
  tmp="$(mktemp)"

  jq \
    --arg event "$event" \
    --arg matcher "$matcher" \
    --arg command "$command" \
    '
    if (.hooks[$event] // null) == null then .
    else
      .hooks[$event] |= (
        map(
          if (.matcher // "") == $matcher then
            .hooks = [.hooks[]? | select(.command != $command)]
          else .
          end
        )
        | map(select((.hooks // []) | length > 0))
      )
      | if (.hooks[$event] | length) == 0 then .hooks |= del(.[$event]) else . end
    end
    ' "$SETTINGS_FILE" > "$tmp"

  mv "$tmp" "$SETTINGS_FILE"
}

echo "Removing hooks..."
remove_hook "Notification" "permission_prompt" "$(sq "$NOTIFY_SCRIPT") NEEDS_APPROVAL"
remove_hook "Notification" "agent_needs_input" "$(sq "$NOTIFY_SCRIPT") NEEDS_APPROVAL"
remove_hook "Notification" "agent_completed"   "$(sq "$NOTIFY_SCRIPT") IDLE"
remove_hook "Notification" "idle_prompt"       "$(sq "$NOTIFY_SCRIPT") IDLE"
remove_hook "Stop"             ""              "$(sq "$STOP_SCRIPT")"
remove_hook "UserPromptSubmit" ""              "$(sq "$PROMPT_SCRIPT")"
echo "Hooks removed."

CURRENT_STATUSLINE="$(jq -r '.statusLine.command // empty' "$SETTINGS_FILE")"
if [[ "$CURRENT_STATUSLINE" == "$(sq "$STATUSLINE_SCRIPT")" ]]; then
  tmp="$(mktemp)"
  jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp"
  mv "$tmp" "$SETTINGS_FILE"
  echo "statusLine removed."
else
  echo "statusLine not set to Clawd's script, leaving it untouched."
fi

# Tidy up: drop an empty "hooks": {} left behind if we removed the last hook.
tmp="$(mktemp)"
jq 'if .hooks == {} then del(.hooks) else . end' "$SETTINGS_FILE" > "$tmp"
mv "$tmp" "$SETTINGS_FILE"

echo
echo "== Done =="
echo "settings.json: $SETTINGS_FILE"
