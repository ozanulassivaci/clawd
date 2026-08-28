// Session state model shared by the network and display layers.
#pragma once

#include <cstdint>

enum class ClawdState {
  UNKNOWN,
  IDLE,
  WORKING,
  NEEDS_APPROVAL,
};

// Parses the plain-string MQTT payload published to clawd/state.
ClawdState clawdStateFromString(const char *payload);

// Short display/debug name for a state.
const char *clawdStateName(ClawdState state);

typedef void (*ClawdStateChangeHook)(ClawdState oldState, ClawdState newState);

// Holds the last known state + usage percentage, and notifies a single
// registered hook whenever the state actually changes. This hook is the
// intended extension point for future buzzer/RGB feedback -- state.cpp never
// needs to change when that lands.
class ClawdStateManager {
public:
  void setOnStateChange(ClawdStateChangeHook hook) { _onStateChange = hook; }

  void setState(ClawdState newState) {
    if (newState == _state) return;
    ClawdState oldState = _state;
    _state = newState;
    if (_onStateChange != nullptr) _onStateChange(oldState, newState);
  }

  // percent < 0 or > 100 is ignored (defensive against a malformed payload).
  void setUsagePercent(int percent) {
    if (percent < 0 || percent > 100) return;
    _usagePercent = static_cast<int8_t>(percent);
  }

  // Negative values ignored (defensive against a malformed payload). No
  // upper bound: the 5-hour window can't exceed ~300 minutes, but a stale
  // or malformed value shouldn't need a guess at the ceiling here.
  void setResetMinutes(int minutes) {
    if (minutes < 0) return;
    _resetMinutes = static_cast<int16_t>(minutes);
  }

  ClawdState state() const { return _state; }

  // -1 means "never received".
  int8_t usagePercent() const { return _usagePercent; }

  // -1 means "never received".
  int16_t resetMinutes() const { return _resetMinutes; }

private:
  ClawdState _state = ClawdState::UNKNOWN;
  int8_t _usagePercent = -1;
  int16_t _resetMinutes = -1;
  ClawdStateChangeHook _onStateChange = nullptr;
};
