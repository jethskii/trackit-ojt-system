import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/empty_state_view.dart';

/// Stand-in for the Teacher tabs not built yet (Students, Document,
/// Notification, Profile) -- only the Home Dashboard is in scope so far.
class TeacherPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const TeacherPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(title: title, subtitle: 'Coming soon'),
          Expanded(
            child: Center(
              child: EmptyStateView(
                icon: icon,
                title: '$title is coming soon',
                message: 'This part of the Teacher module hasn\'t been '
                    'built yet.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
