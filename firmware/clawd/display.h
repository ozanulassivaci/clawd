// OLED rendering. Physical panel is 72x40px, SSD1306-compatible.
#pragma once

#include <U8g2lib.h>

#include "network.h"
#include "state.h"

// U8g2's dedicated constructor for this 0.42" 72x40 panel. If your installed
// U8g2 version doesn't have it (compile error: no matching constructor),
// flip this to 0 to fall back to the 128x64 constructor + the
// OLED_X_OFFSET/OLED_Y_OFFSET constants from pins.h instead. See
// docs/firmware-setup.md.
#define CLAWD_USE_DEDICATED_72X40 1

class Display {
public:
  void begin();

  // Only actually redraws the OLED when state/usage/resetMinutes/
  // networkStatus changed since the last call, to avoid needless I2C
  // traffic and flicker.
  void render(ClawdState state, int8_t usagePercent, int16_t resetMinutes,
              NetworkStatus networkStatus);

private:
  void drawConnecting(const char *line1, const char *line2);
  void drawState(ClawdState state, int8_t usagePercent, int16_t resetMinutes);

#if CLAWD_USE_DEDICATED_72X40
  U8G2_SSD1306_72X40_ER_F_HW_I2C _u8g2{U8G2_R0, U8X8_PIN_NONE};
#else
  U8G2_SSD1306_128X64_NONAME_F_HW_I2C _u8g2{U8G2_R0, U8X8_PIN_NONE};
#endif

  bool _hasRendered = false;
  ClawdState _lastState = ClawdState::UNKNOWN;
  int8_t _lastUsagePercent = -1;
  int16_t _lastResetMinutes = -1;
  NetworkStatus _lastNetworkStatus = NetworkStatus::CONNECTING_WIFI;
};
