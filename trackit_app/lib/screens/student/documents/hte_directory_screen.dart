import 'package:flutter/material.dart';
import '../../../models/hte_company.dart';
import '../../../services/hte_directory_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/empty_state_view.dart';
import '../../../widgets/common/filter_chip_pill.dart';
import '../../../widgets/common/skeleton_list_tile.dart';
import '../../../widgets/student/documents/hte_company_card.dart';

class HteDirectoryScreen extends StatefulWidget {
  final HteDirectoryService service;

  const HteDirectoryScreen({super.key, required this.service});

  @override
  State<HteDirectoryScreen> createState() => _HteDirectoryScreenState();
}

class _HteDirectoryScreenState extends State<HteDirectoryScreen> {
  List<HteCompany> _companies = [];
  bool _loading = true;
  String _query = '';
  String? _industryFilter;
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final companies = await widget.service.getCompanies();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _loading = false;
    });
  }

  List<HteCompany> get _filtered {
    return _companies.where((c) {
      final matchesQuery =
          _query.isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.industry.toLowerCase().contains(_query.toLowerCase());
      final matchesIndustry =
          _industryFilter == null || c.industry == _industryFilter;
      return matchesQuery && matchesIndustry;
    }).toList();
  }

  List<String> get _industries =>
      _companies.map((c) => c.industry).toSet().toList();

  Future<void> _refresh() => _load();

  void _showCompanyDetail(HteCompany company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompanyDetailSheet(company: company),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'HTE Directory'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search companies...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: AppColors.cardWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            FilterChipPill(
                              label: 'All',
                              selected: _industryFilter == null,
                              onTap: () => setState(() => _industryFilter = null),
                            ),
                            for (final industry in _industries)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: FilterChipPill(
                                  label: industry,
                                  selected: _industryFilter == industry,
                                  onTap: () =>
                                      setState(() => _industryFilter = industry),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primaryMaroon,
                          onRefresh: _refresh,
                          child: _filtered.isEmpty
                              ? ListView(
                                  children: [
                                    EmptyStateView(
                                      icon: Icons.business_outlined,
                                      title: _companies.isEmpty
                                          ? 'No partner companies yet'
                                          : 'No companies found',
                                      message: _companies.isEmpty
                                          ? 'The HTE Directory will list '
                                              "partner companies once the "
                                              "department adds them."
                                          : 'Try a different search term or '
                                              'industry filter.',
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final company = _filtered[index];
                                    return HteCompanyCard(
                                      company: company,
                                      isFavorite: _favorites.contains(
                                        company.id,
                                      ),
                                      onTap: () => _showCompanyDetail(company),
                                      onToggleFavorite: () {
                                        setState(() {
                                          if (_favorites.contains(
                                            company.id,
                                          )) {
                                            _favorites.remove(company.id);
                                          } else {
                                            _favorites.add(company.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompanyDetailSheet extends StatelessWidget {
  final HteCompany company;

  const _CompanyDetailSheet({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.chipGrayBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                company.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                company.industry,
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                company.description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _DetailRow(icon: Icons.location_on, label: company.address),
              _DetailRow(icon: Icons.email_outlined, label: company.email),
              _DetailRow(icon: Icons.phone_outlined, label: company.phone),
              if (company.website != null)
                _DetailRow(icon: Icons.link, label: company.website!),
              _DetailRow(
                icon: Icons.work_outline,
                label: '${company.availablePositions} Positions Available',
              ),
              _DetailRow(
                icon: Icons.event_seat_outlined,
                label: '${company.availableSlots} OJT Slots',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Applying through the app is coming soon. Please apply directly with the company for now.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryMaroon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
