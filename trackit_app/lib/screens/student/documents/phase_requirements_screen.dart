import 'package:flutter/material.dart';
import '../../../models/ojt_requirement_doc.dart';
import '../../../models/ojt_requirement_phase.dart';
import '../../../services/ojt_requirements_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/mock_file_picker_sheet.dart';
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

  Future<void> _simulateUpload(OjtRequirementDoc document) async {
    final fileName = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => MockFilePickerSheet(label: document.name),
    );
    if (fileName == null || !mounted) return;

    setState(() => _uploadingDocId = document.id);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final phases = await widget.service.submitDocument(
      phaseId: widget.phaseId,
      documentId: document.id,
      fileName: fileName,
    );
    if (!mounted) return;
    setState(() {
      _phase = phases.firstWhere((p) => p.id == widget.phaseId);
      _uploadingDocId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fileName submitted for ${document.name}.')),
    );
  }

  void _viewFile(OjtRequirementDoc document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.name),
        content: Text('Uploaded file: ${document.uploadedFileName ?? 'N/A'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate(OjtRequirementDoc document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${document.name} template download is coming soon.'),
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
                                onUpload: () => _simulateUpload(document),
                                onView: () => _viewFile(document),
                                onDownloadTemplate: document.hasTemplate
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
