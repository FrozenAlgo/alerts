import 'package:flutter/foundation.dart';

/// Shared ESP32 online state for dashboard badge and app-bar indicator.
class SystemStatusService extends ChangeNotifier {
  SystemStatusService._();
  static final SystemStatusService instance = SystemStatusService._();

  bool _isOnline = false;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
  }

  void reset() => setOnline(false);
}
