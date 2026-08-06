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

  static NotificationTarget _targetFromModule(String? module) {
    switch (module) {
      case 'attendance':
        return NotificationTarget.attendance;
      case 'documents':
        return NotificationTarget.documents;
      case 'profile':
        return NotificationTarget.profile;
      default:
        return NotificationTarget.home;
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NotificationCategory.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      target: _targetFromModule(json['related_module'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

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
