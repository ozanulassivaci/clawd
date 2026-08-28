#include "network.h"

#include <stdlib.h>
#include <string.h>

#include "config.h"

namespace {
constexpr unsigned long WIFI_RETRY_INTERVAL_MS = 5000;
constexpr unsigned long MQTT_RETRY_INTERVAL_MS = 5000;
constexpr char TOPIC_STATE[] = "clawd/state";
constexpr char TOPIC_USAGE[] = "clawd/usage";
constexpr char TOPIC_RESET_MINUTES[] = "clawd/reset_minutes";
constexpr char TOPIC_AVAILABILITY[] = "clawd/availability";
}  // namespace

ClawdNetworkManager *ClawdNetworkManager::_instance = nullptr;

ClawdNetworkManager::ClawdNetworkManager(ClawdStateManager &stateManager)
    : _stateManager(stateManager), _mqttClient(_wifiClient) {
  _instance = this;
}

void ClawdNetworkManager::begin() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  _mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  _mqttClient.setCallback(mqttCallback);
}

void ClawdNetworkManager::loop() {
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

void ClawdNetworkManager::connectWiFi() {
  unsigned long now = millis();
  if (now - _lastWifiAttemptMs < WIFI_RETRY_INTERVAL_MS) return;
  _lastWifiAttemptMs = now;

  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void ClawdNetworkManager::connectMqtt() {
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
  _mqttClient.subscribe(TOPIC_RESET_MINUTES);
}

void ClawdNetworkManager::mqttCallback(char *topic, uint8_t *payload, unsigned int length) {
  if (_instance != nullptr) _instance->handleMessage(topic, payload, length);
}

void ClawdNetworkManager::handleMessage(const char *topic, const uint8_t *payload, unsigned int length) {
  constexpr unsigned int MAX_PAYLOAD_LEN = 31;
  if (length > MAX_PAYLOAD_LEN) length = MAX_PAYLOAD_LEN;

  char buffer[MAX_PAYLOAD_LEN + 1];
  memcpy(buffer, payload, length);
  buffer[length] = '\0';

  if (strcmp(topic, TOPIC_STATE) == 0) {
    _stateManager.setState(clawdStateFromString(buffer));
  } else if (strcmp(topic, TOPIC_USAGE) == 0) {
    _stateManager.setUsagePercent(atoi(buffer));
  } else if (strcmp(topic, TOPIC_RESET_MINUTES) == 0) {
    _stateManager.setResetMinutes(atoi(buffer));
  }
}
