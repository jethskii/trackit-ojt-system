import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ojt_stage.dart';
import '../../models/teacher_student_detail.dart';
import '../../services/teacher_students_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/ojt_progress_status_badge.dart';
import '../../widgets/common/skeleton_list_tile.dart';

/// Plain, read-only info view -- no review/approve actions yet (that
/// needs the Requirements-review and Correction-review workflows, which
/// aren't built).
class TeacherStudentDetailScreen extends StatefulWidget {
  final int studentId;
  final TeacherStudentsService studentsService;

  const TeacherStudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentsService,
  });

  @override
  State<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState
    extends State<TeacherStudentDetailScreen> {
  TeacherStudentDetail? _student;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final student = await widget.studentsService.getStudentDetail(widget.studentId);
    if (!mounted) return;
    setState(() {
      _student = student;
      _loading = false;
    });
  }

  String _stageLabel(OjtStage stage) {
    switch (stage) {
      case OjtStage.notStarted:
        return 'Not Started';
      case OjtStage.readyForDeployment:
        return 'Preparing for Deployment';
      case OjtStage.active:
        return 'Active';
      case OjtStage.completed:
        return 'Completed';
    }
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Student Profile'),
          Expanded(
            child: _loading || _student == null
                ? const SkeletonList()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderCard(student: _student!),
                        const SizedBox(height: 16),
                        _SectionCard(
                          icon: Icons.badge_outlined,
                          title: 'Student Information',
                          rows: [
                            _InfoRow('Full Name', _student!.name),
                            _InfoRow('Program', _student!.course),
                            _InfoRow('Section', _student!.section),
                            _InfoRow(
                              'Student Number',
                              _student!.studentNumber ?? 'Not set',
                            ),
                            _InfoRow('Email', _student!.email),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          icon: Icons.family_restroom_outlined,
                          title: 'Contact Person (Family/Guardian)',
                          rows: [
                            _InfoRow(
                              'Emergency Contact',
                              _student!.contactPerson?.isNotEmpty == true
                                  ? _student!.contactPerson!
                                  : 'Not set',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          icon: Icons.apartment_outlined,
                          title: 'Assigned Company',
                          rows: _student!.company != null
                              ? [
                                  _InfoRow('Company', _student!.company!.name),
                                  _InfoRow('Address', _student!.company!.address),
                                  _InfoRow(
                                    'Supervisor',
                                    _student!.company!.supervisorName,
                                  ),
                                  _InfoRow(
                                    'Contact Number',
                                    _student!.company!.contactNumber,
                                  ),
                                ]
                              : [_InfoRow('Company', 'Not yet deployed')],
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          icon: Icons.bar_chart,
                          title: 'OJT Hours Progress',
                          rows: [
                            _InfoRow(
                              'Completed / Required',
                              '${_formatHours(_student!.progress.completedHours)} / '
                                  '${_formatHours(_student!.progress.requiredHours)} hrs',
                            ),
                            _InfoRow(
                              'Average Hours / Day',
                              '${_formatHours(_student!.progress.averageHoursPerDay)} hrs',
                            ),
                            _InfoRow(
                              'Weekly Average',
                              '${_formatHours(_student!.progress.weeklyAverageHours)} hrs',
                            ),
                          ],
                          trailing: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: _student!.progress.progressRatio,
                              minHeight: 8,
                              backgroundColor: AppColors.background,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primaryMaroon,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          icon: Icons.event_available_outlined,
                          title: 'Attendance Summary',
                          rows: [
                            _InfoRow(
                              'Days Attended',
                              '${_student!.progress.daysAttended} days',
                            ),
                            _InfoRow(
                              'Last Attendance',
                              _student!.progress.lastAttendanceDate != null
                                  ? DateFormat('MMM d, yyyy').format(
                                      _student!.progress.lastAttendanceDate!,
                                    )
                                  : 'No record yet',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          icon: Icons.flag_outlined,
                          title: 'OJT Status',
                          rows: [
                            _InfoRow('Stage', _stageLabel(_student!.stage)),
                          ],
                          trailing: Align(
                            alignment: Alignment.centerLeft,
                            child: OjtProgressStatusBadge(
                              status: _student!.progressStatus,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final TeacherStudentDetail student;

  const _HeaderCard({required this.student});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.background,
            backgroundImage: student.avatarUrl != null
                ? NetworkImage(student.avatarUrl!)
                : null,
            child: student.avatarUrl == null
                ? Text(
                    _initials(student.name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMaroon,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.course} - ${student.section}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow> rows;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.rows,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryMaroon),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (trailing != null) ...[const SizedBox(height: 4), trailing!],
        ],
      ),
    );
  }
}
