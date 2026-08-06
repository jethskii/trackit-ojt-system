import 'package:flutter/material.dart';
import '../../../widgets/common/app_header.dart';
import '../../../widgets/common/maroon_action_card.dart';

class DocumentsHubScreen extends StatelessWidget {
  final VoidCallback onOpenHteDirectory;
  final VoidCallback onOpenOjtRequirements;
  final VoidCallback onOpenActivityReports;

  const DocumentsHubScreen({
    super.key,
    required this.onOpenHteDirectory,
    required this.onOpenOjtRequirements,
    required this.onOpenActivityReports,
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
            const AppHeader(
              title: 'Documents',
              subtitle: 'Access Document Requirements Submissions',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                children: [
                  MaroonActionCard(
                    title: 'HTE Directory',
                    onTap: onOpenHteDirectory,
                  ),
                  const SizedBox(height: 16),
                  MaroonActionCard(
                    title: 'OJT Requirements',
                    onTap: onOpenOjtRequirements,
                  ),
                  const SizedBox(height: 16),
                  MaroonActionCard(
                    title: 'Activity Reports',
                    onTap: onOpenActivityReports,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
