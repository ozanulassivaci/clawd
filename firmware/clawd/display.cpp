#include "display.h"

#include <Wire.h>
#include <stdio.h>
#include <string.h>

#include "pins.h"

namespace {
#if CLAWD_USE_DEDICATED_72X40
constexpr int16_t DRAW_X_OFFSET = 0;
constexpr int16_t DRAW_Y_OFFSET = 0;
#else
constexpr int16_t DRAW_X_OFFSET = OLED_X_OFFSET;
constexpr int16_t DRAW_Y_OFFSET = OLED_Y_OFFSET;
#endif

// NEEDS APPROVAL blinks at 1Hz (toggles every half-period) so it's hard to
// miss glancing at the device.
constexpr unsigned long BLINK_INTERVAL_MS = 500;
}  // namespace

void Display::begin() {
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  _u8g2.begin();
  _u8g2.setFont(u8g2_font_6x10_tf);
}

void Display::render(ClawdState state, int8_t usagePercent, const char *resetTime,
                      NetworkStatus networkStatus) {
  bool blinking = (state == ClawdState::NEEDS_APPROVAL && networkStatus == NetworkStatus::CONNECTED);
  bool blinkOn = !blinking || ((millis() / BLINK_INTERVAL_MS) % 2 == 0);

  if (_hasRendered && state == _lastState && usagePercent == _lastUsagePercent &&
      strcmp(resetTime, _lastResetTime) == 0 && networkStatus == _lastNetworkStatus &&
      blinkOn == _lastBlinkOn) {
    return;
  }
  _hasRendered = true;
  _lastState = state;
  _lastUsagePercent = usagePercent;
  strncpy(_lastResetTime, resetTime, sizeof(_lastResetTime) - 1);
  _lastResetTime[sizeof(_lastResetTime) - 1] = '\0';
  _lastNetworkStatus = networkStatus;
  _lastBlinkOn = blinkOn;

  _u8g2.clearBuffer();

  if (networkStatus == NetworkStatus::CONNECTING_WIFI) {
    drawConnecting("CONNECTING", "WIFI...");
  } else if (networkStatus == NetworkStatus::CONNECTING_MQTT) {
    drawConnecting("CONNECTING", "MQTT...");
  } else {
    drawState(state, usagePercent, resetTime, blinkOn);
  }

  _u8g2.sendBuffer();
}

void Display::drawConnecting(const char *line1, const char *line2) {
  _u8g2.drawStr(DRAW_X_OFFSET + 2, DRAW_Y_OFFSET + 16, line1);
  _u8g2.drawStr(DRAW_X_OFFSET + 2, DRAW_Y_OFFSET + 30, line2);
}

// Pixel positions below are a starting layout for the 72x40 panel with the
// 6x10 font -- tune on real hardware.
void Display::drawState(ClawdState state, int8_t usagePercent, const char *resetTime,
                         bool blinkOn) {
  if (state == ClawdState::NEEDS_APPROVAL) {
    if (blinkOn) {
      _u8g2.drawStr(DRAW_X_OFFSET + 2, DRAW_Y_OFFSET + 14, "NEEDS");
      _u8g2.drawStr(DRAW_X_OFFSET + 2, DRAW_Y_OFFSET + 26, "APPROVAL");
    }
  } else {
    _u8g2.drawStr(DRAW_X_OFFSET + 2, DRAW_Y_OFFSET + 20, clawdStateName(state));
  }

  if (usagePercent >= 0) {
    char line[16];
    if (resetTime[0] != '\0') {
      snprintf(line, sizeof(line), "%d%% %s", usagePercent, resetTime);
    } else {
      snprintf(line, sizeof(line), "%d%%", usagePercent);
    }
    _u8g2.drawStr(DRAW_X_OFFSET + 2, DRAW_Y_OFFSET + 38, line);
  }
}
