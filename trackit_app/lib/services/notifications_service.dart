import 'package:flutter/foundation.dart';
import '../models/notification.dart';

/// Repository-style interface so a real API (and eventually push/WebSocket
/// delivery) can be dropped in later. For now this is session-local: no
/// backend push infrastructure exists yet, so nothing here is delivered
/// in real time -- the list simply reflects the current in-memory state
/// when the tab is opened.
abstract class NotificationsService extends ChangeNotifier {
  List<AppNotification> get notifications;
  int get unreadCount;

  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
}

class MockNotificationsService extends ChangeNotifier
    implements NotificationsService {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'n-1',
      category: NotificationCategory.instructor,
      title: 'Resume Approved',
      message: 'Your Resume submission for Requirements has been approved.',
      target: NotificationTarget.documents,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    AppNotification(
      id: 'n-2',
      category: NotificationCategory.admin,
      title: 'Deadline Reminder',
      message:
          'Submit your Pre-Application Form before the end of this week.',
      target: NotificationTarget.documents,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n-3',
      category: NotificationCategory.system,
      title: 'Account Verified',
      message: 'Your student account has been verified by the department.',
      target: NotificationTarget.profile,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-4',
      category: NotificationCategory.instructor,
      title: 'Missing Attendance',
      message: 'You have no attendance record for yesterday. Please clock in.',
      target: NotificationTarget.attendance,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    AppNotification(
      id: 'n-5',
      category: NotificationCategory.admin,
      title: 'Company Assigned',
      message: 'You have been assigned to GMMTV Company Limited for your OJT.',
      target: NotificationTarget.profile,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-6',
      category: NotificationCategory.instructor,
      title: 'Weekly Report Submitted',
      message: 'Your Week 2 Activity Report was submitted successfully.',
      target: NotificationTarget.documents,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-7',
      category: NotificationCategory.system,
      title: 'Adviser Assigned',
      message: 'Gawin Caskey has been assigned as your OJT Adviser.',
      target: NotificationTarget.profile,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-8',
      category: NotificationCategory.admin,
      title: 'New Downloadable Form',
      message: 'A new MOA template is now available in OJT Requirements.',
      target: NotificationTarget.documents,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-9',
      category: NotificationCategory.instructor,
      title: 'Evaluation Schedule',
      message: 'Your mid-term evaluation is scheduled for next Monday.',
      target: NotificationTarget.home,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
    ),
  ];

  @override
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  @override
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  @override
  Future<void> markAllAsRead() async {
    var changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  @override
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
