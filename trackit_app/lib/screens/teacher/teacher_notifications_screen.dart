import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../models/instructor_notification.dart';
import '../../services/api_client.dart';
import '../../services/teacher_announcements_service.dart';
import '../../services/teacher_notifications_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/teacher/announcement_card.dart';
import '../../widgets/teacher/instructor_notification_tile.dart';

enum _NoticeTab { notifications, announcements }

class TeacherNotificationsScreen extends StatefulWidget {
  final TeacherNotificationsService notificationsService;
  final TeacherAnnouncementsService announcementsService;
  final Future<String?> Function({Announcement? existing}) onOpenCreateAnnouncement;

  const TeacherNotificationsScreen({
    super.key,
    required this.notificationsService,
    required this.announcementsService,
    required this.onOpenCreateAnnouncement,
  });

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  _NoticeTab _tab = _NoticeTab.notifications;
  String _query = '';
  bool _loadingNotifications = true;
  bool _loadingAnnouncements = true;
  List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadAnnouncements();
  }

  Future<void> _loadNotifications() async {
    await widget.notificationsService.load();
    if (mounted) setState(() => _loadingNotifications = false);
  }

  Future<void> _loadAnnouncements() async {
    final announcements = await widget.announcementsService.getAnnouncements();
    if (!mounted) return;
    setState(() {
      _announcements = announcements;
      _loadingAnnouncements = false;
    });
  }

  Future<void> _createAnnouncement() async {
    final result = await widget.onOpenCreateAnnouncement();
    if (!mounted) return;
    await _loadAnnouncements();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: AppColors.successGreenText),
      );
    }
  }

  Future<void> _editAnnouncement(Announcement announcement) async {
    final result = await widget.onOpenCreateAnnouncement(existing: announcement);
    if (!mounted) return;
    await _loadAnnouncements();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: AppColors.successGreenText),
      );
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Delete "${announcement.title}"? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.statRedIcon),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.announcementsService.deleteAnnouncement(announcement.id);
      await _loadAnnouncements();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Is it running?'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
    }
  }

  List<InstructorNotification> get _filteredNotifications {
    final source = widget.notificationsService.notifications;
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source
        .where(
          (n) => n.title.toLowerCase().contains(q) || n.message.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Announcement> get _filteredAnnouncements {
    if (_query.isEmpty) return _announcements;
    final q = _query.toLowerCase();
    return _announcements
        .where(
          (a) => a.title.toLowerCase().contains(q) || a.content.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Notices', subtitle: 'Personal Dashboard'),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegmentButton(
                          label: 'Notifications',
                          selected: _tab == _NoticeTab.notifications,
                          onTap: () => setState(() => _tab = _NoticeTab.notifications),
                        ),
                      ),
                      Expanded(
                        child: _SegmentButton(
                          label: 'Announcements',
                          selected: _tab == _NoticeTab.announcements,
                          onTap: () => setState(() => _tab = _NoticeTab.announcements),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: _tab == _NoticeTab.notifications
                      ? 'Search Notifications...'
                      : 'Search Announcements...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_tab == _NoticeTab.announcements)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createAnnouncement,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Announcement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _tab == _NoticeTab.notifications
                  ? _buildNotifications()
                  : _buildAnnouncements(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    if (_loadingNotifications) return const SkeletonList();
    return ListenableBuilder(
      listenable: widget.notificationsService,
      builder: (context, _) {
        final notifications = _filteredNotifications;
        return RefreshIndicator(
          color: AppColors.primaryMaroon,
          onRefresh: _loadNotifications,
          child: notifications.isEmpty
              ? ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: const [
                    EmptyStateView(
                      icon: Icons.notifications_none,
                      title: 'No notifications yet',
                      message:
                          'Updates about your assigned students -- new '
                          'joins, submissions, and correction requests -- '
                          'will show up here.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    const Text(
                      'Recent Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final notification in notifications)
                      InstructorNotificationTile(
                        notification: notification,
                        onTap: () => widget.notificationsService.markAsRead(notification.id),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAnnouncements() {
    if (_loadingAnnouncements) return const SkeletonList();
    final announcements = _filteredAnnouncements;
    return RefreshIndicator(
      color: AppColors.primaryMaroon,
      onRefresh: _loadAnnouncements,
      child: announcements.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: const [
                EmptyStateView(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements yet',
                  message: 'Tap "Create Announcement" above to post one to '
                      'your class.',
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                for (final announcement in announcements)
                  AnnouncementCard(
                    announcement: announcement,
                    onEdit: () => _editAnnouncement(announcement),
                    onDelete: () => _deleteAnnouncement(announcement),
                  ),
              ],
            ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
