import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notifications_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/filter_chip_pill.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/student/notifications/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationsService service;
  final ValueChanged<NotificationTarget> onNavigateTo;

  const NotificationsScreen({
    super.key,
    required this.service,
    required this.onNavigateTo,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String _query = '';
  NotificationCategory? _categoryFilter;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<AppNotification> _applyFilters(List<AppNotification> source) {
    return source.where((n) {
      final matchesQuery =
          _query.isEmpty ||
          n.title.toLowerCase().contains(_query.toLowerCase()) ||
          n.message.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _categoryFilter == null || n.category == _categoryFilter;
      final matchesUnread = !_unreadOnly || !n.isRead;
      return matchesQuery && matchesCategory && matchesUnread;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
                    'Filter Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryMaroon,
                    title: const Text('Show unread only'),
                    value: _unreadOnly,
                    onChanged: (value) {
                      setSheetState(() => _unreadOnly = value);
                      setState(() => _unreadOnly = value);
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

  void _handleTap(AppNotification notification) {
    widget.service.markAsRead(notification.id);
    widget.onNavigateTo(notification.target);
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppHeader(
            title: 'Notifications',
            subtitle: 'Stay updated on your OJT progress',
          ),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : ListenableBuilder(
                    listenable: widget.service,
                    builder: (context, _) {
                      final filtered = _applyFilters(
                        widget.service.notifications,
                      );
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  FilterChipPill(
                                    label: 'All',
                                    selected: _categoryFilter == null,
                                    onTap: () =>
                                        setState(() => _categoryFilter = null),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterChipPill(
                                    label: 'Admin',
                                    icon: Icons.person,
                                    selected: _categoryFilter ==
                                        NotificationCategory.admin,
                                    onTap: () => setState(
                                      () => _categoryFilter =
                                          NotificationCategory.admin,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterChipPill(
                                    label: 'Instructor',
                                    icon: Icons.menu_book,
                                    selected: _categoryFilter ==
                                        NotificationCategory.instructor,
                                    onTap: () => setState(
                                      () => _categoryFilter =
                                          NotificationCategory.instructor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterChipPill(
                                    label: 'System',
                                    icon: Icons.settings,
                                    selected: _categoryFilter ==
                                        NotificationCategory.system,
                                    onTap: () => setState(
                                      () => _categoryFilter =
                                          NotificationCategory.system,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => _query = v),
                                    decoration: InputDecoration(
                                      hintText: 'Search Notifications...',
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: AppColors.cardWhite,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  child: IconButton(
                                    onPressed: _openFilterSheet,
                                    tooltip: 'Filter notifications',
                                    icon: const Icon(
                                      Icons.tune,
                                      color: AppColors.primaryMaroon,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Notifications',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (widget.service.unreadCount > 0)
                                  TextButton(
                                    onPressed: widget.service.markAllAsRead,
                                    child: const Text('Mark all as read'),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppColors.primaryMaroon,
                              onRefresh: _refresh,
                              child: filtered.isEmpty
                                  ? ListView(
                                      children: [
                                        EmptyStateView(
                                          icon: Icons.notifications_none,
                                          title: widget.service.notifications.isEmpty
                                              ? 'No notifications yet'
                                              : 'No matching notifications',
                                          message: widget
                                                  .service.notifications.isEmpty
                                              ? "You're all caught up. New "
                                                  'updates will show up here.'
                                              : 'Try a different search term '
                                                  'or filter.',
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        24,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final notification = filtered[index];
                                        return NotificationTile(
                                          notification: notification,
                                          onTap: () =>
                                              _handleTap(notification),
                                          onDelete: () => widget.service
                                              .deleteNotification(
                                                notification.id,
                                              ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
