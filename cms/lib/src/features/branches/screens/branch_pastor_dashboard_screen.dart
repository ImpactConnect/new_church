import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/routing/app_router.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _branchMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('members')
        .where('branchId', isEqualTo: branchId)
        .snapshots()
        .map((s) => s.docs.map((d) => MemberModel.fromFirestore(d.data(), d.id)).toList());
  },
);

final _branchEventsProvider = StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('branches')
        .doc(branchId)
        .collection('events')
        .orderBy('dateTime', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d.data(), d.id)).toList());
  },
);

final _branchIncomeHistoryProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('branches')
        .doc(branchId)
        .collection('income')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => IncomeModel.fromFirestore(d.data(), d.id)).toList());
  },
);

final _branchPendingRequestsProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('resourceRequests')
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.length);
  },
);

final _branchPendingRemittancesProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('remittances')
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.length);
  },
);

final _branchPendingBudgetsProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('branches')
        .doc(branchId)
        .collection('budgets')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.length);
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────

class BranchPastorDashboardScreen extends ConsumerStatefulWidget {
  const BranchPastorDashboardScreen({super.key});

  @override
  ConsumerState<BranchPastorDashboardScreen> createState() => _BranchPastorDashboardScreenState();
}

class _BranchPastorDashboardScreenState extends ConsumerState<BranchPastorDashboardScreen> {
  int _chartTab = 0; // 0 = Attendance Trend, 1 = Income Trend

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    final membersAsync = ref.watch(_branchMembersProvider(branchId));
    final eventsAsync = ref.watch(_branchEventsProvider(branchId));
    final incomeAsync = ref.watch(_branchIncomeHistoryProvider(branchId));
    final pendingRequestsAsync = ref.watch(_branchPendingRequestsProvider(branchId));
    final pendingRemittancesAsync = ref.watch(_branchPendingRemittancesProvider(branchId));
    final pendingBudgetsAsync = ref.watch(_branchPendingBudgetsProvider(branchId));

    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';
    final name = user?.displayName?.split(' ').first ?? 'Pastor';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Header
            StreamBuilder(
              stream: ref.read(branchRepositoryProvider).watchBranch(branchId),
              builder: (_, snapshot) {
                final branchName = snapshot.data?.name ?? 'Branch';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting, $name 👋',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$branchName  •  Branch Operations Portal',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: CmsTheme.textSecondary)),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Top Metric Cards
            LayoutBuilder(
              builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth > 850 ? 4 : 2;
                final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                final totalMembers = membersAsync.valueOrNull?.length ?? 0;
                final thisMonthIncome = incomeAsync.valueOrNull
                        ?.where((i) => i.date.month == now.month && i.date.year == now.year)
                        .fold<double>(0, (sum, item) => sum + item.amount) ??
                    0;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _MetricCard(
                      label: 'Branch Members',
                      value: '$totalMembers',
                      icon: Icons.people_outline,
                      color: CmsTheme.accent,
                      onTap: () => context.go(AppRoutes.members),
                      width: cardWidth,
                    ),
                    _MetricCard(
                      label: 'Income (This Month)',
                      value: '₦${thisMonthIncome.toStringAsFixed(0)}',
                      icon: Icons.trending_up_outlined,
                      color: CmsTheme.success,
                      onTap: () => context.go(AppRoutes.income),
                      width: cardWidth,
                    ),
                    _MetricCard(
                      label: 'Pending Remittances',
                      value: pendingRemittancesAsync.when(data: (v) => '$v', loading: () => '–', error: (_, __) => '–'),
                      icon: Icons.paid_outlined,
                      color: CmsTheme.warning,
                      onTap: () => context.go(AppRoutes.remittances),
                      width: cardWidth,
                    ),
                    _MetricCard(
                      label: 'Pending Resource Reqs',
                      value: pendingRequestsAsync.when(data: (v) => '$v', loading: () => '–', error: (_, __) => '–'),
                      icon: Icons.pending_actions_outlined,
                      color: CmsTheme.info,
                      onTap: () => context.go(AppRoutes.resourceRequests),
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Quick Actions Bar
            const Text('Quick Actions', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickAction(icon: Icons.person_add_outlined, label: '+ Add Member', color: CmsTheme.accent, onTap: () => context.go(AppRoutes.members)),
                _QuickAction(icon: Icons.how_to_reg_outlined, label: '+ Attendance', color: CmsTheme.success, onTap: () => context.go(AppRoutes.attendance)),
                _QuickAction(icon: Icons.trending_up_outlined, label: '+ Income', color: CmsTheme.info, onTap: () => context.go(AppRoutes.income)),
                _QuickAction(icon: Icons.paid_outlined, label: 'Submit Remittance', color: CmsTheme.warning, onTap: () => context.go(AppRoutes.remittances)),
                _QuickAction(icon: Icons.receipt_long_outlined, label: 'Request Budget', color: CmsTheme.danger, onTap: () => context.go(AppRoutes.budgets)),
                _QuickAction(icon: Icons.inventory_2_outlined, label: 'Request Equipment', color: CmsTheme.textSecondary, onTap: () => context.go(AppRoutes.resourceRequests)),
              ],
            ),
            const SizedBox(height: 28),

            // Main Content Row: Celebrations & Trend Charts
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly Celebrations (Left side)
                      SizedBox(
                        width: 360,
                        child: _WeeklyCelebrationsCard(membersAsync: membersAsync),
                      ),
                      const SizedBox(width: 20),
                      // Trend Charts (Right side)
                      Expanded(
                        child: _TrendChartsCard(
                          chartTab: _chartTab,
                          onTabChanged: (idx) => setState(() => _chartTab = idx),
                          eventsAsync: eventsAsync,
                          incomeAsync: incomeAsync,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _WeeklyCelebrationsCard(membersAsync: membersAsync),
                    const SizedBox(height: 20),
                    _TrendChartsCard(
                      chartTab: _chartTab,
                      onTabChanged: (idx) => setState(() => _chartTab = idx),
                      eventsAsync: eventsAsync,
                      incomeAsync: incomeAsync,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Pending Budget Approvals Banner
            pendingBudgetsAsync.when(
              data: (count) => count > 0
                  ? _InfoBanner(
                      message: '$count budget request${count > 1 ? 's are' : ' is'} awaiting Lead Pastor approval.',
                      icon: Icons.account_balance_wallet_outlined,
                      color: CmsTheme.warning,
                      actionLabel: 'View Budgets',
                      onAction: () => context.go(AppRoutes.budgets),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap, required this.width});
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CmsTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Celebrations Card ──────────────────────────────────────────────────

class _WeeklyCelebrationsCard extends StatelessWidget {
  const _WeeklyCelebrationsCard({required this.membersAsync});
  final AsyncValue<List<MemberModel>> membersAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CmsTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cake_outlined, color: CmsTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Celebrations This Week', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
                    Text('Birthdays & Anniversaries', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: CmsTheme.border, height: 1),
          const SizedBox(height: 14),

          membersAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (_, __) => const Text('Unable to load celebrations', style: TextStyle(color: CmsTheme.danger, fontSize: 12)),
            data: (members) {
              final items = _getWeeklyCelebrations(members);
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.event_available_outlined, size: 36, color: CmsTheme.textMuted),
                        SizedBox(height: 8),
                        Text('No birthdays or anniversaries this week', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: items.map((item) => _buildCelebrationTile(item)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<_CelebrationItem> _getWeeklyCelebrations(List<MemberModel> members) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    final result = <_CelebrationItem>[];

    for (final m in members) {
      // Birthday check
      if (m.dob != null) {
        final dobThisYear = DateTime(now.year, m.dob!.month, m.dob!.day);
        final dateToCheck = dobThisYear.isBefore(today) ? DateTime(now.year + 1, m.dob!.month, m.dob!.day) : dobThisYear;
        if (!dateToCheck.isBefore(today) && dateToCheck.isBefore(nextWeek)) {
          final age = now.year - m.dob!.year;
          result.add(_CelebrationItem(
            memberName: m.fullName,
            type: _CelebrationType.birthday,
            date: dateToCheck,
            detail: age > 0 ? 'Turning $age years old' : 'Birthday',
            phone: m.phone,
          ));
        }
      }

      // Wedding anniversary check
      if (m.weddingDate != null) {
        final weddingThisYear = DateTime(now.year, m.weddingDate!.month, m.weddingDate!.day);
        final dateToCheck = weddingThisYear.isBefore(today) ? DateTime(now.year + 1, m.weddingDate!.month, m.weddingDate!.day) : weddingThisYear;
        if (!dateToCheck.isBefore(today) && dateToCheck.isBefore(nextWeek)) {
          final years = now.year - m.weddingDate!.year;
          result.add(_CelebrationItem(
            memberName: m.fullName,
            type: _CelebrationType.anniversary,
            date: dateToCheck,
            detail: years > 0 ? '$years Year${years > 1 ? 's' : ''} Marriage Anniversary' : 'Anniversary',
            phone: m.phone,
          ));
        }
      }
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Widget _buildCelebrationTile(_CelebrationItem item) {
    final dayStr = DateFormat('EEEE, MMM d').format(item.date);
    final isToday = item.date.day == DateTime.now().day && item.date.month == DateTime.now().month;
    final isBday = item.type == _CelebrationType.birthday;
    final color = isBday ? CmsTheme.warning : CmsTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? color.withValues(alpha: 0.1) : CmsTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isToday ? color.withValues(alpha: 0.4) : CmsTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(isBday ? Icons.cake : Icons.favorite, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.memberName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                        child: const Text('TODAY 🎉', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${item.detail} • $dayStr', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: isToday ? color : CmsTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CelebrationType { birthday, anniversary }

class _CelebrationItem {
  _CelebrationItem({required this.memberName, required this.type, required this.date, required this.detail, required this.phone});
  final String memberName;
  final _CelebrationType type;
  final DateTime date;
  final String detail;
  final String phone;
}

// ── Trend Charts Card ─────────────────────────────────────────────────────────

class _TrendChartsCard extends StatelessWidget {
  const _TrendChartsCard({
    required this.chartTab,
    required this.onTabChanged,
    required this.eventsAsync,
    required this.incomeAsync,
  });

  final int chartTab;
  final ValueChanged<int> onTabChanged;
  final AsyncValue<List<EventModel>> eventsAsync;
  final AsyncValue<List<IncomeModel>> incomeAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Analytics & Growth Trends', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
              ),

              // Tab Toggle Buttons
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: CmsTheme.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                child: Row(
                  children: [
                    _chartTabBtn('Attendance', 0, Icons.how_to_reg_outlined),
                    _chartTabBtn('Income', 1, Icons.trending_up_outlined),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 230,
            child: chartTab == 0
                ? _buildAttendanceChart(eventsAsync)
                : _buildIncomeChart(incomeAsync),
          ),
        ],
      ),
    );
  }

  Widget _chartTabBtn(String label, int index, IconData icon) {
    final selected = chartTab == index;
    return InkWell(
      onTap: () => onTabChanged(index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? CmsTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : CmsTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : CmsTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(AsyncValue<List<EventModel>> eventsAsync) {
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading attendance', style: TextStyle(color: CmsTheme.danger))),
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text('No service attendance recorded yet', style: TextStyle(color: CmsTheme.textMuted, fontSize: 12)));
        }

        final sorted = events.reversed.take(7).toList();
        final maxHeadcount = sorted.fold<int>(10, (max, e) => e.headcount > max ? e.headcount : max).toDouble() * 1.2;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxHeadcount,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => CmsTheme.surfaceElevated,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final e = sorted[group.x.toInt()];
                  return BarTooltipItem(
                    '${e.title}\n${rod.toY.toInt()} attendees',
                    const TextStyle(color: CmsTheme.accentLight, fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: CmsTheme.textMuted, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                    final d = sorted[idx].dateTime;
                    return Text('${d.day}/${d.month}', style: const TextStyle(color: CmsTheme.textSecondary, fontSize: 10));
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: CmsTheme.border, strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(sorted.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: sorted[i].headcount.toDouble(),
                    gradient: const LinearGradient(colors: [CmsTheme.accent, CmsTheme.accentLight], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildIncomeChart(AsyncValue<List<IncomeModel>> incomeAsync) {
    return incomeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading income data', style: TextStyle(color: CmsTheme.danger))),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No income records available yet', style: TextStyle(color: CmsTheme.textMuted, fontSize: 12)));
        }

        final sorted = items.take(7).toList().reversed.toList();
        final maxAmount = sorted.fold<double>(1000, (max, i) => i.amount > max ? i.amount : max) * 1.2;

        return LineChart(
          LineChartData(
            maxY: maxAmount,
            minY: 0,
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: CmsTheme.border, strokeWidth: 1)),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (v, meta) => Text('₦${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: CmsTheme.textMuted, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                    final d = sorted[idx].date;
                    return Text('${d.day}/${d.month}', style: const TextStyle(color: CmsTheme.textSecondary, fontSize: 10));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(sorted.length, (i) => FlSpot(i.toDouble(), sorted[i].amount)),
                isCurved: true,
                gradient: const LinearGradient(colors: [CmsTheme.success, CmsTheme.info]),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [CmsTheme.success.withValues(alpha: 0.3), CmsTheme.success.withValues(alpha: 0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.icon, required this.color, required this.actionLabel, required this.onAction});
  final String message, actionLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: color))),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}
