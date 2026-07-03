import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/on_alert_app.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmService.instance.initialize();
  runApp(const OnAlertApp());
}
