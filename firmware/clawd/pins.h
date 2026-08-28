// Hardware pin/offset constants. Tweak these here as you confirm what works
// on your actual board -- nothing else in the firmware needs to change.
#pragma once

// I2C pins: clone ESP32-C3 boards are inconsistent here. Try the primary pair
// first; if the OLED doesn't respond (run an I2C scanner sketch to check),
// flip USE_FALLBACK_I2C_PINS to 1. Record whichever works in docs/wiring.md.
#define I2C_SDA_PIN_PRIMARY 5
#define I2C_SCL_PIN_PRIMARY 6
#define I2C_SDA_PIN_FALLBACK 8
#define I2C_SCL_PIN_FALLBACK 9

#define USE_FALLBACK_I2C_PINS 0

#if USE_FALLBACK_I2C_PINS
#define I2C_SDA_PIN I2C_SDA_PIN_FALLBACK
#define I2C_SCL_PIN I2C_SCL_PIN_FALLBACK
#else
#define I2C_SDA_PIN I2C_SDA_PIN_PRIMARY
#define I2C_SCL_PIN I2C_SCL_PIN_PRIMARY
#endif

// Only used by the 128x64+offset fallback constructor in display.cpp, in case
// the installed U8g2 version doesn't ship U8G2_SSD1306_72X40_ER_F_HW_I2C.
// Confirm/tune these by testing on real hardware.
#define OLED_X_OFFSET 30
#define OLED_Y_OFFSET 12
#define OLED_VISIBLE_WIDTH 72
#define OLED_VISIBLE_HEIGHT 40
