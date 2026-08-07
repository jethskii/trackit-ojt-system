import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/teacher_weekly_report_row.dart';
import '../../services/teacher_weekly_reports_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/common/status_badge.dart';

/// Read-only compilation of one student's weekly accomplishment reports
/// -- no approve/reject here, per spec ("record/compilation only").
class TeacherWeeklyReportDetailScreen extends StatefulWidget {
  final int studentId;
  final TeacherWeeklyReportsService service;

  const TeacherWeeklyReportDetailScreen({
    super.key,
    required this.studentId,
    required this.service,
  });

  @override
  State<TeacherWeeklyReportDetailScreen> createState() =>
      _TeacherWeeklyReportDetailScreenState();
}

class _TeacherWeeklyReportDetailScreenState extends State<TeacherWeeklyReportDetailScreen> {
  TeacherStudentWeeklyReports? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.service.getStudentReports(widget.studentId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  StatusKind _kindFor(String status) {
    switch (status) {
      case 'submitted':
        return StatusKind.submitted;
      case 'reviewed':
        return StatusKind.reviewed;
      case 'approved':
        return StatusKind.approved;
      case 'needs_revision':
        return StatusKind.needsRevision;
      case 'draft':
        return StatusKind.draft;
      default:
        return StatusKind.missing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          BackNavHeader(subtitle: data?.studentName ?? 'Weekly AR Submissions'),
          Expanded(
            child: _loading || data == null
                ? const SkeletonList()
                : data.reports.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'This student hasn\'t set an OJT Start Date yet, so no '
                        'weekly slots exist.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: data.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _WeekTile(row: data.reports[index], kindFor: _kindFor),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekTile extends StatelessWidget {
  final TeacherWeeklyReportRow row;
  final StatusKind Function(String) kindFor;

  const _WeekTile({required this.row, required this.kindFor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Week ${row.weekNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(kind: kindFor(row.status)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat('MMM d').format(row.weekStartDate)} - '
            '${DateFormat('MMM d, yyyy').format(row.weekEndDate)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (row.description != null && row.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(row.description!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }
}
