import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'app_header.dart';

class ComingSoonView extends StatelessWidget {
  final String title;
  final String subtitle;

  const ComingSoonView({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          AppHeader(title: title, subtitle: subtitle),
          const Expanded(
            child: Center(
              child: Text(
                'Coming soon.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
