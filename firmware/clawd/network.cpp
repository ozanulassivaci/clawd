#include "network.h"

#include <stdlib.h>
#include <string.h>

#include "config.h"

namespace {
constexpr unsigned long WIFI_RETRY_INTERVAL_MS = 5000;
constexpr unsigned long MQTT_RETRY_INTERVAL_MS = 5000;
constexpr char TOPIC_STATE[] = "clawd/state";
constexpr char TOPIC_USAGE[] = "clawd/usage";
constexpr char TOPIC_AVAILABILITY[] = "clawd/availability";
}  // namespace

NetworkManager *NetworkManager::_instance = nullptr;

NetworkManager::NetworkManager(ClawdStateManager &stateManager)
    : _stateManager(stateManager), _mqttClient(_wifiClient) {
  _instance = this;
}

void NetworkManager::begin() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  _mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  _mqttClient.setCallback(mqttCallback);
}

void NetworkManager::loop() {
  if (WiFi.status() != WL_CONNECTED) {
    _status = NetworkStatus::CONNECTING_WIFI;
    connectWiFi();
    return;
  }

  if (!_mqttClient.connected()) {
    _status = NetworkStatus::CONNECTING_MQTT;
    connectMqtt();
    return;
  }

  _status = NetworkStatus::CONNECTED;
  _mqttClient.loop();
}

void NetworkManager::connectWiFi() {
  unsigned long now = millis();
  if (now - _lastWifiAttemptMs < WIFI_RETRY_INTERVAL_MS) return;
  _lastWifiAttemptMs = now;

  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void NetworkManager::connectMqtt() {
  unsigned long now = millis();
  if (now - _lastMqttAttemptMs < MQTT_RETRY_INTERVAL_MS) return;
  _lastMqttAttemptMs = now;

  bool hasAuth = strlen(MQTT_USER) > 0;
  bool connected =
      hasAuth ? _mqttClient.connect(MQTT_CLIENT_ID, MQTT_USER, MQTT_PASSWORD,
                                     TOPIC_AVAILABILITY, 0, true, "offline")
              : _mqttClient.connect(MQTT_CLIENT_ID, TOPIC_AVAILABILITY, 0, true, "offline");

  if (!connected) return;

  _mqttClient.publish(TOPIC_AVAILABILITY, "online", true);
  _mqttClient.subscribe(TOPIC_STATE);
  _mqttClient.subscribe(TOPIC_USAGE);
}

void NetworkManager::mqttCallback(char *topic, uint8_t *payload, unsigned int length) {
  if (_instance != nullptr) _instance->handleMessage(topic, payload, length);
}

void NetworkManager::handleMessage(const char *topic, const uint8_t *payload, unsigned int length) {
  constexpr unsigned int MAX_PAYLOAD_LEN = 31;
  if (length > MAX_PAYLOAD_LEN) length = MAX_PAYLOAD_LEN;

  char buffer[MAX_PAYLOAD_LEN + 1];
  memcpy(buffer, payload, length);
  buffer[length] = '\0';

  if (strcmp(topic, TOPIC_STATE) == 0) {
    _stateManager.setState(clawdStateFromString(buffer));
  } else if (strcmp(topic, TOPIC_USAGE) == 0) {
    _stateManager.setUsagePercent(atoi(buffer));
  }
}
