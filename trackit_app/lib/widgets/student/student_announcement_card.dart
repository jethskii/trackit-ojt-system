import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_announcement.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/attachment_kind.dart';
import '../../utils/attachment_launcher.dart';

/// A real announcement feed card -- instructor name, title, content, an
/// optional image, and a timestamp. Deliberately its own widget (not the
/// generic NotificationTile) since an announcement carries richer content
/// than a plain in-app alert.
class StudentAnnouncementCard extends StatelessWidget {
  final StudentAnnouncement announcement;

  const StudentAnnouncementCard({super.key, required this.announcement});

  bool get _isAdmin => announcement.source == AnnouncementSource.admin;

  Future<void> _openAttachment(BuildContext context) async {
    final url = announcement.attachmentUrl;
    if (url == null) return;
    final opened = await openAttachment(ApiClient.resolveUrl(url));
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open that attachment.')));
  }

  @override
  Widget build(BuildContext context) {
    final attachmentUrl = announcement.attachmentUrl;
    final kind = attachmentKindOf(announcement.attachmentName ?? attachmentUrl);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isAdmin ? AppColors.statPurpleBg : AppColors.statBlueBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isAdmin ? Icons.shield_outlined : Icons.school_outlined,
                    size: 16,
                    color: _isAdmin ? AppColors.statPurpleIcon : AppColors.statBlueIcon,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            announcement.authorName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.statPurpleBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.statPurpleIcon,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(announcement.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              announcement.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              announcement.content,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          if (attachmentUrl != null && kind == AttachmentKind.image)
            InkWell(
              onTap: () => _openAttachment(context),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    ApiClient.resolveUrl(attachmentUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (attachmentUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: InkWell(
                onTap: () => _openAttachment(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(attachmentIconOf(kind), size: 18, color: AppColors.primaryMaroon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.attachmentName ?? 'Attachment',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}
