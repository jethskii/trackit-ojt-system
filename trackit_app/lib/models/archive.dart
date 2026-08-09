/// One past academic year available in the Archive -- the current/active
/// year never appears here (enforced server-side too, not just hidden in
/// the UI).
class ArchiveAcademicYear {
  final String year;
  final int classCount;

  const ArchiveAcademicYear({required this.year, required this.classCount});

  factory ArchiveAcademicYear.fromJson(Map<String, dynamic> json) {
    return ArchiveAcademicYear(
      year: json['year'] as String,
      classCount: json['classCount'] as int,
    );
  }
}

enum ArchiveStudentStatus { assigned, preparing, inactive }

ArchiveStudentStatus _archiveStatusFromDb(String value) {
  switch (value) {
    case 'assigned':
      return ArchiveStudentStatus.assigned;
    case 'inactive':
      return ArchiveStudentStatus.inactive;
    default:
      return ArchiveStudentStatus.preparing;
  }
}

/// A student as they appeared in an archived class -- includes real
/// completed/required hours (computed the same way as the live Class
/// Management view), read fresh from the same source tables each time
/// since there's no separate frozen snapshot (see the Archive screen's
/// doc comment for why).
class ArchiveClassStudent {
  final int id;
  final String name;
  final String? studentNumber;
  final String? avatarUrl;
  final String? assignedCompany;
  final ArchiveStudentStatus status;
  final String? contactPerson;
  final String? ojtSupervisor;
  final double completedHours;
  final double requiredHours;

  const ArchiveClassStudent({
    required this.id,
    required this.name,
    this.studentNumber,
    this.avatarUrl,
    this.assignedCompany,
    required this.status,
    this.contactPerson,
    this.ojtSupervisor,
    required this.completedHours,
    required this.requiredHours,
  });

  factory ArchiveClassStudent.fromJson(Map<String, dynamic> json) {
    return ArchiveClassStudent(
      id: json['id'] as int,
      name: json['name'] as String,
      studentNumber: json['studentNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      assignedCompany: json['assignedCompany'] as String?,
      status: _archiveStatusFromDb(json['status'] as String),
      contactPerson: json['contactPerson'] as String?,
      ojtSupervisor: json['ojtSupervisor'] as String?,
      completedHours: (json['completedHours'] as num).toDouble(),
      requiredHours: (json['requiredHours'] as num).toDouble(),
    );
  }
}

class ArchiveClassDetail {
  final int id;
  final String program;
  final String? programFullName;
  final String section;
  final String academicYear;
  final String? yearLevel;
  final String instructorName;
  final String instructorEmail;
  final int totalStudents;
  final List<ArchiveClassStudent> students;

  const ArchiveClassDetail({
    required this.id,
    required this.program,
    this.programFullName,
    required this.section,
    required this.academicYear,
    this.yearLevel,
    required this.instructorName,
    required this.instructorEmail,
    required this.totalStudents,
    required this.students,
  });

  factory ArchiveClassDetail.fromJson(Map<String, dynamic> json) {
    return ArchiveClassDetail(
      id: json['id'] as int,
      program: json['program'] as String,
      programFullName: json['programFullName'] as String?,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      yearLevel: json['yearLevel'] as String?,
      instructorName: json['instructorName'] as String? ?? 'Unassigned',
      instructorEmail: json['instructorEmail'] as String? ?? '',
      totalStudents: json['totalStudents'] as int,
      students: (json['students'] as List<dynamic>)
          .map((s) => ArchiveClassStudent.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
