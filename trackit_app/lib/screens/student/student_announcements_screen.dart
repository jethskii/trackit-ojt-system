import 'package:flutter/material.dart';
import '../../models/student_announcement.dart';
import '../../services/student_announcements_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/student/student_announcement_card.dart';

/// Full announcement feed (the Home tab preview's "See All"). Root-level
/// push -- Home has no nested Navigator of its own, unlike the tabs that
/// do -- newest first, pull to refresh.
class StudentAnnouncementsScreen extends StatefulWidget {
  final StudentAnnouncementsService service;

  const StudentAnnouncementsScreen({super.key, required this.service});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState extends State<StudentAnnouncementsScreen> {
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
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Announcements'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _load,
                    child: _announcements.isEmpty
                        ? ListView(
                            children: const [
                              EmptyStateView(
                                icon: Icons.campaign_outlined,
                                title: 'No announcements yet',
                                message:
                                    'Updates from your instructor will show up here.',
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _announcements.length,
                            itemBuilder: (context, index) =>
                                StudentAnnouncementCard(announcement: _announcements[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
