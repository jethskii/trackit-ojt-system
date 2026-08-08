import 'package:flutter/material.dart';
import '../../models/admin_announcement.dart';
import '../../services/admin_announcements_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_announcement_card.dart';
import '../../widgets/admin/admin_announcement_form.dart';
import '../../widgets/admin/admin_pagination.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

const int _pageSize = 10;
// Below this width the feed and the create form can't sit side by side.
const _wideBreakpoint = 900.0;

class AdminAnnouncementsScreen extends StatefulWidget {
  final ApiClient client;

  const AdminAnnouncementsScreen({super.key, required this.client});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  late final AdminAnnouncementsService _service = HttpAdminAnnouncementsService(
    widget.client,
  );
  List<AdminAnnouncement> _announcements = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  AdminAnnouncementAudience? _audienceFilter;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final announcements = await _service.getAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AdminAnnouncement> get _filtered {
    return _announcements.where((a) {
      final matchesQuery = _query.isEmpty ||
          a.title.toLowerCase().contains(_query.toLowerCase()) ||
          a.content.toLowerCase().contains(_query.toLowerCase());
      final matchesAudience = _audienceFilter == null || a.targetAudience == _audienceFilter;
      return matchesQuery && matchesAudience;
    }).toList();
  }

  List<AdminAnnouncement> _pageItems(List<AdminAnnouncement> filtered) {
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<void> _confirmDelete(AdminAnnouncement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Delete "${announcement.title}"? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAnnouncement(announcement.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement deleted.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Announcements',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AdminAnnouncementAudience?>(
                    initialValue: _audienceFilter,
                    decoration: const InputDecoration(labelText: 'Target Audience'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final a in AdminAnnouncementAudience.values)
                        DropdownMenuItem(value: a, child: Text(adminAudienceLabel(a))),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _audienceFilter = value);
                      setState(() {
                        _audienceFilter = value;
                        _page = 0;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
            ),
            const SizedBox(height: 2),
            const Text(
              'Broadcast announcements to instructors and students.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: _buildFeedPanel()),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: AdminAnnouncementForm(service: _service, onCreated: _load),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 520, child: _buildFeedPanel()),
                          const SizedBox(height: 16),
                          AdminAnnouncementForm(service: _service, onCreated: _load),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Announcement Feed',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    _query = v;
                    _page = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search Announcements...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(_audienceFilter == null ? 'Filter' : 'Filter (1)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  side: const BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildFeedBody()),
        ],
      ),
    );
  }

  Widget _buildFeedBody() {
    if (_loading) return const SkeletonList();
    if (_error != null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load announcements',
          message: _error!,
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }

    final filtered = _filtered;
    final pageItems = _pageItems(filtered);
    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final rangeStart = filtered.isEmpty ? 0 : _page * _pageSize + 1;
    final rangeEnd = (_page * _pageSize + pageItems.length).clamp(0, filtered.length);

    if (filtered.isEmpty) {
      return Center(
        child: EmptyStateView(
          icon: Icons.campaign_outlined,
          title: _announcements.isEmpty ? 'No announcements yet' : 'No matching announcements',
          message: _announcements.isEmpty
              ? 'Announcements you publish will appear here.'
              : 'Try a different search or filter.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryMaroon,
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: pageItems.length,
              itemBuilder: (context, index) => AdminAnnouncementCard(
                announcement: pageItems[index],
                onDelete: () => _confirmDelete(pageItems[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Showing $rangeStart to $rangeEnd of ${filtered.length} Announcements',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const Spacer(),
            AdminPagination(
              page: _page,
              totalPages: totalPages,
              onChanged: (p) => setState(() => _page = p),
            ),
          ],
        ),
      ],
    );
  }
}
