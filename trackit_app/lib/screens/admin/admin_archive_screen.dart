import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../models/archive.dart';
import '../../services/admin_archive_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_download.dart';
import '../../widgets/admin/admin_pagination.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

const int _pageSize = 10;
// Below this width the year/class picker and the detail pane can't sit
// side by side.
const _wideBreakpoint = 960.0;

/// Archive is a read-only historical view -- there is no per-year
/// snapshot table in the schema, so this reads the exact same live
/// tables as Class Management, just filtered to a past academic_year
/// (server-enforced: the current/active year can never be requested
/// through these endpoints). That means a later edit to a student's
/// company, instructor, etc. does change what an "archived" year shows,
/// since there's only ever one stored copy of that data -- true
/// point-in-time immutability would need a real snapshot mechanism this
/// round didn't build (see the chat for the tradeoff this was weighed
/// against). No Add/Edit/Delete/Assign controls exist anywhere in this
/// screen by design.
class AdminArchiveScreen extends StatefulWidget {
  final ApiClient client;

  const AdminArchiveScreen({super.key, required this.client});

  @override
  State<AdminArchiveScreen> createState() => _AdminArchiveScreenState();
}

class _AdminArchiveScreenState extends State<AdminArchiveScreen> {
  late final AdminArchiveService _service = HttpAdminArchiveService(widget.client);

  List<ArchiveAcademicYear> _years = [];
  bool _yearsLoading = true;
  String? _yearsError;
  String? _selectedYear;

  List<AdminClassSummary> _classes = [];
  bool _classesLoading = false;
  String _classQuery = '';

  int? _selectedClassId;
  ArchiveClassDetail? _classDetail;
  bool _detailLoading = false;
  String _studentQuery = '';
  int _page = 0;

  bool _narrowShowDetail = false;
  String? _exportingFormat;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    setState(() {
      _yearsLoading = true;
      _yearsError = null;
    });
    try {
      final years = await _service.getAcademicYears();
      if (!mounted) return;
      setState(() {
        _years = years;
        _yearsLoading = false;
      });
      if (years.isNotEmpty) {
        await _selectYear(years.first.year);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yearsError = e.toString();
        _yearsLoading = false;
      });
    }
  }

  Future<void> _selectYear(String year) async {
    setState(() {
      _selectedYear = year;
      _classes = [];
      _classesLoading = true;
      _selectedClassId = null;
      _classDetail = null;
      _page = 0;
    });
    try {
      final classes = await _service.getClasses(year: year);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _classesLoading = false;
      });
      if (classes.isNotEmpty) {
        await _selectClass(classes.first.id, narrow: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _classesLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load classes: $e')));
    }
  }

  Future<void> _selectClass(int classId, {required bool narrow}) async {
    setState(() {
      _selectedClassId = classId;
      _classDetail = null;
      _detailLoading = true;
      _studentQuery = '';
      _page = 0;
      if (narrow) _narrowShowDetail = true;
    });
    try {
      final detail = await _service.getClassDetail(classId);
      if (!mounted) return;
      setState(() {
        _classDetail = detail;
        _detailLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _detailLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load class: $e')));
    }
  }

  List<AdminClassSummary> get _filteredClasses {
    if (_classQuery.isEmpty) return _classes;
    final q = _classQuery.toLowerCase();
    return _classes
        .where(
          (c) =>
              c.program.toLowerCase().contains(q) ||
              c.section.toLowerCase().contains(q) ||
              c.instructorName.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ArchiveClassStudent> get _filteredStudents {
    final students = _classDetail?.students ?? const [];
    if (_studentQuery.isEmpty) return students;
    final q = _studentQuery.toLowerCase();
    return students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.studentNumber?.toLowerCase().contains(q) ?? false) ||
              (s.assignedCompany?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  List<ArchiveClassStudent> _pageItems(List<ArchiveClassStudent> filtered) {
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<void> _exportYear(String format) async {
    final year = _selectedYear;
    if (year == null || _exportingFormat != null) return;
    setState(() => _exportingFormat = format);
    try {
      final file = await _service.exportYear(year, format: format);
      final filename = file.filename ?? 'trackit-archive-$year.$format';
      final saved = downloadBytes(filename: filename, bytes: file.bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Exported $filename' : 'Export isn\'t supported on this device yet.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exportingFormat = null);
    }
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
              child: _yearsLoading
                  ? const SkeletonList()
                  : _yearsError != null
                  ? EmptyStateView(
                      icon: Icons.error_outline,
                      title: 'Could not load the Archive',
                      message: _yearsError!,
                      actionLabel: 'Retry',
                      onAction: _loadYears,
                    )
                  : _years.isEmpty
                  ? const Center(
                      child: EmptyStateView(
                        icon: Icons.archive_outlined,
                        title: 'Nothing archived yet',
                        message:
                            'Past academic years will appear here once a newer academic '
                            "year exists in Class Management. The current year is never "
                            'archived.',
                      ),
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
          'Archive',
          style: TextStyle(
            fontSize: isWide ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryMaroon,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'View and access past academic years, classes, and student records.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
    final exportButton = PopupMenuButton<String>(
      enabled: _selectedYear != null && _exportingFormat == null,
      onSelected: _exportYear,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'pdf', child: Text('Download as PDF')),
        PopupMenuItem(value: 'xlsx', child: Text('Download as Excel')),
        PopupMenuItem(value: 'csv', child: Text('Download as CSV')),
      ],
      child: IgnorePointer(
        child: ElevatedButton.icon(
          onPressed: (_selectedYear != null && _exportingFormat == null) ? () {} : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: _exportingFormat != null
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export All Data'),
        ),
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titleBlock), exportButton],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 12), exportButton],
    );
  }

  Widget _buildContent(bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 320, child: _buildYearAndClassPanel(narrow: false)),
          const SizedBox(width: 16),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }

    if (_narrowShowDetail && _selectedClassId != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _narrowShowDetail = false),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Archive'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }

    return _buildYearAndClassPanel(narrow: true);
  }

  Widget _buildYearAndClassPanel({required bool narrow}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Academic Year',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _classQuery = v),
            decoration: InputDecoration(
              hintText: 'Search Class / Instructor...',
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
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              itemCount: _years.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final year = _years[index];
                final selected = year.year == _selectedYear;
                return _SelectableTile(
                  selected: selected,
                  onTap: () => _selectYear(year.year),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'A.Y. ${year.year}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${year.classCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: selected ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedYear != null)
            Text(
              'Archived Classes (A.Y. $_selectedYear)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _classesLoading
                ? const SkeletonList()
                : _filteredClasses.isEmpty
                ? Center(
                    child: EmptyStateView(
                      icon: Icons.class_outlined,
                      title: _classes.isEmpty ? 'No classes this year' : 'No matching classes',
                      message: _classes.isEmpty
                          ? 'No classes were recorded for this academic year.'
                          : 'Try a different search.',
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredClasses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final c = _filteredClasses[index];
                      final selected = c.id == _selectedClassId;
                      return _SelectableTile(
                        selected: selected,
                        onTap: () => _selectClass(c.id, narrow: narrow),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 16,
                              color: selected ? Colors.white : AppColors.primaryMaroon,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.program} - ${c.section}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${c.studentCount} Students · ${c.instructorName}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: selected ? Colors.white70 : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_detailLoading || _classDetail == null) {
      if (_selectedClassId == null) {
        return Container(
          decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
          child: const Center(
            child: EmptyStateView(
              icon: Icons.class_outlined,
              title: 'Select a class',
              message: 'Choose an academic year and class to view its archived record.',
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
        child: const Padding(padding: EdgeInsets.all(16), child: SkeletonList()),
      );
    }

    final detail = _classDetail!;
    final filtered = _filteredStudents;
    final pageItems = _pageItems(filtered);
    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final rangeStart = filtered.isEmpty ? 0 : _page * _pageSize + 1;
    final rangeEnd = (_page * _pageSize + pageItems.length).clamp(0, filtered.length);

    return Container(
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBanner(detail),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Students',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.chipGrayBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'View Only',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() {
                      _studentQuery = v;
                      _page = 0;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Search Students...',
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
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: EmptyStateView(
                          icon: Icons.groups_outlined,
                          title: detail.students.isEmpty ? 'No students recorded' : 'No matching students',
                          message: detail.students.isEmpty
                              ? 'No students were recorded for this archived class.'
                              : 'Try a different search.',
                        ),
                      ),
                    )
                  else
                    Expanded(child: _StudentTable(students: pageItems)),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Showing $rangeStart to $rangeEnd of ${filtered.length} students',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(ArchiveClassDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryMaroon,
        border: Border(bottom: BorderSide(color: AppColors.accentOrange, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.program} - ${detail.section}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      [
                        detail.programFullName ?? detail.program,
                        if (detail.yearLevel != null) detail.yearLevel!,
                      ].join(' | '),
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ACADEMIC YEAR',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(
                      detail.academicYear,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BannerStat(icon: Icons.person_outline, label: 'INSTRUCTOR', value: detail.instructorName),
              const SizedBox(width: 28),
              _BannerStat(icon: Icons.groups_outlined, label: 'TOTAL STUDENTS', value: '${detail.totalStudents}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableTile({required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: child),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BannerStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _StudentTable extends StatelessWidget {
  final List<ArchiveClassStudent> students;

  const _StudentTable({required this.students});

  static const _indexWidth = 36.0;
  static const _nameWidth = 220.0;
  static const _companyWidth = 200.0;
  static const _hoursWidth = 140.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _indexWidth + _nameWidth + _companyWidth + _hoursWidth,
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
                  SizedBox(width: _indexWidth, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  SizedBox(width: _nameWidth, child: Text('Students Info', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  SizedBox(width: _companyWidth, child: Text('Company', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  SizedBox(width: _hoursWidth, child: Text('Hours Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.background)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _indexWidth,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                        SizedBox(
                          width: _nameWidth,
                          child: Text(
                            student.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: _companyWidth,
                          child: Text(
                            student.assignedCompany ?? 'Not yet assigned',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: _hoursWidth,
                          child: Text(
                            '${student.completedHours.toStringAsFixed(0)} / ${student.requiredHours.toStringAsFixed(0)} hrs',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryMaroon),
                          ),
                        ),
                      ],
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
}
