import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../models/ojt_requirement_doc.dart';
import '../../../models/ojt_requirement_phase.dart';
import '../../../services/api_client.dart';
import '../../../services/ojt_requirements_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/attachment_launcher.dart';
import '../../../utils/requirement_file_types.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/skeleton_list_tile.dart';
import '../../../widgets/student/documents/requirement_doc_tile.dart';

class PhaseRequirementsScreen extends StatefulWidget {
  final String phaseId;
  final OjtRequirementsService service;

  const PhaseRequirementsScreen({
    super.key,
    required this.phaseId,
    required this.service,
  });

  @override
  State<PhaseRequirementsScreen> createState() =>
      _PhaseRequirementsScreenState();
}

class _PhaseRequirementsScreenState extends State<PhaseRequirementsScreen> {
  OjtRequirementPhase? _phase;
  bool _loading = true;
  String? _uploadingDocId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phases = await widget.service.getPhases();
    if (!mounted) return;
    setState(() {
      _phase = phases.firstWhere((p) => p.id == widget.phaseId);
      _loading = false;
    });
  }

  Future<void> _upload(OjtRequirementDoc document) async {
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

    setState(() => _uploadingDocId = document.id);
    try {
      final phases = await widget.service.submitDocument(
        phaseId: widget.phaseId,
        documentId: document.id,
        fileBytes: file.bytes!,
        fileName: file.name,
        contentType: requirementFileContentType(file.extension),
      );
      if (!mounted) return;
      setState(() {
        _phase = phases.firstWhere((p) => p.id == widget.phaseId);
        _uploadingDocId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} submitted for ${document.name}.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingDocId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.statRedIcon),
      );
    }
  }

  Future<void> _viewFile(OjtRequirementDoc document) async {
    final url = document.uploadedFileUrl;
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

  Future<void> _downloadTemplate(OjtRequirementDoc document) async {
    final url = document.templateUrl;
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
          BackNavHeader(subtitle: _phase?.title ?? 'Requirements'),
          Expanded(
            child: _loading || _phase == null
                ? const SkeletonList(count: 3)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Text(
                        _phase!.description,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      for (final document in _phase!.documents)
                        _uploadingDocId == document.id
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryMaroon,
                                  ),
                                ),
                              )
                            : RequirementDocTile(
                                document: document,
                                onUpload: () => _upload(document),
                                onView: () => _viewFile(document),
                                onDownloadTemplate: document.templateUrl != null
                                    ? () => _downloadTemplate(document)
                                    : null,
                              ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
