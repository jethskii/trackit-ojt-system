/// An instructor announcement as a student sees it -- read fresh from
/// GET /api/announcements (not the flattened notifications-table
/// snapshot), so it always carries the instructor's name and image, and
/// reflects the latest edit.
class StudentAnnouncement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String instructorName;
  final DateTime createdAt;

  const StudentAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.instructorName,
    required this.createdAt,
  });

  factory StudentAnnouncement.fromJson(Map<String, dynamic> json) {
    return StudentAnnouncement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      instructorName: json['instructorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
