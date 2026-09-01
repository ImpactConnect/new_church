import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

// ── Data Providers ─────────────────────────────────────────────────────────────

final _rptIncomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);
final _rptGivingProvider = StreamProvider.autoDispose.family<List<GivingModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchGiving(branchId),
);
final _rptExpendituresProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditures(branchId),
);
final _rptBudgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId),
);
final _rptMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

// Attendance record model
class _AttRec {
  _AttRec({required this.date, required this.eventName, required this.total,
    required this.male, required this.female, required this.adult,
    required this.youth, required this.children});
  final DateTime date;
  final String eventName;
  final int total, male, female, adult, youth, children;
}

final _rptAttendanceProvider = StreamProvider.autoDispose.family<List<_AttRec>, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
      .collection('branches').doc(branchId)
      .collection('attendance_records')
      .orderBy('date', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        final d = doc.data();
        DateTime parseDate(dynamic v) {
          if (v == null) return DateTime.now();
          if (v is Timestamp) return v.toDate();
          return DateTime.tryParse(v.toString()) ?? DateTime.now();
        }
        return _AttRec(
          date: parseDate(d['date']),
          eventName: d['eventName'] as String? ?? '',
          total: (d['total'] as num?)?.toInt() ?? 0,
          male: (d['male'] as num?)?.toInt() ?? 0,
          female: (d['female'] as num?)?.toInt() ?? 0,
          adult: (d['adult'] as num?)?.toInt() ?? 0,
          youth: (d['youth'] as num?)?.toInt() ?? 0,
          children: (d['children'] as num?)?.toInt() ?? 0,
        );
      }).toList());
  },
);

// ── Main Widget ────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final canExport = user?.can(AppPermission.viewFinancialReports) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: CmsPageHeader(
              title: 'Reports & Analytics',
              subtitle: 'Financial statements, attendance trends, and membership metrics',
            )),
            if (canExport) _ExportBtn(branchId: branchId, fmt: _currencyFmt),
          ]),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: CmsTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CmsTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: CmsTheme.accent, borderRadius: BorderRadius.circular(8)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: CmsTheme.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Financial Summary'),
                Tab(text: 'Budget vs. Actual'),
                Tab(text: 'Attendance Trends'),
                Tab(text: 'Membership'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(child: TabBarView(controller: _tabController, children: [
            _FinSummaryTab(branchId: branchId, fmt: _currencyFmt),
            _BudgetActualTab(branchId: branchId, fmt: _currencyFmt),
            _AttendanceTab(branchId: branchId),
            _MembershipTab(branchId: branchId),
          ])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Financial Summary
// ─────────────────────────────────────────────────────────────────────────────

class _FinSummaryTab extends ConsumerWidget {
  const _FinSummaryTab({required this.branchId, required this.fmt});
  final String branchId;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incA  = ref.watch(_rptIncomeProvider(branchId));
    final givA  = ref.watch(_rptGivingProvider(branchId));
    final expA  = ref.watch(_rptExpendituresProvider(branchId));
    final memA  = ref.watch(_rptMembersProvider(branchId));

    final totalInc = incA.valueOrNull?.fold<double>(0, (s, i) => s + i.amount) ?? 0;
    final totalExp = expA.valueOrNull?.fold<double>(0, (s, e) => s + e.approvedAmount) ?? 0;

    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _Card(label: 'Total Revenue',       value: incA.isLoading ? '…' : fmt.format(totalInc),        color: CmsTheme.success,  icon: Icons.trending_up),
        const SizedBox(width: 16),
        _Card(label: 'Total Expenditures',  value: expA.isLoading ? '…' : fmt.format(totalExp),        color: CmsTheme.danger,   icon: Icons.trending_down),
        const SizedBox(width: 16),
        _Card(label: 'Net Balance',         value: incA.isLoading ? '…' : fmt.format(totalInc - totalExp), color: CmsTheme.accent, icon: Icons.account_balance_wallet_outlined),
        const SizedBox(width: 16),
        _Card(label: 'Active Members',      value: memA.when(data: (m) => '${m.length}', loading: () => '…', error: (_, __) => '—'), color: const Color(0xFF8B5CF6), icon: Icons.people_outline),
      ]),
      const SizedBox(height: 24),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: CmsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Revenue vs Expenditures', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(height: 240, child: incA.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (inc) {
              final maxY = (totalInc > totalExp ? totalInc : totalExp) * 1.2 + 100;
              return BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (val, _) => Padding(padding: const EdgeInsets.only(top: 8),
                      child: Text(val == 0 ? 'Revenue' : 'Expenditure',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))))),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalInc, color: CmsTheme.success, width: 32, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalExp, color: CmsTheme.danger, width: 32, borderRadius: BorderRadius.circular(6))]),
                ],
              ));
            },
          )),
        ]))),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: CmsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Giving Breakdown', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(height: 240, child: givA.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (g) {
              final tithes   = g.where((x) => x.type == 'tithe').fold<double>(0, (s, x) => s + x.amount);
              final offering = g.where((x) => x.type == 'offering').fold<double>(0, (s, x) => s + x.amount);
              final pledges  = g.where((x) => x.type == 'pledge').fold<double>(0, (s, x) => s + x.amount);
              if (tithes + offering + pledges == 0) return const Center(child: Text('No giving records yet', style: TextStyle(color: CmsTheme.textMuted)));
              return PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 40, sections: [
                if (tithes   > 0) PieChartSectionData(color: CmsTheme.accent,   value: tithes,   title: 'Tithe',    radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                if (offering > 0) PieChartSectionData(color: CmsTheme.success,  value: offering, title: 'Offering', radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                if (pledges  > 0) PieChartSectionData(color: CmsTheme.warning,  value: pledges,  title: 'Pledge',   radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ]));
            },
          )),
        ]))),
      ]),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Budget vs. Actual
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetActualTab extends ConsumerWidget {
  const _BudgetActualTab({required this.branchId, required this.fmt});
  final String branchId;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budA = ref.watch(_rptBudgetsProvider(branchId));
    final expA = ref.watch(_rptExpendituresProvider(branchId));

    return budA.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (budgets) {
        final approved = budgets.where((b) => b.status == 'approved').toList();
        if (approved.isEmpty) return const Center(child: Text('No approved budgets yet', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textMuted)));

        final totalBudgeted  = approved.fold<double>(0, (s, b) => s + (b.approvedAmount ?? b.requestedAmount));
        final totalDisbursed = expA.valueOrNull?.fold<double>(0, (s, e) => s + e.totalDisbursed) ?? 0;

        return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Card(label: 'Total Approved Budget', value: fmt.format(totalBudgeted),                color: CmsTheme.accent,   icon: Icons.account_balance_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Total Disbursed',       value: fmt.format(totalDisbursed),               color: CmsTheme.warning,  icon: Icons.payments_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Remaining',             value: fmt.format(totalBudgeted - totalDisbursed), color: CmsTheme.success, icon: Icons.savings_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Utilisation',           value: totalBudgeted > 0 ? '${(totalDisbursed / totalBudgeted * 100).toStringAsFixed(1)}%' : '0%', color: const Color(0xFF8B5CF6), icon: Icons.pie_chart_outline),
          ]),
          const SizedBox(height: 24),

          CmsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Budget vs. Actual — By Line Item',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
            const SizedBox(height: 16),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: CmsTheme.bg, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Expanded(flex: 3, child: Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Period',   style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Budget',   style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Disbursed',style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Remaining',style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary))),
                Expanded(flex: 1, child: Text('Usage',    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary))),
              ]),
            ),
            const SizedBox(height: 8),

            ...approved.map((b) {
              final amt = b.approvedAmount ?? b.requestedAmount;
              final cat = b.approvedCategory ?? b.category;
              final relExp = expA.valueOrNull?.where((e) => e.category == cat).toList() ?? [];
              final disb = relExp.fold<double>(0, (s, e) => s + e.totalDisbursed);
              final rem  = amt - disb;
              final usage = amt > 0 ? disb / amt : 0.0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: CmsTheme.border.withValues(alpha: 0.5)))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(flex: 3, child: Text(cat, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary))),
                    Expanded(flex: 2, child: Text(b.fiscalPeriod, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary))),
                    Expanded(flex: 2, child: Text(fmt.format(amt), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary))),
                    Expanded(flex: 2, child: Text(fmt.format(disb), style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: disb > 0 ? CmsTheme.warning : CmsTheme.textMuted))),
                    Expanded(flex: 2, child: Text(fmt.format(rem),  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: rem < 0 ? CmsTheme.danger : CmsTheme.success))),
                    Expanded(flex: 1, child: Text('${(usage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                        color: usage > 1 ? CmsTheme.danger : usage > 0.8 ? CmsTheme.warning : CmsTheme.success))),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usage.clamp(0.0, 1.0),
                      backgroundColor: CmsTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(usage > 1 ? CmsTheme.danger : usage > 0.8 ? CmsTheme.warning : CmsTheme.accent),
                      minHeight: 6,
                    ),
                  ),
                ]),
              );
            }),
          ])),
        ]));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Attendance Trends
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.branchId});
  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attA = ref.watch(_rptAttendanceProvider(branchId));
    return attA.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: CmsTheme.textMuted),
            SizedBox(height: 12),
            Text('No attendance records yet', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textMuted)),
          ]));
        }

        records.sort((a, b) => a.date.compareTo(b.date));
        final recent = records.length > 12 ? records.sublist(records.length - 12) : records;
        final dateFmt = DateFormat('dd/MM');
        final spots   = recent.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total.toDouble())).toList();
        final avg     = recent.isEmpty ? 0 : recent.fold<int>(0, (s, r) => s + r.total) ~/ recent.length;
        final avgM    = recent.isEmpty ? 0 : recent.fold<int>(0, (s, r) => s + r.male)  ~/ recent.length;
        final avgF    = recent.isEmpty ? 0 : recent.fold<int>(0, (s, r) => s + r.female)~/ recent.length;
        final peak    = recent.map((r) => r.total).reduce((a, b) => a > b ? a : b);
        final minAtt  = recent.map((r) => r.total).reduce((a, b) => a < b ? a : b);

        return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Card(label: 'Avg. Attendance', value: '$avg',  color: CmsTheme.accent,              icon: Icons.groups_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Avg. Male',       value: '$avgM', color: const Color(0xFF3B82F6),       icon: Icons.man_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Avg. Female',     value: '$avgF', color: const Color(0xFFEC4899),       icon: Icons.woman_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Peak',            value: '$peak', color: CmsTheme.success,              icon: Icons.trending_up),
          ]),
          const SizedBox(height: 24),

          CmsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Attendance Trend (Last 12 Records)',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
            const SizedBox(height: 20),
            SizedBox(height: 280, child: LineChart(LineChartData(
              lineBarsData: [LineChartBarData(
                spots: spots,
                isCurved: true,
                color: CmsTheme.accent,
                barWidth: 3,
                dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(radius: 4, color: CmsTheme.accent, strokeWidth: 2, strokeColor: Colors.white)),
                belowBarData: BarAreaData(show: true, color: CmsTheme.accent.withValues(alpha: 0.1)),
              )],
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: CmsTheme.border, strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= recent.length) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 8),
                      child: Text(dateFmt.format(recent[i].date),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textSecondary)));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textSecondary)))),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: (minAtt * 0.8).toDouble(),
              lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItems: (pts) => pts.map((s) {
                  final i = s.x.toInt();
                  if (i < 0 || i >= recent.length) return null;
                  final r = recent[i];
                  return LineTooltipItem(
                    '${DateFormat('dd MMM').format(r.date)}\nTotal: ${r.total} | ♂${r.male} ♀${r.female}',
                    const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white));
                }).toList(),
              )),
            ))),
          ])),
          const SizedBox(height: 20),

          // Demographic table
          CmsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Attendance Records — Demographic Detail',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1),
                4: FlexColumnWidth(1), 5: FlexColumnWidth(1), 6: FlexColumnWidth(1), 7: FlexColumnWidth(1)},
              children: [
                TableRow(
                  decoration: BoxDecoration(color: CmsTheme.bg, borderRadius: BorderRadius.circular(6)),
                  children: ['Date','Service','Total','Male','Female','Adult','Youth','Children'].map((h) =>
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: Text(h, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)))).toList(),
                ),
                ...recent.reversed.take(10).map((r) => TableRow(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: CmsTheme.border.withValues(alpha: 0.4)))),
                  children: [
                    _tc(DateFormat('dd/MM/yy').format(r.date)),
                    _tc(r.eventName.split(' ').take(3).join(' ')),
                    _tc('${r.total}', bold: true),
                    _tc('${r.male}'), _tc('${r.female}'), _tc('${r.adult}'), _tc('${r.youth}'), _tc('${r.children}'),
                  ],
                )),
              ],
            ),
          ])),
        ]));
      },
    );
  }

  Widget _tc(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    child: Text(t, style: TextStyle(fontFamily: 'Inter', fontSize: 12,
      fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: CmsTheme.textPrimary)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4: Membership Demographics
// ─────────────────────────────────────────────────────────────────────────────

class _MembershipTab extends ConsumerWidget {
  const _MembershipTab({required this.branchId});
  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memA = ref.watch(_rptMembersProvider(branchId));
    return memA.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        final active   = members.where((m) => m.memberStatus == 'active').length;
        final inactive = members.length - active;
        final male     = members.where((m) => m.gender?.toLowerCase() == 'male').length;
        final female   = members.where((m) => m.gender?.toLowerCase() == 'female').length;
        final married  = members.where((m) => m.maritalStatus?.toLowerCase() == 'married').length;
        final single   = members.where((m) => m.maritalStatus?.toLowerCase() == 'single').length;

        return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Card(label: 'Total Members', value: '${members.length}', color: CmsTheme.accent,                  icon: Icons.people_outline),
            const SizedBox(width: 16),
            _Card(label: 'Active',        value: '$active',           color: CmsTheme.success,                 icon: Icons.check_circle_outline),
            const SizedBox(width: 16),
            _Card(label: 'Inactive',      value: '$inactive',         color: CmsTheme.textMuted,               icon: Icons.person_off_outlined),
            const SizedBox(width: 16),
            _Card(label: 'Male / Female', value: '$male / $female',   color: const Color(0xFF8B5CF6),          icon: Icons.balance_outlined),
          ]),
          const SizedBox(height: 24),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _PieCard(title: 'Gender Distribution', sections: [
              if (male   > 0) PieChartSectionData(color: const Color(0xFF3B82F6), value: male.toDouble(),   title: 'M\n$male',    radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              if (female > 0) PieChartSectionData(color: const Color(0xFFEC4899), value: female.toDouble(), title: 'F\n$female',  radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ])),
            const SizedBox(width: 20),
            Expanded(child: _PieCard(title: 'Marital Status', sections: [
              if (married > 0) PieChartSectionData(color: CmsTheme.success, value: married.toDouble(), title: 'Married\n$married', radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
              if (single  > 0) PieChartSectionData(color: CmsTheme.accent,  value: single.toDouble(),  title: 'Single\n$single',  radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
            ])),
            const SizedBox(width: 20),
            Expanded(child: _PieCard(title: 'Member Status', sections: [
              if (active   > 0) PieChartSectionData(color: CmsTheme.success,  value: active.toDouble(),   title: 'Active\n$active',     radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
              if (inactive > 0) PieChartSectionData(color: CmsTheme.textMuted, value: inactive.toDouble(), title: 'Inactive\n$inactive', radius: 50, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
            ])),
          ]),
        ]));
      },
    );
  }
}

class _PieCard extends StatelessWidget {
  const _PieCard({required this.title, required this.sections});
  final String title;
  final List<PieChartSectionData> sections;

  @override
  Widget build(BuildContext context) => CmsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
    const SizedBox(height: 20),
    SizedBox(height: 200, child: sections.isEmpty
      ? const Center(child: Text('No data', style: TextStyle(color: CmsTheme.textMuted)))
      : PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 45, sections: sections))),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF Export
// ─────────────────────────────────────────────────────────────────────────────

class _ExportBtn extends ConsumerWidget {
  const _ExportBtn({required this.branchId, required this.fmt});
  final String branchId;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incA = ref.watch(_rptIncomeProvider(branchId));
    final expA = ref.watch(_rptExpendituresProvider(branchId));
    final budA = ref.watch(_rptBudgetsProvider(branchId));

    return ElevatedButton.icon(
      onPressed: (incA.isLoading || expA.isLoading) ? null : () async {
        final pdfBytes = await _buildPdf(
          incA.valueOrNull ?? [],
          expA.valueOrNull ?? [],
          budA.valueOrNull ?? [],
        );
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'ChurchCMS_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        );
      },
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: const Text('Export PDF', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: CmsTheme.danger, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<Uint8List> _buildPdf(List<IncomeModel> inc, List<ExpenditureModel> exp, List<BudgetModel> bud) async {
    final doc = pw.Document();
    final totalInc  = inc.fold<double>(0, (s, i) => s + i.amount);
    final totalExp  = exp.fold<double>(0, (s, e) => s + e.approvedAmount);
    final totalDisb = exp.fold<double>(0, (s, e) => s + e.totalDisbursed);
    final now = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pw.TableRow _hdr(List<String> cols) => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
      children: cols.map((c) => pw.Padding(padding: const pw.EdgeInsets.all(6),
        child: pw.Text(c, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)))).toList());

    pw.TableRow _row(List<String> cols, {bool alt = false}) => pw.TableRow(
      decoration: alt ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: cols.map((c) => pw.Padding(padding: const pw.EdgeInsets.all(6),
        child: pw.Text(c, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)))).toList());

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('CHURCH FINANCIAL REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ]),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
        pw.SizedBox(height: 8),
      ]),
      build: (_) => [
        pw.Header(level: 1, text: 'Executive Summary'),
        pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
          _hdr(['Metric', 'Amount']),
          _row(['Total Revenue',                  '₦${totalInc.toStringAsFixed(2)}']),
          _row(['Total Approved Expenditures',    '₦${totalExp.toStringAsFixed(2)}'], alt: true),
          _row(['Total Disbursed',                '₦${totalDisb.toStringAsFixed(2)}']),
          _row(['Net Balance (Revenue - Disbursed)', '₦${(totalInc - totalDisb).toStringAsFixed(2)}'], alt: true),
        ]),
        pw.SizedBox(height: 20),

        if (inc.isNotEmpty) ...[
          pw.Header(level: 1, text: 'Income Records'),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            _hdr(['Source', 'Type', 'Date', 'Amount']),
            ...inc.asMap().entries.map((e) => _row([
              e.value.source, e.value.formType,
              DateFormat('dd/MM/yyyy').format(e.value.date),
              '₦${e.value.amount.toStringAsFixed(2)}',
            ], alt: e.key.isOdd)),
          ]),
          pw.SizedBox(height: 20),
        ],

        if (exp.isNotEmpty) ...[
          pw.Header(level: 1, text: 'Expenditure Ledger'),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            _hdr(['Category', 'Approved', 'Disbursed', 'Remaining', 'Status']),
            ...exp.asMap().entries.map((e) => _row([
              e.value.category,
              '₦${e.value.approvedAmount.toStringAsFixed(2)}',
              '₦${e.value.totalDisbursed.toStringAsFixed(2)}',
              '₦${e.value.remainingBalance.toStringAsFixed(2)}',
              e.value.status.replaceAll('-', ' ').toUpperCase(),
            ], alt: e.key.isOdd)),
          ]),
          pw.SizedBox(height: 20),
        ],

        if (bud.where((b) => b.status == 'approved').isNotEmpty) ...[
          pw.Header(level: 1, text: 'Approved Budgets'),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            _hdr(['Category', 'Period', 'Requested', 'Approved', 'Approved By']),
            ...bud.where((b) => b.status == 'approved').toList().asMap().entries.map((e) {
              final b = e.value;
              return _row([
                b.approvedCategory ?? b.category, b.fiscalPeriod,
                '₦${b.requestedAmount.toStringAsFixed(2)}',
                '₦${(b.approvedAmount ?? b.requestedAmount).toStringAsFixed(2)}',
                b.approvedBy ?? '—',
              ], alt: e.key.isOdd);
            }),
          ]),
        ],
      ],
    ));

    return doc.save();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Metric Card
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value, required this.color, required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: CmsTheme.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CmsTheme.border),
    ),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
      ])),
    ]),
  ));
}

