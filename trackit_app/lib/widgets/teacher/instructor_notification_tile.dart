import 'package:flutter/material.dart';
import '../../models/instructor_notification.dart';
import '../../utils/app_colors.dart';

class InstructorNotificationTile extends StatelessWidget {
  final InstructorNotification notification;
  final VoidCallback onTap;

  const InstructorNotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  bool get _isAdmin => notification.category == 'admin';

  IconData get _moduleIcon {
    if (_isAdmin) return Icons.shield_outlined;
    switch (notification.relatedModule) {
      case 'requirements':
        return Icons.assignment_late_outlined;
      case 'attendance':
        return Icons.edit_document;
      case 'reports':
        return Icons.description_outlined;
      case 'students':
        return Icons.person_add_alt_1;
      default:
        return Icons.notifications_none;
    }
  }

  String get _relativeTime {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? AppColors.cardWhite : AppColors.statRedBg.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.cardWhite : AppColors.statRedBg.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isAdmin ? AppColors.statPurpleBg : AppColors.statBlueBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _moduleIcon,
                  size: 16,
                  color: _isAdmin ? AppColors.statPurpleIcon : AppColors.statBlueIcon,
                ),
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
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.statRedIcon,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
