import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/hte_company.dart';
import '../../models/hte_company_contact.dart';
import '../../services/admin_hte_companies_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_pagination.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import 'admin_hte_company_form_screen.dart';

const int _pageSize = 10;
// Below this width the company table and the detail pane can't sit side
// by side.
const _wideBreakpoint = 900.0;

class AdminHteDirectoryScreen extends StatefulWidget {
  final ApiClient client;

  const AdminHteDirectoryScreen({super.key, required this.client});

  @override
  State<AdminHteDirectoryScreen> createState() => _AdminHteDirectoryScreenState();
}

class _AdminHteDirectoryScreenState extends State<AdminHteDirectoryScreen> {
  late final AdminHteCompaniesService _service = HttpAdminHteCompaniesService(
    widget.client,
  );
  List<HteCompany> _companies = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _industryFilter;
  String? _locationFilter;
  int? _selectedCompanyId;
  int _page = 0;
  bool _narrowShowDetail = false;
  bool _deleting = false;

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
      final companies = await _service.getCompanies();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _loading = false;
        final stillPresent = companies.any((c) => c.id == _selectedCompanyId);
        if (!stillPresent) {
          _selectedCompanyId = companies.isNotEmpty ? companies.first.id : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  HteCompany? get _selected {
    if (_selectedCompanyId == null) return null;
    for (final c in _companies) {
      if (c.id == _selectedCompanyId) return c;
    }
    return null;
  }

  List<HteCompany> get _filtered {
    return _companies.where((c) {
      final matchesQuery = _query.isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.industry.toLowerCase().contains(_query.toLowerCase());
      final matchesIndustry = _industryFilter == null || c.industry == _industryFilter;
      final matchesLocation = _locationFilter == null || c.location == _locationFilter;
      return matchesQuery && matchesIndustry && matchesLocation;
    }).toList();
  }

  List<HteCompany> _pageItems(List<HteCompany> filtered) {
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  List<String> get _industries => _companies.map((c) => c.industry).toSet().toList();

  List<String> get _locations =>
      _companies.map((c) => c.location).where((l) => l.isNotEmpty).toSet().toList();

  Future<void> _openAddForm() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AdminHteCompanyFormScreen(service: _service)),
    );
    if (result == null) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> _openEditForm(HteCompany company) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AdminHteCompanyFormScreen(service: _service, existingCompany: company),
      ),
    );
    if (result == null) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> _confirmDelete(HteCompany company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Company'),
        content: Text('Remove "${company.name}" from the HTE Directory? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteCompany(company.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Company removed.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
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
                    'Filter Companies',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _industryFilter,
                    decoration: const InputDecoration(labelText: 'Industry'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final i in _industries) DropdownMenuItem(value: i, child: Text(i)),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _industryFilter = value);
                      setState(() {
                        _industryFilter = value;
                        _page = 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _locationFilter,
                    decoration: const InputDecoration(labelText: 'Location'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final l in _locations) DropdownMenuItem(value: l, child: Text(l)),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _locationFilter = value);
                      setState(() {
                        _locationFilter = value;
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
            _buildHeader(isWide),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const SkeletonList()
                  : _error != null
                  ? EmptyStateView(
                      icon: Icons.error_outline,
                      title: 'Could not load companies',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    )
                  : _buildContent(isWide),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isWide) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HTE Directory',
          style: TextStyle(
            fontSize: isWide ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryMaroon,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "Browse and manage the University's official list of partner companies for OJT.",
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
    final addButton = ElevatedButton.icon(
      onPressed: _openAddForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.add_business_outlined, size: 18),
      label: const Text('Add HTE/Company'),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titleBlock), addButton],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 12), addButton],
    );
  }

  Widget _buildContent(bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildListPanel(narrow: false)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildDetailPanel()),
        ],
      );
    }

    if (_narrowShowDetail && _selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _narrowShowDetail = false),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Directory'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }

    return _buildListPanel(narrow: true);
  }

  Widget _buildListPanel({required bool narrow}) {
    final filtered = _filtered;
    final pageItems = _pageItems(filtered);
    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final rangeStart = filtered.isEmpty ? 0 : _page * _pageSize + 1;
    final rangeEnd = (_page * _pageSize + pageItems.length).clamp(0, filtered.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    _query = v;
                    _page = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search Company Name...',
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
                label: Text(
                  (_industryFilter == null && _locationFilter == null) ? 'Filter' : 'Filter (1)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  side: const BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: EmptyStateView(
                  icon: Icons.business_outlined,
                  title: _companies.isEmpty ? 'No companies yet' : 'No matching companies',
                  message: _companies.isEmpty
                      ? 'Companies you add will appear here.'
                      : 'Try a different search or filter.',
                ),
              ),
            )
          else
            Expanded(child: _buildTable(pageItems, narrow: narrow)),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Showing $rangeStart to $rangeEnd of ${filtered.length} companies',
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
        ],
      ),
    );
  }

  Widget _buildTable(List<HteCompany> companies, {required bool narrow}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.background, width: 2)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(
                      'Company Name',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: Text(
                      'Industry',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Location',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ),
                  SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final selected = company.id == _selectedCompanyId;
                  return Material(
                    color: selected ? AppColors.background : Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedCompanyId = company.id;
                        if (narrow) _narrowShowDetail = true;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.background)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 220,
                              child: Text(
                                company.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: Text(
                                company.industry,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      company.location,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: selected ? AppColors.primaryMaroon : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final company = _selected;
    if (company == null) {
      return Container(
        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: EmptyStateView(
            icon: Icons.business_outlined,
            title: 'Select a company',
            message: 'Choose a company on the left to view its details.',
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Company Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _openEditForm(company),
                  tooltip: 'Edit company',
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryMaroon),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: _deleting ? null : () => _confirmDelete(company),
                  tooltip: 'Remove company',
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statRedIcon),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    company.name.isNotEmpty ? company.name.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    company.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.background),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.category_outlined, label: 'Industry', value: company.industry),
            _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: company.address),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: company.email),
            _InfoRow(icon: Icons.link, label: 'Website', value: company.website ?? 'Not provided'),
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Date HTE Accredited',
              value: company.dateAccredited != null
                  ? DateFormat('MMMM d, y').format(company.dateAccredited!)
                  : 'Not provided',
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.background),
            const SizedBox(height: 12),
            const Text(
              'Available Contact Person',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
            ),
            const SizedBox(height: 8),
            if (company.contacts.isEmpty)
              const Text(
                'No contact persons added yet.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              )
            else
              for (final contact in company.contacts) _ContactRow(contact: contact),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryMaroon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final HteCompanyContact contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 15, color: AppColors.primaryMaroon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              contact.name,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Text(
            contact.phone,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
