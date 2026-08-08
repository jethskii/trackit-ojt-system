import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/login_history_entry.dart';
import '../../../services/student_profile_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/empty_state_view.dart';
import '../../../widgets/common/skeleton_list_tile.dart';

/// Real login/logout activity -- one row per session (see
/// login_history table), newest first. Never sample data: a page
/// refresh reuses the existing token and never creates a new row here.
class LoginHistoryScreen extends StatefulWidget {
  final StudentProfileService service;

  const LoginHistoryScreen({super.key, required this.service});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  List<LoginHistoryEntry> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await widget.service.getLoginHistory();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Login History'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _load,
                    child: _sessions.isEmpty
                        ? ListView(
                            children: const [
                              EmptyStateView(
                                icon: Icons.history,
                                title: 'No login history yet',
                                message: 'Your account activity will show up here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _sessions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _SessionTile(session: _sessions[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final LoginHistoryEntry session;

  const _SessionTile({required this.session});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = session.isActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: AppColors.successGreenText, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM d, yyyy').format(session.loginAt),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.successGreenBg : AppColors.chipGrayBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Currently Logged In' : 'Logged Out',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.successGreenText : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  label: 'LOGIN TIME',
                  value: DateFormat('h:mm a').format(session.loginAt),
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: 'LOGOUT TIME',
                  value: session.logoutAt != null
                      ? DateFormat('h:mm a').format(session.logoutAt!)
                      : '--',
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: 'DURATION',
                  value: isActive ? 'Active' : _formatDuration(session.sessionDuration),
                  valueColor: isActive ? AppColors.successGreenText : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoColumn({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
