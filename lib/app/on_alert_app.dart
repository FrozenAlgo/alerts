import 'package:flutter/material.dart';

import 'app_screens.dart';
import 'navigator_key.dart';
import '../theme/app_theme.dart';

class OnAlertApp extends StatelessWidget {
  const OnAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'OnAlert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(),
      home: const SplashScreen(),
    );
  }
}
