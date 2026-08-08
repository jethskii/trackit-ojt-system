import 'package:flutter/material.dart';
import '../../services/admin_classes_service.dart';
import 'admin_class_detail_screen.dart';
import 'admin_class_management_screen.dart';

/// Mirrors TeacherStudentsTabNavigator: a nested Navigator so drilling into
/// a class's detail view keeps the sidebar visible around it.
class AdminClassesTabNavigator extends StatefulWidget {
  final AdminClassesService classesService;

  const AdminClassesTabNavigator({super.key, required this.classesService});

  @override
  State<AdminClassesTabNavigator> createState() => _AdminClassesTabNavigatorState();
}

class _AdminClassesTabNavigatorState extends State<AdminClassesTabNavigator> {
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
          if (settings.name != null && settings.name!.startsWith('/class/')) {
            final classId = int.parse(settings.name!.substring('/class/'.length));
            page = AdminClassDetailScreen(
              classId: classId,
              classesService: widget.classesService,
            );
          } else {
            page = AdminClassManagementScreen(
              classesService: widget.classesService,
              onOpenClass: (classId) =>
                  _navigatorKey.currentState?.pushNamed('/class/$classId'),
            );
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
