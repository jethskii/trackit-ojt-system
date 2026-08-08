import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

const int _pageSize = 10;

class AdminClassDetailScreen extends StatefulWidget {
  final int classId;
  final AdminClassesService classesService;

  const AdminClassDetailScreen({
    super.key,
    required this.classId,
    required this.classesService,
  });

  @override
  State<AdminClassDetailScreen> createState() => _AdminClassDetailScreenState();
}

class _AdminClassDetailScreenState extends State<AdminClassDetailScreen> {
  AdminClassDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _regenerating = false;
  bool _exporting = false;
  String _query = '';
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
        _detail = AdminClassDetail(
          id: _detail!.id,
          program: _detail!.program,
          programFullName: _detail!.programFullName,
          section: _detail!.section,
          academicYear: _detail!.academicYear,
          yearLevel: _detail!.yearLevel,
          instructorName: _detail!.instructorName,
          instructorEmail: _detail!.instructorEmail,
          activationCode: code,
          totalStudents: _detail!.totalStudents,
          students: _detail!.students,
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

  List<AdminClassStudent> get _filtered {
    final students = _detail?.students ?? const [];
    if (_query.isEmpty) return students;
    final q = _query.toLowerCase();
    return students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.studentNumber?.toLowerCase().contains(q) ?? false) ||
              (s.assignedCompany?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  List<AdminClassStudent> get _pageItems {
    final filtered = _filtered;
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SkeletonList();
    }
    if (_error != null || _detail == null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Could not load this class',
        message: _error ?? 'Unknown error.',
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    final detail = _detail!;
    final filtered = _filtered;
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999999);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  '${detail.program} - ${detail.section}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exporting ? null : _exportThisClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Export Data'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _InfoField(
                      icon: Icons.school_outlined,
                      label: 'Program & Section',
                      value: '${detail.program} - ${detail.section}',
                    ),
                    _InfoField(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Degree',
                      value: detail.programFullName ?? detail.program,
                    ),
                    _InfoField(
                      icon: Icons.stairs_outlined,
                      label: 'Year Level',
                      value: detail.yearLevel ?? 'Mixed',
                    ),
                    _InfoField(
                      icon: Icons.person_outline,
                      label: 'Instructor',
                      value: detail.instructorName,
                    ),
                    _InfoField(
                      icon: Icons.groups_outlined,
                      label: 'Total Students',
                      value: '${detail.totalStudents}',
                    ),
                    _InfoField(
                      icon: Icons.event_outlined,
                      label: 'Academic Year',
                      value: detail.academicYear,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Class Activation Code',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        detail.activationCode,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryMaroon,
                        side: const BorderSide(color: AppColors.primaryMaroon),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _regenerating ? null : _regenerateCode,
                      icon: _regenerating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 15),
                      label: const Text('Regenerate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentOrange,
                        side: const BorderSide(color: AppColors.accentOrange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    _query = v;
                    _page = 0;
                  }),
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
              const SizedBox(width: 12),
              Material(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            EmptyStateView(
              icon: Icons.groups_outlined,
              title: detail.students.isEmpty ? 'No students yet' : 'No matching students',
              message: detail.students.isEmpty
                  ? 'Students who join with this class\'s activation code will appear here.'
                  : 'Try a different search.',
            )
          else
            _StudentTable(students: _pageItems, expanded: _expanded),
          if (filtered.isNotEmpty && totalPages > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _page > 0 ? () => setState(() => _page -= 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  'Page ${_page + 1} of $totalPages',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                IconButton(
                  onPressed: _page < totalPages - 1
                      ? () => setState(() => _page += 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

(String, Color, Color) _statusStyle(AdminStudentStatus status) {
  switch (status) {
    case AdminStudentStatus.assigned:
      return ('Assigned', AppColors.successGreenBg, AppColors.successGreenText);
    case AdminStudentStatus.preparing:
      return ('Preparing', AppColors.statOrangeBg, AppColors.statOrangeIcon);
    case AdminStudentStatus.inactive:
      return ('Inactive', AppColors.statRedBg, AppColors.statRedIcon);
  }
}

class _StudentTable extends StatelessWidget {
  final List<AdminClassStudent> students;
  final bool expanded;

  const _StudentTable({required this.students, required this.expanded});

  static const _nameWidth = 220.0;
  static const _numberWidth = 130.0;
  static const _companyWidth = 180.0;
  static const _statusWidth = 110.0;
  static const _extraWidth = 180.0;

  double get _totalWidth =>
      _nameWidth +
      _numberWidth +
      _companyWidth +
      _statusWidth +
      (expanded ? _extraWidth * 2 : 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _totalWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.background, width: 2)),
                ),
                child: Row(
                  children: [
                    _headerCell('Student', _nameWidth),
                    _headerCell('Student No.', _numberWidth),
                    _headerCell('Assigned Company', _companyWidth),
                    _headerCell('Status', _statusWidth),
                    if (expanded) ...[
                      _headerCell('Contact Person', _extraWidth),
                      _headerCell('OJT Supervisor', _extraWidth),
                    ],
                  ],
                ),
              ),
              for (final student in students)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.background)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _nameWidth,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.background,
                              backgroundImage: student.avatarUrl != null
                                  ? NetworkImage(ApiClient.resolveUrl(student.avatarUrl!))
                                  : null,
                              child: student.avatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                          ],
                        ),
                      ),
                      _cell(student.studentNumber ?? '--', _numberWidth),
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
                ),
            ],
          ),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
