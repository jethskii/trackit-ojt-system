class AnnouncementTarget {
  final int classId;
  final String program;
  final String section;

  const AnnouncementTarget({
    required this.classId,
    required this.program,
    required this.section,
  });

  String get label => '$program - $section';

  factory AnnouncementTarget.fromJson(Map<String, dynamic> json) {
    return AnnouncementTarget(
      classId: json['classId'] as int,
      program: json['program'] as String,
      section: json['section'] as String,
    );
  }
}

/// An instructor-authored post targeted at their own class(es)/section(s).
/// Creating one also fans out into the student-facing notifications feed
/// for every student in the targeted sections (see
/// TeacherAnnouncementsService.createAnnouncement).
class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final List<AnnouncementTarget> targets;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.targets,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'].toString(),
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      targets: (json['targets'] as List<dynamic>)
          .map((t) => AnnouncementTarget.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
