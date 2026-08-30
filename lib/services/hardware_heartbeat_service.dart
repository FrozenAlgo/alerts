import 'package:firebase_database/firebase_database.dart';

import '../config/demo_config.dart';
import 'app_database.dart';

/// ESP32 telemetry at RTDB `users/{userId}/hardware`.
class HardwareHeartbeat {
  final bool connected;
  final bool isOnline;
  final int? lastSeenMs;
  final double lat;
  final double lng;
  final bool gpsFix;
  final String alert;

  const HardwareHeartbeat({
    required this.connected,
    required this.isOnline,
    this.lastSeenMs,
    this.lat = 0,
    this.lng = 0,
    this.gpsFix = false,
    this.alert = 'NORMAL',
  });

  static const offline = HardwareHeartbeat(connected: false, isOnline: false);
}

class HardwareHeartbeatService {
  HardwareHeartbeatService._();
  static final HardwareHeartbeatService instance = HardwareHeartbeatService._();

  DatabaseReference heartbeatRef(String userId) =>
      AppDatabase.rtdb.ref('users/$userId/hardware');

  Stream<DatabaseEvent> heartbeatStream(String userId) =>
      heartbeatRef(userId).onValue;

  HardwareHeartbeat parse(dynamic value, {DateTime? receivedAt}) {
    if (value == null) {
      return _finalize(
        DemoConfig.forceSystemOnline ? _demoHeartbeat() : HardwareHeartbeat.offline,
      );
    }

    final data = Map<dynamic, dynamic>.from(value as Map);
    final connected = _isConnected(data['connected']);
    final lat = _toDouble(data['lat']) ?? 0;
    final lng = _toDouble(data['lng']) ?? 0;
    final gpsFix = data['gps_fix'] == true || _coordsValid(lat, lng);
    final alert = data['alert']?.toString() ?? 'NORMAL';

    if (!connected) {
      return _finalize(HardwareHeartbeat(
        connected: false,
        isOnline: false,
        lat: lat,
        lng: lng,
        gpsFix: gpsFix,
        alert: alert,
      ));
    }

    final lastSeenMs = _toEpochMs(data['last_seen'], receivedAt: receivedAt);
    final isOnline = isCurrentlyOnline(
      connected: true,
      lastSeenMs: lastSeenMs,
      lastFirebaseEventAt: receivedAt,
    );

    return _finalize(HardwareHeartbeat(
      connected: true,
      isOnline: isOnline,
      lastSeenMs: lastSeenMs,
      lat: lat,
      lng: lng,
      gpsFix: gpsFix,
      alert: alert,
    ));
  }

  /// Online when connected and (last_seen within 10s OR Firebase event within 10s).
  bool isCurrentlyOnline({
    required bool connected,
    int? lastSeenMs,
    DateTime? lastFirebaseEventAt,
  }) {
    if (DemoConfig.forceSystemOnline) return true;
    if (!connected) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = DemoConfig.heartbeatOnlineWindow.inMilliseconds;

    if (lastSeenMs != null) {
      final age = now - lastSeenMs;
      if (age >= 0 && age <= windowMs) return true;
    }

    if (lastFirebaseEventAt != null) {
      final sinceEvent = DateTime.now().difference(lastFirebaseEventAt);
      if (sinceEvent <= DemoConfig.heartbeatOnlineWindow) return true;
    }

    return false;
  }

  bool _isConnected(dynamic raw) {
    if (raw == true || raw == 1) return true;
    if (raw is String) {
      final lower = raw.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  bool _coordsValid(double lat, double lng) =>
      lat.abs() > 0.001 || lng.abs() > 0.001;

  double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  int? _toEpochMs(dynamic raw, {DateTime? receivedAt}) {
    if (raw == null) return receivedAt?.millisecondsSinceEpoch;

    // Firebase server timestamp placeholder while resolving.
    if (raw is Map) {
      if (raw['.sv'] != null) return receivedAt?.millisecondsSinceEpoch;
      return receivedAt?.millisecondsSinceEpoch;
    }

    if (raw is int) {
      return raw < 10000000000 ? raw * 1000 : raw;
    }
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  HardwareHeartbeat _demoHeartbeat() => HardwareHeartbeat(
        connected: true,
        isOnline: true,
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        lat: DemoConfig.islamabadLat,
        lng: DemoConfig.islamabadLng,
        gpsFix: true,
        alert: 'NORMAL',
      );

  HardwareHeartbeat _finalize(HardwareHeartbeat hb) {
    if (!DemoConfig.forceSystemOnline) return hb;
    final hasCoords = hb.lat.abs() > 0.001 || hb.lng.abs() > 0.001;
    return HardwareHeartbeat(
      connected: true,
      isOnline: true,
      lastSeenMs: hb.lastSeenMs ?? DateTime.now().millisecondsSinceEpoch,
      lat: hasCoords ? hb.lat : DemoConfig.islamabadLat,
      lng: hasCoords ? hb.lng : DemoConfig.islamabadLng,
      gpsFix: true,
      alert: hb.alert,
    );
  }
}
