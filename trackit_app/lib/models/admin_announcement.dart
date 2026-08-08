enum AdminAnnouncementAudience { all, instructors, students }

AdminAnnouncementAudience adminAudienceFromDb(String value) {
  switch (value) {
    case 'instructors':
      return AdminAnnouncementAudience.instructors;
    case 'students':
      return AdminAnnouncementAudience.students;
    default:
      return AdminAnnouncementAudience.all;
  }
}

String adminAudienceToDb(AdminAnnouncementAudience audience) {
  switch (audience) {
    case AdminAnnouncementAudience.all:
      return 'all';
    case AdminAnnouncementAudience.instructors:
      return 'instructors';
    case AdminAnnouncementAudience.students:
      return 'students';
  }
}

String adminAudienceLabel(AdminAnnouncementAudience audience) {
  switch (audience) {
    case AdminAnnouncementAudience.all:
      return 'All Users';
    case AdminAnnouncementAudience.instructors:
      return 'Instructors';
    case AdminAnnouncementAudience.students:
      return 'Students';
  }
}

/// An announcement the admin has broadcast school-wide -- fans out into
/// students' and/or instructors' notification feeds and (for students)
/// the rich Announcement feed on their Dashboard, depending on
/// [targetAudience].
class AdminAnnouncement {
  final int id;
  final String title;
  final String content;
  final AdminAnnouncementAudience targetAudience;
  final String? imageUrl;
  final String adminName;
  final DateTime createdAt;

  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.targetAudience,
    this.imageUrl,
    required this.adminName,
    required this.createdAt,
  });

  factory AdminAnnouncement.fromJson(Map<String, dynamic> json) {
    return AdminAnnouncement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      targetAudience: adminAudienceFromDb(json['targetAudience'] as String),
      imageUrl: json['imageUrl'] as String?,
      adminName: json['adminName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
