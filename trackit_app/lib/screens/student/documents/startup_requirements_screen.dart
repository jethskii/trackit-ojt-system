import 'package:flutter/material.dart';
import '../../../models/ojt_requirement_phase.dart';
import '../../../services/ojt_requirements_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/info_reminder_card.dart';
import '../../../widgets/common/skeleton_list_tile.dart';
import '../../../widgets/student/documents/phase_card.dart';
import 'phase_requirements_screen.dart';

class StartupRequirementsScreen extends StatefulWidget {
  final OjtRequirementsService service;

  const StartupRequirementsScreen({super.key, required this.service});

  @override
  State<StartupRequirementsScreen> createState() =>
      _StartupRequirementsScreenState();
}

class _StartupRequirementsScreenState
    extends State<StartupRequirementsScreen> {
  List<OjtRequirementPhase> _phases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phases = await widget.service.getPhases();
    if (!mounted) return;
    setState(() {
      _phases = phases;
      _loading = false;
    });
  }

  Future<void> _openPhase(OjtRequirementPhase phase) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhaseRequirementsScreen(
          phaseId: phase.id,
          service: widget.service,
        ),
      ),
    );
    _load();
  }

  double get _progress {
    if (_phases.isEmpty) return 0;
    final completed = _phases
        .where((p) => p.status == PhaseStatus.completed)
        .length;
    return completed / _phases.length;
  }

  bool get _allCompleted =>
      _phases.isNotEmpty &&
      _phases.every((p) => p.status == PhaseStatus.completed);

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Startup Requirements'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OverallProgressCard(progress: _progress),
                            const SizedBox(height: 16),
                            const InfoReminderCard(
                              message:
                                  'Complete each phase in order. Some phases '
                                  'will unlock automatically once '
                                  'requirements are met.',
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Requirements',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final phase in _phases) ...[
                              PhaseCard(
                                phase: phase,
                                onTap: () => _openPhase(phase),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'Details Confirmation',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _allCompleted
                                ? const _FinalizationCard()
                                : const _PendingConfirmationCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  final double progress;

  const _OverallProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryMaroon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingConfirmationCard extends StatelessWidget {
  const _PendingConfirmationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Complete all pre requisite requirements and start your OJT Journey!',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FinalizationCard extends StatelessWidget {
  const _FinalizationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.successGreenBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.successGreenText,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Account Details Finalization',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.successGreenText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Requirements Completed. Start Finalizing your Account Information.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.successGreenText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account Finalization page is coming soon.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreenText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
