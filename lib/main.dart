import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/on_alert_app.dart';
import '../services/app_database.dart';
import '../services/fcm_service.dart';
import '../services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppDatabase.initialize();
  await GoogleAuthService.instance.initialize();
  await FcmService.instance.initialize();
  runApp(const OnAlertApp());
}
