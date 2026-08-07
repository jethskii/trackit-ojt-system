/// One row in the Attendance > Records log -- a single student's clock
/// in/out for a single day, across every student assigned to this
/// instructor.
class TeacherAttendanceRecord {
  final int id;
  final int studentId;
  final String studentName;
  final String? avatarUrl;
  final DateTime workDate;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final double? hoursRendered;

  const TeacherAttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.workDate,
    this.clockIn,
    this.clockOut,
    this.hoursRendered,
  });

  factory TeacherAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceRecord(
      id: json['id'] as int,
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      workDate: DateTime.parse(json['workDate'] as String),
      clockIn: json['clockIn'] != null ? DateTime.parse(json['clockIn'] as String) : null,
      clockOut: json['clockOut'] != null ? DateTime.parse(json['clockOut'] as String) : null,
      hoursRendered: json['hoursRendered'] != null
          ? (json['hoursRendered'] as num).toDouble()
          : null,
    );
  }
}
