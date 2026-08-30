import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'app_database.dart';

class DeviceService {
  static const String latestFirmwareVersion = '1.1.0';

  static Future<void> pairDevice(
    String inputSerial,
    String inputPin,
    String userId,
  ) async {
    final ref = AppDatabase.rtdb.ref('devices/$inputSerial');
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw 'Device Serial Number not recognized.';
    }

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    if (data['security_pin']?.toString() != inputPin) {
      throw 'Invalid Security PIN. Access Denied.';
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'pairedDevice': inputSerial},
      SetOptions(merge: true),
    );
  }

  static Future<void> removeDevice(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'pairedDevice': FieldValue.delete(),
    });
  }

  static Future<String?> getFirmwareVersion(String serial) async {
    final snapshot =
        await AppDatabase.rtdb.ref('devices/$serial/status').get();
    if (!snapshot.exists) return null;
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return data['firmware_version']?.toString();
  }

  static Future<bool> isUpdateAvailable(String serial) async {
    final current = await getFirmwareVersion(serial);
    if (current == null) return false;
    return _compareVersions(current, latestFirmwareVersion) < 0;
  }

  static Future<void> triggerOtaUpdate(String serial) async {
    await AppDatabase.rtdb.ref('devices/$serial/commands/ota').set({
      'action': 'UPDATE',
      'target_version': latestFirmwareVersion,
      'requested_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<int> measureSignalLatency(String serial) async {
    final pingRef = AppDatabase.rtdb.ref('devices/$serial/ping');
    final start = DateTime.now();
    await pingRef.set({'ts': start.millisecondsSinceEpoch});
    await pingRef.onValue.first;
    return DateTime.now().difference(start).inMilliseconds;
  }

  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map(int.parse).toList();
    final pb = b.split('.').map(int.parse).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return pa.length.compareTo(pb.length);
  }
}
