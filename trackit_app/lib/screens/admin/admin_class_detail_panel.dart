import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/admin/admin_pagination.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

const int _pageSize = 10;
// Below this width the info cards wrap to a single column instead of a row.
const _cardsWideBreakpoint = 640.0;

/// Embedded in AdminClassManagementScreen's right-hand pane (not pushed as
/// a route) -- a ValueKey(classId) on the caller's side forces a fresh
/// State whenever the selected section changes, so this can stay a simple
/// "load once in initState" widget instead of watching for id changes.
class AdminClassDetailPanel extends StatefulWidget {
  final int classId;
  final AdminClassesService classesService;

  /// The list panel's student counts go stale after Import Students adds
  /// new rows -- this tells the parent to reload them without this panel
  /// needing to know anything about how that list is structured.
  final VoidCallback? onStudentCountChanged;

  const AdminClassDetailPanel({
    super.key,
    required this.classId,
    required this.classesService,
    this.onStudentCountChanged,
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
  bool _importing = false;
  String _query = '';
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
      await widget.classesService.regenerateActivationCode(widget.classId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Activation code regenerated.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _regenerating = false);
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

  Future<void> _importStudents() async {
    if (_importing) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
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

  void _viewStudent(AdminClassStudent student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Student ID', value: student.studentNumber ?? 'Not set'),
              _DetailRow(label: 'Email', value: student.email),
              _DetailRow(
                label: 'Account Status',
                value: student.accountStatus == AdminAccountStatus.activated
                    ? 'Activated'
                    : 'Pending',
              ),
              _DetailRow(
                label: 'Date Activated',
                value: student.dateActivated != null
                    ? DateFormat('MMM d, yyyy').format(student.dateActivated!.toLocal())
                    : 'Not yet activated',
              ),
              _DetailRow(label: 'Assigned Company', value: student.assignedCompany ?? 'Not yet assigned'),
              _DetailRow(label: 'Contact Person', value: student.contactPerson ?? '--'),
              _DetailRow(label: 'OJT Supervisor', value: student.ojtSupervisor ?? '--'),
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

  List<AdminClassStudent> get _filtered {
    final students = _detail?.students ?? const [];
    if (_query.isEmpty) return students;
    final q = _query.toLowerCase();
    return students.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.studentNumber?.toLowerCase().contains(q) ?? false);
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(),
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
          title: 'Could not load this section',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _cardsWideBreakpoint;
              final cards = [
                _InfoCard(label: 'Section', value: '${detail.program} - ${detail.section}'),
                _InfoCard(label: 'Program', value: detail.programFullName ?? detail.program),
                _InfoCard(label: 'Academic Year', value: detail.academicYear),
                _InfoCard(
                  label: 'Assigned Instructor',
                  value: detail.instructorName ?? 'Not yet assigned',
                  subtitle: detail.instructorEmail,
                ),
              ];
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    cards[i],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActivationCodeCard(detail),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Student List (${detail.totalStudents})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() {
              _query = v;
              _page = 0;
            }),
            decoration: InputDecoration(
              hintText: 'Search student...',
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
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: EmptyStateView(
                  icon: Icons.groups_outlined,
                  title: detail.students.isEmpty ? 'No students yet' : 'No matching students',
                  message: detail.students.isEmpty
                      ? "Import a CSV or share this section's activation code to add students."
                      : 'Try a different search.',
                ),
              ),
            )
          else
            _StudentTable(students: pageItems, startIndex: _page * _pageSize, onView: _viewStudent),
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
        final wide = constraints.maxWidth >= _cardsWideBreakpoint;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${detail.program} - ${detail.section}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Text(
              'Section Information and Students',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _importing ? null : _importStudents,
              icon: _importing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
                    )
                  : const Icon(Icons.upload_outlined, size: 16),
              label: const Text('Import Students'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMaroon,
                side: const BorderSide(color: AppColors.primaryMaroon),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _exportThisClass,
              icon: _exporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
                    )
                  : const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export Students'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMaroon,
                side: const BorderSide(color: AppColors.primaryMaroon),
              ),
            ),
          ],
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: titleBlock),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [titleBlock, const SizedBox(height: 10), actions],
        );
      },
    );
  }

  Widget _buildActivationCodeCard(AdminClassDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Activation Code',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          const Text(
            'Give this code to students so they can activate their accounts.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail.activationCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.successGreenText,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.successGreenText,
                  side: const BorderSide(color: AppColors.successGreenText),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _regenerating ? null : _regenerateCode,
                icon: _regenerating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.successGreenText),
                      )
                    : const Icon(Icons.refresh, size: 14),
                label: const Text('Regenerate Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.successGreenText,
                  side: const BorderSide(color: AppColors.successGreenText),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${DateFormat('MMM d, yyyy').format(detail.activationCodeCreatedAt.toLocal())}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _InfoCard({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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

class _AccountStatusChip extends StatelessWidget {
  final AdminAccountStatus status;

  const _AccountStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final activated = status == AdminAccountStatus.activated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activated ? AppColors.successGreenBg : AppColors.statOrangeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activated ? 'Activated' : 'Pending',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: activated ? AppColors.successGreenText : AppColors.statOrangeIcon,
        ),
      ),
    );
  }
}

class _StudentTable extends StatelessWidget {
  final List<AdminClassStudent> students;
  final int startIndex;
  final ValueChanged<AdminClassStudent> onView;

  const _StudentTable({required this.students, required this.startIndex, required this.onView});

  static const _indexWidth = 36.0;
  static const _idWidth = 110.0;
  static const _nameWidth = 190.0;
  static const _emailWidth = 220.0;
  static const _statusWidth = 100.0;
  static const _dateWidth = 130.0;
  static const _actionsWidth = 70.0;

  double get _totalWidth =>
      _indexWidth + _idWidth + _nameWidth + _emailWidth + _statusWidth + _dateWidth + _actionsWidth;

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
                  _headerCell('Student ID', _idWidth),
                  _headerCell('Full Name', _nameWidth),
                  _headerCell('Email', _emailWidth),
                  _headerCell('Status', _statusWidth),
                  _headerCell('Date Activated', _dateWidth),
                  _headerCell('Actions', _actionsWidth),
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
                    _cell(students[i].studentNumber ?? '--', _idWidth),
                    SizedBox(
                      width: _nameWidth,
                      child: Text(
                        students[i].name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _cell(students[i].email, _emailWidth),
                    SizedBox(
                      width: _statusWidth,
                      child: _AccountStatusChip(status: students[i].accountStatus),
                    ),
                    _cell(
                      students[i].dateActivated != null
                          ? DateFormat('MMM d, yyyy').format(students[i].dateActivated!.toLocal())
                          : '--',
                      _dateWidth,
                    ),
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
