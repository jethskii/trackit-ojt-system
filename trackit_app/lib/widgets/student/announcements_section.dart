import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notifications_service.dart';
import '../../utils/app_colors.dart';
import '../common/empty_state_view.dart';
import 'notifications/notification_tile.dart';

/// Home tab preview of the most recent notifications -- backed by the same
/// [NotificationsService] as the Notifications tab (StudentShell shares one
/// instance), not a separate/unconnected announcements list.
class AnnouncementsSection extends StatelessWidget {
  final NotificationsService service;
  final ValueChanged<NotificationTarget> onNavigateTo;
  final VoidCallback onSeeAll;

  static const int _previewCount = 3;

  const AnnouncementsSection({
    super.key,
    required this.service,
    required this.onNavigateTo,
    required this.onSeeAll,
  });

  void _handleTap(AppNotification notification) {
    service.markAsRead(notification.id);
    onNavigateTo(notification.target);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final latest = [...service.notifications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final preview = latest.take(_previewCount).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, size: 18, color: AppColors.primaryMaroon),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Latest Announcement / Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (preview.isNotEmpty)
                  InkWell(
                    onTap: onSeeAll,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryMaroon,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.primaryMaroon,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (preview.isEmpty)
              const EmptyStateView(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
                message:
                    'Updates from your instructor and department will show up '
                    'here.',
              )
            else
              for (final notification in preview)
                NotificationTile(
                  notification: notification,
                  onTap: () => _handleTap(notification),
                  onDelete: () => service.deleteNotification(notification.id),
                ),
          ],
        );
      },
    );
  }
}
