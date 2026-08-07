import 'package:flutter/material.dart';
import '../../models/instructor_class.dart';
import '../../models/ojt_progress.dart';
import '../../models/ojt_stage.dart';
import '../../models/teacher_student_summary.dart';
import '../../services/teacher_classes_service.dart';
import '../../services/teacher_students_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/teacher/class_info_card.dart';
import '../../widgets/teacher/create_class_card.dart';
import '../../widgets/teacher/teacher_student_list_tile.dart';
import '../../widgets/teacher/teacher_summary_tile.dart';

class TeacherStudentsScreen extends StatefulWidget {
  final TeacherClassesService classesService;
  final TeacherStudentsService studentsService;
  final ValueChanged<int> onOpenStudent;

  const TeacherStudentsScreen({
    super.key,
    required this.classesService,
    required this.studentsService,
    required this.onOpenStudent,
  });

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  List<InstructorClass> _classes = [];
  List<TeacherStudentSummary> _students = [];
  bool _loading = true;
  String _query = '';
  String? _companyFilter; // null = All, 'none' = No Company, else a name
  OjtStage? _stageFilter;
  OjtProgressStatus? _progressFilter;
  String _sortBy = 'name'; // 'name' | 'progress'
  bool _sortDescending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.classesService.getClasses(),
      widget.studentsService.getStudents(),
    ]);
    if (!mounted) return;
    setState(() {
      _classes = results[0] as List<InstructorClass>;
      _students = results[1] as List<TeacherStudentSummary>;
      _loading = false;
    });
  }

  Future<void> _refresh() => _load();

  Future<void> _createClass({
    required String program,
    required String section,
    required String academicYear,
  }) async {
    await widget.classesService.createClass(
      program: program,
      section: section,
      academicYear: academicYear,
    );
    await _load();
  }

  List<String> get _companyOptions {
    final names = _students
        .map((s) => s.companyName)
        .whereType<String>()
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  List<TeacherStudentSummary> get _filtered {
    var list = _students.where((s) {
      final matchesQuery =
          _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCompany = _companyFilter == null
          ? true
          : _companyFilter == 'none'
              ? s.companyName == null
              : s.companyName == _companyFilter;
      final matchesStage = _stageFilter == null || s.stage == _stageFilter;
      final matchesProgress =
          _progressFilter == null || s.progressStatus == _progressFilter;
      return matchesQuery && matchesCompany && matchesStage && matchesProgress;
    }).toList();

    list.sort((a, b) {
      final result = _sortBy == 'progress'
          ? a.progressRatio.compareTo(b.progressRatio)
          : a.name.compareTo(b.name);
      return _sortDescending ? -result : result;
    });
    return list;
  }

  int _countByStage(OjtStage stage) =>
      _students.where((s) => s.stage == stage).length;

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _companyFilter,
                    decoration: const InputDecoration(labelText: 'Assigned Company'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(
                        value: 'none',
                        child: Text('No Company Yet'),
                      ),
                      for (final name in _companyOptions)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _companyFilter = value);
                      setState(() => _companyFilter = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OjtStage?>(
                    initialValue: _stageFilter,
                    decoration: const InputDecoration(labelText: 'OJT Stage'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                        value: OjtStage.notStarted,
                        child: Text('Not Started'),
                      ),
                      DropdownMenuItem(
                        value: OjtStage.readyForDeployment,
                        child: Text('Preparing'),
                      ),
                      DropdownMenuItem(value: OjtStage.active, child: Text('Active')),
                      DropdownMenuItem(
                        value: OjtStage.completed,
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _stageFilter = value);
                      setState(() => _stageFilter = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OjtProgressStatus?>(
                    initialValue: _progressFilter,
                    decoration: const InputDecoration(labelText: 'OJT Progress'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                        value: OjtProgressStatus.onTrack,
                        child: Text('On Track'),
                      ),
                      DropdownMenuItem(
                        value: OjtProgressStatus.behind,
                        child: Text('Behind'),
                      ),
                      DropdownMenuItem(
                        value: OjtProgressStatus.needsAttention,
                        child: Text('Needs Attention'),
                      ),
                      DropdownMenuItem(
                        value: OjtProgressStatus.aheadOfSchedule,
                        child: Text('Ahead of Schedule'),
                      ),
                      DropdownMenuItem(
                        value: OjtProgressStatus.completed,
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _progressFilter = value);
                      setState(() => _progressFilter = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: const InputDecoration(labelText: 'Sort By'),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'progress', child: Text('OJT Progress')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => _sortBy = value);
                      setState(() => _sortBy = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryMaroon,
                    title: const Text('Descending'),
                    value: _sortDescending,
                    onChanged: (value) {
                      setSheetState(() => _sortDescending = value);
                      setState(() => _sortDescending = value);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppHeader(title: 'Students', subtitle: 'Personal Dashboard'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -20),
                              child: _classes.isEmpty
                                  ? CreateClassCard(onCreate: _createClass)
                                  : ClassInfoCard(instructorClass: _classes.first),
                            ),
                            if (_classes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
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
                                  const SizedBox(width: 8),
                                  Material(
                                    color: AppColors.cardWhite,
                                    borderRadius: BorderRadius.circular(14),
                                    child: IconButton(
                                      onPressed: _openFilterSheet,
                                      tooltip: 'Filter & sort students',
                                      icon: const Icon(
                                        Icons.tune,
                                        color: AppColors.primaryMaroon,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.9,
                                children: [
                                  TeacherSummaryTile(
                                    icon: Icons.groups_outlined,
                                    iconColor: AppColors.primaryMaroon,
                                    backgroundColor: AppColors.statRedBg,
                                    label: 'Assigned Students',
                                    value: '${_students.length}',
                                  ),
                                  TeacherSummaryTile(
                                    icon: Icons.directions_run,
                                    iconColor: AppColors.statRedIcon,
                                    backgroundColor: AppColors.statRedBg,
                                    label: 'Active Students',
                                    value: '${_countByStage(OjtStage.active)}',
                                  ),
                                  TeacherSummaryTile(
                                    icon: Icons.flight_takeoff,
                                    iconColor: AppColors.statOrangeIcon,
                                    backgroundColor: AppColors.statOrangeBg,
                                    label: 'Preparing',
                                    value:
                                        '${_countByStage(OjtStage.readyForDeployment)}',
                                  ),
                                  TeacherSummaryTile(
                                    icon: Icons.check_circle_outline,
                                    iconColor: AppColors.successGreenText,
                                    backgroundColor: AppColors.successGreenBg,
                                    label: 'Completed Students',
                                    value: '${_countByStage(OjtStage.completed)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Student List',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_filtered.isEmpty)
                                EmptyStateView(
                                  icon: Icons.groups_outlined,
                                  title: _students.isEmpty
                                      ? 'No students yet'
                                      : 'No matching students',
                                  message: _students.isEmpty
                                      ? 'Share your class activation code so '
                                          'students can join.'
                                      : 'Try a different search or filter.',
                                )
                              else
                                for (final student in _filtered) ...[
                                  TeacherStudentListTile(
                                    student: student,
                                    onTap: () => widget.onOpenStudent(student.id),
                                  ),
                                  const SizedBox(height: 10),
                                ],
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
