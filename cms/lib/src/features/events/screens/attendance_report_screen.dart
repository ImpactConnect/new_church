import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/events/models/attendance_record_model.dart';

// ─────────────────────────── Providers ─────────────────────────────────────

final _detailedAttendanceProvider =
    StreamProvider.autoDispose.family<List<AttendanceRecordModel>, String>(
  (ref, branchId) =>
      ref.watch(eventRepositoryProvider).watchDetailedAttendanceRecords(branchId),
);

final _eventsListProvider =
    StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) => ref.watch(eventRepositoryProvider).watchEvents(branchId),
);

// ─────────────────────────── Main Screen ───────────────────────────────────

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filters
  String _categoryFilter = 'All';
  String _dayTypeFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AttendanceRecordModel> _applyFilters(
      List<AttendanceRecordModel> records) {
    return records.where((r) {
      if (_categoryFilter != 'All' && r.eventCategory != _categoryFilter) {
        return false;
      }
      if (_dayTypeFilter != 'All' &&
          r.dayType.toLowerCase() != _dayTypeFilter.toLowerCase()) {
        return false;
      }
      if (_fromDate != null && r.date.isBefore(_fromDate!)) return false;
      if (_toDate != null && r.date.isAfter(_toDate!.add(const Duration(days: 1)))) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!r.eventName.toLowerCase().contains(q) &&
            !r.eventCategory.toLowerCase().contains(q) &&
            !(r.recordedByName ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final recordsAsync = ref.watch(_detailedAttendanceProvider(branchId));
    final eventsAsync = ref.watch(_eventsListProvider(branchId));
    final canRecord = user?.can(AppPermission.recordAttendance) ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tabs & Actions ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: CmsTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CmsTheme.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: CmsTheme.accent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: CmsTheme.textSecondary,
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Records & Logs'),
                      Tab(text: 'Analytics & Insights'),
                    ],
                  ),
                ),
              ),
              if (canRecord) ...[
                const SizedBox(width: 16),
                CmsButton(
                  label: 'Record Attendance',
                  icon: Icons.add_chart,
                  onPressed: () => _showRecordDialog(
                    context,
                    ref,
                    branchId,
                    user?.displayName ?? user?.email ?? 'Secretary',
                    eventsAsync.valueOrNull ?? [],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Filter Bar ────────────────────────────────────────────────────
        recordsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (allRecords) => _FilterBar(
            records: allRecords,
            categoryFilter: _categoryFilter,
            dayTypeFilter: _dayTypeFilter,
            fromDate: _fromDate,
            toDate: _toDate,
            searchQuery: _searchQuery,
            onCategoryChanged: (v) => setState(() => _categoryFilter = v),
            onDayTypeChanged: (v) => setState(() => _dayTypeFilter = v),
            onFromDateChanged: (v) => setState(() => _fromDate = v),
            onToDateChanged: (v) => setState(() => _toDate = v),
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onReset: () => setState(() {
              _categoryFilter = 'All';
              _dayTypeFilter = 'All';
              _fromDate = null;
              _toDate = null;
              _searchQuery = '';
            }),
          ),
        ),
        const SizedBox(height: 8),

        // ── Tab Views ─────────────────────────────────────────────────────
        Expanded(
          child: recordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading attendance: $e',
                    style: const TextStyle(color: CmsTheme.danger)),
              ),
            ),
            data: (allRecords) {
              final filtered = _applyFilters(allRecords);
              return TabBarView(
                controller: _tabController,
                children: [
                  _RecordsTab(
                    records: filtered,
                    canRecord: canRecord,
                    branchId: branchId,
                    recorderName: user?.displayName ?? user?.email ?? 'Secretary',
                    eventsAsync: eventsAsync,
                    ref: ref,
                    onRecord: () => _showRecordDialog(context, ref, branchId,
                        user?.displayName ?? user?.email ?? 'Secretary',
                        eventsAsync.valueOrNull ?? []),
                  ),
                  _AnalyticsTab(records: filtered, allRecords: allRecords),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecordDialog(
    BuildContext context,
    WidgetRef ref,
    String branchId,
    String recorderName,
    List<EventModel> existingEvents,
  ) {
    showDialog(
      context: context,
      builder: (_) => _RecordAttendanceDialog(
        branchId: branchId,
        recorderName: recorderName,
        existingEvents: existingEvents,
        ref: ref,
      ),
    );
  }
}

// ─────────────────────────── Filter Bar ────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.records,
    required this.categoryFilter,
    required this.dayTypeFilter,
    required this.fromDate,
    required this.toDate,
    required this.searchQuery,
    required this.onCategoryChanged,
    required this.onDayTypeChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onSearchChanged,
    required this.onReset,
  });

  final List<AttendanceRecordModel> records;
  final String categoryFilter;
  final String dayTypeFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String searchQuery;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onDayTypeChanged;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final categories = <String>{'All', ...records.map((r) => r.eventCategory)};
    final hasActiveFilter = categoryFilter != 'All' ||
        dayTypeFilter != 'All' ||
        fromDate != null ||
        toDate != null ||
        searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CmsTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Row(
          children: [
            // Search
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 36,
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: CmsTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search events, categories…',
                    hintStyle: const TextStyle(
                        color: CmsTheme.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: CmsTheme.textMuted),
                    filled: true,
                    fillColor: CmsTheme.bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: CmsTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: CmsTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: CmsTheme.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Category
            _FilterDropdown<String>(
              value: categoryFilter,
              items: categories.toList(),
              label: (v) => v,
              onChanged: onCategoryChanged,
              hint: 'Category',
            ),
            const SizedBox(width: 10),

            // Day Type
            _FilterDropdown<String>(
              value: dayTypeFilter,
              items: const ['All', 'weekend', 'weekday'],
              label: (v) => v == 'All' ? 'All Days' : v.capitalize(),
              onChanged: onDayTypeChanged,
              hint: 'Day Type',
            ),
            const SizedBox(width: 10),

            // Date From
            _DatePickerButton(
              label: fromDate != null
                  ? 'From: ${DateFormat('MMM d').format(fromDate!)}'
                  : 'From Date',
              onPick: (ctx) async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: fromDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                onFromDateChanged(picked);
              },
              active: fromDate != null,
            ),
            const SizedBox(width: 10),

            // Date To
            _DatePickerButton(
              label: toDate != null
                  ? 'To: ${DateFormat('MMM d').format(toDate!)}'
                  : 'To Date',
              onPick: (ctx) async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: toDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                onToDateChanged(picked);
              },
              active: toDate != null,
            ),

            // Reset
            if (hasActiveFilter) ...[
              const SizedBox(width: 10),
              InkWell(
                onTap: onReset,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CmsTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: CmsTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.filter_alt_off, size: 13, color: CmsTheme.danger),
                      SizedBox(width: 4),
                      Text('Clear',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CmsTheme.danger)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.hint,
  });
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CmsTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: CmsTheme.surfaceElevated,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary),
          icon: const Icon(Icons.expand_more,
              size: 14, color: CmsTheme.textMuted),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(label(i))))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton(
      {required this.label, required this.onPick, required this.active});
  final String label;
  final void Function(BuildContext ctx) onPick;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onPick(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active
              ? CmsTheme.accent.withValues(alpha: 0.15)
              : CmsTheme.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? CmsTheme.accent.withValues(alpha: 0.5) : CmsTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 13, color: active ? CmsTheme.accent : CmsTheme.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: active ? CmsTheme.accent : CmsTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Records Tab ───────────────────────────────────

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({
    required this.records,
    required this.canRecord,
    required this.branchId,
    required this.recorderName,
    required this.eventsAsync,
    required this.ref,
    required this.onRecord,
  });

  final List<AttendanceRecordModel> records;
  final bool canRecord;
  final String branchId;
  final String recorderName;
  final AsyncValue<List<EventModel>> eventsAsync;
  final WidgetRef ref;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 52, color: CmsTheme.textMuted),
              const SizedBox(height: 16),
              const Text('No attendance records match your filters',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CmsTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Adjust your filters or record a new attendance entry.',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: CmsTheme.textSecondary)),
              if (canRecord) ...[
                const SizedBox(height: 20),
                CmsButton(
                    label: 'Record Attendance',
                    icon: Icons.add,
                    onPressed: onRecord),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Record count chip
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CmsTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${records.length} record${records.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CmsTheme.accent),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),

          // ── DataTable2 with fixed header ──────────────────────────────
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 20,
                  minWidth: 900,
                  fixedTopRows: 1,
                  headingRowHeight: 44,
                  dataRowHeight: 56,
                  headingRowColor: WidgetStateProperty.all(
                      CmsTheme.surfaceElevated),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                        color: CmsTheme.border.withValues(alpha: 0.6),
                        width: 1),
                  ),
                  columns: const [
                    DataColumn2(
                      label: _ColHeader('Date'),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: _ColHeader('Event / Service'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: _ColHeader('Category'),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: _ColHeader('Day'),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: _ColHeader('Male'),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: _ColHeader('Female'),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: _ColHeader('Adult'),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: _ColHeader('Youth'),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: _ColHeader('Children'),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: _ColHeader('Total'),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: _ColHeader('Recorded By'),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows: records
                      .map((r) => _buildRow(r))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(AttendanceRecordModel r) {
    final isWeekend = r.dayType.toLowerCase() == 'weekend';
    final dateStr = DateFormat('MMM d, yyyy').format(r.date);
    return DataRow2(
      cells: [
        DataCell(Text(dateStr,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: CmsTheme.textSecondary))),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r.eventName,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CmsTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(r.eventCategory,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: CmsTheme.textMuted)),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(r.eventCategory,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.accent)),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (isWeekend ? CmsTheme.accent : CmsTheme.success)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              r.dayType.toUpperCase(),
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isWeekend ? CmsTheme.accent : CmsTheme.success),
            ),
          ),
        ),
        DataCell(_numCell('${r.male}', const Color(0xFF60A5FA))),
        DataCell(_numCell('${r.female}', const Color(0xFFF472B6))),
        DataCell(_numCell('${r.adult}', CmsTheme.textSecondary)),
        DataCell(_numCell('${r.youth}', CmsTheme.warning)),
        DataCell(_numCell('${r.children}', CmsTheme.success)),
        DataCell(
          Text('${r.total}',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.textPrimary)),
        ),
        DataCell(
          Text(r.recordedByName ?? r.recordedBy ?? '—',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: CmsTheme.textMuted)),
        ),
      ],
    );
  }

  Widget _numCell(String value, Color color) => Text(
        value,
        style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color),
      );
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CmsTheme.textSecondary));
}

// ─────────────────────────── Analytics Tab ─────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab(
      {required this.records, required this.allRecords});
  final List<AttendanceRecordModel> records;
  final List<AttendanceRecordModel> allRecords;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No data for selected filters.',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: CmsTheme.textSecondary)),
        ),
      );
    }

    // ── Compute aggregates ────────────────────────────────────────────────
    final totalHeadcount = records.fold<int>(0, (s, r) => s + r.total);
    final totalMale = records.fold<int>(0, (s, r) => s + r.male);
    final totalFemale = records.fold<int>(0, (s, r) => s + r.female);
    final totalAdult = records.fold<int>(0, (s, r) => s + r.adult);
    final totalYouth = records.fold<int>(0, (s, r) => s + r.youth);
    final totalChildren = records.fold<int>(0, (s, r) => s + r.children);
    final avgAttendance =
        records.isEmpty ? 0 : (totalHeadcount / records.length).round();

    final weekendRecords =
        records.where((r) => r.dayType.toLowerCase() == 'weekend').toList();
    final weekdayRecords =
        records.where((r) => r.dayType.toLowerCase() == 'weekday').toList();
    final avgWeekend = weekendRecords.isEmpty
        ? 0
        : (weekendRecords.fold<int>(0, (s, r) => s + r.total) /
                weekendRecords.length)
            .round();
    final avgWeekday = weekdayRecords.isEmpty
        ? 0
        : (weekdayRecords.fold<int>(0, (s, r) => s + r.total) /
                weekdayRecords.length)
            .round();

    // Category breakdown
    final Map<String, int> categoryTotals = {};
    for (final r in records) {
      categoryTotals[r.eventCategory] =
          (categoryTotals[r.eventCategory] ?? 0) + r.total;
    }

    // Trend (chronological)
    final trendRecords = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final trendMax =
        records.map((r) => r.total).fold(0, (a, b) => a > b ? a : b) * 1.25;

    // Category avg
    final Map<String, List<int>> categoryData = {};
    for (final r in records) {
      categoryData.putIfAbsent(r.eventCategory, () => []).add(r.total);
    }
    final categoryAvg = {
      for (final e in categoryData.entries)
        e.key: e.value.fold<int>(0, (s, v) => s + v) ~/ e.value.length
    };

    final palette = [
      CmsTheme.accent,
      CmsTheme.success,
      CmsTheme.warning,
      CmsTheme.info,
      CmsTheme.danger,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metric Cards ────────────────────────────────────────────────
          Row(
            children: [
              _MetricCard(
                label: 'Total Attendees',
                value: '$totalHeadcount',
                sub: '${records.length} services',
                color: CmsTheme.accent,
                icon: Icons.groups_outlined,
              ),
              const SizedBox(width: 14),
              _MetricCard(
                label: 'Avg per Service',
                value: '$avgAttendance',
                sub: 'across all types',
                color: CmsTheme.success,
                icon: Icons.trending_up,
              ),
              const SizedBox(width: 14),
              _MetricCard(
                label: 'Avg Weekend',
                value: '$avgWeekend',
                sub: '${weekendRecords.length} weekend services',
                color: CmsTheme.warning,
                icon: Icons.wb_sunny_outlined,
              ),
              const SizedBox(width: 14),
              _MetricCard(
                label: 'Avg Weekday',
                value: '$avgWeekday',
                sub: '${weekdayRecords.length} weekday services',
                color: CmsTheme.info,
                icon: Icons.today_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Row 1: Trend Chart + Gender Pie ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attendance Trend Line Chart
              Expanded(
                flex: 3,
                child: _ChartCard(
                  title: 'Attendance Trend',
                  subtitle:
                      'Total headcount over time — chronological view of service growth',
                  child: SizedBox(
                    height: 220,
                    child: trendRecords.length < 2
                        ? _singlePointChart(trendRecords, palette[0])
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: trendMax.toDouble() + 5,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => const FlLine(
                                    color: CmsTheme.border, strokeWidth: 1),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (val, _) {
                                      final idx = val.toInt();
                                      if (idx < 0 ||
                                          idx >= trendRecords.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          DateFormat('MMM d')
                                              .format(trendRecords[idx].date),
                                          style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10,
                                              color: CmsTheme.textMuted),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 36,
                                    getTitlesWidget: (val, _) => Text(
                                      val.toInt() == 0
                                          ? ''
                                          : '${val.toInt()}',
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          color: CmsTheme.textMuted),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (spots) => spots
                                      .map((spot) {
                                        final idx = spot.x.toInt();
                                        final r = trendRecords[idx];
                                        return LineTooltipItem(
                                          '${r.eventName}\n${DateFormat('MMM d').format(r.date)}: ${r.total} people',
                                          const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: Colors.white),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: trendRecords
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value.total.toDouble()))
                                      .toList(),
                                  isCurved: true,
                                  color: CmsTheme.accent,
                                  barWidth: 2.5,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: CmsTheme.accent.withValues(alpha: 0.1),
                                  ),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, __, ___, ____) =>
                                        FlDotCirclePainter(
                                      radius: 4,
                                      color: CmsTheme.accent,
                                      strokeWidth: 2,
                                      strokeColor: CmsTheme.bg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Gender Distribution Donut
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Gender Distribution',
                  subtitle: 'Male vs Female ratio across all recorded services',
                  child: SizedBox(
                    height: 220,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                              sections: [
                                if (totalMale > 0)
                                  PieChartSectionData(
                                    color: const Color(0xFF60A5FA),
                                    value: totalMale.toDouble(),
                                    radius: 38,
                                    title: '${((totalMale / (totalMale + totalFemale)) * 100).round()}%',
                                    titleStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                if (totalFemale > 0)
                                  PieChartSectionData(
                                    color: const Color(0xFFF472B6),
                                    value: totalFemale.toDouble(),
                                    radius: 38,
                                    title: '${((totalFemale / (totalMale + totalFemale)) * 100).round()}%',
                                    titleStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Legend(color: const Color(0xFF60A5FA),
                                label: 'Male', value: '$totalMale'),
                            const SizedBox(height: 12),
                            _Legend(color: const Color(0xFFF472B6),
                                label: 'Female', value: '$totalFemale'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Row 2: Category Bar + Age Group Donut ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Average Bar Chart
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Average Attendance by Category',
                  subtitle: 'Compare typical turnout across service types',
                  child: SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (categoryAvg.values.isEmpty
                                ? 100
                                : categoryAvg.values
                                    .reduce((a, b) => a > b ? a : b)) *
                            1.35 +
                            10,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, gi, rod, ri) {
                              final cat =
                                  categoryAvg.keys.elementAt(group.x.toInt());
                              return BarTooltipItem(
                                '$cat\nAvg: ${rod.toY.round()} people',
                                const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx < 0 ||
                                    idx >= categoryAvg.length) {
                                  return const SizedBox.shrink();
                                }
                                final cat =
                                    categoryAvg.keys.elementAt(idx);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    cat.length > 10
                                        ? '${cat.substring(0, 9)}…'
                                        : cat,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        color: CmsTheme.textMuted),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (val, _) => Text(
                                '${val.toInt()}',
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: CmsTheme.textMuted),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                              color: CmsTheme.border, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: categoryAvg.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) => BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.value.toDouble(),
                                      color: palette[e.key % palette.length],
                                      width: 28,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(5)),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Age Group Distribution Donut
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Age Group Distribution',
                  subtitle: 'Adults, youth and children breakdown across services',
                  child: SizedBox(
                    height: 220,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                              sections: [
                                if (totalAdult > 0)
                                  PieChartSectionData(
                                    color: CmsTheme.accent,
                                    value: totalAdult.toDouble(),
                                    radius: 38,
                                    title: '${((totalAdult / (totalAdult + totalYouth + totalChildren)) * 100).round()}%',
                                    titleStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                if (totalYouth > 0)
                                  PieChartSectionData(
                                    color: CmsTheme.warning,
                                    value: totalYouth.toDouble(),
                                    radius: 38,
                                    title: '${((totalYouth / (totalAdult + totalYouth + totalChildren)) * 100).round()}%',
                                    titleStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                if (totalChildren > 0)
                                  PieChartSectionData(
                                    color: CmsTheme.success,
                                    value: totalChildren.toDouble(),
                                    radius: 38,
                                    title: '${((totalChildren / (totalAdult + totalYouth + totalChildren)) * 100).round()}%',
                                    titleStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Legend(
                                color: CmsTheme.accent,
                                label: 'Adults',
                                value: '$totalAdult'),
                            const SizedBox(height: 10),
                            _Legend(
                                color: CmsTheme.warning,
                                label: 'Youth',
                                value: '$totalYouth'),
                            const SizedBox(height: 10),
                            _Legend(
                                color: CmsTheme.success,
                                label: 'Children',
                                value: '$totalChildren'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Row 3: Weekend vs Weekday Grouped Bar + Category Totals ──────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekend vs Weekday Stacked Bar
              Expanded(
                flex: 3,
                child: _ChartCard(
                  title: 'Weekend vs Weekday Attendance',
                  subtitle:
                      'Side-by-side comparison of weekend and weekday attendance',
                  child: SizedBox(
                    height: 220,
                    child: _WeekendWeekdayChart(records: records),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Category Totals Breakdown
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Total by Service Category',
                  subtitle: 'Cumulative headcount per service type',
                  child: SizedBox(
                    height: 220,
                    child: Column(
                      children: categoryTotals.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                        final maxVal = categoryTotals.values
                            .fold<int>(0, (a, b) => a > b ? a : b);
                        final pct = maxVal == 0
                            ? 0.0
                            : e.value.value / maxVal;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.value.key,
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: CmsTheme.textSecondary)),
                                  Text('${e.value.value}',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: palette[
                                              e.key % palette.length])),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor:
                                      palette[e.key % palette.length]
                                          .withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      palette[e.key % palette.length]),
                                  minHeight: 7,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Insight Summary Card ─────────────────────────────────────────
          _InsightCard(records: records),
        ],
      ),
    );
  }

  Widget _singlePointChart(
      List<AttendanceRecordModel> data, Color color) {
    if (data.isEmpty) {
      return const Center(
          child: Text('No data', style: TextStyle(color: CmsTheme.textMuted)));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${data.first.total}',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text('attendance — ${data.first.eventName}',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: CmsTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _WeekendWeekdayChart extends StatelessWidget {
  const _WeekendWeekdayChart({required this.records});
  final List<AttendanceRecordModel> records;

  @override
  Widget build(BuildContext context) {
    final weekendR =
        records.where((r) => r.dayType.toLowerCase() == 'weekend').toList();
    final weekdayR =
        records.where((r) => r.dayType.toLowerCase() == 'weekday').toList();

    if (weekendR.isEmpty && weekdayR.isEmpty) {
      return const Center(
          child: Text('No data', style: TextStyle(color: CmsTheme.textMuted)));
    }

    final maxLen =
        weekendR.length > weekdayR.length ? weekendR.length : weekdayR.length;
    final maxY = [
      ...weekendR.map((r) => r.total),
      ...weekdayR.map((r) => r.total),
    ].fold<int>(0, (a, b) => a > b ? a : b) * 1.3 + 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        groupsSpace: 8,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) {
              final label = ri == 0 ? 'Weekend' : 'Weekday';
              return BarTooltipItem('$label: ${rod.toY.round()}',
                  const TextStyle(color: Colors.white, fontSize: 12));
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) => Text(
                '#${val.toInt() + 1}',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: CmsTheme.textMuted),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, _) => Text('${val.toInt()}',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: CmsTheme.textMuted)),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: CmsTheme.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(maxLen, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              if (i < weekendR.length)
                BarChartRodData(
                  toY: weekendR[i].total.toDouble(),
                  color: CmsTheme.accent,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              if (i < weekdayR.length)
                BarChartRodData(
                  toY: weekdayR[i].total.toDouble(),
                  color: CmsTheme.success,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.records});
  final List<AttendanceRecordModel> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final sorted = [...records]..sort((a, b) => b.total.compareTo(a.total));
    final highest = sorted.first;
    final lowest = sorted.last;
    final avg =
        records.fold<int>(0, (s, r) => s + r.total) ~/ records.length;
    final weekendRecords =
        records.where((r) => r.dayType.toLowerCase() == 'weekend').toList();
    final trend = records.length >= 2
        ? records.last.total - records.first.total
        : 0;
    final trendUp = trend >= 0;

    return CmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CmsTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: CmsTheme.accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Attendance Insights & Recommendations',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CmsTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InsightChip(
                icon: Icons.emoji_events_outlined,
                label: 'Best Attendance',
                value:
                    '${highest.total} on ${DateFormat('MMM d').format(highest.date)} (${highest.eventName})',
                color: CmsTheme.success,
              ),
              _InsightChip(
                icon: Icons.arrow_downward_outlined,
                label: 'Lowest Attendance',
                value:
                    '${lowest.total} on ${DateFormat('MMM d').format(lowest.date)} (${lowest.eventName})',
                color: CmsTheme.danger,
              ),
              _InsightChip(
                icon: Icons.bar_chart,
                label: 'Average per Service',
                value: '$avg people',
                color: CmsTheme.accent,
              ),
              if (weekendRecords.isNotEmpty)
                _InsightChip(
                  icon: Icons.weekend_outlined,
                  label: 'Weekend Engagement',
                  value:
                      '${weekendRecords.length} weekend services • ${weekendRecords.fold<int>(0, (s, r) => s + r.total) ~/ weekendRecords.length} avg',
                  color: CmsTheme.warning,
                ),
              _InsightChip(
                icon: trendUp ? Icons.trending_up : Icons.trending_down,
                label: 'Growth Trend',
                value: trendUp
                    ? '+$trend from first to last recorded'
                    : '$trend from first to last recorded',
                color: trendUp ? CmsTheme.success : CmsTheme.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: CmsTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CmsTheme.textPrimary)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: CmsTheme.textMuted)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: CmsTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CmsTheme.textPrimary)),
                  Text(sub,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: CmsTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: CmsTheme.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: CmsTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────── Record Dialog ─────────────────────────────────

class _RecordAttendanceDialog extends StatefulWidget {
  const _RecordAttendanceDialog({
    required this.branchId,
    required this.recorderName,
    required this.existingEvents,
    required this.ref,
  });
  final String branchId;
  final String recorderName;
  final List<EventModel> existingEvents;
  final WidgetRef ref;

  @override
  State<_RecordAttendanceDialog> createState() =>
      _RecordAttendanceDialogState();
}

class _RecordAttendanceDialogState extends State<_RecordAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEventId;
  final _customEventCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _category = 'Sunday Service';

  final _maleCtrl = TextEditingController(text: '0');
  final _femaleCtrl = TextEditingController(text: '0');
  final _adultCtrl = TextEditingController(text: '0');
  final _youthCtrl = TextEditingController(text: '0');
  final _childrenCtrl = TextEditingController(text: '0');

  bool _saving = false;

  int get _computedTotal {
    final m = int.tryParse(_maleCtrl.text.trim()) ?? 0;
    final f = int.tryParse(_femaleCtrl.text.trim()) ?? 0;
    final a = int.tryParse(_adultCtrl.text.trim()) ?? 0;
    final y = int.tryParse(_youthCtrl.text.trim()) ?? 0;
    final c = int.tryParse(_childrenCtrl.text.trim()) ?? 0;
    final genderSum = m + f;
    final ageSum = a + y + c;
    return genderSum > 0 ? genderSum : ageSum;
  }

  String get _dayType =>
      (_selectedDate.weekday == DateTime.saturday ||
              _selectedDate.weekday == DateTime.sunday)
          ? 'weekend'
          : 'weekday';

  @override
  void dispose() {
    _customEventCtrl.dispose();
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    _adultCtrl.dispose();
    _youthCtrl.dispose();
    _childrenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CmsTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.add_chart, color: CmsTheme.accent, size: 22),
          SizedBox(width: 8),
          Text('Record Service Attendance',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CmsTheme.textPrimary)),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event select
                const Text('Event / Service',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedEventId,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(
                      color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(
                      hintText: 'Select existing event or enter custom…'),
                  items: [
                    const DropdownMenuItem(
                        value: '__custom__',
                        child: Text('+ Custom / Special Event')),
                    ...widget.existingEvents.map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text('${e.title} (${e.category})'))),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedEventId = v;
                      if (v != null && v != '__custom__') {
                        final found =
                            widget.existingEvents.firstWhere((e) => e.id == v);
                        _category = found.category;
                      }
                    });
                  },
                ),
                if (_selectedEventId == '__custom__') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customEventCtrl,
                    style: const TextStyle(
                        color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                    decoration:
                        const InputDecoration(labelText: 'Custom Event Title'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter event title'
                        : null,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Date picker
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: CmsTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: CmsTheme.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 15, color: CmsTheme.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(_selectedDate),
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: CmsTheme.textPrimary),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CmsTheme.accent
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _dayType.toUpperCase(),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: CmsTheme.accent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        dropdownColor: CmsTheme.surfaceElevated,
                        style: const TextStyle(
                            color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(
                              value: 'Sunday Service',
                              child: Text('Sunday Service')),
                          DropdownMenuItem(
                              value: 'Midweek',
                              child: Text('Midweek Service')),
                          DropdownMenuItem(
                              value: 'Vigil', child: Text('Vigil')),
                          DropdownMenuItem(
                              value: 'Special Event',
                              child: Text('Special Event')),
                        ],
                        onChanged: (v) =>
                            setState(() => _category = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionDivider('Gender Breakdown'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maleCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                        decoration: const InputDecoration(
                          labelText: 'Male',
                          prefixIcon:
                              Icon(Icons.male, color: Color(0xFF60A5FA)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _femaleCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                        decoration: const InputDecoration(
                          labelText: 'Female',
                          prefixIcon:
                              Icon(Icons.female, color: Color(0xFFF472B6)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionDivider('Age Group Breakdown'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adultCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                        decoration: const InputDecoration(labelText: 'Adults'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _youthCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                        decoration: const InputDecoration(labelText: 'Youth'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _childrenCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                        decoration:
                            const InputDecoration(labelText: 'Children'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Live total
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CmsTheme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: CmsTheme.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Computed Total Headcount',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CmsTheme.textSecondary)),
                      Text('$_computedTotal',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: CmsTheme.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Save Attendance',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final total = _computedTotal;
            if (total <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Enter at least one count.'),
                  backgroundColor: CmsTheme.warning));
              return;
            }

            final nav = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _saving = true);
            try {
              String eventId = _selectedEventId ?? '';
              String eventName = _category;

              if (_selectedEventId == '__custom__' ||
                  _selectedEventId == null) {
                eventName = _selectedEventId == '__custom__'
                    ? _customEventCtrl.text.trim()
                    : _category;
                eventId = 'custom-${DateTime.now().millisecondsSinceEpoch}';
              } else {
                final found = widget.existingEvents
                    .firstWhere((e) => e.id == _selectedEventId);
                eventName = found.title;
              }

              final m = int.tryParse(_maleCtrl.text.trim()) ?? 0;
              final f = int.tryParse(_femaleCtrl.text.trim()) ?? 0;
              final a = int.tryParse(_adultCtrl.text.trim()) ?? 0;
              final y = int.tryParse(_youthCtrl.text.trim()) ?? 0;
              final c = int.tryParse(_childrenCtrl.text.trim()) ?? 0;

              final record = AttendanceRecordModel(
                id: '',
                eventId: eventId,
                eventName: eventName,
                eventCategory: _category,
                date: _selectedDate,
                dayType: _dayType,
                male: m,
                female: f,
                adult: a,
                youth: y,
                children: c,
                total: total,
                recordedByName: widget.recorderName,
              );

              await widget.ref
                  .read(eventRepositoryProvider)
                  .recordDetailedAttendance(widget.branchId, record);
              if (mounted) nav.pop();
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: CmsTheme.danger));
              }
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CmsTheme.textPrimary)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: CmsTheme.border)),
      ],
    );
  }
}

// ─────────────────────────── String extension ──────────────────────────────

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
