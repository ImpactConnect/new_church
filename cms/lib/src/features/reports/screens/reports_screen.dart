import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

final _allIncomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);

final _allGivingProvider = StreamProvider.autoDispose.family<List<GivingModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchGiving(branchId),
);

final _allExpendituresReportProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditures(branchId),
);

final _allMembersReportProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);

    final incomeAsync = ref.watch(_allIncomeProvider(branchId));
    final givingAsync = ref.watch(_allGivingProvider(branchId));
    final expenditureAsync = ref.watch(_allExpendituresReportProvider(branchId));
    final membersAsync = ref.watch(_allMembersReportProvider(branchId));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CmsPageHeader(
              title: 'Reports & Analytics',
              subtitle: 'Executive financial statements and growth metrics',
            ),
            const SizedBox(height: 24),

            // Summary Metric Cards
            Row(
              children: [
                _metricCard(
                  'Total Revenue',
                  incomeAsync.when(
                    data: (items) => '₦${items.fold<double>(0, (s, i) => s + i.amount).toStringAsFixed(2)}',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  CmsTheme.success,
                  Icons.trending_up,
                ),
                const SizedBox(width: 16),
                _metricCard(
                  'Total Expenditures',
                  expenditureAsync.when(
                    data: (items) => '₦${items.fold<double>(0, (s, e) => s + e.approvedAmount).toStringAsFixed(2)}',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  CmsTheme.danger,
                  Icons.trending_down,
                ),
                const SizedBox(width: 16),
                _metricCard(
                  'Total Membership',
                  membersAsync.when(
                    data: (m) => '${m.length} active',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  CmsTheme.accent,
                  Icons.people_outline,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Charts Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue vs Expenditure Bar Chart
                Expanded(
                  flex: 3,
                  child: CmsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue vs Expenditures Overview',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 240,
                          child: incomeAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (incomes) {
                              final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);
                              final totalExp = expenditureAsync.valueOrNull?.fold<double>(0, (s, e) => s + e.approvedAmount) ?? 0;

                              return BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (totalIncome > totalExp ? totalIncome : totalExp) * 1.2 + 100,
                                  barTouchData: BarTouchDataEnabled(false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, _) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              val == 0 ? 'Revenue' : 'Expenditure',
                                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: [
                                    BarChartGroupData(
                                      x: 0,
                                      barRods: [
                                        BarChartRodData(
                                          toY: totalIncome,
                                          color: CmsTheme.success,
                                          width: 32,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 1,
                                      barRods: [
                                        BarChartRodData(
                                          toY: totalExp,
                                          color: CmsTheme.danger,
                                          width: 32,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ],
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
                ),
                const SizedBox(width: 20),

                // Giving Distribution Pie Chart
                Expanded(
                  flex: 2,
                  child: CmsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giving Breakdown',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 240,
                          child: givingAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (givings) {
                              final tithes = givings.where((g) => g.type == 'tithe').fold<double>(0, (s, g) => s + g.amount);
                              final offerings = givings.where((g) => g.type == 'offering').fold<double>(0, (s, g) => s + g.amount);
                              final pledges = givings.where((g) => g.type == 'pledge').fold<double>(0, (s, g) => s + g.amount);
                              final total = tithes + offerings + pledges;

                              if (total == 0) {
                                return const Center(child: Text('No giving records yet', style: TextStyle(color: CmsTheme.textMuted)));
                              }

                              return PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    if (tithes > 0)
                                      PieChartSectionData(
                                        color: CmsTheme.accent,
                                        value: tithes,
                                        title: 'Tithe',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    if (offerings > 0)
                                      PieChartSectionData(
                                        color: CmsTheme.success,
                                        value: offerings,
                                        title: 'Offering',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    if (pledges > 0)
                                      PieChartSectionData(
                                        color: CmsTheme.warning,
                                        value: pledges,
                                        title: 'Pledge',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
            ],
          ),
        ],
      ),
    ),
  );
}
