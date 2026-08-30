/// Presentation / Wizard-of-Oz demo constants.
class DemoConfig {
  DemoConfig._();

  /// ESP32 fried — keep dashboard ACTIVE/OFFLINE UI showing online.
  static const bool forceSystemOnline = true;

  /// Shake phone → send real SMS from device SIM on accident.
  static const bool sendRealSmsOnAccident = true;

  /// Presentation: always SMS this number when accident is detected (no contacts needed).
  static const String demoEmergencySmsNumber = '+923335115065';

  static const double islamabadLat = 33.6782;
  static const double islamabadLng = 73.0688;

  static const String smsSimulationMessage =
      'Emergency SMS dispatched to 3 contacts';

  static const Duration heartbeatOnlineWindow = Duration(seconds: 10);
  static const Duration accidentUiDuration = Duration(seconds: 8);

  /// Presentation shake sensitivity — lower = easier to trigger (1.6G ≈ firm flick).
  static const double gForceThreshold = 1.6;

  /// Use Firebase GPS when valid; otherwise Islamabad so the map never looks broken.
  static ({double lat, double lng}) resolveMapCoordinates(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) {
      return (lat: islamabadLat, lng: islamabadLng);
    }
    return (lat: lat, lng: lng);
  }
}
