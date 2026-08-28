#!/usr/bin/env bash
# Installs Clawd's Claude Code hooks and statusLine into ~/.claude/settings.json.
#
# Safe to re-run: every merge step below is idempotent (checks whether its
# entry already exists before adding it). Never overwrites settings.json
# wholesale -- only merges the specific hooks/statusLine fields Clawd needs,
# and backs up the file first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

NOTIFY_SCRIPT="$REPO_DIR/hooks/notification.sh"
STOP_SCRIPT="$REPO_DIR/hooks/stop.sh"
PROMPT_SCRIPT="$REPO_DIR/hooks/user-prompt-submit.sh"
STATUSLINE_SCRIPT="$REPO_DIR/statusline/statusline.sh"
HOOK_TIMEOUT=5

# Single-quotes a path for safe use inside a settings.json "command" string.
# Claude Code runs hook/statusLine commands through a shell, and this repo's
# path may contain spaces (or worse); wrapping in single quotes keeps it one
# shell word regardless of what characters it contains.
sq() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

echo "== Clawd host installer =="

# --- Pre-flight -------------------------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required (used to safely merge settings.json)." >&2
  echo "Install it with: sudo apt install jq" >&2
  exit 1
fi

if command -v mosquitto_pub >/dev/null 2>&1; then
  echo "mosquitto_pub found."
else
  echo "WARNING: mosquitto_pub not found -- hooks will install but publish nothing"
  echo "         until a broker + mosquitto-clients are set up."
  echo "         See docs/host-setup.md."
fi

# --- Config bootstrap ---------------------------------------------------------

if [[ ! -f "$REPO_DIR/config.local.sh" ]]; then
  cp "$REPO_DIR/config.local.sh.example" "$REPO_DIR/config.local.sh"
  echo "Created $REPO_DIR/config.local.sh from the example (edit it to point at your broker)."
else
  echo "Using existing $REPO_DIR/config.local.sh."
fi

# --- settings.json bootstrap + validation ------------------------------------

mkdir -p "$SETTINGS_DIR"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "{}" > "$SETTINGS_FILE"
  echo "Created empty $SETTINGS_FILE."
fi

if ! jq empty "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "ERROR: $SETTINGS_FILE is not valid JSON. Fix it by hand before re-running." >&2
  exit 1
fi

BACKUP_FILE="$SETTINGS_FILE.bak.$(date +%s)"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo "Backed up settings to $BACKUP_FILE."

# --- Hook merge ---------------------------------------------------------------
#
# merge_hook EVENT MATCHER COMMAND
#
# MATCHER "" means "no matcher key" (Stop, UserPromptSubmit). Finds the
# existing hooks[EVENT] entry with a matching matcher (treating a missing
# matcher key as ""), creates one if absent, and appends {type:"command",
# command, timeout} to its hooks array only if that exact command isn't
# already there.
merge_hook() {
  local event="$1" matcher="$2" command="$3"
  local tmp
  tmp="$(mktemp)"

  jq \
    --arg event "$event" \
    --arg matcher "$matcher" \
    --arg command "$command" \
    --argjson timeout "$HOOK_TIMEOUT" \
    '
    .hooks //= {}
    | .hooks[$event] //= []
    | .hooks[$event] |= (
        if any(.[]; (.matcher // "") == $matcher) then
          map(
            if (.matcher // "") == $matcher then
              .hooks //= []
              | if any(.hooks[]; .command == $command) then .
                else .hooks += [{type: "command", command: $command, timeout: $timeout}]
                end
            else .
            end
          )
        else
          . + [
              (if $matcher == "" then
                {hooks: [{type: "command", command: $command, timeout: $timeout}]}
              else
                {matcher: $matcher, hooks: [{type: "command", command: $command, timeout: $timeout}]}
              end)
            ]
        end
      )
    ' "$SETTINGS_FILE" > "$tmp"

  mv "$tmp" "$SETTINGS_FILE"
}

echo "Merging hooks..."
merge_hook "Notification" "permission_prompt" "$(sq "$NOTIFY_SCRIPT") NEEDS_APPROVAL"
merge_hook "Notification" "agent_needs_input" "$(sq "$NOTIFY_SCRIPT") NEEDS_APPROVAL"
merge_hook "Notification" "agent_completed"   "$(sq "$NOTIFY_SCRIPT") IDLE"
merge_hook "Notification" "idle_prompt"       "$(sq "$NOTIFY_SCRIPT") IDLE"
merge_hook "Stop"             ""              "$(sq "$STOP_SCRIPT")"
merge_hook "UserPromptSubmit" ""              "$(sq "$PROMPT_SCRIPT")"
echo "Hooks merged."

# --- statusLine ---------------------------------------------------------------

STATUSLINE_CMD="$(sq "$STATUSLINE_SCRIPT")"
EXISTING_STATUSLINE="$(jq -r '.statusLine.command // empty' "$SETTINGS_FILE")"

if [[ -z "$EXISTING_STATUSLINE" || "$EXISTING_STATUSLINE" == "$STATUSLINE_CMD" ]]; then
  tmp="$(mktemp)"
  jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {type: "command", command: $cmd}' \
    "$SETTINGS_FILE" > "$tmp"
  mv "$tmp" "$SETTINGS_FILE"
  echo "statusLine configured: $STATUSLINE_CMD"
else
  echo "NOTE: statusLine is already set to a different command -- leaving it untouched:"
  echo "  existing: $EXISTING_STATUSLINE"
  echo "  Clawd's:  $STATUSLINE_CMD"
  echo "  To get usage-percentage publishing, either point statusLine at Clawd's"
  echo "  script yourself, or add its publish logic to your existing one."
fi

# --- Permissions ---------------------------------------------------------------

chmod +x "$NOTIFY_SCRIPT" "$STOP_SCRIPT" "$PROMPT_SCRIPT" "$STATUSLINE_SCRIPT" \
  "$REPO_DIR/install.sh" "$REPO_DIR/uninstall.sh"

echo
echo "== Done =="
echo "settings.json: $SETTINGS_FILE"
echo "Broker config: $REPO_DIR/config.local.sh"
echo "Next: set up mosquitto (docs/host-setup.md) if you haven't, then start a"
echo "Claude Code session and watch: mosquitto_sub -t 'clawd/#' -v"
