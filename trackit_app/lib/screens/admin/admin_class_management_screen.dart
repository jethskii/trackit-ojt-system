import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import 'admin_class_management_detail_panel.dart';

// Below this width there's no room for the class list and its detail pane
// side by side -- falls back to a single pane (list, or detail-with-a-
// back-button once a class is picked).
const _wideBreakpoint = 720.0;

/// Class Management: browse every section school-wide (flat list, all
/// academic years -- year-scoped browsing already lives in Overview) and
/// manage a section's activation code, students, and data export/import.
/// This is deliberately a separate screen/widget tree from Overview's own
/// list+detail pair, even though both read the same AdminClassesService --
/// Overview must stay untouched, and this view's card style, lack of a
/// year selector, and multi-select export are real, spec-driven
/// differences, not just a reskin.
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _classesService.getClasses();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isWide),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
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
                ),
              ],
            ),
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
          'Browse and Manage the Sections for OJT.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
    final exportAll = _ExportMenuButton(
      label: 'Export All Data',
      icon: Icons.ios_share,
      variant: _ExportButtonVariant.solidMaroon,
      onSelected: (format) => _exportIds(_filtered.map((c) => c.id).toList(), format),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titleBlock), exportAll],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 12), exportAll],
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
          TextField(
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
          const SizedBox(height: 12),
          Expanded(
            child: classes.isEmpty
                ? EmptyStateView(
                    icon: Icons.class_outlined,
                    title: _classes.isEmpty ? 'No classes yet' : 'No matching classes',
                    message: _classes.isEmpty
                        ? 'Sections created in Overview will show up here.'
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
