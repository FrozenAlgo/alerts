import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/full_screen_emergency_alert.dart';
import 'location_service.dart';

class EmergencyAlertService {
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

    try {
      await FirebaseFirestore.instance.collection('alerts').add({
        'userId': userId,
        'type': isAuto ? 'Automated Crash Detection' : 'Manual SOS',
        'lat': lat.toString(),
        'lng': lng.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'HELP_REQUESTED',
      });
    } catch (e) {
      debugPrint('Logging Error: $e');
    }

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
