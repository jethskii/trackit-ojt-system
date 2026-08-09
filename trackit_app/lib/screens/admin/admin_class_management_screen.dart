import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import 'admin_class_detail_panel.dart';
import 'admin_faculty_screen.dart';

// Below this width there's no room for the class list and its detail pane
// side by side -- falls back to a single pane (list, or detail-with-a-
// back-button once a class is picked).
const _wideBreakpoint = 720.0;

/// The current calendar month decides a sensible starting suggestion for
/// a brand-new academic year (only used to bootstrap the picker when the
/// database has no classes -- and therefore no real academic years --
/// yet at all). Aug-Dec is treated as the start of a school year.
String _suggestedAcademicYear() {
  final now = DateTime.now();
  final startYear = now.month >= 8 ? now.year : now.year - 1;
  return '$startYear-${startYear + 1}';
}

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

  List<AdminAcademicYear> _academicYears = [];
  String? _selectedAcademicYear;
  bool _yearsLoading = true;
  String? _yearsError;

  List<AdminClassSummary> _classes = [];
  bool _classesLoading = false;
  String? _classesError;
  String _query = '';
  int? _selectedClassId;
  // Only meaningful on a narrow layout, where list and detail can't share
  // the screen -- true once a class has been picked, so the detail pane
  // (with a back button) replaces the list instead of sitting beside it.
  bool _narrowShowDetail = false;

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
  }

  Future<void> _loadAcademicYears({String? preferYear}) async {
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
          _selectedAcademicYear ??
          working.firstWhere((y) => y.isCurrent, orElse: () => working.first).year;
      setState(() {
        _academicYears = working;
        _selectedAcademicYear = target;
        _yearsLoading = false;
      });
      await _loadClassesForYear(target);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yearsError = e.toString();
        _yearsLoading = false;
      });
    }
  }

  Future<void> _loadClassesForYear(String year) async {
    setState(() {
      _classesLoading = true;
      _classesError = null;
    });
    try {
      final classes = await _classesService.getClasses(academicYear: year);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _classesLoading = false;
        final stillPresent = classes.any((c) => c.id == _selectedClassId);
        if (!stillPresent) {
          _selectedClassId = classes.isNotEmpty ? classes.first.id : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classesError = e.toString();
        _classesLoading = false;
      });
    }
  }

  Future<void> _selectAcademicYear(String year) async {
    if (year == _selectedAcademicYear) return;
    setState(() {
      _selectedAcademicYear = year;
      _selectedClassId = null;
      _narrowShowDetail = false;
    });
    await _loadClassesForYear(year);
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

  Map<String, List<AdminClassSummary>> get _groupedByProgram {
    final grouped = <String, List<AdminClassSummary>>{};
    for (final c in _filtered) {
      grouped.putIfAbsent(c.program, () => []).add(c);
    }
    return grouped;
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (year == null || !mounted) return;
    setState(() {
      if (_academicYears.every((y) => y.year != year)) {
        _academicYears = [
          ..._academicYears,
          AdminAcademicYear(year: year, classCount: 0, isCurrent: false),
        ]..sort((a, b) => b.year.compareTo(a.year));
      }
    });
    await _selectAcademicYear(year);
  }

  Future<void> _openCreateSectionDialog() async {
    final formKey = GlobalKey<FormState>();
    final programController = TextEditingController(text: 'BSIT');
    final sectionController = TextEditingController();
    final yearController = TextEditingController(text: _selectedAcademicYear ?? _suggestedAcademicYear());
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
    // A brand-new academic year typed in the dialog wouldn't be in
    // _academicYears yet -- reloading picks it up as real data now that
    // a class actually exists for it.
    await _loadAcademicYears(preferYear: created.academicYear);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Section "${created.program} - ${created.section}" created.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isWide),
            const SizedBox(height: 14),
            _TopTabs(
              selected: _topTab,
              onChanged: (i) => setState(() => _topTab = i),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _yearsLoading
                  ? const SkeletonList()
                  : _yearsError != null
                  ? EmptyStateView(
                      icon: Icons.error_outline,
                      title: 'Could not load academic years',
                      message: _yearsError!,
                      actionLabel: 'Retry',
                      onAction: _loadAcademicYears,
                    )
                  // IndexedStack (not a rebuild-on-switch) so flipping
                  // between Sections and Faculty feels like two sides of
                  // the same screen -- neither side loses its selection
                  // or scroll position when you switch away and back.
                  : IndexedStack(
                      index: _topTab,
                      children: [
                        _buildContent(isWide),
                        AdminFacultyScreen(
                          client: widget.client,
                          academicYear: _selectedAcademicYear,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
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
    final yearPicker = _AcademicYearPicker(
      years: _academicYears,
      selected: _selectedAcademicYear,
      onSelected: _selectAcademicYear,
      onAddNew: _addAcademicYear,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titleBlock), yearPicker],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 12), yearPicker],
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
              label: const Text('Back to Sections'),
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
    final grouped = _groupedByProgram;
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
              const Expanded(
                child: Text(
                  'Sections List',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search section...',
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
            child: _classesLoading
                ? const SkeletonList()
                : _classesError != null
                ? EmptyStateView(
                    icon: Icons.error_outline,
                    title: 'Could not load sections',
                    message: _classesError!,
                    actionLabel: 'Retry',
                    onAction: () => _loadClassesForYear(_selectedAcademicYear!),
                  )
                : grouped.isEmpty
                ? EmptyStateView(
                    icon: Icons.class_outlined,
                    title: _classes.isEmpty ? 'No sections yet' : 'No matching sections',
                    message: _classes.isEmpty
                        ? 'Tap "Create" to add the first section for A.Y. $_selectedAcademicYear.'
                        : 'Try a different search.',
                  )
                : ListView(
                    children: [
                      for (final program in grouped.keys) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                          child: Text(
                            program,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        for (final c in grouped[program]!) ...[
                          _SectionListTile(
                            summary: c,
                            selected: c.id == _selectedClassId,
                            onTap: () => setState(() {
                              _selectedClassId = c.id;
                              if (narrow) _narrowShowDetail = true;
                            }),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ],
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
            title: 'Select a section',
            message: 'Choose a section on the left to view its information and students.',
          ),
        ),
      );
    }
    return AdminClassDetailPanel(
      key: ValueKey(_selectedClassId),
      classId: _selectedClassId!,
      classesService: _classesService,
      onStudentCountChanged: () => _loadClassesForYear(_selectedAcademicYear!),
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

class _AcademicYearPicker extends StatelessWidget {
  final List<AdminAcademicYear> years;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddNew;

  const _AcademicYearPicker({
    required this.years,
    required this.selected,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final matches = years.where((y) => y.year == selected);
    final current = matches.isEmpty ? null : matches.first;
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == '__add__') {
          onAddNew();
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (context) => [
        for (final y in years)
          PopupMenuItem(
            value: y.year,
            child: Text(y.isCurrent ? '${y.year} (Active)' : y.year),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: '__add__', child: Text('+ Add Academic Year')),
      ],
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.chipGrayBg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Academic Year: ',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              Text(
                selected ?? '--',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (current?.isCurrent ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreenBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreenText,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionListTile extends StatelessWidget {
  final AdminClassSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _SectionListTile({required this.summary, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 16,
                color: selected ? Colors.white : AppColors.primaryMaroon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.section,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${summary.studentCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
