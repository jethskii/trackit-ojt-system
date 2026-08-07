import 'package:flutter/material.dart';
import '../../../models/custom_requirement.dart';
import '../../../models/ojt_requirement_doc.dart';
import '../../../services/custom_requirements_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/empty_state_view.dart';
import '../../../widgets/common/mock_file_picker_sheet.dart';
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
    final fileName = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => MockFilePickerSheet(label: requirement.name),
    );
    if (fileName == null || !mounted) return;

    setState(() => _uploadingId = requirement.id);
    final requirements = await widget.service.submitRequirement(
      requirementId: requirement.id,
      fileName: fileName,
    );
    if (!mounted) return;
    setState(() {
      _requirements = requirements;
      _uploadingId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fileName submitted for ${requirement.name}.')),
    );
  }

  void _viewFile(CustomRequirement requirement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(requirement.name),
        content: Text('Uploaded file: ${requirement.uploadedFileName ?? 'N/A'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
