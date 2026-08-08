import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

class AdminClassManagementScreen extends StatefulWidget {
  final AdminClassesService classesService;
  final ValueChanged<int> onOpenClass;

  const AdminClassManagementScreen({
    super.key,
    required this.classesService,
    required this.onOpenClass,
  });

  @override
  State<AdminClassManagementScreen> createState() =>
      _AdminClassManagementScreenState();
}

class _AdminClassManagementScreenState
    extends State<AdminClassManagementScreen> {
  List<AdminClassSummary> _classes = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  final Set<int> _selected = {};
  bool _exporting = false;

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
      final classes = await widget.classesService.getClasses();
      if (!mounted) return;
      setState(() {
        _classes = classes;
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

  List<AdminClassSummary> get _filtered {
    if (_query.isEmpty) return _classes;
    final q = _query.toLowerCase();
    return _classes
        .where(
          (c) =>
              c.program.toLowerCase().contains(q) ||
              c.section.toLowerCase().contains(q) ||
              c.instructorName.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleSelected(int classId) {
    setState(() {
      if (_selected.contains(classId)) {
        _selected.remove(classId);
      } else {
        _selected.add(classId);
      }
    });
  }

  Future<void> _exportSelected() async {
    if (_selected.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final file = await widget.classesService.exportClasses(_selected.toList());
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Class Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_selected.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _exporting ? null : _exportSelected,
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
                label: Text('Export ${_selected.length} Selected'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search Class or Instructor...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.cardWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
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
              : RefreshIndicator(
                  color: AppColors.primaryMaroon,
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? ListView(
                          children: [
                            EmptyStateView(
                              icon: Icons.class_outlined,
                              title: _classes.isEmpty
                                  ? 'No classes yet'
                                  : 'No matching classes',
                              message: _classes.isEmpty
                                  ? 'Classes created by instructors will appear here.'
                                  : 'Try a different search.',
                            ),
                          ],
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 340,
                                mainAxisExtent: 150,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final c = _filtered[index];
                            return _ClassCard(
                              summary: c,
                              selected: _selected.contains(c.id),
                              onTap: () => widget.onOpenClass(c.id),
                              onToggleSelected: () => _toggleSelected(c.id),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final AdminClassSummary summary;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelected;

  const _ClassCard({
    required this.summary,
    required this.selected,
    required this.onTap,
    required this.onToggleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primaryMaroon : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${summary.program} - ${summary.section}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    activeColor: AppColors.primaryMaroon,
                    onChanged: (_) => onToggleSelected(),
                  ),
                ],
              ),
              Text(
                summary.academicYear,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      summary.instructorName,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 16, color: AppColors.primaryMaroon),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.studentCount} student${summary.studentCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMaroon,
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
