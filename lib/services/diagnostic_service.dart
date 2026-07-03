import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'device_service.dart';
import 'fcm_service.dart';
import 'location_service.dart';
import 'permission_service.dart';

class DiagnosticResult {
  final String label;
  final bool passed;
  final String detail;

  DiagnosticResult(this.label, this.passed, this.detail);
}

class DiagnosticService {
  static Future<List<DiagnosticResult>> runFullDiagnostic(String userId) async {
    final results = <DiagnosticResult>[];

    final permissions = await PermissionService.statusAll();
    results.add(DiagnosticResult(
      'Location Permission',
      permissions[OnAlertPermission.location] ?? false,
      permissions[OnAlertPermission.location] == true ? 'Granted' : 'Denied',
    ));
    results.add(DiagnosticResult(
      'SMS Permission',
      permissions[OnAlertPermission.sms] ?? false,
      permissions[OnAlertPermission.sms] == true ? 'Granted' : 'Denied',
    ));
    results.add(DiagnosticResult(
      'Notification Permission',
      permissions[OnAlertPermission.notification] ?? false,
      permissions[OnAlertPermission.notification] == true ? 'Granted' : 'Denied',
    ));

    final fcmToken = await FcmService.instance.getToken();
    results.add(DiagnosticResult(
      'FCM Token',
      fcmToken != null && fcmToken.isNotEmpty,
      fcmToken != null ? 'Valid' : 'Missing',
    ));

    final phoneGps = await LocationService.getPhoneLocation();
    results.add(DiagnosticResult(
      'Phone GPS',
      phoneGps != null,
      phoneGps != null
          ? '${phoneGps.lat.toStringAsFixed(4)}, ${phoneGps.lng.toStringAsFixed(4)}'
          : 'Unavailable',
    ));

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final serial = userDoc.data()?['pairedDevice']?.toString() ?? '';
    results.add(DiagnosticResult(
      'Device Paired',
      serial.isNotEmpty,
      serial.isEmpty ? 'No device' : serial,
    ));

    if (serial.isNotEmpty) {
      try {
        final latency = await DeviceService.measureSignalLatency(serial);
        results.add(DiagnosticResult(
          'RTDB Signal',
          latency < 5000,
          'Latency: ${latency}ms',
        ));
        final fw = await DeviceService.getFirmwareVersion(serial);
        results.add(DiagnosticResult(
          'Firmware Version',
          fw != null,
          fw ?? 'Unknown',
        ));
      } catch (e) {
        results.add(DiagnosticResult('RTDB Signal', false, e.toString()));
      }
    }

    final contacts = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .get();
    results.add(DiagnosticResult(
      'Emergency Contacts',
      contacts.docs.isNotEmpty,
      '${contacts.docs.length} contact(s)',
    ));

    final uid = FirebaseAuth.instance.currentUser?.uid;
    results.add(DiagnosticResult(
      'Auth Session',
      uid != null,
      uid != null ? 'Active' : 'Signed out',
    ));

    return results;
  }
}
