#include "state.h"

#include <string.h>

ClawdState clawdStateFromString(const char *payload) {
  if (strcmp(payload, "IDLE") == 0) return ClawdState::IDLE;
  if (strcmp(payload, "WORKING") == 0) return ClawdState::WORKING;
  if (strcmp(payload, "NEEDS_APPROVAL") == 0) return ClawdState::NEEDS_APPROVAL;
  return ClawdState::UNKNOWN;
}

const char *clawdStateName(ClawdState state) {
  switch (state) {
    case ClawdState::IDLE: return "IDLE";
    case ClawdState::WORKING: return "WORKING";
    case ClawdState::NEEDS_APPROVAL: return "NEEDS APPROVAL";
    default: return "UNKNOWN";
  }
}
