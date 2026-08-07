import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../models/ojt_progress.dart';
import '../../models/student.dart';
import '../../services/notifications_service.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/student/announcements_section.dart';
import '../../widgets/student/ojt_progress_card.dart';
import '../../widgets/student/student_profile_card.dart';

class StudentHomeView extends StatelessWidget {
  final Student student;
  final OjtProgress progress;
  final NotificationsService notificationsService;
  final ValueChanged<NotificationTarget> onNavigateTo;
  final VoidCallback onOpenNotifications;

  const StudentHomeView({
    super.key,
    required this.student,
    required this.progress,
    required this.notificationsService,
    required this.onNavigateTo,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Home', subtitle: 'Personal Dashboard'),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StudentProfileCard(student: student),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OjtProgressCard(progress: progress),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AnnouncementsSection(
                service: notificationsService,
                onNavigateTo: onNavigateTo,
                onSeeAll: onOpenNotifications,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
