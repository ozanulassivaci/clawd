// Extension point for future buzzer/RGB LED feedback. v1 is display-only, so
// this is currently a no-op -- wire a buzzer or RGB LED in here later without
// touching state.cpp, network.cpp, or clawd.ino.
#pragma once

#include "state.h"

void feedbackOnStateChange(ClawdState oldState, ClawdState newState);
