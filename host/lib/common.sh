# Shared config loading and MQTT publish helper for all Clawd host scripts.
# Meant to be sourced, not executed directly.

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
[[ -f "$HOST_DIR/config.local.sh" ]] && source "$HOST_DIR/config.local.sh"

: "${MQTT_HOST:=localhost}"
: "${MQTT_PORT:=1883}"
: "${MQTT_USER:=}"
: "${MQTT_PASS:=}"
: "${CLAWD_STATE_TOPIC:=clawd/state}"
: "${CLAWD_USAGE_TOPIC:=clawd/usage}"
: "${CLAWD_RESET_MINUTES_TOPIC:=clawd/reset_minutes}"

clawd_have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# clawd_mqtt_publish TOPIC PAYLOAD [RETAIN=1]
#
# Never blocks or fails the caller: silently no-ops if mosquitto_pub isn't
# installed, and always backgrounds the actual publish behind a short timeout
# so a slow/unreachable broker can never stall a Claude Code hook.
clawd_mqtt_publish() {
  local topic="$1" payload="$2" retain="${3:-1}"

  clawd_have_cmd mosquitto_pub || return 0

  local args=(-h "$MQTT_HOST" -p "$MQTT_PORT" -t "$topic" -m "$payload" -q 0)
  [[ "$retain" == "1" ]] && args+=(-r)
  [[ -n "$MQTT_USER" ]] && args+=(-u "$MQTT_USER" -P "$MQTT_PASS")

  ( timeout 2s mosquitto_pub "${args[@]}" >/dev/null 2>&1 & )
}
