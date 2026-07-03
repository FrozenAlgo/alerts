import 'package:permission_handler/permission_handler.dart';

enum OnAlertPermission {
  location,
  sms,
  notification,
  bluetooth,
}

class PermissionService {
  static Permission _map(OnAlertPermission p) {
    switch (p) {
      case OnAlertPermission.location:
        return Permission.locationWhenInUse;
      case OnAlertPermission.sms:
        return Permission.sms;
      case OnAlertPermission.notification:
        return Permission.notification;
      case OnAlertPermission.bluetooth:
        return Permission.bluetoothScan;
    }
  }

  static Future<bool> isGranted(OnAlertPermission permission) async {
    return _map(permission).isGranted;
  }

  static Future<bool> request(OnAlertPermission permission) async {
    final result = await _map(permission).request();
    return result.isGranted;
  }

  static Future<Map<OnAlertPermission, bool>> requestAll() async {
    final results = <OnAlertPermission, bool>{};
    for (final p in OnAlertPermission.values) {
      if (p == OnAlertPermission.bluetooth) continue;
      results[p] = await request(p);
    }
    return results;
  }

  static Future<Map<OnAlertPermission, bool>> statusAll() async {
    final results = <OnAlertPermission, bool>{};
    for (final p in OnAlertPermission.values) {
      results[p] = await isGranted(p);
    }
    return results;
  }

  static Future<void> openSettings() => openAppSettings();
}
