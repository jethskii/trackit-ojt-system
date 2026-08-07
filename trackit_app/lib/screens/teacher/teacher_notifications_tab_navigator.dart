import 'package:flutter/material.dart';
import '../../services/teacher_announcements_service.dart';
import '../../services/teacher_classes_service.dart';
import '../../services/teacher_notifications_service.dart';
import 'create_announcement_screen.dart';
import 'teacher_notifications_screen.dart';

/// Mirrors TeacherStudentsTabNavigator: owns a nested Navigator so
/// pushing into Create Announcement keeps the bottom nav visible.
class TeacherNotificationsTabNavigator extends StatefulWidget {
  final TeacherNotificationsService notificationsService;
  final TeacherAnnouncementsService announcementsService;
  final TeacherClassesService classesService;

  const TeacherNotificationsTabNavigator({
    super.key,
    required this.notificationsService,
    required this.announcementsService,
    required this.classesService,
  });

  @override
  State<TeacherNotificationsTabNavigator> createState() =>
      _TeacherNotificationsTabNavigatorState();
}

class _TeacherNotificationsTabNavigatorState
    extends State<TeacherNotificationsTabNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigatorKey.currentState?.maybePop();
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/create-announcement':
              page = CreateAnnouncementScreen(
                announcementsService: widget.announcementsService,
                classesService: widget.classesService,
              );
              break;
            case '/':
            default:
              page = TeacherNotificationsScreen(
                notificationsService: widget.notificationsService,
                announcementsService: widget.announcementsService,
                onOpenCreateAnnouncement: () => _navigatorKey.currentState!
                    .pushNamed<String>('/create-announcement'),
              );
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
