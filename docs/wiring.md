# Wiring

## OLED

SSD1306-compatible I2C OLED breakout, 0.42" panel, 72x40 visible pixels.

| OLED pin | ESP32-C3 pin |
|---|---|
| VCC | 3V3 |
| GND | GND |
| SCL | see I2C pins below |
| SDA | see I2C pins below |

## I2C pins

Clone ESP32-C3 boards are inconsistent about which GPIOs are safe/available
for I2C. `firmware/clawd/pins.h` defines a primary pair and a fallback pair:

- Primary: SDA=GPIO5, SCL=GPIO6
- Fallback: SDA=GPIO8, SCL=GPIO9 (flip `USE_FALLBACK_I2C_PINS` to `1` in
  `pins.h` if the primary pair doesn't work)

Before wiring the OLED, it's worth running a basic I2C scanner sketch (search
"ESP32 I2C scanner" -- a few lines using `Wire.begin(sda, scl)` and probing
addresses 0x00-0x7F) to confirm the SSD1306 responds, typically at `0x3C` or
`0x3D`, on whichever pin pair you've wired.

**Confirmed working on this build:** _fill in once tested on real hardware --
which pin pair, which I2C address._

## USB

Native USB-C on the ESP32-C3. "USB CDC On Boot" must be **Enabled** in the
Arduino IDE's Tools menu, or the serial port won't enumerate on your host.
See `docs/firmware-setup.md`.
