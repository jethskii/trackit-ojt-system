import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/custom_requirement_target.dart';
import '../../services/api_client.dart';
import '../../services/teacher_requirements_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/attachment_launcher.dart';
import '../../utils/requirement_file_types.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

/// The instructor's own list of Additional Requirements they've posted
/// -- title, description, deadline, which section(s) it targets, and the
/// official template file (if any) students will download before
/// submitting their own filled-out copy.
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
  int? _uploadingTemplateId;

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

  Future<void> _uploadTemplate(CustomRequirementDefinition requirement) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: requirementFileExtensions,
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

    setState(() => _uploadingTemplateId = requirement.id);
    try {
      await widget.service.uploadCustomRequirementTemplate(
        requirementId: requirement.id,
        templateBytes: file.bytes!,
        templateFileName: file.name,
        templateContentType: requirementFileContentType(file.extension),
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template updated for "${requirement.title}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.statRedIcon),
      );
    } finally {
      if (mounted) setState(() => _uploadingTemplateId = null);
    }
  }

  Future<void> _viewTemplate(CustomRequirementDefinition requirement) async {
    final url = requirement.templateUrl;
    if (url == null) return;
    final opened = await openAttachment(ApiClient.resolveUrl(url));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the template.'),
          backgroundColor: AppColors.statRedIcon,
        ),
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
                              itemBuilder: (context, index) => _RequirementCard(
                                requirement: _requirements[index],
                                uploadingTemplate:
                                    _uploadingTemplateId == _requirements[index].id,
                                onUploadTemplate: () => _uploadTemplate(_requirements[index]),
                                onViewTemplate: () => _viewTemplate(_requirements[index]),
                              ),
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
  final bool uploadingTemplate;
  final VoidCallback onUploadTemplate;
  final VoidCallback onViewTemplate;

  const _RequirementCard({
    required this.requirement,
    required this.uploadingTemplate,
    required this.onUploadTemplate,
    required this.onViewTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final hasTemplate = requirement.templateUrl != null;
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: hasTemplate ? AppColors.primaryMaroon : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasTemplate
                        ? 'Template: ${requirement.templateName ?? 'attached'}'
                        : 'No official template attached',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (uploadingTemplate)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
                  )
                else ...[
                  if (hasTemplate)
                    TextButton(
                      onPressed: onViewTemplate,
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('View', style: TextStyle(fontSize: 12)),
                    ),
                  TextButton(
                    onPressed: onUploadTemplate,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(
                      hasTemplate ? 'Replace' : 'Upload Template',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
