import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../common/empty_state_view.dart';

class AnnouncementsSection extends StatelessWidget {
  final List<String> announcements;

  const AnnouncementsSection({super.key, this.announcements = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.campaign, size: 18, color: AppColors.primaryMaroon),
            SizedBox(width: 6),
            Text(
              'Latest Announcement / Notifications',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (announcements.isEmpty)
          const EmptyStateView(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
            message:
                'Updates from your instructor and department will show up '
                'here.',
          )
        else
          for (final announcement in announcements)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(announcement),
            ),
      ],
    );
  }
}
