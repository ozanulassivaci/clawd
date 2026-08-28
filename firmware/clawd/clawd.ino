// Clawd status display -- orchestration only. See display.cpp, network.cpp,
// state.cpp and feedback.cpp for the actual logic.
#include "config.h"
#include "display.h"
#include "feedback.h"
#include "network.h"
#include "state.h"

ClawdStateManager stateManager;
ClawdNetworkManager network(stateManager);
Display display;

void setup() {
  Serial.begin(115200);
  stateManager.setOnStateChange(&feedbackOnStateChange);
  display.begin();
  network.begin();
}

void loop() {
  network.loop();
  display.render(stateManager.state(), stateManager.usagePercent(), stateManager.resetMinutes(),
                  network.status());
}
