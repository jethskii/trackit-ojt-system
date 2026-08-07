import 'ojt_progress.dart';
import 'ojt_stage.dart';

class TeacherStudentCompany {
  final String name;
  final String address;
  final String supervisorName;
  final String contactNumber;

  const TeacherStudentCompany({
    required this.name,
    required this.address,
    required this.supervisorName,
    required this.contactNumber,
  });

  factory TeacherStudentCompany.fromJson(Map<String, dynamic> json) {
    return TeacherStudentCompany(
      name: json['name'] as String,
      address: json['address'] as String,
      supervisorName: json['supervisorName'] as String,
      contactNumber: json['contactNumber'] as String,
    );
  }
}

class TeacherStudentProgressSummary {
  final double completedHours;
  final double requiredHours;
  final int daysAttended;
  final double averageHoursPerDay;
  final double weeklyAverageHours;
  final DateTime? lastAttendanceDate;

  const TeacherStudentProgressSummary({
    required this.completedHours,
    required this.requiredHours,
    required this.daysAttended,
    required this.averageHoursPerDay,
    required this.weeklyAverageHours,
    this.lastAttendanceDate,
  });

  double get progressRatio {
    if (requiredHours <= 0) return 0;
    final ratio = completedHours / requiredHours;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  factory TeacherStudentProgressSummary.fromJson(Map<String, dynamic> json) {
    return TeacherStudentProgressSummary(
      completedHours: (json['completedHours'] as num).toDouble(),
      requiredHours: (json['requiredHours'] as num).toDouble(),
      daysAttended: json['daysAttended'] as int,
      averageHoursPerDay: (json['averageHoursPerDay'] as num).toDouble(),
      weeklyAverageHours: (json['weeklyAverageHours'] as num).toDouble(),
      lastAttendanceDate: json['lastAttendanceDate'] != null
          ? DateTime.parse(json['lastAttendanceDate'] as String)
          : null,
    );
  }
}

class TeacherStudentDetail {
  final int id;
  final String name;
  final String email;
  final String course;
  final String section;
  final String? studentNumber;
  final String? yearLevel;
  final String? avatarUrl;
  final String? contactPerson;
  final TeacherStudentCompany? company;
  final TeacherStudentProgressSummary progress;
  final OjtStage stage;
  final OjtProgressStatus progressStatus;

  const TeacherStudentDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.course,
    required this.section,
    this.studentNumber,
    this.yearLevel,
    this.avatarUrl,
    this.contactPerson,
    this.company,
    required this.progress,
    required this.stage,
    required this.progressStatus,
  });

  factory TeacherStudentDetail.fromJson(Map<String, dynamic> json) {
    return TeacherStudentDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      course: json['course'] as String,
      section: json['section'] as String,
      studentNumber: json['studentNumber'] as String?,
      yearLevel: json['yearLevel'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      contactPerson: json['contactPerson'] as String?,
      company: json['company'] != null
          ? TeacherStudentCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      progress: TeacherStudentProgressSummary.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
      stage: ojtStageFromDb(json['stage'] as String),
      progressStatus: ojtProgressStatusFromDb(json['progressStatus'] as String?),
    );
  }
}
