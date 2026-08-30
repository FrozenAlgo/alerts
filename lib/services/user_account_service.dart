import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'contact_notification_service.dart';
import 'fcm_service.dart';

class UserAccountService {
  UserAccountService._();
  static final UserAccountService instance = UserAccountService._();

  /// Deletes Firestore data, clears phone index, then removes the Auth user.
  /// Call [reauthenticate] first if Firebase requires recent login.
  Future<void> deleteAccount(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Not signed in.');
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final phone = userDoc.data()?['phone']?.toString() ?? '';

    final contactsSnap = await userRef.collection('contacts').get();
    if (contactsSnap.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in contactsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final alertsSnap = await FirebaseFirestore.instance
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .get();
    if (alertsSnap.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in alertsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final inboxSnap = await FirebaseFirestore.instance
        .collection('contact_notifications')
        .where('recipientUserId', isEqualTo: userId)
        .get();
    if (inboxSnap.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in inboxSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await FcmService.instance.clearTokenForCurrentUser();
    if (phone.isNotEmpty) {
      await ContactNotificationService.instance.clearPhoneIndex(phone);
    }
    await userRef.delete();
    await user.delete();
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Re-authentication requires an email/password account.',
      );
    }
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> ensureProfileDocument(String userId, {String? email, String? name}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(userId);
    final doc = await ref.get();
    if (doc.exists) return;

    await ref.set({
      'name': name ?? 'OnAlert User',
      if (email != null) 'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('Created missing user profile for $userId');
  }
}
