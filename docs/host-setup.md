# Host setup (Ubuntu 22.04)

## 1. Install mosquitto

```
sudo apt update
sudo apt install mosquitto mosquitto-clients
sudo systemctl enable --now mosquitto
```

### LAN listener gotcha

Mosquitto 2.x defaults to a `localhost`-only listener with no anonymous
connections on some distro packagings. Publishing from the laptop itself via
`localhost` will "work" in testing, while the ESP32 -- a separate physical
device on WiFi -- silently fails to connect. Give it an explicit listener
bound to the LAN, e.g. in `/etc/mosquitto/conf.d/clawd.conf`:

```
listener 1883 0.0.0.0
allow_anonymous true
```

(Or configure a username/password with `mosquitto_passwd` and set
`allow_anonymous false` -- then fill in `MQTT_USER`/`MQTT_PASS` in
`host/config.local.sh` and `MQTT_USER`/`MQTT_PASSWORD` in
`firmware/clawd/config.h` to match.)

Restart after editing: `sudo systemctl restart mosquitto`.

Verify from another machine on the same LAN (not just `localhost`):

```
mosquitto_sub -h <laptop-lan-ip> -t 'clawd/#' -v
```

## 2. Run the installer

```
cd host
./install.sh
```

This is safe to re-run. It will:

- Create `host/config.local.sh` from `config.local.sh.example` if it doesn't
  exist yet (edit it to point at your broker/credentials).
- Merge Clawd's hooks and statusLine into `~/.claude/settings.json`, backing
  the file up first (`settings.json.bak.<timestamp>`). It never overwrites
  the file wholesale, and never touches hooks or a statusLine you already
  have configured for anything else.
- Warn (not fail) if `mosquitto_pub` isn't installed yet -- the hooks are
  safe no-ops until it is.

To remove everything it added: `./uninstall.sh`.

### Resulting settings.json shape

```json
{
  "hooks": {
    "Notification": [
      { "matcher": "permission_prompt", "hooks": [ { "type": "command", "command": "'/path/to/Clawd/host/hooks/notification.sh' NEEDS_APPROVAL", "timeout": 5 } ] },
      { "matcher": "agent_needs_input", "hooks": [ { "type": "command", "command": "'/path/to/Clawd/host/hooks/notification.sh' NEEDS_APPROVAL", "timeout": 5 } ] },
      { "matcher": "agent_completed", "hooks": [ { "type": "command", "command": "'/path/to/Clawd/host/hooks/notification.sh' IDLE", "timeout": 5 } ] },
      { "matcher": "idle_prompt", "hooks": [ { "type": "command", "command": "'/path/to/Clawd/host/hooks/notification.sh' IDLE", "timeout": 5 } ] }
    ],
    "Stop": [ { "hooks": [ { "type": "command", "command": "'/path/to/Clawd/host/hooks/stop.sh'", "timeout": 5 } ] } ],
    "UserPromptSubmit": [ { "hooks": [ { "type": "command", "command": "'/path/to/Clawd/host/hooks/user-prompt-submit.sh'", "timeout": 5 } ] } ]
  },
  "statusLine": { "type": "command", "command": "'/path/to/Clawd/host/statusline/statusline.sh'" }
}
```

The single-quotes around each path are intentional: Claude Code runs these
commands through a shell, and this repo's own path may contain spaces (or
other characters a shell would otherwise split on), so `install.sh` quotes
every path it writes.

## 3. Test without hardware

```
mosquitto_sub -t 'clawd/#' -v
```

Then start a Claude Code session and watch `clawd/state` / `clawd/usage`
update as you prompt, wait for a tool-approval prompt, and let a turn finish.
You can also invoke a hook script by hand, e.g.:

```
host/hooks/notification.sh NEEDS_APPROVAL
```
