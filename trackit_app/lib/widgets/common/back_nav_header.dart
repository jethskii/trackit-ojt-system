import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class BackNavHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback? onBack;

  const BackNavHeader({super.key, required this.subtitle, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.primaryMaroon,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.accentOrange, width: 3),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Return',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
