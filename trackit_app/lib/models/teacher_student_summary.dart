import 'ojt_progress.dart';
import 'ojt_stage.dart';

class TeacherStudentSummary {
  final int id;
  final String name;
  final String? avatarUrl;
  final String course;
  final String section;
  final String? companyName;
  final double completedHours;
  final double requiredHours;
  final OjtStage stage;
  final OjtProgressStatus progressStatus;

  const TeacherStudentSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.course,
    required this.section,
    this.companyName,
    required this.completedHours,
    required this.requiredHours,
    required this.stage,
    required this.progressStatus,
  });

  double get progressRatio {
    if (requiredHours <= 0) return 0;
    final ratio = completedHours / requiredHours;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  factory TeacherStudentSummary.fromJson(Map<String, dynamic> json) {
    return TeacherStudentSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      course: json['course'] as String,
      section: json['section'] as String,
      companyName: json['companyName'] as String?,
      completedHours: (json['completedHours'] as num).toDouble(),
      requiredHours: (json['requiredHours'] as num).toDouble(),
      stage: ojtStageFromDb(json['stage'] as String),
      progressStatus: ojtProgressStatusFromDb(json['progressStatus'] as String?),
    );
  }
}
