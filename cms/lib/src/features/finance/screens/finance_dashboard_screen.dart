import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:go_router/go_router.dart';

import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/routing/app_router.dart';

// ─── Data Providers ──────────────────────────────────────────────────────────

final _dashIncomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);

final _dashGivingProvider = StreamProvider.autoDispose.family<List<GivingModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchGiving(branchId),
);

final _dashBudgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId),
);

final _dashExpendituresProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditures(branchId),
);

final _dashExpRequestsProvider = StreamProvider.autoDispose.family<List<ExpenditureRequestModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditureRequests(branchId),
);

final _dashNotificationsProvider = StreamProvider.autoDispose.family<List<FinanceNotificationModel>, (String, String)>(
  (ref, params) => ref.watch(financeRepositoryProvider).watchNotifications(params.$1, params.$2),
);

// ─── Main Stateful Widget ───────────────────────────────────────────────────

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter State
  String _periodFilter = 'all'; // 'all', 'thisMonth', 'thisQuarter', 'thisYear', 'custom'
  DateTime? _fromDate;
  DateTime? _toDate;
  String _categoryFilter = 'all';
  String _searchQuery = '';
  int _touchedPieIndex = -1;
  int _touchedExpPieIndex = -1;

  final _currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
  final _compactFmt = NumberFormat.compact();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    final incomeAsync = ref.watch(_dashIncomeProvider(branchId));
    final givingAsync = ref.watch(_dashGivingProvider(branchId));
    final budgetsAsync = ref.watch(_dashBudgetsProvider(branchId));
    final expendituresAsync = ref.watch(_dashExpendituresProvider(branchId));
    final expRequestsAsync = ref.watch(_dashExpRequestsProvider(branchId));
    final notifAsync = user != null
        ? ref.watch(_dashNotificationsProvider((branchId, user.uid)))
        : const AsyncValue<List<FinanceNotificationModel>>.data([]);

    final canRecordIncome = user?.can(AppPermission.recordIncome) ?? false;
    final canCreateBudget = user?.can(AppPermission.createBudgetRequest) ?? false;
    final canCreateExp = user?.can(AppPermission.createExpenditureRequest) ?? false;

    final isLoading = incomeAsync.isLoading ||
        givingAsync.isLoading ||
        budgetsAsync.isLoading ||
        expendituresAsync.isLoading ||
        expRequestsAsync.isLoading;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Bar & Actions ────────────────────────────────────────
          _buildFilterBar(
            canRecordIncome: canRecordIncome,
            canCreateBudget: canCreateBudget,
            canCreateExp: canCreateExp,
          ),
          const SizedBox(height: 16),


          // ── Screen Content ──────────────────────────────────────────────
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: Column(
                children: [
                  // KPI Header Cards
                  _buildKpiMetrics(
                    incomeAsync.valueOrNull ?? [],
                    givingAsync.valueOrNull ?? [],
                    expendituresAsync.valueOrNull ?? [],
                  ),
                  const SizedBox(height: 16),

                  // Tab Bar Navigation
                  Container(
                    height: 42,
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
                        Tab(text: 'Executive Overview & Strategic Insights'),
                        Tab(text: 'Visual Charts & Trends Analysis'),
                        Tab(text: 'Budget Variance & Ledger Comparison'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExecutiveTab(
                          income: _filterIncome(incomeAsync.valueOrNull ?? []),
                          giving: _filterGiving(givingAsync.valueOrNull ?? []),
                          expenditures: _filterExpenditures(expendituresAsync.valueOrNull ?? []),
                          budgets: budgetsAsync.valueOrNull ?? [],
                          pendingBudgets: (budgetsAsync.valueOrNull ?? []).where((b) => b.status == 'pending').toList(),
                          pendingExp: (expRequestsAsync.valueOrNull ?? []).where((r) => r.status == 'pending').toList(),
                          notifications: notifAsync.valueOrNull ?? [],
                        ),
                        _buildVisualChartsTab(
                          income: _filterIncome(incomeAsync.valueOrNull ?? []),
                          giving: _filterGiving(givingAsync.valueOrNull ?? []),
                          expenditures: _filterExpenditures(expendituresAsync.valueOrNull ?? []),
                        ),
                        _buildVarianceTab(
                          budgets: budgetsAsync.valueOrNull ?? [],
                          expenditures: expendituresAsync.valueOrNull ?? [],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Filter Helpers ─────────────────────────────

  Widget _buildFilterBar({
    bool canRecordIncome = false,
    bool canCreateBudget = false,
    bool canCreateExp = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 18, color: CmsTheme.textMuted),
            const SizedBox(width: 8),
            const Text('Period:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
            const SizedBox(width: 8),
            _periodChip('All Time', 'all'),
            const SizedBox(width: 6),
            _periodChip('This Month', 'thisMonth'),
            const SizedBox(width: 6),
            _periodChip('This Quarter', 'thisQuarter'),
            const SizedBox(width: 6),
            _periodChip('This Year', 'thisYear'),
            const SizedBox(width: 16),
            if (_periodFilter == 'custom' || _fromDate != null || _toDate != null) ...[
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  _fromDate == null
                      ? 'Pick Date Range'
                      : '${DateFormat('MMM d').format(_fromDate!)} - ${fromDateToLabel()}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
                onPressed: () => _pickDateRange(),
              ),
              const SizedBox(width: 12),
            ],
            SizedBox(
              width: 180,
              height: 34,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search categories…',
                  hintStyle: const TextStyle(color: CmsTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 14, color: CmsTheme.textMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CmsTheme.border)),
                ),
              ),
            ),
            if (_periodFilter != 'all' || _fromDate != null || _searchQuery.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _periodFilter = 'all';
                  _fromDate = null;
                  _toDate = null;
                  _categoryFilter = 'all';
                  _searchQuery = '';
                }),
                child: const Text('Reset', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.danger)),
              ),
            ],
            const SizedBox(width: 24),
            // Action Buttons
            if (canRecordIncome)
              CmsButton(
                label: 'Income',
                icon: Icons.add,
                compact: true,
                variant: CmsButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.income),
              ),
            if (canRecordIncome) ...[
              const SizedBox(width: 6),
              CmsButton(
                label: 'Giving',
                icon: Icons.volunteer_activism_outlined,
                compact: true,
                variant: CmsButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.giving),
              ),
            ],
            if (canCreateBudget) ...[
              const SizedBox(width: 6),
              CmsButton(
                label: 'Budget',
                icon: Icons.account_balance_wallet_outlined,
                compact: true,
                variant: CmsButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.budgets),
              ),
            ],
            if (canCreateExp) ...[
              const SizedBox(width: 6),
              CmsButton(
                label: 'Expenditure',
                icon: Icons.receipt_long_outlined,
                compact: true,
                onPressed: () => context.go(AppRoutes.expenditures),
              ),
            ],
          ],
        ),
      ),
    );
  }



  String fromDateToLabel() {
    if (_toDate == null) return 'Now';
    return DateFormat('MMM d, yyyy').format(_toDate!);
  }

  Widget _periodChip(String label, String value) {
    final selected = _periodFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _periodFilter = value;
          final now = DateTime.now();
          if (value == 'thisMonth') {
            _fromDate = DateTime(now.year, now.month, 1);
            _toDate = now;
          } else if (value == 'thisQuarter') {
            final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
            _fromDate = DateTime(now.year, qMonth, 1);
            _toDate = now;
          } else if (value == 'thisYear') {
            _fromDate = DateTime(now.year, 1, 1);
            _toDate = now;
          } else if (value == 'all') {
            _fromDate = null;
            _toDate = null;
          }
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _periodFilter = 'custom';
      });
    }
  }

  List<IncomeModel> _filterIncome(List<IncomeModel> list) {
    return list.where((i) {
      if (_fromDate != null && i.date.isBefore(_fromDate!)) return false;
      if (_toDate != null && i.date.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!i.source.toLowerCase().contains(q) && !i.formType.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<GivingModel> _filterGiving(List<GivingModel> list) {
    return list.where((g) {
      if (_fromDate != null && g.date.isBefore(_fromDate!)) return false;
      if (_toDate != null && g.date.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!g.type.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<ExpenditureModel> _filterExpenditures(List<ExpenditureModel> list) {
    return list.where((e) {
      if (_fromDate != null && e.date.isBefore(_fromDate!)) return false;
      if (_toDate != null && e.date.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.category.toLowerCase().contains(q) && !e.description.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // ─────────────────────────── KPI Metrics ─────────────────────────────────

  Widget _buildKpiMetrics(
    List<IncomeModel> income,
    List<GivingModel> giving,
    List<ExpenditureModel> expenditures,
  ) {
    final filteredInc = _filterIncome(income);
    final filteredGiv = _filterGiving(giving);
    final filteredExp = _filterExpenditures(expenditures);

    final totalGeneralIncome = filteredInc.fold<double>(0, (s, i) => s + i.amount);
    final totalMemberGiving = filteredGiv.fold<double>(0, (s, g) => s + g.amount);
    final totalRevenue = totalGeneralIncome + totalMemberGiving;

    final totalApprovedExp = filteredExp.fold<double>(0, (s, e) => s + e.approvedAmount);
    final totalDisbursed = filteredExp.fold<double>(0, (s, e) => s + e.totalDisbursed);
    final netPosition = totalRevenue - totalApprovedExp;
    final isSurplus = netPosition >= 0;

    return Row(
      children: [
        _KpiCard(
          label: 'Total Inflow (Revenue)',
          value: _currencyFmt.format(totalRevenue),
          subtitle: '${filteredInc.length} entries + ${filteredGiv.length} giving records',
          icon: Icons.trending_up,
          color: CmsTheme.success,
        ),
        const SizedBox(width: 14),
        _KpiCard(
          label: 'Approved Expenditures',
          value: _currencyFmt.format(totalApprovedExp),
          subtitle: '${filteredExp.length} approved ledger items',
          icon: Icons.receipt_long,
          color: CmsTheme.accent,
        ),
        const SizedBox(width: 14),
        _KpiCard(
          label: 'Net Cash Position',
          value: '${isSurplus ? '+' : ''}${_currencyFmt.format(netPosition)}',
          subtitle: isSurplus ? 'Surplus (Revenue > Exp)' : 'Deficit (Exp > Revenue)',
          icon: isSurplus ? Icons.account_balance_outlined : Icons.warning_amber_rounded,
          color: isSurplus ? CmsTheme.success : CmsTheme.danger,
        ),
        const SizedBox(width: 14),
        _KpiCard(
          label: 'Disbursement & Liabilities',
          value: _currencyFmt.format(totalDisbursed),
          subtitle: 'Outstanding balance: ${_currencyFmt.format(totalApprovedExp - totalDisbursed)}',
          icon: Icons.payments_outlined,
          color: CmsTheme.warning,
        ),
      ],
    );
  }

  // ─────────────────────────── Tab 1: Executive Overview ───────────────────

  Widget _buildExecutiveTab({
    required List<IncomeModel> income,
    required List<GivingModel> giving,
    required List<ExpenditureModel> expenditures,
    required List<BudgetModel> budgets,
    required List<BudgetModel> pendingBudgets,
    required List<ExpenditureRequestModel> pendingExp,
    required List<FinanceNotificationModel> notifications,
  }) {
    final totalGenInc = income.fold<double>(0, (s, i) => s + i.amount);
    final totalGiv = giving.fold<double>(0, (s, g) => s + g.amount);
    final totalRev = totalGenInc + totalGiv;
    final totalExp = expenditures.fold<double>(0, (s, e) => s + e.approvedAmount);
    final totalDisbursed = expenditures.fold<double>(0, (s, e) => s + e.totalDisbursed);
    final netPos = totalRev - totalExp;

    final operatingMargin = totalRev > 0 ? (netPos / totalRev) * 100 : 0.0;
    final disbursementRate = totalExp > 0 ? (totalDisbursed / totalExp) * 100 : 0.0;

    // Top Revenue Source
    final Map<String, double> revByCategory = {};
    for (final i in income) {
      revByCategory[i.source] = (revByCategory[i.source] ?? 0) + i.amount;
    }
    for (final g in giving) {
      final key = 'Member Giving (${g.type})';
      revByCategory[key] = (revByCategory[key] ?? 0) + g.amount;
    }
    String topRevSource = 'N/A';
    double topRevAmount = 0;
    revByCategory.forEach((k, v) {
      if (v > topRevAmount) {
        topRevAmount = v;
        topRevSource = k;
      }
    });

    // Top Expenditure Category
    final Map<String, double> expByCategory = {};
    for (final e in expenditures) {
      expByCategory[e.category] = (expByCategory[e.category] ?? 0) + e.approvedAmount;
    }
    String topExpCat = 'N/A';
    double topExpAmount = 0;
    expByCategory.forEach((k, v) {
      if (v > topExpAmount) {
        topExpAmount = v;
        topExpCat = k;
      }
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Smart Insights Banner
          _buildExecutiveInsightsBanner(
            operatingMargin: operatingMargin,
            netPos: netPos,
            disbursementRate: disbursementRate,
            topRevSource: topRevSource,
            topRevAmount: topRevAmount,
            topExpCat: topExpCat,
            topExpAmount: topExpAmount,
            totalRev: totalRev,
          ),
          const SizedBox(height: 20),

          // Two-column layout: Pending Approvals & Notifications
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Requests Queue
              Expanded(
                flex: 3,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Pending Approvals Queue', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          StatusBadge('${pendingBudgets.length + pendingExp.length} pending'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Financial requests awaiting Lead Pastor review & authorization', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      const SizedBox(height: 16),
                      if (pendingBudgets.isEmpty && pendingExp.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(child: Text('No pending budget or expenditure requests.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted))),
                        )
                      else
                        Column(
                          children: [
                            ...pendingBudgets.map((b) => _buildPendingRow(
                              title: b.category,
                              subtitle: 'Budget Request · ${b.fiscalPeriod}',
                              amount: b.requestedAmount,
                              icon: Icons.account_balance_wallet_outlined,
                            )),
                            ...pendingExp.map((r) => _buildPendingRow(
                              title: r.description,
                              subtitle: 'Expenditure Request · ${r.category}',
                              amount: r.amount,
                              icon: Icons.receipt_long_outlined,
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Recent Notifications & Changes
              Expanded(
                flex: 2,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Approval Alerts & Diffs', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.financeNotifications),
                            child: const Text('View All', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(child: Text('No recent notifications', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notifications.take(4).length,
                          separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 16),
                          itemBuilder: (_, i) {
                            final n = notifications[i];
                            return _buildNotificationMiniTile(n);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveInsightsBanner({
    required double operatingMargin,
    required double netPos,
    required double disbursementRate,
    required String topRevSource,
    required double topRevAmount,
    required String topExpCat,
    required double topExpAmount,
    required double totalRev,
  }) {
    final isHealthy = netPos >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHealthy ? CmsTheme.success.withValues(alpha: 0.3) : CmsTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.insights : Icons.warning_amber_rounded,
                color: isHealthy ? CmsTheme.success : CmsTheme.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Executive Financial Diagnosis & Health Assessment',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isHealthy ? CmsTheme.success : CmsTheme.danger,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isHealthy ? CmsTheme.success : CmsTheme.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Margin: ${operatingMargin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHealthy ? CmsTheme.success : CmsTheme.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  title: 'Financial Surplus / Reserves',
                  detail: isHealthy
                      ? 'Healthy position with a net surplus of ${_currencyFmt.format(netPos)}. Cash reserves meet operational target.'
                      : 'WARNING: Operating at a net deficit of ${_currencyFmt.format(netPos.abs())}. Expenditures exceed inflows.',
                  icon: isHealthy ? Icons.check_circle_outline : Icons.error_outline,
                  color: isHealthy ? CmsTheme.success : CmsTheme.danger,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InsightTile(
                  title: 'Dominant Inflow Driver',
                  detail: topRevAmount > 0
                      ? '"$topRevSource" generated ${_currencyFmt.format(topRevAmount)} (${(totalRev > 0 ? (topRevAmount / totalRev * 100) : 0).toStringAsFixed(1)}% of total revenue).'
                      : 'No revenue records logged for selected period.',
                  icon: Icons.trending_up,
                  color: CmsTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InsightTile(
                  title: 'Primary Cost Center',
                  detail: topExpAmount > 0
                      ? '"$topExpCat" represents highest expenditure at ${_currencyFmt.format(topExpAmount)}.'
                      : 'No expenditures logged for selected period.',
                  icon: Icons.pie_chart_outline,
                  color: CmsTheme.warning,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InsightTile(
                  title: 'Disbursement Execution Rate',
                  detail: '${disbursementRate.toStringAsFixed(1)}% of approved funds have been disbursed to beneficiaries.',
                  icon: Icons.speed,
                  color: CmsTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Tab 2: Visual Charts ────────────────────────

  Widget _buildVisualChartsTab({
    required List<IncomeModel> income,
    required List<GivingModel> giving,
    required List<ExpenditureModel> expenditures,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Row 1: Income vs Expenditure Monthly Comparison (Bar Chart)
          CmsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Monthly Financial Trend (Revenue vs Expenditure)', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                        SizedBox(height: 2),
                        Text('Comparison of total monthly inflows vs approved expenditures', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    _buildLegendItem('Inflows (Revenue)', CmsTheme.success),
                    const SizedBox(width: 16),
                    _buildLegendItem('Expenditures', CmsTheme.accent),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 260,
                  child: _buildMonthlyComparisonBarChart(income, giving, expenditures),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Row 2: Revenue Distribution vs Expenditure Distribution (Two Donut Charts)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart 1: Revenue Streams
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue Breakdown by Source', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Distribution of tithes, offerings, & funds', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: _buildRevenueDonutChart(income, giving),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Chart 2: Expenditure Categories
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expenditure Allocation by Category', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Cost breakdown across church departments & projects', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: _buildExpenditureDonutChart(expenditures),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonBarChart(
    List<IncomeModel> income,
    List<GivingModel> giving,
    List<ExpenditureModel> expenditures,
  ) {
    // Group totals by Month (Jan..Dec of current year)
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));

    final List<BarChartGroupData> groups = [];
    double maxY = 1000;

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final incTotal = income
          .where((x) => x.date.year == m.year && x.date.month == m.month)
          .fold<double>(0, (s, x) => s + x.amount) +
          giving
              .where((x) => x.date.year == m.year && x.date.month == m.month)
              .fold<double>(0, (s, x) => s + x.amount);

      final expTotal = expenditures
          .where((x) => x.date.year == m.year && x.date.month == m.month)
          .fold<double>(0, (s, x) => s + x.approvedAmount);

      if (incTotal > maxY) maxY = incTotal;
      if (expTotal > maxY) maxY = expTotal;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: incTotal, color: CmsTheme.success, width: 14, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: expTotal, color: CmsTheme.accent, width: 14, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (v, _) => Text('₦${_compactFmt.format(v)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, _) {
                if (i.toInt() >= 0 && i.toInt() < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(DateFormat('MMM yyyy').format(months[i.toInt()]), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }

  Widget _buildRevenueDonutChart(List<IncomeModel> income, List<GivingModel> giving) {
    final Map<String, double> map = {};
    for (final i in income) {
      map[i.source] = (map[i.source] ?? 0) + i.amount;
    }
    for (final g in giving) {
      final key = 'Giving: ${g.type.toUpperCase()}';
      map[key] = (map[key] ?? 0) + g.amount;
    }

    if (map.isEmpty) {
      return const Center(child: Text('No revenue data available', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)));
    }

    final total = map.values.fold<double>(0, (s, v) => s + v);
    final colors = [CmsTheme.success, CmsTheme.accent, CmsTheme.warning, CmsTheme.info, Colors.purple, Colors.orange];

    final entries = map.entries.toList();
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < entries.length; i++) {
      final isTouched = i == _touchedPieIndex;
      final pct = (entries[i].value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: entries[i].value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: isTouched ? 55 : 45,
          titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 180,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(entry.key, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                      Text('₦${_compactFmt.format(entry.value)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenditureDonutChart(List<ExpenditureModel> expenditures) {
    final Map<String, double> map = {};
    for (final e in expenditures) {
      map[e.category] = (map[e.category] ?? 0) + e.approvedAmount;
    }

    if (map.isEmpty) {
      return const Center(child: Text('No expenditure data available', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)));
    }

    final total = map.values.fold<double>(0, (s, v) => s + v);
    final colors = [CmsTheme.accent, CmsTheme.warning, CmsTheme.danger, CmsTheme.info, Colors.purple, Colors.teal];

    final entries = map.entries.toList();
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < entries.length; i++) {
      final isTouched = i == _touchedExpPieIndex;
      final pct = (entries[i].value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: entries[i].value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: isTouched ? 55 : 45,
          titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _touchedExpPieIndex = -1;
                      return;
                    }
                    _touchedExpPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 180,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(entry.key, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                      Text('₦${_compactFmt.format(entry.value)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Tab 3: Budget Variance ──────────────────────

  Widget _buildVarianceTab({
    required List<BudgetModel> budgets,
    required List<ExpenditureModel> expenditures,
  }) {
    // Map expenditure totals by category
    final Map<String, double> actualExpMap = {};
    for (final e in expenditures) {
      actualExpMap[e.category] = (actualExpMap[e.category] ?? 0) + e.approvedAmount;
    }

    return CmsCard(
      padding: EdgeInsets.zero,
      child: budgets.isEmpty
          ? const CmsEmptyState(
              icon: Icons.table_chart_outlined,
              title: 'No budget allocations found',
              subtitle: 'Create and approve budget requests to track budget vs. actual variance.',
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 20,
                minWidth: 840,
                headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) return CmsTheme.surfaceElevated;
                  return CmsTheme.surface;
                }),
                columns: const [
                  DataColumn2(label: Text('Category', style: _colStyle), size: ColumnSize.M),
                  DataColumn2(label: Text('Fiscal Period', style: _colStyle), size: ColumnSize.S),
                  DataColumn2(label: Text('Requested', style: _colStyle), size: ColumnSize.S, numeric: true),
                  DataColumn2(label: Text('Approved Budget', style: _colStyle), size: ColumnSize.M, numeric: true),
                  DataColumn2(label: Text('Actual Spent', style: _colStyle), size: ColumnSize.M, numeric: true),
                  DataColumn2(label: Text('Variance (Budget - Spent)', style: _colStyle), size: ColumnSize.M, numeric: true),
                  DataColumn2(label: Text('Status', style: _colStyle), size: ColumnSize.S),
                ],
                rows: budgets.map((b) {
                  final approved = b.approvedAmount ?? b.requestedAmount;
                  final actual = actualExpMap[b.category] ?? 0.0;
                  final variance = approved - actual;
                  final isOver = actual > approved;

                  return DataRow2(
                    cells: [
                      DataCell(Text(b.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
                      DataCell(Text(b.fiscalPeriod, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                      DataCell(Text('₦${_compactFmt.format(b.requestedAmount)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
                      DataCell(Text('₦${_currencyFmt.format(approved)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary))),
                      DataCell(Text('₦${_currencyFmt.format(actual)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary))),
                      DataCell(Text(
                        '${variance >= 0 ? '+' : ''}${_currencyFmt.format(variance)}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: isOver ? CmsTheme.danger : CmsTheme.success),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isOver ? CmsTheme.danger : CmsTheme.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOver ? 'OVER BUDGET' : 'ON BUDGET',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: isOver ? CmsTheme.danger : CmsTheme.success),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  // ─────────────────────────── Small Helper Widgets ────────────────────────

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
      ],
    );
  }

  Widget _buildPendingRow({
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: CmsTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: CmsTheme.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(_currencyFmt.format(amount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.warning)),
        ],
      ),
    );
  }

  Widget _buildNotificationMiniTile(FinanceNotificationModel n) {
    final isChange = n.type.contains('with-changes');
    final isRejected = n.type.contains('rejected');
    final color = isRejected ? CmsTheme.danger : isChange ? CmsTheme.warning : CmsTheme.success;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.message, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary)),
              if (n.changesSummary.isNotEmpty) ...[
                const SizedBox(height: 4),
                DiffViewer(changes: n.changesSummary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Sub-widgets ─────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmsTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

const _colStyle = TextStyle(
  color: CmsTheme.textSecondary,
  fontFamily: 'Inter',
  fontSize: 12,
  fontWeight: FontWeight.w600,
);
