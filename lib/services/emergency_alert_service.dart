import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/full_screen_emergency_alert.dart';
import '../config/demo_config.dart';
import 'contact_notification_service.dart';
import 'location_service.dart';
import 'sms_service.dart';

class EmergencyAlertService {
  /// Phone-shake accident: log alert + send SMS from device SIM.
  Future<SmsSendResult> sendLocalAccidentAlert(String userId) async {
    if (!DemoConfig.sendRealSmsOnAccident) {
      return const SmsSendResult(sentCount: 0, detail: 'Demo SMS disabled');
    }

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('sms_active') ?? true)) {
      return const SmsSendResult(sentCount: 0, detail: 'SMS alerts are off in Settings');
    }

    final coords = await LocationService.resolveLocation(
      deviceLat: 0,
      deviceLng: 0,
    );

    final contactsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .get();
    final contacts = contactsSnap.docs.map((d) => d.data()).toList();

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final senderName = userDoc.data()?['name']?.toString() ?? 'OnAlert user';

    String? alertId;
    try {
      final doc = await FirebaseFirestore.instance.collection('alerts').add({
        'userId': userId,
        'type': 'Automated Crash Detection',
        'lat': coords.lat.toString(),
        'lng': coords.lng.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'HELP_REQUESTED',
        'source': 'phone_accelerometer',
        'notifiedNumber': DemoConfig.demoEmergencySmsNumber,
      });
      alertId = doc.id;
    } catch (e) {
      debugPrint('Alert log error: $e');
    }

    if (contacts.isNotEmpty) {
      await ContactNotificationService.instance.notifyRegisteredContacts(
        senderUserId: userId,
        senderName: senderName,
        contacts: contacts,
        alertType: 'Automated Crash Detection',
        lat: coords.lat,
        lng: coords.lng,
        alertId: alertId,
      );
    }

    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${coords.lat},${coords.lng}';
    final message =
        'EMERGENCY ALERT from $senderName! Possible accident detected. Location: $googleMapsUrl';

    return SmsService.instance.sendEmergencySms(
      phoneNumbers: [DemoConfig.demoEmergencySmsNumber],
      message: message,
    );
  }

  Future<void> sendEmergencyAlert(
    BuildContext context,
    List<Map<String, dynamic>> contacts,
    String userId,
    double lat,
    double lng, {
    bool isAuto = false,
  }) async {
    final resolved = await LocationService.resolveLocation(
      deviceLat: lat,
      deviceLng: lng,
    );
    lat = resolved.lat;
    lng = resolved.lng;

    String? alertId;
    final alertType = isAuto ? 'Automated Crash Detection' : 'Manual SOS';

    try {
      final doc = await FirebaseFirestore.instance.collection('alerts').add({
        'userId': userId,
        'type': alertType,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'HELP_REQUESTED',
      });
      alertId = doc.id;
    } catch (e) {
      debugPrint('Logging Error: $e');
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final senderName = userDoc.data()?['name']?.toString() ?? 'OnAlert user';

    await ContactNotificationService.instance.notifyRegisteredContacts(
      senderUserId: userId,
      senderName: senderName,
      contacts: contacts,
      alertType: alertType,
      lat: lat,
      lng: lng,
      alertId: alertId,
    );

    final prefs = await SharedPreferences.getInstance();
    final smsEnabled = prefs.getBool('sms_active') ?? true;

    if (smsEnabled && contacts.isNotEmpty) {
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final message =
          'EMERGENCY ALERT! I have been in an accident. My exact location: $googleMapsUrl';

      final numbers = contacts
          .map((c) => c['number']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(',');

      if (numbers.isNotEmpty) {
        final smsUri = Uri.parse('sms:$numbers?body=${Uri.encodeComponent(message)}');
        try {
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          }
        } catch (e) {
          debugPrint('SMS launch error: $e');
        }
      }
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenEmergencyAlert(
            time: DateTime.now(),
            location: '$lat, $lng',
          ),
        ),
      );
    }
  }
}
