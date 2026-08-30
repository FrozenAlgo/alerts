import 'package:flutter/material.dart';

import '../app/navigator_key.dart';
import '../services/in_app_notification_service.dart';
import '../theme/app_theme.dart';
import '../screens/in_app_notifications_page.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: InAppNotificationService.instance,
      builder: (context, _) {
        final count = InAppNotificationService.instance.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded, color: AppTheme.kCyan),
              onPressed: () {
                final ctx = rootNavigatorKey.currentContext ?? context;
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => const InAppNotificationsPage()));
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.kAlertRed, shape: BoxShape.circle),
                  child: Text('$count', style: const TextStyle(fontSize: 10, color: AppTheme.kTextOnBrand)),
                ),
              ),
          ],
        );
      },
    );
  }
}
