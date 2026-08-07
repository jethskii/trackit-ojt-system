import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Stand-in for a teacher tab that hasn't been built yet.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                '$title coming soon',
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
