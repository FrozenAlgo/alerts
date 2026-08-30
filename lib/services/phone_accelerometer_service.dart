import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../config/demo_config.dart';

/// Demo-mode phone accelerometer readings (bypasses Firebase accel axes).
class AccelerometerReading {
  final double x;
  final double y;
  final double z;
  final double gForce;
  final bool localAccidentActive;

  const AccelerometerReading({
    required this.x,
    required this.y,
    required this.z,
    required this.gForce,
    required this.localAccidentActive,
  });

  static const idle = AccelerometerReading(
    x: 0,
    y: 0,
    z: 0,
    gForce: 0,
    localAccidentActive: false,
  );
}

class PhoneAccelerometerService {
  PhoneAccelerometerService._();
  static final PhoneAccelerometerService instance = PhoneAccelerometerService._();

  static const double gForceThreshold = DemoConfig.gForceThreshold;
  static const double upsideDownZThreshold = -7.0;
  static const Duration localAccidentDuration = DemoConfig.accidentUiDuration;

  StreamSubscription<AccelerometerEvent>? _subscription;
  int _listenerCount = 0;
  Timer? _accidentClearTimer;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _gForce = 0;
  bool _localAccidentActive = false;
  bool _accidentEmittedThisEpisode = false;

  final _readingsController = StreamController<AccelerometerReading>.broadcast();
  final _accidentController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<AccelerometerReading> get readings => _readingsController.stream;

  /// Fires once when local accident detection starts (for SOS dialog).
  Stream<Map<String, dynamic>> get onLocalAccidentDetected => _accidentController.stream;

  AccelerometerReading get current => AccelerometerReading(
        x: _x,
        y: _y,
        z: _z,
        gForce: _gForce,
        localAccidentActive: _localAccidentActive,
      );

  void addListener() {
    _listenerCount++;
    _ensureListening();
  }

  void removeListener() {
    _listenerCount = max(0, _listenerCount - 1);
    if (_listenerCount == 0) {
      _stopListening();
    }
  }

  void _ensureListening() {
    if (_subscription != null) return;
    _subscription = accelerometerEventStream().listen(
      _onEvent,
      onError: (Object e) => debugPrint('Accelerometer error: $e'),
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _accidentClearTimer?.cancel();
    _accidentClearTimer = null;
    _localAccidentActive = false;
    _accidentEmittedThisEpisode = false;
    _emit();
  }

  void _onEvent(AccelerometerEvent event) {
    _x = event.x;
    _y = event.y;
    _z = event.z;
    _gForce = sqrt(_x * _x + _y * _y + _z * _z) / 9.8;

    final hardShake = _gForce > gForceThreshold;
    final upsideDown = _z < upsideDownZThreshold;

    if ((hardShake || upsideDown) && !_localAccidentActive) {
      _activateLocalAccident();
    }

    _emit();
  }

  void _activateLocalAccident() {
    _localAccidentActive = true;
    _accidentClearTimer?.cancel();
    _accidentClearTimer = Timer(localAccidentDuration, () {
      _localAccidentActive = false;
      _accidentEmittedThisEpisode = false;
      _emit();
    });

    if (!_accidentEmittedThisEpisode) {
      _accidentEmittedThisEpisode = true;
      if (!_accidentController.isClosed) {
        _accidentController.add({
          'alert': 'ACCIDENT_DETECTED',
          'source': 'phone_accelerometer',
          'g_force': _gForce,
        });
      }
    }

    _emit();
  }

  /// Demo UI: local accident overrides Firebase alert display.
  String resolveAlertStatus(String? firebaseAlert) {
    if (_localAccidentActive) return 'ACCIDENT_DETECTED';
    return firebaseAlert ?? 'NORMAL';
  }

  void _emit() {
    if (!_readingsController.isClosed) {
      _readingsController.add(current);
    }
  }
}
