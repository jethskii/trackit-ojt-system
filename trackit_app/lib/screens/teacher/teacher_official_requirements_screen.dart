import 'package:flutter/material.dart';
import '../../models/teacher_requirement_student_summary.dart';
import '../../services/teacher_requirements_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/teacher/teacher_requirement_student_list_tile.dart';

/// "Official Requirements" -- submission list across every assigned
/// student, filterable by status. Tapping a student opens the full
/// review screen (Progress Summary + stage-locked checklist).
class TeacherOfficialRequirementsScreen extends StatefulWidget {
  final TeacherRequirementsService service;
  final ValueChanged<int> onOpenStudent;

  const TeacherOfficialRequirementsScreen({
    super.key,
    required this.service,
    required this.onOpenStudent,
  });

  @override
  State<TeacherOfficialRequirementsScreen> createState() =>
      _TeacherOfficialRequirementsScreenState();
}

class _TeacherOfficialRequirementsScreenState
    extends State<TeacherOfficialRequirementsScreen> {
  List<TeacherRequirementStudentSummary> _students = [];
  bool _loading = true;
  String _query = '';
  String? _statusFilter; // null | 'needsReview' | 'completed' | 'pending'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await widget.service.getStudents(
      search: _query.isEmpty ? null : _query,
      status: _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Official Requirements'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) {
                                      _query = v;
                                      _load();
                                    },
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
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _FilterChip(
                                    label: 'All',
                                    selected: _statusFilter == null,
                                    onTap: () {
                                      setState(() => _statusFilter = null);
                                      _load();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'Needs Review',
                                    selected: _statusFilter == 'needsReview',
                                    onTap: () {
                                      setState(() => _statusFilter = 'needsReview');
                                      _load();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'Completed',
                                    selected: _statusFilter == 'completed',
                                    onTap: () {
                                      setState(() => _statusFilter = 'completed');
                                      _load();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'Pending',
                                    selected: _statusFilter == 'pending',
                                    onTap: () {
                                      setState(() => _statusFilter = 'pending');
                                      _load();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_students.isEmpty)
                              const EmptyStateView(
                                icon: Icons.folder_shared_outlined,
                                title: 'No students found',
                                message: 'Try a different search or filter.',
                              )
                            else
                              for (final student in _students) ...[
                                TeacherRequirementStudentListTile(
                                  student: student,
                                  onTap: () => widget.onOpenStudent(student.id),
                                ),
                                const SizedBox(height: 10),
                              ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryMaroon,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}
