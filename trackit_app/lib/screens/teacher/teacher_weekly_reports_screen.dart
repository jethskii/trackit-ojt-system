import 'package:flutter/material.dart';
import '../../models/teacher_weekly_report_row.dart';
import '../../services/teacher_weekly_reports_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

/// Weekly AR Submissions -- "record/compilation only" per spec, so
/// there's no approve/reject action here, unlike Official Requirements.
class TeacherWeeklyReportsScreen extends StatefulWidget {
  final TeacherWeeklyReportsService service;
  final ValueChanged<int> onOpenStudent;

  const TeacherWeeklyReportsScreen({
    super.key,
    required this.service,
    required this.onOpenStudent,
  });

  @override
  State<TeacherWeeklyReportsScreen> createState() => _TeacherWeeklyReportsScreenState();
}

class _TeacherWeeklyReportsScreenState extends State<TeacherWeeklyReportsScreen> {
  List<TeacherWeeklyReportStudentSummary> _students = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await widget.service.getStudents();
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  List<TeacherWeeklyReportStudentSummary> get _filtered {
    if (_query.isEmpty) return _students;
    final q = _query.toLowerCase();
    return _students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Weekly AR Submissions'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search Student...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.cardWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              EmptyStateView(
                                icon: Icons.summarize_outlined,
                                title: 'No students found',
                                message: 'Try a different search.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final student = _filtered[index];
                              return _StudentTile(
                                student: student,
                                onTap: () => widget.onOpenStudent(student.id),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final TeacherWeeklyReportStudentSummary student;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ratio = student.expectedWeeks > 0 ? student.submittedWeeks / student.expectedWeeks : 0.0;
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.background,
                backgroundImage: student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
                child: student.avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.primaryMaroon, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.course} - ${student.section}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0, 1).toDouble(),
                        minHeight: 6,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryMaroon),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${student.submittedWeeks}/${student.expectedWeeks}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
