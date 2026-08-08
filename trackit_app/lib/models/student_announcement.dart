/// An announcement as a student sees it -- read fresh from
/// GET /api/announcements (not the flattened notifications-table
/// snapshot), so it always carries the author's name and image, and
/// reflects the latest edit. Two possible sources: an instructor
/// announcement targeted at the student's class, or an admin
/// announcement broadcast to all students.
enum AnnouncementSource { instructor, admin }

AnnouncementSource _sourceFromJson(String value) {
  return value == 'admin' ? AnnouncementSource.admin : AnnouncementSource.instructor;
}

class StudentAnnouncement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String authorName;
  final AnnouncementSource source;
  final DateTime createdAt;

  const StudentAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorName,
    required this.source,
    required this.createdAt,
  });

  factory StudentAnnouncement.fromJson(Map<String, dynamic> json) {
    return StudentAnnouncement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      authorName: json['authorName'] as String,
      source: _sourceFromJson(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
