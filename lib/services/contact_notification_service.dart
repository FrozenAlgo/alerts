import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'fcm_service.dart';
import 'in_app_notification_service.dart';

class ContactNotificationService {
  ContactNotificationService._();
  static final ContactNotificationService instance = ContactNotificationService._();

  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  Future<void> syncPhoneIndex(String userId, String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized.length < 7) return;

    final indexRef = FirebaseFirestore.instance.collection('phone_index').doc(normalized);
    final existing = await indexRef.get();
    if (existing.exists && existing.data()?['userId'] != userId) {
      debugPrint('Phone index conflict for $normalized');
      return;
    }

    await indexRef.set({
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearPhoneIndex(String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return;
    await FirebaseFirestore.instance.collection('phone_index').doc(normalized).delete();
  }

  Future<List<String>> _resolveRecipientUserIds(List<Map<String, dynamic>> contacts) async {
    final ids = <String>{};
    for (final contact in contacts) {
      final normalized = normalizePhone(contact['number']?.toString() ?? '');
      if (normalized.length < 7) continue;

      final doc = await FirebaseFirestore.instance.collection('phone_index').doc(normalized).get();
      final userId = doc.data()?['userId']?.toString();
      if (userId != null && userId.isNotEmpty) ids.add(userId);
    }
    return ids.toList();
  }

  Future<void> notifyRegisteredContacts({
    required String senderUserId,
    required String senderName,
    required List<Map<String, dynamic>> contacts,
    required String alertType,
    required double lat,
    required double lng,
    String? alertId,
  }) async {
    final recipientIds = await _resolveRecipientUserIds(contacts);
    if (recipientIds.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final notifCollection = FirebaseFirestore.instance.collection('contact_notifications');

    for (final recipientId in recipientIds) {
      if (recipientId == senderUserId) continue;

      final ref = notifCollection.doc();
      batch.set(ref, {
        'recipientUserId': recipientId,
        'senderUserId': senderUserId,
        'senderName': senderName,
        'type': 'EMERGENCY',
        'alertType': alertType,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'alertId': alertId,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  StreamSubscription<QuerySnapshot>? _inboxSub;
  final Set<String> _deliveredIds = {};

  void startListening(String userId) {
    _inboxSub?.cancel();
    _inboxSub = FirebaseFirestore.instance
        .collection('contact_notifications')
        .where('recipientUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final id = change.doc.id;
        if (_deliveredIds.contains(id)) continue;
        _deliveredIds.add(id);

        final data = change.doc.data();
        if (data == null) continue;

        final sender = data['senderName']?.toString() ?? 'OnAlert user';
        final alertType = data['alertType']?.toString() ?? 'Emergency';
        final lat = data['lat']?.toString() ?? '0';
        final lng = data['lng']?.toString() ?? '0';

        InAppNotificationService.instance.add(
          title: 'Emergency from $sender',
          body: '$alertType — location shared. Tap to view.',
          data: {
            'type': 'CONTACT_EMERGENCY',
            'lat': lat,
            'lng': lng,
            'senderName': sender,
          },
        );

        await FcmService.instance.showLocalEmergencyNotification(
          title: 'Emergency from $sender',
          body: '$alertType — tap to view location',
          data: {
            'type': 'CONTACT_EMERGENCY',
            'lat': lat,
            'lng': lng,
          },
        );

        await change.doc.reference.update({'read': true, 'deliveredAt': FieldValue.serverTimestamp()});
      }
    });
  }

  void stopListening() {
    _inboxSub?.cancel();
    _inboxSub = null;
    _deliveredIds.clear();
  }
}
