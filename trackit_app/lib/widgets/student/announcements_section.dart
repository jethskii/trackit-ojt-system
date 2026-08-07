import 'package:flutter/material.dart';
import '../../models/student_announcement.dart';
import '../../services/student_announcements_service.dart';
import '../../utils/app_colors.dart';
import '../common/empty_state_view.dart';
import '../common/skeleton_list_tile.dart';
import 'student_announcement_card.dart';

/// Home tab preview of the real announcement feed -- instructor name,
/// title, content, image -- read straight from
/// GET /api/announcements, not the generic in-app notifications list
/// (that stays on its own Notifications tab).
class AnnouncementsSection extends StatefulWidget {
  final StudentAnnouncementsService service;
  final VoidCallback onSeeAll;

  static const int previewCount = 3;

  const AnnouncementsSection({
    super.key,
    required this.service,
    required this.onSeeAll,
  });

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  List<StudentAnnouncement> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final announcements = await widget.service.getAnnouncements();
    if (!mounted) return;
    setState(() {
      _announcements = announcements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = _announcements.take(AnnouncementsSection.previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign, size: 18, color: AppColors.primaryMaroon),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (preview.isNotEmpty)
              InkWell(
                onTap: widget.onSeeAll,
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
                    Icon(Icons.chevron_right, size: 18, color: AppColors.primaryMaroon),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const SkeletonList(count: 2)
        else if (preview.isEmpty)
          const EmptyStateView(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
            message: 'Updates from your instructor will show up here.',
          )
        else
          for (final announcement in preview)
            StudentAnnouncementCard(announcement: announcement),
      ],
    );
  }
}
