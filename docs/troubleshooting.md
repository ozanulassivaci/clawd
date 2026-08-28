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

**Hooks don't seem to publish anything.**
Run `host/install.sh` again and check its output for warnings (missing `jq`
or `mosquitto_pub`). You can also invoke a hook script directly to test it,
e.g. `host/hooks/notification.sh NEEDS_APPROVAL`, then watch
`mosquitto_sub -t 'clawd/#' -v`.
