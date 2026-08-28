// WiFi + MQTT connection management: non-blocking connect/reconnect state
// machine, subscribes to clawd/state and clawd/usage, and publishes
// clawd/availability via MQTT's last-will mechanism.
#pragma once

#include <PubSubClient.h>
#include <WiFi.h>

#include "state.h"

enum class NetworkStatus {
  CONNECTING_WIFI,
  CONNECTING_MQTT,
  CONNECTED,
};

// Named ClawdNetworkManager, not NetworkManager: the ESP32 Arduino core
// (arduino-esp32 3.x) ships its own global ::NetworkManager class (pulled in
// transitively via <WiFi.h> -> Network.h), which collides otherwise.
class ClawdNetworkManager {
public:
  explicit ClawdNetworkManager(ClawdStateManager &stateManager);

  void begin();
  void loop();

  NetworkStatus status() const { return _status; }

private:
  void connectWiFi();
  void connectMqtt();
  void handleMessage(const char *topic, const uint8_t *payload, unsigned int length);

  static void mqttCallback(char *topic, uint8_t *payload, unsigned int length);
  static ClawdNetworkManager *_instance;

  ClawdStateManager &_stateManager;
  WiFiClient _wifiClient;
  PubSubClient _mqttClient;
  NetworkStatus _status = NetworkStatus::CONNECTING_WIFI;
  unsigned long _lastWifiAttemptMs = 0;
  unsigned long _lastMqttAttemptMs = 0;
};
