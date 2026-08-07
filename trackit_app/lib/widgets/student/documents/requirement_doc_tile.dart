import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ojt_requirement_doc.dart';
import '../../../utils/app_colors.dart';
import '../../common/status_badge.dart';

class RequirementDocTile extends StatelessWidget {
  final OjtRequirementDoc document;
  final VoidCallback onUpload;
  final VoidCallback onView;
  final VoidCallback? onDownloadTemplate;

  const RequirementDocTile({
    super.key,
    required this.document,
    required this.onUpload,
    required this.onView,
    this.onDownloadTemplate,
  });

  StatusKind get _statusKind {
    switch (document.status) {
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

  @override
  Widget build(BuildContext context) {
    final hasFile = document.status != RequirementDocStatus.missing;

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
                  document.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(kind: _statusKind),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            document.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (document.deadline != null) ...[
            const SizedBox(height: 6),
            Text(
              'Deadline: ${DateFormat('MMM d, yyyy').format(document.deadline!)}',
              style: const TextStyle(
                color: AppColors.statOrangeIcon,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasFile && document.uploadedFileName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    document.uploadedFileName!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (document.remarks != null && document.remarks!.isNotEmpty) ...[
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
                  const Icon(
                    Icons.comment_outlined,
                    size: 14,
                    color: AppColors.statRedIcon,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Remarks: ${document.remarks}',
                      style: const TextStyle(
                        color: AppColors.statRedIcon,
                        fontSize: 12,
                      ),
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
              OutlinedButton.icon(
                onPressed: onUpload,
                icon: Icon(hasFile ? Icons.refresh : Icons.upload_file, size: 16),
                label: Text(hasFile ? 'Replace' : 'Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  side: const BorderSide(color: AppColors.primaryMaroon),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (hasFile)
                OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statBlueIcon,
                    side: const BorderSide(color: AppColors.statBlueIcon),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (document.hasTemplate)
                OutlinedButton.icon(
                  onPressed: onDownloadTemplate,
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Template'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.chipGrayBg),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
