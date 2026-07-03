import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/navigator_key.dart';
import '../screens/full_screen_emergency_alert.dart';
import 'in_app_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      'onalert_emergency',
      'Emergency Alerts',
      description: 'Critical accident and SOS notifications',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageOpened(initial);

    _initialized = true;
    await syncTokenForCurrentUser();
  }

  Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_active') ?? true;
  }

  Future<void> syncTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!await isPushEnabled()) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> clearTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  void _handleForegroundMessage(RemoteMessage message) async {
    if (!await isPushEnabled()) return;

    final title = message.notification?.title ?? 'OnAlert Emergency';
    final body = message.notification?.body ?? 'An alert requires your attention';

    InAppNotificationService.instance.add(
      title: title,
      body: body,
      data: message.data,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'onalert_emergency',
          'Emergency Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );

    if (message.data['type'] == 'ACCIDENT_DETECTED') {
      _showEmergencyOverlay(message.data);
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    InAppNotificationService.instance.add(
      title: message.notification?.title ?? 'OnAlert',
      body: message.notification?.body ?? '',
      data: message.data,
    );
    if (message.data['type'] == 'ACCIDENT_DETECTED') {
      _showEmergencyOverlay(message.data);
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      if (data['type'] == 'ACCIDENT_DETECTED') {
        _showEmergencyOverlay(data);
      }
    } catch (_) {}
  }

  void _showEmergencyOverlay(Map<String, dynamic> data) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final lat = data['lat']?.toString() ?? '0';
    final lng = data['lng']?.toString() ?? '0';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenEmergencyAlert(
          time: DateTime.now(),
          location: '$lat, $lng',
        ),
      ),
    );
  }
}
