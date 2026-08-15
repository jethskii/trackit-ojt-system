import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/admin/academic_year_picker.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import 'admin_class_management_detail_panel.dart';
import 'admin_faculty_screen.dart';

// Below this width there's no room for the class list and its detail pane
// side by side -- falls back to a single pane (list, or detail-with-a-
// back-button once a class is picked).
const _wideBreakpoint = 720.0;

/// Class Management: Sections (Students) and Faculty (Instructors), both
/// scoped to one academic year at a time -- the Faculty side
/// (AdminFacultyScreen) used to live under the old Overview page; it's
/// merged in here now that Overview became the stats dashboard, so
/// nothing that was built is lost. Sections management (activation code,
/// students, data export/import) is this screen's own real feature, not
/// a reskin of anything -- see admin_class_management_detail_panel.dart.
class AdminClassManagementScreen extends StatefulWidget {
  final ApiClient client;

  const AdminClassManagementScreen({super.key, required this.client});

  @override
  State<AdminClassManagementScreen> createState() =>
      _AdminClassManagementScreenState();
}

class _AdminClassManagementScreenState
    extends State<AdminClassManagementScreen> {
  late final AdminClassesService _classesService = HttpAdminClassesService(
    widget.client,
  );

  int _topTab = 0; // 0 = Sections (Students), 1 = Faculty (Instructors)

  List<AdminAcademicYear> _years = [];
  String? _selectedYear;
  bool _yearsLoading = true;
  String? _yearsError;

  List<AdminClassSummary> _classes = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int? _selectedClassId;
  // Only meaningful on a narrow layout, where list and detail can't share
  // the screen -- true once a class has been picked, so the detail pane
  // (with a back button) replaces the list instead of sitting beside it.
  bool _narrowShowDetail = false;

  final Set<int> _selectedForExport = {};
  bool _bulkExporting = false;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  String _suggestedAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  Future<void> _loadYears({String? preferYear}) async {
    setState(() {
      _yearsLoading = true;
      _yearsError = null;
    });
    try {
      final years = await _classesService.getAcademicYears();
      if (!mounted) return;
      final working = years.isEmpty
          ? [AdminAcademicYear(year: _suggestedAcademicYear(), classCount: 0, isCurrent: true)]
          : years;
      final target = preferYear ??
          _selectedYear ??
          working.firstWhere((y) => y.isCurrent, orElse: () => working.first).year;
      setState(() {
        _years = working;
        _selectedYear = target;
        _yearsLoading = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yearsError = e.toString();
        _yearsLoading = false;
      });
    }
  }

  Future<void> _addAcademicYear() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final year = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Academic Year'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Academic Year', hintText: 'e.g. 2027-2028'),
            validator: (v) {
              if (v == null || !RegExp(r'^\d{4}-\d{4}$').hasMatch(v.trim())) {
                return 'Use the format YYYY-YYYY';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (year == null || !mounted) return;
    setState(() {
      if (_years.every((y) => y.year != year)) {
        _years = [..._years, AdminAcademicYear(year: year, classCount: 0, isCurrent: false)]
          ..sort((a, b) => b.year.compareTo(a.year));
      }
    });
    await _selectYear(year);
  }

  Future<void> _selectYear(String year) async {
    if (year == _selectedYear) return;
    setState(() {
      _selectedYear = year;
      _selectedClassId = null;
      _narrowShowDetail = false;
      _selectedForExport.clear();
    });
    await _load();
  }

  Future<void> _load() async {
    if (_selectedYear == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _classesService.getClasses(academicYear: _selectedYear);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _loading = false;
        final stillPresent = classes.any((c) => c.id == _selectedClassId);
        if (!stillPresent) {
          _selectedClassId = classes.isNotEmpty ? classes.first.id : null;
        }
        _selectedForExport.removeWhere((id) => !classes.any((c) => c.id == id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AdminClassSummary> get _filtered {
    if (_query.isEmpty) return _classes;
    final q = _query.toLowerCase();
    return _classes
        .where(
          (c) =>
              c.program.toLowerCase().contains(q) ||
              c.section.toLowerCase().contains(q) ||
              (c.instructorName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  Future<void> _openCreateSectionDialog() async {
    final formKey = GlobalKey<FormState>();
    final programController = TextEditingController(text: 'BSIT');
    final sectionController = TextEditingController();
    final yearController = TextEditingController(text: _selectedYear ?? _suggestedAcademicYear());
    bool submitting = false;
    String? error;

    final created = await showDialog<AdminClassSummary>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              final section = await _classesService.createSection(
                program: programController.text.trim(),
                section: sectionController.text.trim(),
                academicYear: yearController.text.trim(),
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(section);
            } on ApiException catch (e) {
              setDialogState(() {
                error = e.message;
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Create Section'),
            content: SizedBox(
              width: 360,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        Text(error!, style: const TextStyle(color: AppColors.statRedIcon, fontSize: 13)),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: programController,
                        decoration: const InputDecoration(labelText: 'Program'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sectionController,
                        decoration: const InputDecoration(labelText: 'Section', hintText: 'e.g. 4A'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: yearController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          hintText: 'e.g. 2026-2027',
                        ),
                        validator: (v) {
                          if (v == null || !RegExp(r'^\d{4}-\d{4}$').hasMatch(v.trim())) {
                            return 'Use the format YYYY-YYYY';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (created == null || !mounted) return;
    setState(() => _selectedClassId = created.id);
    // A brand-new academic year typed in the dialog wouldn't be in _years
    // yet -- reloading picks it up as real data now that a class
    // actually exists for it, and switches to it so the new section is
    // actually visible.
    await _loadYears(preferYear: created.academicYear);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Section "${created.program} - ${created.section}" created.')),
    );
  }

  Future<void> _exportIds(List<int> ids, String format) async {
    if (ids.isEmpty) return;
    try {
      final file = await _classesService.exportClasses(ids, format: format);
      final filename = file.filename ?? 'trackit-class-management.$format';
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
    }
  }

  Future<void> _exportSelected(String format) async {
    if (_bulkExporting || _selectedForExport.isEmpty) return;
    setState(() => _bulkExporting = true);
    await _exportIds(_selectedForExport.toList(), format);
    if (mounted) setState(() => _bulkExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_yearsLoading) return const SkeletonList();
    if (_yearsError != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Could not load academic years',
        message: _yearsError!,
        actionLabel: 'Retry',
        onAction: _loadYears,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isWide),
            const SizedBox(height: 14),
            _TopTabs(selected: _topTab, onChanged: (i) => setState(() => _topTab = i)),
            const SizedBox(height: 16),
            Expanded(
              // IndexedStack (not a rebuild-on-switch) so flipping between
              // Sections and Faculty keeps each side's own selection and
              // scroll position, the same reasoning the old Overview page
              // used for this exact tab pair.
              child: IndexedStack(
                index: _topTab,
                children: [
                  _buildSectionsTab(isWide),
                  AdminFacultyScreen(client: widget.client, academicYear: _selectedYear),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionsTab(bool isWide) {
    return Stack(
      children: [
        _loading
            ? const SkeletonList()
            : _error != null
            ? EmptyStateView(
                icon: Icons.error_outline,
                title: 'Could not load classes',
                message: _error!,
                actionLabel: 'Retry',
                onAction: _load,
              )
            : _buildContent(isWide),
        if (_selectedForExport.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SelectionBar(
              count: _selectedForExport.length,
              exporting: _bulkExporting,
              onExport: _exportSelected,
              onClear: () => setState(_selectedForExport.clear),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isWide) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Management',
          style: TextStyle(
            fontSize: isWide ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryMaroon,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Manage sections, instructors, and students.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AcademicYearPicker(
          years: _years,
          selected: _selectedYear,
          onSelected: _selectYear,
          onAddNew: _addAcademicYear,
        ),
        if (_topTab == 0) ...[
          const SizedBox(width: 10),
          _ExportMenuButton(
            label: 'Export All Data',
            icon: Icons.ios_share,
            variant: _ExportButtonVariant.solidMaroon,
            onSelected: (format) => _exportIds(_filtered.map((c) => c.id).toList(), format),
          ),
        ],
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titleBlock), controls],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 12), controls],
    );
  }

  Widget _buildContent(bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 320, child: _buildListPanel(narrow: false)),
          const SizedBox(width: 16),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }

    if (_narrowShowDetail && _selectedClassId != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _narrowShowDetail = false),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Classes'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }

    return _buildListPanel(narrow: true);
  }

  Widget _buildListPanel({required bool narrow}) {
    final classes = _filtered;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search Class / Instructor...',
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
              ElevatedButton.icon(
                onPressed: _openCreateSectionDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: classes.isEmpty
                ? EmptyStateView(
                    icon: Icons.class_outlined,
                    title: _classes.isEmpty ? 'No classes yet' : 'No matching classes',
                    message: _classes.isEmpty
                        ? 'Tap "Create" to add the first section for A.Y. $_selectedYear.'
                        : 'Try a different search.',
                  )
                : ListView.separated(
                    itemCount: classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = classes[i];
                      return _ClassCard(
                        summary: c,
                        selected: c.id == _selectedClassId,
                        checked: _selectedForExport.contains(c.id),
                        onTap: () => setState(() {
                          _selectedClassId = c.id;
                          if (narrow) _narrowShowDetail = true;
                        }),
                        onCheckedChanged: (checked) => setState(() {
                          if (checked) {
                            _selectedForExport.add(c.id);
                          } else {
                            _selectedForExport.remove(c.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedClassId == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: EmptyStateView(
            icon: Icons.class_outlined,
            title: 'Select a class',
            message: 'Choose a class on the left to view and manage its information.',
          ),
        ),
      );
    }
    return AdminClassManagementDetailPanel(
      key: ValueKey(_selectedClassId),
      classId: _selectedClassId!,
      classesService: _classesService,
      onStudentCountChanged: _load,
    );
  }
}

class _ClassCard extends StatelessWidget {
  final AdminClassSummary summary;
  final bool selected;
  final bool checked;
  final VoidCallback onTap;
  final ValueChanged<bool> onCheckedChanged;

  const _ClassCard({
    required this.summary,
    required this.selected,
    required this.checked,
    required this.onTap,
    required this.onCheckedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: (v) => onCheckedChanged(v ?? false),
                activeColor: selected ? Colors.white : AppColors.primaryMaroon,
                checkColor: selected ? AppColors.primaryMaroon : Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : AppColors.chipGrayBg,
                child: Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: selected ? Colors.white : AppColors.primaryMaroon,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${summary.program} - ${summary.section}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary.instructorName ?? 'Unassigned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${summary.studentCount} Students',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: selected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ExportButtonVariant { solidMaroon, outlinedMaroon, outlinedOnDark }

class _ExportMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _ExportButtonVariant variant;
  final ValueChanged<String> onSelected;

  const _ExportMenuButton({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.variant = _ExportButtonVariant.outlinedMaroon,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'csv', child: Text('CSV')),
        PopupMenuItem(value: 'xlsx', child: Text('Excel (.xlsx)')),
        PopupMenuItem(value: 'pdf', child: Text('PDF')),
      ],
      child: IgnorePointer(
        child: switch (variant) {
          _ExportButtonVariant.solidMaroon => ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(icon, size: 16),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
              ),
            ),
          _ExportButtonVariant.outlinedMaroon => OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(icon, size: 16),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMaroon,
                side: const BorderSide(color: AppColors.primaryMaroon),
              ),
            ),
          _ExportButtonVariant.outlinedOnDark => OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(icon, size: 16, color: Colors.white),
              label: Text(label, style: const TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
              ),
            ),
        },
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final bool exporting;
  final ValueChanged<String> onExport;
  final VoidCallback onClear;

  const _SelectionBar({
    required this.count,
    required this.exporting,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count section${count == 1 ? '' : 's'} selected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Clear'),
          ),
          const SizedBox(width: 8),
          if (exporting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            _ExportMenuButton(
              label: 'Export Selected',
              icon: Icons.download_outlined,
              variant: _ExportButtonVariant.outlinedOnDark,
              onSelected: onExport,
            ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TopTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopTabButton(
          icon: Icons.groups_outlined,
          label: 'Sections (Students)',
          selected: selected == 0,
          onTap: () => onChanged(0),
        ),
        const SizedBox(width: 8),
        _TopTabButton(
          icon: Icons.badge_outlined,
          label: 'Faculty (Instructors)',
          selected: selected == 1,
          onTap: () => onChanged(1),
        ),
      ],
    );
  }
}

class _TopTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.cardWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
