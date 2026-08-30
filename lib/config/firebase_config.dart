/// Firebase project configuration (must match ESP32 firmware).
class FirebaseConfig {
  FirebaseConfig._();

  /// Same host as ESP32 `FIREBASE_HOST` + `.firebaseio.com`.
  static const String realtimeDatabaseUrl =
      'https://accident-alert-system-bce17-default-rtdb.firebaseio.com';
}
