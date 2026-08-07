/// Aggregate data for the Teacher Home Dashboard, computed server-side
/// from real student records (see GET /api/teacher/dashboard) -- not
/// mock data. Program/sections are derived from the instructor's
/// assigned students rather than self-declared, since a teacher's
/// students are the source of truth for what they actually teach.
class TeacherDashboard {
  final String instructorName;
  final List<String> programs;
  final List<String> sections;
  final int assignedStudents;
  final int activeStudents;
  final int readyForDeployment;
  final int completedStudents;
  final int requirementsToReview;
  final int attendanceCorrections;

  const TeacherDashboard({
    required this.instructorName,
    required this.programs,
    required this.sections,
    required this.assignedStudents,
    required this.activeStudents,
    required this.readyForDeployment,
    required this.completedStudents,
    required this.requirementsToReview,
    required this.attendanceCorrections,
  });

  factory TeacherDashboard.fromJson(Map<String, dynamic> json) {
    return TeacherDashboard(
      instructorName: json['instructorName'] as String,
      programs: (json['programs'] as List<dynamic>).cast<String>(),
      sections: (json['sections'] as List<dynamic>).cast<String>(),
      assignedStudents: json['assignedStudents'] as int,
      activeStudents: json['activeStudents'] as int,
      readyForDeployment: json['readyForDeployment'] as int,
      completedStudents: json['completedStudents'] as int,
      requirementsToReview: json['requirementsToReview'] as int,
      attendanceCorrections: json['attendanceCorrections'] as int,
    );
  }
}
