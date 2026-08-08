import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/admin/admin_pagination.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

const int _pageSize = 10;

/// Embedded in AdminClassManagementScreen's right-hand pane (not pushed as
/// a route) -- a ValueKey(classId) on the caller's side forces a fresh
/// State whenever the selected class changes, so this can stay a simple
/// "load once in initState" widget instead of watching for id changes.
class AdminClassDetailPanel extends StatefulWidget {
  final int classId;
  final AdminClassesService classesService;

  const AdminClassDetailPanel({
    super.key,
    required this.classId,
    required this.classesService,
  });

  @override
  State<AdminClassDetailPanel> createState() => _AdminClassDetailPanelState();
}

class _AdminClassDetailPanelState extends State<AdminClassDetailPanel> {
  AdminClassDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _regenerating = false;
  bool _exporting = false;
  String _query = '';
  AdminStudentStatus? _statusFilter;
  bool _expanded = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.classesService.getClassDetail(widget.classId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _copyCode() {
    if (_detail == null) return;
    Clipboard.setData(ClipboardData(text: _detail!.activationCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Activation code copied.')));
  }

  Future<void> _regenerateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Activation Code'),
        content: const Text(
          'The current code will stop working immediately. Students who '
          "haven't joined yet will need the new code to register.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _regenerating = true);
    try {
      final code = await widget.classesService.regenerateActivationCode(widget.classId);
      if (!mounted) return;
      setState(() {
        final d = _detail!;
        _detail = AdminClassDetail(
          id: d.id,
          program: d.program,
          programFullName: d.programFullName,
          section: d.section,
          academicYear: d.academicYear,
          yearLevel: d.yearLevel,
          instructorName: d.instructorName,
          instructorEmail: d.instructorEmail,
          activationCode: code,
          totalStudents: d.totalStudents,
          students: d.students,
        );
        _regenerating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Activation code regenerated.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _regenerating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _exportThisClass() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final file = await widget.classesService.exportClasses([widget.classId]);
      final filename = file.filename ?? 'trackit-export.csv';
      final saved = downloadBytes(filename: filename, bytes: file.bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Exported $filename' : 'Export isn\'t supported on this device yet.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
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
                    'Filter Students',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AdminStudentStatus?>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                        value: AdminStudentStatus.assigned,
                        child: Text('Assigned'),
                      ),
                      DropdownMenuItem(
                        value: AdminStudentStatus.preparing,
                        child: Text('Preparing'),
                      ),
                      DropdownMenuItem(
                        value: AdminStudentStatus.inactive,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _statusFilter = value);
                      setState(() {
                        _statusFilter = value;
                        _page = 0;
                      });
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

  List<AdminClassStudent> get _filtered {
    final students = _detail?.students ?? const [];
    return students.where((s) {
      final matchesQuery = _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          (s.studentNumber?.toLowerCase().contains(_query.toLowerCase()) ?? false) ||
          (s.assignedCompany?.toLowerCase().contains(_query.toLowerCase()) ?? false);
      final matchesStatus = _statusFilter == null || s.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  List<AdminClassStudent> _pageItems(List<AdminClassStudent> filtered) {
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(),
    );
    return content;
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonList());
    }
    if (_error != null || _detail == null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load this class',
          message: _error ?? 'Unknown error.',
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }

    final detail = _detail!;
    final filtered = _filtered;
    final pageItems = _pageItems(filtered);
    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final rangeStart = filtered.isEmpty ? 0 : _page * _pageSize + 1;
    final rangeEnd = (_page * _pageSize + pageItems.length).clamp(0, filtered.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBanner(detail),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Expanded',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Switch(
                      value: _expanded,
                      activeThumbColor: AppColors.primaryMaroon,
                      onChanged: (v) => setState(() => _expanded = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() {
                          _query = v;
                          _page = 0;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search Students...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _openFilterSheet,
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: Text(_statusFilter == null ? 'Filter' : 'Filter (1)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryMaroon,
                        side: const BorderSide(color: AppColors.primaryMaroon),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  Expanded(
                    child: Center(
                      child: EmptyStateView(
                        icon: Icons.groups_outlined,
                        title: detail.students.isEmpty
                            ? 'No students yet'
                            : 'No matching students',
                        message: detail.students.isEmpty
                            ? "Students who join with this class's activation code will appear here."
                            : 'Try a different search or filter.',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _StudentTable(students: pageItems, expanded: _expanded),
                  ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Showing $rangeStart to $rangeEnd of ${filtered.length} students',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      AdminPagination(
                        page: _page,
                        totalPages: totalPages,
                        onChanged: (p) => setState(() => _page = p),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(AdminClassDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryMaroon,
        border: Border(bottom: BorderSide(color: AppColors.accentOrange, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.program} - ${detail.section}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      [
                        detail.programFullName ?? detail.program,
                        if (detail.yearLevel != null) detail.yearLevel!,
                      ].join(' | '),
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ACTIVATION CODE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          detail.activationCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _regenerating ? null : _regenerateCode,
                        tooltip: 'Regenerate code',
                        icon: _regenerating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh, color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 150,
                    child: OutlinedButton.icon(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy Code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 150,
                    child: OutlinedButton.icon(
                      onPressed: _exporting ? null : _exportThisClass,
                      icon: _exporting
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_download_outlined, size: 14),
                      label: const Text('Export Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BannerStat(
                icon: Icons.person_outline,
                label: 'INSTRUCTOR',
                value: detail.instructorName,
              ),
              const SizedBox(width: 28),
              _BannerStat(
                icon: Icons.groups_outlined,
                label: 'TOTAL STUDENTS',
                value: '${detail.totalStudents}',
              ),
              const SizedBox(width: 28),
              _BannerStat(
                icon: Icons.event_outlined,
                label: 'ACADEMIC YEAR',
                value: detail.academicYear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BannerStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

(String, Color, Color) _statusStyle(AdminStudentStatus status) {
  switch (status) {
    case AdminStudentStatus.assigned:
      return ('ASSIGNED', AppColors.successGreenBg, AppColors.successGreenText);
    case AdminStudentStatus.preparing:
      return ('PREPARING', AppColors.statOrangeBg, AppColors.statOrangeIcon);
    case AdminStudentStatus.inactive:
      return ('INACTIVE', AppColors.statRedBg, AppColors.statRedIcon);
  }
}

class _StudentTable extends StatelessWidget {
  final List<AdminClassStudent> students;
  final bool expanded;

  const _StudentTable({required this.students, required this.expanded});

  static const _indexWidth = 36.0;
  static const _nameWidth = 220.0;
  static const _companyWidth = 180.0;
  static const _statusWidth = 110.0;
  static const _extraWidth = 170.0;

  double get _totalWidth =>
      _indexWidth +
      _nameWidth +
      _companyWidth +
      _statusWidth +
      (expanded ? _extraWidth * 2 : 0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _totalWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.background, width: 2)),
              ),
              child: Row(
                children: [
                  _headerCell('#', _indexWidth),
                  _headerCell('Students Info', _nameWidth),
                  _headerCell('Company', _companyWidth),
                  _headerCell('Status', _statusWidth),
                  if (expanded) ...[
                    _headerCell('Contact Person', _extraWidth),
                    _headerCell('OJT Supervisor', _extraWidth),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.background)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _indexWidth,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                        SizedBox(
                          width: _nameWidth,
                          child: Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _cell(student.assignedCompany ?? 'Not yet assigned', _companyWidth),
                        SizedBox(
                          width: _statusWidth,
                          child: _StatusChip(status: student.status),
                        ),
                        if (expanded) ...[
                          _cell(student.contactPerson ?? '--', _extraWidth),
                          _cell(student.ojtSupervisor ?? '--', _extraWidth),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _cell(String value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdminStudentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
