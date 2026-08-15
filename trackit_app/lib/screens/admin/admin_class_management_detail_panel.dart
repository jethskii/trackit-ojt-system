import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/admin_class.dart';
import '../../models/admin_student_detail.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/admin/admin_pagination.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

const int _pageSize = 10;
// Below this width the header/info row wraps to a stacked layout instead
// of sitting side by side.
const _wideBreakpoint = 640.0;
// The Student Details panel needs 340px plus a 16px gap; below that plus
// a reasonable minimum for the class detail panel itself, there's no room
// to sit them side by side -- View pushes a full-screen page instead.
// This is checked against this widget's OWN available width (measured via
// LayoutBuilder in build()), not the browser window -- the window can be
// "wide" while this panel's actual slot is much narrower, once the
// sidebar (250px) and the class list column (320px + 16px gap) have
// already taken their share of it. Using the window width here previously
// let the class detail panel collapse to a sliver a few pixels wide (its
// 18px padding alone exceeded the space left), rendering as blank white.
const _minMainPanelWidth = 380.0;
const _studentPanelWideBreakpoint = 340.0 + 16.0 + _minMainPanelWidth;

enum _StudentTableMode { showSome, expanded }

/// Class Management's own detail panel for the Sections (Students) tab.
/// Shares the same AdminClassDetail/AdminClassStudent model and
/// AdminClassesService, but surfaces the OJT-progress fields (Assigned
/// Company, Status, Contact Person, OJT Supervisor) that were already in
/// the data model but not shown anywhere yet, plus real CSV/Excel/PDF
/// export, Excel/CSV import, and a single per-class activation code.
class AdminClassManagementDetailPanel extends StatefulWidget {
  final int classId;
  final AdminClassesService classesService;
  final VoidCallback? onStudentCountChanged;

  const AdminClassManagementDetailPanel({
    super.key,
    required this.classId,
    required this.classesService,
    this.onStudentCountChanged,
  });

  @override
  State<AdminClassManagementDetailPanel> createState() =>
      _AdminClassManagementDetailPanelState();
}

class _AdminClassManagementDetailPanelState
    extends State<AdminClassManagementDetailPanel> {
  AdminClassDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _regenerating = false;
  bool _exporting = false;
  bool _importing = false;
  String _query = '';
  int _page = 0;
  AdminStudentStatus? _statusFilter;
  _StudentTableMode _mode = _StudentTableMode.showSome;
  // Which student's row is open in the Student Details panel -- purely
  // local UI state, so opening/closing it never touches _detail, _page,
  // _query, or triggers a reload of the class itself.
  int? _selectedStudentId;
  // Cached from the LayoutBuilder in build() so _viewStudent (called from
  // a tap handler, outside the build phase) can make the same wide/narrow
  // decision the panel itself is actually laid out with.
  double _availableWidth = 0;

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
          'The current code will stop working immediately. Anyone -- '
          "instructor or student -- who hasn't joined yet will need the "
          'new code.',
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
      await widget.classesService.regenerateActivationCode(widget.classId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Activation code regenerated.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _export(String format) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final file = await widget.classesService.exportClasses(
        [widget.classId],
        format: format,
      );
      final filename = file.filename ?? 'trackit-export.$format';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _downloadImportTemplate() async {
    try {
      final file = await widget.classesService.downloadImportTemplate();
      final filename = file.filename ?? 'trackit-student-import-template.xlsx';
      final saved = downloadBytes(filename: filename, bytes: file.bytes);
      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download isn\'t supported on this device yet.')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _importStudents() async {
    if (_importing) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read that file.'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final importResult = await widget.classesService.importStudents(
        classId: widget.classId,
        fileBytes: file.bytes!,
        fileName: file.name,
      );
      if (!mounted) return;
      await _load();
      widget.onStudentCountChanged?.call();
      if (!mounted) return;
      await _showImportSummary(importResult);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _showImportSummary(AdminImportResult result) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Complete'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.created} student${result.created == 1 ? '' : 's'} imported as Pending.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (result.skipped.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${result.skipped.length} row(s) skipped:',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final skip in result.skipped)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              '${skip.email} -- ${skip.reason}',
                              style: const TextStyle(fontSize: 12, color: AppColors.statRedIcon),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // View -> studentId -> fetch that exact student's record -> display.
  // Wide enough to sit the Student Details panel next to the class detail
  // (matching the reference design); otherwise it's pushed as its own
  // page, same narrow-mode fallback used throughout Admin.
  void _viewStudent(AdminClassStudent student) {
    if (_availableWidth < _studentPanelWideBreakpoint) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _StudentDetailScreen(
            classId: widget.classId,
            studentId: student.id,
            classesService: widget.classesService,
          ),
        ),
      );
      return;
    }
    setState(() => _selectedStudentId = student.id);
  }

  List<AdminClassStudent> get _filtered {
    var students = _detail?.students ?? const <AdminClassStudent>[];
    if (_statusFilter != null) {
      students = students.where((s) => s.status == _statusFilter).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      students = students.where((s) {
        return s.name.toLowerCase().contains(q) ||
            (s.studentNumber?.toLowerCase().contains(q) ?? false) ||
            (s.assignedCompany?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return students;
  }

  List<AdminClassStudent> _pageItems(List<AdminClassStudent> filtered) {
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cache for _viewStudent's tap handler, and re-check on every
        // rebuild (not just at the moment "View" was tapped) -- if the
        // window is resized narrower after opening the panel, this keeps
        // the class detail content fully visible instead of collapsing it.
        _availableWidth = constraints.maxWidth;
        final mainPanel = Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildBody(),
        );
        final showSidePanel =
            _selectedStudentId != null && constraints.maxWidth >= _studentPanelWideBreakpoint;
        if (!showSidePanel) return mainPanel;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: mainPanel),
            const SizedBox(width: 16),
            SizedBox(
              width: 340,
              child: _StudentDetailPanel(
                // A fresh State per student -- switching from one selected
                // student to another must never show stale data from the
                // previous one, even for a single frame.
                key: ValueKey(_selectedStudentId),
                classId: widget.classId,
                studentId: _selectedStudentId!,
                classesService: widget.classesService,
                onClose: () => setState(() => _selectedStudentId = null),
              ),
            ),
          ],
        );
      },
    );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(detail),
          const SizedBox(height: 16),
          _buildInfoRow(detail),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Students (${detail.totalStudents})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              _ModeToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
            ],
          ),
          const SizedBox(height: 10),
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
              _FilterButton(
                value: _statusFilter,
                onChanged: (v) => setState(() {
                  _statusFilter = v;
                  _page = 0;
                }),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Download student list (CSV)',
                onPressed: () => _export('csv'),
                icon: const Icon(Icons.file_download_outlined, size: 18),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: _importing ? null : _importStudents,
                icon: _importing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
                      )
                    : const Icon(Icons.upload_outlined, size: 16),
                label: const Text('Import'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  side: const BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _downloadImportTemplate,
              child: const Text('Download blank import template (.xlsx)'),
            ),
          ),
          const SizedBox(height: 6),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: EmptyStateView(
                  icon: Icons.groups_outlined,
                  title: detail.students.isEmpty ? 'No students yet' : 'No matching students',
                  message: detail.students.isEmpty
                      ? "Import a file or share this class's activation code to add students."
                      : 'Try a different search or filter.',
                ),
              ),
            )
          else
            _StudentTable(
              students: pageItems,
              startIndex: _page * _pageSize,
              mode: _mode,
              onView: _viewStudent,
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
    );
  }

  Widget _buildHeader(AdminClassDetail detail) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        final subtitleParts = [
          if (detail.programFullName != null) detail.programFullName!,
          if (detail.yearLevel != null) detail.yearLevel!,
        ];
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${detail.program} - ${detail.section}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitleParts.join(' | '),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        );
        final codeCard = _ActivationCodeCard(
          code: detail.activationCode,
          createdAt: detail.activationCodeCreatedAt,
          regenerating: _regenerating,
          onCopy: _copyCode,
          onRegenerate: _regenerateCode,
        );
        final exportButton = _ExportButton(exporting: _exporting, onSelected: _export);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              exportButton,
              const SizedBox(width: 12),
              codeCard,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleBlock,
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: exportButton),
            const SizedBox(height: 10),
            codeCard,
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(AdminClassDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: [
          _InfoItem(
            icon: Icons.person_outline,
            label: 'Instructor',
            value: detail.instructorName ?? 'Not yet assigned',
          ),
          _InfoItem(
            icon: Icons.groups_outlined,
            label: 'Total Students',
            value: '${detail.totalStudents}',
          ),
          _InfoItem(
            icon: Icons.calendar_today_outlined,
            label: 'Academic Year',
            value: detail.academicYear,
          ),
        ],
      ),
    );
  }
}

/// The narrow-mode fallback for View -- a full page instead of the side
/// panel, same convention as everything else in Admin that can't fit a
/// second pane. Wraps the same _StudentDetailPanel content so there's
/// exactly one implementation of what a student's details look like.
class _StudentDetailScreen extends StatelessWidget {
  final int classId;
  final int studentId;
  final AdminClassesService classesService;

  const _StudentDetailScreen({
    required this.classId,
    required this.studentId,
    required this.classesService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        title: const Text('Student Details'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _StudentDetailPanel(
            classId: classId,
            studentId: studentId,
            classesService: classesService,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

/// Student List -> click a row -> studentId -> fetch that exact record ->
/// display -> replace on the next click. Keyed by studentId at the call
/// site so switching students always starts this State fresh (loading,
/// then that student's real data) instead of showing stale content from
/// whoever was selected before.
class _StudentDetailPanel extends StatefulWidget {
  final int classId;
  final int studentId;
  final AdminClassesService classesService;
  final VoidCallback onClose;

  const _StudentDetailPanel({
    super.key,
    required this.classId,
    required this.studentId,
    required this.classesService,
    required this.onClose,
  });

  @override
  State<_StudentDetailPanel> createState() => _StudentDetailPanelState();
}

class _StudentDetailPanelState extends State<_StudentDetailPanel> {
  AdminStudentDetail? _detail;
  bool _loading = true;
  String? _error;

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
      final detail = await widget.classesService.getStudentDetail(
        classId: widget.classId,
        studentId: widget.studentId,
      );
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

  String _formatHours(double hours) =>
      hours == hours.roundToDouble() ? hours.toInt().toString() : hours.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.background, width: 2)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Student Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonList());
    }
    if (_error != null || _detail == null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load this student',
          message: _error ?? 'Unknown error.',
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }

    final s = _detail!;
    final activated = s.accountStatus == AdminAccountStatus.activated;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.background,
                backgroundImage: s.avatarUrl != null
                    ? NetworkImage(ApiClient.resolveUrl(s.avatarUrl!))
                    : null,
                child: s.avatarUrl == null
                    ? const Icon(Icons.person_outline, size: 26, color: AppColors.primaryMaroon)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (s.studentNumber != null)
                      Text(
                        s.studentNumber!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          label: activated ? 'ACTIVATED' : 'PENDING',
                          bg: activated ? AppColors.successGreenBg : AppColors.statOrangeBg,
                          fg: activated ? AppColors.successGreenText : AppColors.statOrangeIcon,
                        ),
                        _StudentStatusChip(status: s.ojtStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeading(title: 'Personal Information', icon: Icons.person_outline),
          _DetailRow(label: 'Program', value: s.program ?? 'Not provided'),
          _DetailRow(label: 'Section', value: s.section ?? 'Not provided'),
          _DetailRow(label: 'Contact Number', value: s.phone ?? 'Not provided'),
          _DetailRow(label: 'Email', value: s.email),
          _DetailRow(label: 'Guardian Contact', value: s.guardianContact ?? 'Not provided'),
          _DetailRow(label: 'Address', value: s.address ?? 'Not provided'),
          const SizedBox(height: 16),
          const _SectionHeading(title: 'Company Information', icon: Icons.apartment_outlined),
          if (s.company == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Not yet deployed.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            )
          else ...[
            _DetailRow(label: 'Company Name', value: s.company!.name),
            _DetailRow(label: 'Industry', value: s.company!.industry ?? 'Not provided'),
            _DetailRow(label: 'Company Address', value: s.company!.address ?? 'Not provided'),
            _DetailRow(
              label: 'Date Deployed',
              value: s.company!.dateDeployed != null
                  ? DateFormat('MMM d, yyyy').format(s.company!.dateDeployed!)
                  : 'Not deployed',
            ),
            _DetailRow(label: 'Supervisor', value: s.company!.supervisorName ?? 'No supervisor assigned'),
            _DetailRow(
              label: 'Supervisor Contact',
              value: s.company!.supervisorContact ?? 'Not provided',
            ),
          ],
          const SizedBox(height: 16),
          const _SectionHeading(title: 'OJT Progress', icon: Icons.timeline_outlined),
          _DetailRow(label: 'Hours Completed', value: '${_formatHours(s.progress.completedHours)} hrs'),
          _DetailRow(label: 'Required Hours', value: '${_formatHours(s.progress.requiredHours)} hrs'),
          _DetailRow(
            label: 'Days Attended',
            value: s.progress.daysAttended > 0 ? '${s.progress.daysAttended} days' : 'No attendance recorded',
          ),
          _DetailRow(
            label: 'Estimated Completion',
            value: s.progress.estimatedCompletion != null
                ? DateFormat('MMM d, yyyy').format(s.progress.estimatedCompletion!)
                : 'Not enough data yet',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '${s.progress.completionPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.progress.completionPercent / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryMaroon),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeading({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primaryMaroon),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

String _statusLabel(AdminStudentStatus status) {
  switch (status) {
    case AdminStudentStatus.assigned:
      return 'Assigned';
    case AdminStudentStatus.preparing:
      return 'Preparing';
    case AdminStudentStatus.inactive:
      return 'Inactive';
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryMaroon),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivationCodeCard extends StatelessWidget {
  final String code;
  final DateTime createdAt;
  final bool regenerating;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  const _ActivationCodeCard({
    required this.code,
    required this.createdAt,
    required this.regenerating,
    required this.onCopy,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVATION CODE',
            style: TextStyle(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            code,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniButton(icon: Icons.copy, label: 'Copy Code', onTap: onCopy),
              const SizedBox(width: 6),
              _MiniButton(
                icon: Icons.refresh,
                label: 'Regenerate',
                onTap: regenerating ? null : onRegenerate,
                loading: regenerating,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Created ${DateFormat('MMM d, yyyy').format(createdAt.toLocal())}',
            style: const TextStyle(fontSize: 9.5, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _MiniButton({required this.icon, required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool exporting;
  final ValueChanged<String> onSelected;

  const _ExportButton({required this.exporting, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (exporting) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
        ),
      );
    }
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'csv', child: Text('CSV')),
        PopupMenuItem(value: 'xlsx', child: Text('Excel (.xlsx)')),
        PopupMenuItem(value: 'pdf', child: Text('PDF')),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.ios_share, size: 16),
          label: const Text('Export Data'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryMaroon,
            side: const BorderSide(color: AppColors.primaryMaroon),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final AdminStudentStatus? value;
  final ValueChanged<AdminStudentStatus?> onChanged;

  const _FilterButton({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AdminStudentStatus?>(
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('All Statuses')),
        const PopupMenuDivider(),
        for (final s in AdminStudentStatus.values)
          PopupMenuItem(value: s, child: Text(_statusLabel(s))),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 16),
          label: Text(value == null ? 'Filter' : _statusLabel(value!)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.chipGrayBg),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _StudentTableMode mode;
  final ValueChanged<_StudentTableMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: 'Show Some',
            selected: mode == _StudentTableMode.showSome,
            onTap: () => onChanged(_StudentTableMode.showSome),
          ),
          _ModeChip(
            label: 'Expanded',
            selected: mode == _StudentTableMode.expanded,
            onTap: () => onChanged(_StudentTableMode.expanded),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentStatusChip extends StatelessWidget {
  final AdminStudentStatus status;

  const _StudentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case AdminStudentStatus.assigned:
        bg = AppColors.successGreenBg;
        fg = AppColors.successGreenText;
        break;
      case AdminStudentStatus.preparing:
        bg = AppColors.statBlueBg;
        fg = AppColors.statBlueIcon;
        break;
      case AdminStudentStatus.inactive:
        bg = AppColors.statRedBg;
        fg = AppColors.statRedIcon;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _StudentTable extends StatelessWidget {
  final List<AdminClassStudent> students;
  final int startIndex;
  final _StudentTableMode mode;
  final ValueChanged<AdminClassStudent> onView;

  const _StudentTable({
    required this.students,
    required this.startIndex,
    required this.mode,
    required this.onView,
  });

  static const _indexWidth = 36.0;
  static const _nameWidth = 180.0;
  static const _numberWidth = 120.0;
  static const _companyWidth = 170.0;
  static const _statusWidth = 100.0;
  static const _contactWidth = 170.0;
  static const _supervisorWidth = 160.0;
  static const _actionsWidth = 60.0;

  bool get _expanded => mode == _StudentTableMode.expanded;

  double get _totalWidth =>
      _indexWidth +
      _nameWidth +
      _numberWidth +
      _companyWidth +
      _statusWidth +
      (_expanded ? _contactWidth + _supervisorWidth : 0) +
      _actionsWidth;

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
                  _headerCell('Student Name', _nameWidth),
                  _headerCell('Student Number', _numberWidth),
                  _headerCell('Assigned Company', _companyWidth),
                  _headerCell('Status', _statusWidth),
                  if (_expanded) ...[
                    _headerCell('Contact Person', _contactWidth),
                    _headerCell('OJT Supervisor', _supervisorWidth),
                  ],
                  _headerCell('', _actionsWidth),
                ],
              ),
            ),
            for (var i = 0; i < students.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.background)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: _indexWidth,
                      child: Text(
                        '${startIndex + i + 1}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: _nameWidth,
                      child: Text(
                        students[i].name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _cell(students[i].studentNumber ?? '--', _numberWidth),
                    _cell(students[i].assignedCompany ?? 'N/A', _companyWidth),
                    SizedBox(
                      width: _statusWidth,
                      child: _StudentStatusChip(status: students[i].status),
                    ),
                    if (_expanded) ...[
                      _cell(students[i].contactPerson ?? '--', _contactWidth),
                      _cell(students[i].ojtSupervisor ?? '--', _supervisorWidth),
                    ],
                    SizedBox(
                      width: _actionsWidth,
                      child: IconButton(
                        tooltip: 'View',
                        onPressed: () => onView(students[i]),
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryMaroon),
                      ),
                    ),
                  ],
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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
