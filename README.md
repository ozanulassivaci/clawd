# Clawd

A small OLED status display for background Claude Code sessions, housed in a
3D-printed Clawd mascot enclosure. Shows whether Claude is idle, working, or
waiting on your approval, plus the current 5-hour usage-window percentage.

> **Only updates from the terminal CLI.** The percentage and reset-time
> shown on the device come from Claude Code's `statusLine` feature, which
> only runs in a terminal `claude` session. It does **not** fire in the
> VSCode extension or the Claude desktop app -- if you work exclusively in
> either of those, the device's state (idle/working/needs approval) still
> updates live via hooks, but the percentage/reset time will be frozen at
> whatever a terminal session last reported. This is a Claude Code platform
> limitation, not a bug in this project. See
> [docs/troubleshooting.md](docs/troubleshooting.md) if the numbers look
> stuck or don't match what you see elsewhere.

<!-- TODO: add a photo or short demo GIF of the assembled device here -->

## Features

- Claude Code hooks publish session state (`IDLE` / `WORKING` /
  `NEEDS_APPROVAL`) to MQTT as it changes. Works from any Claude Code UI
  (terminal, VSCode extension) since hooks aren't terminal-specific.
- A statusLine script publishes the current 5-hour usage percentage and the
  window's reset time (as an absolute clock time, e.g. `14:32`, so it stays
  correct even between updates) alongside your normal status line text,
  without changing it. Terminal-only -- see the callout above.
- ESP32-C3 firmware subscribes over WiFi/MQTT and renders both on a 72x40
  OLED, with automatic WiFi/MQTT reconnection and a visible connecting
  state. `NEEDS APPROVAL` blinks at 1Hz so it's hard to miss.
- v1 has no buzzer/RGB feedback yet, but the firmware has a single, explicit
  hook point (`feedback.cpp`) for adding one later without touching the
  rest of the code.

## Tech stack

- **Host:** bash, `jq`, `mosquitto_pub` (Claude Code hooks + statusLine)
- **Broker:** mosquitto (MQTT)
- **Firmware:** Arduino framework on ESP32-C3, U8g2 (display), PubSubClient
  (MQTT)

## Installation

### 1. Broker + host hooks

```
sudo apt install mosquitto mosquitto-clients
cd host
./install.sh
```

`install.sh` merges Clawd's hooks/statusLine into `~/.claude/settings.json`
without touching anything else already there, and is safe to re-run. Full
details, including a mosquitto LAN-listener gotcha you'll want to know about
before wiring up real hardware: [docs/host-setup.md](docs/host-setup.md).

### 2. Firmware

```
cp firmware/clawd/config.h.example firmware/clawd/config.h
# edit config.h with your WiFi + broker details
```

Then open `firmware/clawd/clawd.ino` in the Arduino IDE and flash. Full
steps (board package, USB CDC On Boot, libraries):
[docs/firmware-setup.md](docs/firmware-setup.md). Wiring notes:
[docs/wiring.md](docs/wiring.md).

## Usage

Once both sides are running, the device shows the last known state, with the
usage percentage and reset time (if a terminal session has reported them)
underneath:

```
IDLE
74% 14:32

WORKING
74% 14:32

NEEDS APPROVAL     (blinking)
74% 14:32
```

While WiFi or the broker is unreachable, it shows a connecting screen instead
and keeps retrying automatically.

## Project structure

```
Clawd/
├── host/            # Claude Code hooks + statusLine scripts, install.sh
├── firmware/clawd/   # ESP32-C3 Arduino sketch
└── docs/            # wiring, host setup, firmware setup, MQTT topics, troubleshooting
```

## Limitations

- v1 is display-only: no buzzer or RGB feedback yet.
- Global state, not per-session: `clawd/state` reflects whichever Claude Code
  session most recently published, so running several sessions at once won't
  distinguish between them.
- The usage percentage and reset time only update from a terminal `claude`
  session (see the callout above) -- they'll look frozen or wrong compared
  to the Claude desktop app or claude.ai if you only ever work from the
  VSCode extension.
- The usage percentage requires a Claude Pro/Max plan and only appears after
  a session's first API response; before that, the device simply shows no
  percentage.
- MQTT topics use QoS 0 with no auth by default (local network only, no TLS).
- The OLED offset/I2C pin constants in `firmware/clawd/pins.h` are the
  documented defaults for this display, but may need tuning per board -- see
  `docs/wiring.md`.

## License

MIT -- see [LICENSE](LICENSE).
