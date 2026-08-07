import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../utils/app_colors.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              const Icon(Icons.campaign, size: 16, color: AppColors.primaryMaroon),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            announcement.content,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final target in announcement.targets)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statBlueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    target.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statBlueIcon,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM d, yyyy • hh:mm a').format(announcement.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
