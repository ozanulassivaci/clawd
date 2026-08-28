# Troubleshooting

**OLED stays blank.**
Check the I2C address/pins first with a scanner sketch (see `docs/wiring.md`).
If the panel responds but the image is garbled or off-screen, you're likely
on the 128x64+offset fallback constructor -- tune `OLED_X_OFFSET`/
`OLED_Y_OFFSET` in `firmware/clawd/pins.h`.

**Device stuck on "CONNECTING... WIFI...".**
Double-check `WIFI_SSID`/`WIFI_PASSWORD` in `firmware/clawd/config.h`. The
ESP32-C3 only supports 2.4GHz networks.

**Device stuck on "CONNECTING... MQTT...".**
WiFi is fine but the broker isn't reachable. Most common cause: mosquitto is
only listening on `localhost` and/or rejecting anonymous connections -- see
the LAN listener gotcha in `docs/host-setup.md`. Confirm `MQTT_HOST` in
`config.h` is the broker's LAN IP, not `localhost`. Test from another device
on the LAN: `mosquitto_sub -h <broker-ip> -t 'clawd/#' -v`.

**statusLine text looks wrong / usage percentage never shows up.**
- If you already had a custom `statusLine` configured before running
  `host/install.sh`, it leaves yours untouched and prints a note instead of
  overwriting it -- check the installer's output.
- The usage percentage is only published after the session's first API
  response, and only on Pro/Max plans (`rate_limits.five_hour.used_percentage`
  is simply absent otherwise). No publish in that case is expected, not a bug.

**Percentage/reset time on the device is stuck, or doesn't match what I see
in the Claude desktop app / claude.ai.**
This is expected, not a bug. `statusLine.command` -- the only source Clawd
has for the usage percentage and reset time -- is a **terminal-CLI-only**
Claude Code feature. It does not fire in the VSCode extension, and it has
nothing to do with the Claude desktop app (which reads its own account API
directly, independent of Claude Code entirely). Two consequences:
- If you only ever work through the VSCode extension, `clawd/usage` and
  `clawd/reset_time` will simply never update -- the device shows whatever a
  terminal `claude` session last reported, however old that is. `clawd/state`
  (idle/working/needs approval) is unaffected and keeps updating live, since
  hooks fire regardless of which UI you're using.
- Even when it does update, the numbers can legitimately lag a live figure
  in the desktop app by a percent or two, since they're only as fresh as the
  last statusLine invocation (each turn in a terminal session), not
  continuously polled.

There is no supported way to get live rate-limit data outside of an active
terminal session -- it isn't cached to disk, there's no separate API for it,
and non-interactive `claude -p` invocations don't return it either. If you
want the device to track reality closely, run `claude` in a terminal
alongside (or instead of) the VSCode extension.

**Hooks don't seem to publish anything.**
Run `host/install.sh` again and check its output for warnings (missing `jq`
or `mosquitto_pub`). You can also invoke a hook script directly to test it,
e.g. `host/hooks/notification.sh NEEDS_APPROVAL`, then watch
`mosquitto_sub -t 'clawd/#' -v`.
