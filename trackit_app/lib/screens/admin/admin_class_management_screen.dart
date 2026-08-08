import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import 'admin_class_detail_panel.dart';

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
  bool _exportingAll = false;

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

  Future<void> _exportAll() async {
    if (_classes.isEmpty || _exportingAll) return;
    setState(() => _exportingAll = true);
    try {
      final file = await _classesService.exportClasses(
        _classes.map((c) => c.id).toList(),
      );
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
      if (mounted) setState(() => _exportingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Browse and manage all classes for OJT.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _exportingAll ? null : _exportAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: _exportingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export All Data'),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 320, child: _buildListPanel()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDetailPanel()),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildListPanel() {
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
            child: _filtered.isEmpty
                ? EmptyStateView(
                    icon: Icons.class_outlined,
                    title: _classes.isEmpty ? 'No classes yet' : 'No matching classes',
                    message: _classes.isEmpty
                        ? 'Classes created by instructors will appear here.'
                        : 'Try a different search.',
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = _filtered[index];
                      return _ClassListTile(
                        summary: c,
                        selected: c.id == _selectedClassId,
                        onTap: () => setState(() => _selectedClassId = c.id),
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
            message: 'Choose a class on the left to view its details.',
          ),
        ),
      );
    }
    return AdminClassDetailPanel(
      key: ValueKey(_selectedClassId),
      classId: _selectedClassId!,
      classesService: _classesService,
    );
  }
}

class _ClassListTile extends StatelessWidget {
  final AdminClassSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _ClassListTile({required this.summary, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.cardWhite,
                child: Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: selected ? Colors.white : AppColors.primaryMaroon,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.program} - ${summary.section}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${summary.studentCount} Students',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: selected ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      summary.instructorName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Instructor',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: selected ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
