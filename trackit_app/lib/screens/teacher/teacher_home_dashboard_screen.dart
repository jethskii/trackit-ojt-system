import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../models/teacher_dashboard.dart';
import '../../services/teacher_announcements_service.dart';
import '../../services/teacher_notifications_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/teacher/announcement_card.dart';
import '../../widgets/teacher/attention_list_card.dart';
import '../../widgets/teacher/instructor_notification_tile.dart';
import '../../widgets/teacher/teacher_dashboard_header.dart';
import '../../widgets/teacher/teacher_summary_tile.dart';

class TeacherHomeDashboardScreen extends StatefulWidget {
  final TeacherDashboard dashboard;
  final TeacherNotificationsService notificationsService;
  final TeacherAnnouncementsService announcementsService;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenDocumentsHub;
  final VoidCallback onOpenRequirementsReview;
  final VoidCallback onOpenAttendanceCorrections;
  final Future<void> Function() onRefresh;

  const TeacherHomeDashboardScreen({
    super.key,
    required this.dashboard,
    required this.notificationsService,
    required this.announcementsService,
    required this.onOpenNotifications,
    required this.onOpenDocumentsHub,
    required this.onOpenRequirementsReview,
    required this.onOpenAttendanceCorrections,
    required this.onRefresh,
  });

  @override
  State<TeacherHomeDashboardScreen> createState() =>
      _TeacherHomeDashboardScreenState();
}

class _TeacherHomeDashboardScreenState
    extends State<TeacherHomeDashboardScreen> {
  static const int _previewCount = 3;

  List<Announcement> _announcements = [];
  bool _loadingAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final announcements = await widget.announcementsService.getAnnouncements();
    if (!mounted) return;
    setState(() {
      _announcements = announcements;
      _loadingAnnouncements = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([widget.onRefresh(), _loadAnnouncements()]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TeacherDashboardHeader(
                instructorName: dashboard.instructorName,
                programs: dashboard.programs,
                sections: dashboard.sections,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  "Today's Summary",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TeacherSummaryTile(
                            icon: Icons.groups_outlined,
                            iconColor: AppColors.primaryMaroon,
                            backgroundColor: AppColors.statRedBg,
                            label: 'Assigned Students',
                            value: '${dashboard.assignedStudents}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TeacherSummaryTile(
                            icon: Icons.directions_run,
                            iconColor: AppColors.statRedIcon,
                            backgroundColor: AppColors.statRedBg,
                            label: 'Active Students',
                            value:
                                '${dashboard.activeStudents}/${dashboard.assignedStudents}',
                            progress: dashboard.assignedStudents == 0
                                ? 0
                                : dashboard.activeStudents /
                                    dashboard.assignedStudents,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TeacherSummaryTile(
                            icon: Icons.flight_takeoff,
                            iconColor: AppColors.statOrangeIcon,
                            backgroundColor: AppColors.statOrangeBg,
                            label: 'Ready for Deployment',
                            value:
                                '${dashboard.readyForDeployment}/${dashboard.assignedStudents}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TeacherSummaryTile(
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.successGreenText,
                            backgroundColor: AppColors.successGreenBg,
                            label: 'Completed Students',
                            value:
                                '${dashboard.completedStudents}/${dashboard.assignedStudents}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Needs your Attention',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: widget.onOpenDocumentsHub,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AttentionListCard(
                  items: [
                    AttentionItem(
                      icon: Icons.assignment_late_outlined,
                      iconColor: AppColors.statOrangeIcon,
                      backgroundColor: AppColors.statOrangeBg,
                      label: 'Requirements to Review',
                      count: dashboard.requirementsToReview,
                      onTap: widget.onOpenRequirementsReview,
                    ),
                    AttentionItem(
                      icon: Icons.edit_document,
                      iconColor: AppColors.statBlueIcon,
                      backgroundColor: AppColors.statBlueBg,
                      label: 'Attendance Corrections',
                      count: dashboard.attendanceCorrections,
                      onTap: widget.onOpenAttendanceCorrections,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: _PreviewSectionHeader(
                  icon: Icons.campaign,
                  title: 'Recent Announcements',
                  onViewAll: widget.onOpenNotifications,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _loadingAnnouncements
                    ? const _PreviewCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : _announcements.isEmpty
                        ? const _PreviewCard(
                            child: EmptyStateView(
                              icon: Icons.campaign_outlined,
                              title: 'No announcements yet',
                              message: 'Announcements you post will appear here.',
                              padding: EdgeInsets.symmetric(vertical: 20),
                            ),
                          )
                        : Column(
                            children: [
                              for (final announcement
                                  in _announcements.take(_previewCount))
                                AnnouncementCard(announcement: announcement),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _PreviewSectionHeader(
                  icon: Icons.notifications,
                  title: 'Recent Notifications',
                  onViewAll: widget.onOpenNotifications,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: ListenableBuilder(
                  listenable: widget.notificationsService,
                  builder: (context, _) {
                    final notifications = widget.notificationsService.notifications;
                    if (notifications.isEmpty) {
                      return const _PreviewCard(
                        child: EmptyStateView(
                          icon: Icons.notifications_none,
                          title: 'No notifications yet',
                          message:
                              'Updates about your assigned students will '
                              'appear here.',
                          padding: EdgeInsets.symmetric(vertical: 20),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final notification in notifications.take(_previewCount))
                          InstructorNotificationTile(
                            notification: notification,
                            onTap: () =>
                                widget.notificationsService.markAsRead(notification.id),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onViewAll;

  const _PreviewSectionHeader({
    required this.icon,
    required this.title,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryMaroon),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onViewAll,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
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
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Widget child;

  const _PreviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
