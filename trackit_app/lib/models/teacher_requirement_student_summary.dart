/// One row in the "OJT Requirements" student list -- Official Requirements
/// progress only (Additional Requirements are counted separately once a
/// student is opened, since they don't apply to every student equally).
class TeacherRequirementStudentSummary {
  final int id;
  final String name;
  final String? avatarUrl;
  final String course;
  final String section;
  final int totalDocuments;
  final int completedCount;
  final int needsReviewCount;
  final int pendingCount;
  final double progress;

  const TeacherRequirementStudentSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.course,
    required this.section,
    required this.totalDocuments,
    required this.completedCount,
    required this.needsReviewCount,
    required this.pendingCount,
    required this.progress,
  });

  factory TeacherRequirementStudentSummary.fromJson(Map<String, dynamic> json) {
    return TeacherRequirementStudentSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      course: json['course'] as String,
      section: json['section'] as String,
      totalDocuments: json['totalDocuments'] as int,
      completedCount: json['completedCount'] as int,
      needsReviewCount: json['needsReviewCount'] as int,
      pendingCount: json['pendingCount'] as int,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

class RequirementProgressSummary {
  final int completed;
  final int needsReview;
  final int pending;

  const RequirementProgressSummary({
    required this.completed,
    required this.needsReview,
    required this.pending,
  });

  int get total => completed + needsReview + pending;

  factory RequirementProgressSummary.fromJson(Map<String, dynamic> json) {
    return RequirementProgressSummary(
      completed: json['completed'] as int,
      needsReview: json['needsReview'] as int,
      pending: json['pending'] as int,
    );
  }
}
