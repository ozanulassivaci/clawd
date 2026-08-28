# Firmware setup (Arduino IDE)

## 1. Install the ESP32 board package

File -> Preferences -> "Additional Boards Manager URLs", add:

```
https://espressif.github.io/arduino-esp32/package_esp32_index.json
```

Then Tools -> Board -> Boards Manager, search "esp32", install "esp32 by
Espressif Systems".

Select your board under Tools -> Board -> esp32 -> (your ESP32-C3 variant,
e.g. "ESP32C3 Dev Module").

## 2. Enable USB CDC On Boot

Tools -> "USB CDC On Boot" -> **Enabled**.

Required for the native USB-C port to enumerate as a serial port at all --
without this, uploading/Serial Monitor won't find the board.

## 3. Install libraries

Sketch -> Include Library -> Manage Libraries, install:

- **U8g2** by olikraus
- **PubSubClient** by Nick O'Leary (knolleary)

_Record the exact versions installed here once you've done it, e.g.:_
`U8g2 x.x.x`, `PubSubClient x.x.x`.

### If U8g2 doesn't have the dedicated 72x40 constructor

`display.h` defaults to `U8G2_SSD1306_72X40_ER_F_HW_I2C`, which recent U8g2
versions ship specifically for this panel. If your installed version doesn't
have it, you'll get a compile error there. Fix: open `display.h` and set

```cpp
#define CLAWD_USE_DEDICATED_72X40 0
```

which switches to the 128x64 constructor plus the `OLED_X_OFFSET`/
`OLED_Y_OFFSET` constants in `pins.h` -- tune those on real hardware until
the image lands correctly in the visible 72x40 window.

## 4. Configure

```
cp firmware/clawd/config.h.example firmware/clawd/config.h
```

Edit `config.h` with your WiFi SSID/password and your mosquitto broker's LAN
IP (not `localhost` -- the device is a separate machine on the network). See
`docs/host-setup.md` for the broker-side LAN listener gotcha.

Check `firmware/clawd/pins.h` for the I2C pin pair and OLED offset constants
if you need to change them (see `docs/wiring.md`).

## 5. Flash

Open `firmware/clawd/clawd.ino` in the Arduino IDE, select the correct port,
and upload. Serial Monitor baud rate: 115200.

Expected first-boot behavior: "CONNECTING... WIFI..." while joining WiFi,
then "CONNECTING... MQTT..." while reaching the broker, then the current
state (from the retained `clawd/state`/`clawd/usage` messages, if any) once
connected.
