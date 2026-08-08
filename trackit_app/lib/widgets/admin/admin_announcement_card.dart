import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_announcement.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';

class AdminAnnouncementCard extends StatelessWidget {
  final AdminAnnouncement announcement;
  final VoidCallback onDelete;

  const AdminAnnouncementCard({
    super.key,
    required this.announcement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border.all(color: AppColors.background),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ApiClient.resolveUrl(announcement.imageUrl!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryMaroon,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.campaign, color: Colors.white, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _AudienceChip(audience: announcement.targetAudience),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy - h:mm a').format(announcement.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete announcement',
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statRedIcon),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  final AdminAnnouncementAudience audience;

  const _AudienceChip({required this.audience});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.chipGrayBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        adminAudienceLabel(audience),
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
