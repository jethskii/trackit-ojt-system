import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Simulates a device file picker so upload flows can be demoed end-to-end
/// without a real file_picker plugin. Returns the chosen mock file name.
class MockFilePickerSheet extends StatelessWidget {
  final String label;

  const MockFilePickerSheet({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final baseName = label.replaceAll(' ', '_');
    final mockFiles = [
      '$baseName.pdf',
      '${baseName}_scanned.jpg',
      '$baseName.docx',
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Select a file',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          for (final file in mockFiles)
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_outlined,
                color: AppColors.primaryMaroon,
              ),
              title: Text(file),
              onTap: () => Navigator.of(context).pop(file),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
