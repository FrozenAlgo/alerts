import 'package:geolocator/geolocator.dart';

import '../config/demo_config.dart';

class LocationService {
  static Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<({double lat, double lng})?> getPhoneLocation() async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) return null;

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }

  static bool coordsValid(double lat, double lng) =>
      lat.abs() > 0.001 || lng.abs() > 0.001;

  /// ESP32 device path → ESP32 hardware path → phone GPS → Islamabad demo fix.
  static ({double lat, double lng, String source}) resolveDisplayCoordinates({
    double deviceLat = 0,
    double deviceLng = 0,
    double hardwareLat = 0,
    double hardwareLng = 0,
    double? phoneLat,
    double? phoneLng,
  }) {
    if (coordsValid(deviceLat, deviceLng)) {
      return (lat: deviceLat, lng: deviceLng, source: 'esp32_gps');
    }
    if (coordsValid(hardwareLat, hardwareLng)) {
      return (lat: hardwareLat, lng: hardwareLng, source: 'esp32_gps');
    }
    if (phoneLat != null &&
        phoneLng != null &&
        coordsValid(phoneLat, phoneLng)) {
      return (lat: phoneLat, lng: phoneLng, source: 'phone_gps');
    }
    final fallback = DemoConfig.resolveMapCoordinates(0, 0);
    return (lat: fallback.lat, lng: fallback.lng, source: 'demo_fix');
  }

  /// Prefer ESP32 coordinates when valid; fall back to phone GPS.
  static Future<({double lat, double lng})> resolveLocation({
    required double deviceLat,
    required double deviceLng,
    double hardwareLat = 0,
    double hardwareLng = 0,
  }) async {
    final resolved = resolveDisplayCoordinates(
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      hardwareLat: hardwareLat,
      hardwareLng: hardwareLng,
    );
    if (resolved.source != 'demo_fix') {
      return (lat: resolved.lat, lng: resolved.lng);
    }

    final phone = await getPhoneLocation();
    if (phone != null) return phone;

    return (lat: resolved.lat, lng: resolved.lng);
  }
}
