import 'package:geolocator/geolocator.dart';

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

  /// Prefer ESP32 coordinates when valid; fall back to phone GPS.
  static Future<({double lat, double lng})> resolveLocation({
    required double deviceLat,
    required double deviceLng,
  }) async {
    final deviceValid = deviceLat.abs() > 0.001 && deviceLng.abs() > 0.001;
    if (deviceValid) return (lat: deviceLat, lng: deviceLng);

    final phone = await getPhoneLocation();
    if (phone != null) return phone;

    return (lat: deviceLat, lng: deviceLng);
  }
}
