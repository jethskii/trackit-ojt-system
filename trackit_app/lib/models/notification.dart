enum NotificationCategory { admin, instructor, system }

/// Where tapping a notification should take the student. Maps to a
/// StudentShell bottom-nav tab; deeper in-module deep linking (e.g.
/// jumping straight to one document row) is a future enhancement.
enum NotificationTarget { home, attendance, documents, profile }

class AppNotification {
  final String id;
  final NotificationCategory category;
  final String title;
  final String message;
  final NotificationTarget target;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.target,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      message: message,
      target: target,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
