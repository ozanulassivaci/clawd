# MQTT topics

| Topic | Payload | Retain | QoS | Publisher | Subscriber |
|---|---|---|---|---|---|
| `clawd/state` | `IDLE` \| `WORKING` \| `NEEDS_APPROVAL` | yes | 0 | host hooks | device |
| `clawd/usage` | integer string `0`-`100` | yes | 0 | host statusLine | device |
| `clawd/reset_time` | `HH:MM` (local wall-clock time, 24h) | yes | 0 | host statusLine | device |
| `clawd/availability` | `online` \| `offline` (MQTT last-will) | yes | 0 | device | none yet (debugging) |

Notes:

- Payloads are plain strings, not JSON -- trivial to build with `mosquitto_pub -m`
  and trivial to parse in firmware without a JSON library.
- Retained messages so a rebooting/reconnecting device shows the last known
  values immediately, instead of a blank screen until the next event.
- QoS 0 is a deliberate simplicity trade-off: the host republishes on every
  relevant hook/statusLine call, so a dropped message self-corrects quickly.
- `clawd/usage` is **not** published when `rate_limits.five_hour.used_percentage`
  is absent from the statusLine JSON (before the session's first API response,
  or on a non-Pro/Max plan). This is correct behavior, not a bug -- the device
  simply omits the percentage until a real value arrives.
- `clawd/reset_time` is an **absolute** clock time, not a countdown. Both it
  and `clawd/usage` only get published when `statusLine` fires, which only
  happens in a terminal `claude` session (see the README callout) -- an
  absolute time stays correct regardless of how long it's been since the
  last update (within the same 5-hour window), whereas a countdown would
  drift further from reality with every minute that passes without a fresh
  publish.
- `clawd/availability` costs nothing extra (it rides on PubSubClient's
  `connect()` last-will parameters) and is useful for debugging with
  `mosquitto_sub -t 'clawd/#' -v`, even though nothing subscribes to it yet.
- No device-ID namespacing (e.g. `clawd/<id>/state`) -- fine for a single
  device. Would need revisiting for multiple Clawd units on the same broker.
