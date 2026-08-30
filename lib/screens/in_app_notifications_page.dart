import 'package:flutter/material.dart';

import '../services/in_app_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/ui.dart';

class InAppNotificationsPage extends StatelessWidget {
  const InAppNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: const AppBrandedAppBar(
        title: 'Notifications',
        actions: [_MarkAllReadButton()],
      ),
      body: AnimatedBuilder(
        animation: InAppNotificationService.instance,
        builder: (context, _) {
          final items = InAppNotificationService.instance.items;
          if (items.isEmpty) {
            return const Center(
              child: Text('No notifications yet', style: TextStyle(color: AppTheme.kTextSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i];
              return AppCard(
                padding: EdgeInsets.zero,
                borderColor: n.isRead ? AppTheme.kBorder : AppTheme.kCyan.withValues(alpha: 0.4),
                child: ListTile(
                  title: Text(n.title, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w700)),
                  subtitle: Text(n.body, style: const TextStyle(color: AppTheme.kTextSecondary)),
                  trailing: n.isRead ? null : const Icon(Icons.circle, color: AppTheme.kCyan, size: 10),
                  onTap: () => InAppNotificationService.instance.markRead(n.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => InAppNotificationService.instance.markAllRead(),
      child: const Text('Mark all read', style: TextStyle(color: AppTheme.kCyan, fontWeight: FontWeight.w600)),
    );
  }
}
