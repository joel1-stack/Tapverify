import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

/// A single in-app notification (bell feed), shared by every user kind.
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.icon = Icons.notifications_rounded,
    this.color = AppColors.primary,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime at;
  final IconData icon;
  final Color color;
  bool read;
}

/// In-memory notification feed. A [ValueNotifier] holds the unread count so
/// the bell badge updates everywhere automatically.
class NotificationCenter {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  final ValueNotifier<int> unread = ValueNotifier<int>(0);

  final List<AppNotification> _items = [];
  int _seq = 0;

  List<AppNotification> get items => List.unmodifiable(_items);

  void notify({
    required String title,
    required String body,
    IconData icon = Icons.notifications_rounded,
    Color color = AppColors.primary,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: 'n-${_seq++}',
        title: title,
        body: body,
        at: DateTime.now(),
        icon: icon,
        color: color,
      ),
    );
    unread.value = _items.where((n) => !n.read).length;
  }

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    unread.value = 0;
  }

  void markRead(String id) {
    for (final n in _items) {
      if (n.id == id) n.read = true;
    }
    unread.value = _items.where((n) => !n.read).length;
  }
}