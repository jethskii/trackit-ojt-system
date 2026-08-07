import 'package:flutter/foundation.dart';
import '../models/instructor_notification.dart';
import 'api_client.dart';

abstract class TeacherNotificationsService extends ChangeNotifier {
  List<InstructorNotification> get notifications;
  int get unreadCount;

  Future<void> load();
  Future<void> markAsRead(String id);
}

class HttpTeacherNotificationsService extends ChangeNotifier
    implements TeacherNotificationsService {
  final ApiClient client;
  List<InstructorNotification> _notifications = [];

  HttpTeacherNotificationsService(this.client);

  @override
  List<InstructorNotification> get notifications => List.unmodifiable(_notifications);

  @override
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> load() async {
    final response = await client.get('/api/teacher/notifications');
    final rows = response['notifications'] as List<dynamic>;
    _notifications = rows
        .map(
          (row) => InstructorNotification.fromJson(row as Map<String, dynamic>),
        )
        .toList();
    notifyListeners();
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    await client.patch('/api/teacher/notifications/$id/read');
  }
}
