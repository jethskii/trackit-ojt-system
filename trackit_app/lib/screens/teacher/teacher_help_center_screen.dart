import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/settings_tile.dart';

class TeacherHelpCenterScreen extends StatelessWidget {
  const TeacherHelpCenterScreen({super.key});

  static const _faqs = [
    (
      'How do I create a class?',
      'Go to the Students tab. If you have no class yet, you\'ll see a '
          '"Create Your Class" form -- fill in Program, Section, and '
          'Academic Year to get a real activation code.',
    ),
    (
      'How do students join my class?',
      'Share your Class Activation Code (Students tab > Class Information '
          '> Copy) or the invitation message. Students enter it when they '
          'register, which links them to you and your section '
          'automatically.',
    ),
    (
      'How do I post an announcement?',
      'Notification tab > Announcements > Create Announcement. Pick which '
          'of your sections should see it -- it shows up in their Home '
          'tab and Notifications immediately.',
    ),
    (
      'What shows up in my Notifications?',
      'Real activity from your assigned students: new students joining '
          'your class, requirement submissions, weekly report '
          'submissions, and attendance correction requests.',
    ),
    (
      'What do the OJT Stage labels mean?',
      'Preparing: company confirmed but attendance not started yet. '
          'Active: currently logging OJT hours. Completed: hit their '
          'required hours. On Track/Behind/Needs Attention/Ahead of '
          'Schedule (the colored badge) reflects pace, not stage.',
    ),
  ];

  void _showContentDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackNavHeader(subtitle: 'Help Center'),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (final faq in _faqs)
                      ExpansionTile(
                        title: Text(
                          faq.$1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedAlignment: Alignment.topLeft,
                        children: [
                          Text(
                            faq.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.support_agent_outlined,
                      title: 'Contact Support',
                      onTap: () => _showComingSoon(context, 'Contact Support'),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Report a Bug',
                      onTap: () => _showComingSoon(context, 'Report a Bug'),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About TRACKIT',
                      onTap: () => _showContentDialog(
                        context,
                        'About TRACKIT',
                        'TRACKIT is a centralized OJT tracking and '
                            'documentation system built for the Department '
                            'of Computing Sciences and Engineering (DCSE) '
                            'at Dalubhasaan ng Lungsod ng San Pablo.',
                      ),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _showContentDialog(
                        context,
                        'Privacy Policy',
                        'TRACKIT collects only the information needed for '
                            'OJT monitoring and documentation. Data is used '
                            'solely by DCSE for OJT purposes and is not '
                            'shared with third parties.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
