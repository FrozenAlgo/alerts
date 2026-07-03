import 'package:flutter/material.dart';

import '../services/in_app_notification_service.dart';
import '../theme/app_theme.dart';

class InAppNotificationsPage extends StatelessWidget {
  const InAppNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => InAppNotificationService.instance.markAllRead(),
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.kPrimaryCyan)),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: InAppNotificationService.instance,
        builder: (context, _) {
          final items = InAppNotificationService.instance.items;
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet', style: TextStyle(color: Colors.blueGrey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.kGlassDecoration.copyWith(
                  border: Border.all(
                    color: n.isRead ? Colors.transparent : AppTheme.kPrimaryCyan.withOpacity(0.4),
                  ),
                ),
                child: ListTile(
                  title: Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(n.body, style: const TextStyle(color: Colors.blueGrey)),
                  trailing: n.isRead ? null : const Icon(Icons.circle, color: AppTheme.kPrimaryCyan, size: 10),
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
