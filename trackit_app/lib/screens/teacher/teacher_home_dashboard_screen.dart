import 'package:flutter/material.dart';

import '../../repositories/dashboard_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/attention_list_item.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/preview_list_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_tile.dart';

class TeacherHomeDashboardScreen extends StatelessWidget {
  final String teacherId;

  const TeacherHomeDashboardScreen({super.key, this.teacherId = 't1'});

  @override
  Widget build(BuildContext context) {
    final data = DashboardRepository.instance.getHomeDashboardData(teacherId);
    final total = data.assignedStudents == 0 ? 1 : data.assignedStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DashboardHeader(title: 'Home', subtitle: 'Personal Dashboard'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingForNow(),
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  data.teacher.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.maroonText,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(label: 'Program', value: data.teacher.program),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(label: 'Sections', value: data.teacher.sectionsLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Today's Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 168,
                  ),
                  children: [
                    SummaryTile(
                      icon: Icons.groups_rounded,
                      accentColor: AppColors.maroon,
                      label: 'Assigned Students',
                      value: '${data.assignedStudents}',
                      subtitle: 'Total Students',
                    ),
                    SummaryTile(
                      icon: Icons.directions_run_rounded,
                      accentColor: AppColors.rose,
                      label: 'Active Students',
                      value: '${data.activeStudents}/${data.assignedStudents}',
                      subtitle: 'Currently deployed',
                      progress: data.activeStudents / total,
                    ),
                    SummaryTile(
                      icon: Icons.flight_takeoff_rounded,
                      accentColor: AppColors.peach,
                      label: 'Ready for Deployment',
                      value: '${data.readyForDeployment}/${data.assignedStudents}',
                      subtitle: 'Awaiting placement',
                      progress: data.readyForDeployment / total,
                    ),
                    SummaryTile(
                      icon: Icons.check_circle_rounded,
                      accentColor: AppColors.mint,
                      label: 'Completed Students',
                      value: '${data.completedStudents}/${data.assignedStudents}',
                      subtitle: 'Finished OJT',
                      progress: data.completedStudents / total,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Needs your Attention',
                  onViewAll: () {},
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      AttentionListItem(
                        icon: Icons.fact_check_rounded,
                        accentColor: AppColors.rose,
                        label: 'Requirements to Review',
                        count: data.requirementsToReview,
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      AttentionListItem(
                        icon: Icons.edit_calendar_rounded,
                        accentColor: AppColors.peach,
                        label: 'Attendance Corrections',
                        count: data.attendanceCorrections,
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      AttentionListItem(
                        icon: Icons.swap_horiz_rounded,
                        accentColor: AppColors.lavender,
                        label: 'Company Change Requests',
                        count: data.companyChangeRequests,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: 'Recent Announcements', onViewAll: () {}),
                const SizedBox(height: 10),
                PreviewListCard(
                  icon: Icons.campaign_rounded,
                  accentColor: AppColors.rose,
                  emptyLabel: 'No announcements yet',
                  title: data.announcements.isNotEmpty ? data.announcements.first.title : null,
                  subtitle: data.announcements.isNotEmpty
                      ? timeAgo(data.announcements.first.postedAt)
                      : null,
                ),
                const SizedBox(height: 24),
                SectionHeader(title: 'Recent Notifications', onViewAll: () {}),
                const SizedBox(height: 10),
                PreviewListCard(
                  icon: Icons.notifications_rounded,
                  accentColor: AppColors.rose,
                  emptyLabel: 'No notifications yet',
                  title: data.notifications.isNotEmpty ? data.notifications.first.title : null,
                  subtitle: data.notifications.isNotEmpty
                      ? timeAgo(data.notifications.first.createdAt)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
