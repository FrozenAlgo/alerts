import 'package:flutter/foundation.dart';

class InAppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });
}

class InAppNotificationService extends ChangeNotifier {
  InAppNotificationService._();
  static final InAppNotificationService instance = InAppNotificationService._();

  final List<InAppNotification> _items = [];

  List<InAppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void add({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    _items.insert(
      0,
      InAppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
    notifyListeners();
  }

  void markRead(String id) {
    final item = _items.where((n) => n.id == id).firstOrNull;
    if (item != null && !item.isRead) {
      item.isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final item in _items) {
      item.isRead = true;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
