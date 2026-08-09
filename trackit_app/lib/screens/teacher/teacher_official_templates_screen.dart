import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/teacher_official_template.dart';
import '../../services/api_client.dart';
import '../../services/teacher_requirements_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/attachment_launcher.dart';
import '../../utils/requirement_file_types.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/skeleton_list_tile.dart';

/// Lets an instructor publish the official template file for each Official
/// Requirement (e.g. the actual OJT_Application_Form.docx for "Pre-
/// Application Form"). This catalog is shared department-wide -- the same
/// one every Official Requirements screen already reads from -- so a
/// published template is immediately available to every student, not
/// just this instructor's own section.
class TeacherOfficialTemplatesScreen extends StatefulWidget {
  final TeacherRequirementsService service;

  const TeacherOfficialTemplatesScreen({super.key, required this.service});

  @override
  State<TeacherOfficialTemplatesScreen> createState() =>
      _TeacherOfficialTemplatesScreenState();
}

class _TeacherOfficialTemplatesScreenState
    extends State<TeacherOfficialTemplatesScreen> {
  List<TeacherOfficialTemplatePhase> _phases = [];
  bool _loading = true;
  int? _uploadingTemplateId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phases = await widget.service.getOfficialTemplates();
    if (!mounted) return;
    setState(() {
      _phases = phases;
      _loading = false;
    });
  }

  Future<void> _uploadTemplate(TeacherOfficialTemplateItem item) async {
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

    setState(() => _uploadingTemplateId = item.id);
    try {
      await widget.service.uploadOfficialTemplate(
        templateId: item.id,
        templateBytes: file.bytes!,
        templateFileName: file.name,
        templateContentType: requirementFileContentType(file.extension),
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template updated for "${item.name}".')),
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

  Future<void> _viewTemplate(TeacherOfficialTemplateItem item) async {
    final url = item.templateUrl;
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
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Requirement Templates'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        const Text(
                          'Publish the official document template for each requirement '
                          '-- students will see a "Download Template" option before '
                          'submitting their own filled-out copy.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        for (final phase in _phases) ...[
                          Text(
                            phase.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in phase.templates)
                            _TemplateTile(
                              item: item,
                              uploading: _uploadingTemplateId == item.id,
                              onUpload: () => _uploadTemplate(item),
                              onView: () => _viewTemplate(item),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final TeacherOfficialTemplateItem item;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback onView;

  const _TemplateTile({
    required this.item,
    required this.uploading,
    required this.onUpload,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final hasTemplate = item.templateUrl != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
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
                      ? 'Template: ${item.templateName ?? 'attached'}'
                      : 'No template uploaded yet',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (uploading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
                )
              else ...[
                if (hasTemplate)
                  TextButton(
                    onPressed: onView,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                TextButton(
                  onPressed: onUpload,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text(
                    hasTemplate ? 'Replace' : 'Upload',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
