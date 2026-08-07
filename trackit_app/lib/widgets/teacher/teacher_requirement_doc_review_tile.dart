import 'package:flutter/material.dart';
import '../../models/ojt_requirement_doc.dart';
import '../../utils/app_colors.dart';
import '../common/status_badge.dart';

/// A single document as the reviewing instructor sees it: status, the
/// uploaded file (viewable), any past remarks, and -- once the student
/// has submitted -- Approve / Request Re-upload actions.
class TeacherRequirementDocReviewTile extends StatelessWidget {
  final String name;
  final String description;
  final RequirementDocStatus status;
  final String? uploadedFileName;
  final String? uploadedFileUrl;
  final String? remarks;
  final bool canReview;
  final void Function(bool approve, {String? remarks}) onDecision;

  const TeacherRequirementDocReviewTile({
    super.key,
    required this.name,
    required this.description,
    required this.status,
    this.uploadedFileName,
    this.uploadedFileUrl,
    this.remarks,
    required this.canReview,
    required this.onDecision,
  });

  StatusKind get _statusKind {
    switch (status) {
      case RequirementDocStatus.missing:
        return StatusKind.missing;
      case RequirementDocStatus.pending:
        return StatusKind.pending;
      case RequirementDocStatus.submitted:
        return StatusKind.submitted;
      case RequirementDocStatus.approved:
        return StatusKind.approved;
      case RequirementDocStatus.rejected:
        return StatusKind.rejected;
    }
  }

  void _viewFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: uploadedFileUrl != null
            ? Text('Uploaded file: ${uploadedFileName ?? uploadedFileUrl}')
            : Text('Uploaded file: ${uploadedFileName ?? 'N/A'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReupload(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Re-upload'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note to student (why it needs to be re-uploaded)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.statRedIcon),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final note = controller.text.trim();
    onDecision(false, remarks: note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = status != RequirementDocStatus.missing;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(kind: _statusKind),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (hasFile && uploadedFileName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    uploadedFileName!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (remarks != null && remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statRedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: AppColors.statRedIcon),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reviewer note: $remarks',
                      style: const TextStyle(color: AppColors.statRedIcon, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasFile)
                OutlinedButton.icon(
                  onPressed: () => _viewFile(context),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statBlueIcon,
                    side: const BorderSide(color: AppColors.statBlueIcon),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (canReview) ...[
                OutlinedButton.icon(
                  onPressed: () => onDecision(true),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.successGreenText,
                    side: const BorderSide(color: AppColors.successGreenText),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _requestReupload(context),
                  icon: const Icon(Icons.replay_outlined, size: 16),
                  label: const Text('Re-upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statRedIcon,
                    side: const BorderSide(color: AppColors.statRedIcon),
                    visualDensity: VisualDensity.compact,
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
