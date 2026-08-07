import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/custom_requirement_target.dart';
import '../../services/teacher_requirements_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

/// The instructor's own list of Additional Requirements they've posted
/// -- title, description, deadline, and which section(s) it targets.
class TeacherCustomRequirementsScreen extends StatefulWidget {
  final TeacherRequirementsService service;
  final Future<String?> Function() onAddNew;

  const TeacherCustomRequirementsScreen({
    super.key,
    required this.service,
    required this.onAddNew,
  });

  @override
  State<TeacherCustomRequirementsScreen> createState() =>
      _TeacherCustomRequirementsScreenState();
}

class _TeacherCustomRequirementsScreenState
    extends State<TeacherCustomRequirementsScreen> {
  List<CustomRequirementDefinition> _requirements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requirements = await widget.service.getCustomRequirements();
    if (!mounted) return;
    setState(() {
      _requirements = requirements;
      _loading = false;
    });
  }

  Future<void> _addNew() async {
    final result = await widget.onAddNew();
    if (!mounted) return;
    await _load();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: AppColors.successGreenText),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        onPressed: _addNew,
        icon: const Icon(Icons.add),
        label: const Text('Add New Requirement'),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const BackNavHeader(subtitle: 'Additional Requirement'),
            Expanded(
              child: _loading
                  ? const SkeletonList()
                  : RefreshIndicator(
                      color: AppColors.primaryMaroon,
                      onRefresh: _load,
                      child: _requirements.isEmpty
                          ? ListView(
                              children: const [
                                EmptyStateView(
                                  icon: Icons.playlist_add_check_outlined,
                                  title: 'No additional requirements yet',
                                  message:
                                      'Tap "Add New Requirement" to post one to '
                                      'your section(s).',
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              itemCount: _requirements.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  _RequirementCard(requirement: _requirements[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final CustomRequirementDefinition requirement;

  const _RequirementCard({required this.requirement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requirement.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
          ),
          if (requirement.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(requirement.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (requirement.deadline != null) ...[
            const SizedBox(height: 6),
            Text(
              'Deadline: ${DateFormat('MMM d, yyyy').format(requirement.deadline!)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statOrangeIcon),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final target in requirement.targets)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${target.program} - ${target.section}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
