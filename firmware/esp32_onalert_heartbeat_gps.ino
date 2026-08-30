/*
 * OnAlert ESP32 — heartbeat + GPS + manual accident trigger
 * Matches Flutter path: /users/{uid}/hardware
 *
 * Wire GPS module TX -> GPIO16 (RX2), GPS RX -> GPIO17 (TX2) on most ESP32 boards.
 */
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

#define WIFI_SSID "SABTECH"
#define WIFI_PASSWORD "s@btech123"
#define FIREBASE_HOST "accident-alert-system-bce17-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "6SUQqvyRAZbxsZWtteym9lAWnFSNNV9VV51Wujo7"

// Must match the Firebase Auth user logged into the Flutter app
#define USER_ID "KBJfAUatifNFJRw0GwKciLnzzGo2"

#define MANUAL_TRIGGER_PIN 13
#define GPS_RX_PIN 16
#define GPS_TX_PIN 17

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;
TinyGPSPlus gps;
HardwareSerial GPSSerial(2);

bool isAlertActive = false;
String hardwarePath;

void setup() {
  Serial.begin(115200);
  pinMode(MANUAL_TRIGGER_PIN, INPUT_PULLUP);

  GPSSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");

  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&config, &auth);

  hardwarePath = "/users/" + String(USER_ID) + "/hardware";
}

void loop() {
  // Read GPS bytes
  while (GPSSerial.available() > 0) {
    gps.encode(GPSSerial.read());
  }

  static unsigned long lastUpdate = 0;
  if (millis() - lastUpdate > 1000) {
    lastUpdate = millis();

    Firebase.setBool(firebaseData, hardwarePath + "/connected", true);
    Firebase.setTimestamp(firebaseData, hardwarePath + "/last_seen");

    if (gps.location.isValid()) {
      Firebase.setFloat(firebaseData, hardwarePath + "/lat", gps.location.lat());
      Firebase.setFloat(firebaseData, hardwarePath + "/lng", gps.location.lng());
      Firebase.setBool(firebaseData, hardwarePath + "/gps_fix", true);
    } else {
      Firebase.setBool(firebaseData, hardwarePath + "/gps_fix", false);
    }

    Firebase.setString(
        firebaseData,
        hardwarePath + "/alert",
        isAlertActive ? "ACCIDENT_DETECTED" : "NORMAL");

    Firebase.setString(firebaseData, hardwarePath + "/firmware_version", "1.1.0");
  }

  if (digitalRead(MANUAL_TRIGGER_PIN) == LOW) {
    isAlertActive = true;
  }
  if (isAlertActive && millis() % 10000 > 8000) {
    isAlertActive = false;
  }
}
