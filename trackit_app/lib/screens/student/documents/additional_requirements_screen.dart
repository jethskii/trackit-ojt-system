import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../models/custom_requirement.dart';
import '../../../services/api_client.dart';
import '../../../services/custom_requirements_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/attachment_launcher.dart';
import '../../../utils/requirement_file_types.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/empty_state_view.dart';
import '../../../widgets/common/skeleton_list_tile.dart';
import '../../../widgets/student/documents/requirement_doc_tile.dart';

/// Instructor-created requirements, targeted at the student's class.
/// Unlike Official Requirements, these aren't stage-locked -- each one
/// can be submitted independently as soon as it's posted.
class AdditionalRequirementsScreen extends StatefulWidget {
  final CustomRequirementsService service;

  const AdditionalRequirementsScreen({super.key, required this.service});

  @override
  State<AdditionalRequirementsScreen> createState() =>
      _AdditionalRequirementsScreenState();
}

class _AdditionalRequirementsScreenState
    extends State<AdditionalRequirementsScreen> {
  List<CustomRequirement> _requirements = [];
  bool _loading = true;
  String? _uploadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requirements = await widget.service.getRequirements();
    if (!mounted) return;
    setState(() {
      _requirements = requirements;
      _loading = false;
    });
  }

  Future<void> _upload(CustomRequirement requirement) async {
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

    setState(() => _uploadingId = requirement.id);
    try {
      final requirements = await widget.service.submitRequirement(
        requirementId: requirement.id,
        fileBytes: file.bytes!,
        fileName: file.name,
        contentType: requirementFileContentType(file.extension),
      );
      if (!mounted) return;
      setState(() {
        _requirements = requirements;
        _uploadingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} submitted for ${requirement.name}.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.statRedIcon),
      );
    }
  }

  Future<void> _viewFile(CustomRequirement requirement) async {
    final url = requirement.uploadedFileUrl;
    if (url == null) return;
    final opened = await openAttachment(ApiClient.resolveUrl(url));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open that file.'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
    }
  }

  Future<void> _downloadTemplate(CustomRequirement requirement) async {
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
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Additional Requirements'),
          Expanded(
            child: _loading
                ? const SkeletonList(count: 3)
                : _requirements.isEmpty
                ? const EmptyStateView(
                    icon: Icons.playlist_add_check_outlined,
                    title: 'No Additional Requirements',
                    message:
                        'Your instructor hasn\'t posted any additional '
                        'requirements yet.',
                  )
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        for (final requirement in _requirements)
                          _uploadingId == requirement.id
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryMaroon,
                                    ),
                                  ),
                                )
                              : RequirementDocTile(
                                  document: requirement.toDoc(),
                                  onUpload: () => _upload(requirement),
                                  onView: () => _viewFile(requirement),
                                  onDownloadTemplate: requirement.templateUrl != null
                                      ? () => _downloadTemplate(requirement)
                                      : null,
                                ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
